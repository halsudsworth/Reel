-- /reel event: join a tournament or event by pasting its event string from halsudsworth.com.
--
-- The string is "!REELEV1!" and the base64 of a JSON document (site/FORMAT.md, "Event
-- string"). Joined strings are kept per character in data.events and go out with the
-- journal export, so halsudsworth.com scores the paste against them. While an event runs,
-- the event tracker shows a counter worked out from this character's catches.
--
-- The counter follows the site's scoring (site/server/lib/core.php) closely enough to
-- show progress; the site's score is the one that counts.

local _, ns = ...
local W = ns.W

local PREFIX = "!REELEV1!"
local KEEP_DAYS = 60 -- a joined event is dropped this long after it ends
local MAX_EVENTS = 8

-- Base64 and JSON decoding -------------------------------------------------------------

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local B64VAL = {}
for i = 1, #B64 do B64VAL[B64:byte(i)] = i - 1 end

local function Unbase64(s)
    s = s:gsub("[^%w%+/=]", "")
    if #s % 4 ~= 0 then return end
    local out = {}
    for i = 1, #s, 4 do
        local a, b, c, d = s:byte(i, i + 3)
        local va, vb = B64VAL[a], B64VAL[b]
        if not (va and vb) then return end
        local vc, vd = B64VAL[c] or 0, B64VAL[d] or 0
        local n = va * 262144 + vb * 4096 + vc * 64 + vd
        out[#out + 1] = string.char(math.floor(n / 65536) % 256)
        if c ~= 61 then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
        if d ~= 61 then out[#out + 1] = string.char(n % 256) end
    end
    return table.concat(out)
end

-- A small JSON reader: objects, arrays, strings, numbers, true, false, null (as nil).
local function ParseJSON(s)
    local i = 1
    local Value
    local function Skip() i = s:find("[^ \t\r\n]", i) or #s + 1 end
    local function Fail() error("bad json", 0) end
    local function Utf8(cp)
        if cp < 0x80 then return string.char(cp) end
        if cp < 0x800 then return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64) end
        return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
    end
    local function String()
        i = i + 1
        local out = {}
        while true do
            local c = s:sub(i, i)
            if c == "" then Fail() end
            if c == '"' then i = i + 1; return table.concat(out) end
            if c == "\\" then
                local e = s:sub(i + 1, i + 1)
                local map = { ['"'] = '"', ["\\"] = "\\", ["/"] = "/", b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }
                if map[e] then out[#out + 1] = map[e]; i = i + 2
                elseif e == "u" then
                    local cp = tonumber(s:sub(i + 2, i + 5), 16) or Fail()
                    out[#out + 1] = Utf8(cp); i = i + 6
                else Fail() end
            else
                out[#out + 1] = c; i = i + 1
            end
        end
    end
    Value = function()
        Skip()
        local c = s:sub(i, i)
        if c == "{" then
            local t = {}
            i = i + 1; Skip()
            if s:sub(i, i) == "}" then i = i + 1; return t end
            while true do
                Skip()
                if s:sub(i, i) ~= '"' then Fail() end
                local k = String()
                Skip()
                if s:sub(i, i) ~= ":" then Fail() end
                i = i + 1
                t[k] = Value()
                Skip()
                local d = s:sub(i, i); i = i + 1
                if d == "}" then return t end
                if d ~= "," then Fail() end
            end
        elseif c == "[" then
            local t, n = {}, 0
            i = i + 1; Skip()
            if s:sub(i, i) == "]" then i = i + 1; return t end
            while true do
                n = n + 1
                t[n] = Value()
                Skip()
                local d = s:sub(i, i); i = i + 1
                if d == "]" then return t end
                if d ~= "," then Fail() end
            end
        elseif c == '"' then return String()
        elseif s:sub(i, i + 3) == "true" then i = i + 4; return true
        elseif s:sub(i, i + 4) == "false" then i = i + 5; return false
        elseif s:sub(i, i + 3) == "null" then i = i + 4; return nil
        else
            local num = s:match("^-?%d+%.?%d*[eE]?[-+]?%d*", i)
            if not num or num == "" then Fail() end
            i = i + #num
            return tonumber(num) or Fail()
        end
    end
    local ok, v = pcall(Value)
    if ok then return v end
end

-- Event strings ------------------------------------------------------------------------

local SCORINGS = { race = true, most = true, best30 = true, best = true, target = true, set = true, variety = true, quest = true }

local function AsList(v)
    if v == nil then return nil end
    if type(v) == "table" then return v end
    return { v }
end

-- Event codes from halsudsworth.com name zones in English; catches carry the zone in the
-- client's language, so each zone goes through its map ID to this client's name (ns.LocalZone).
-- Subzones have no IDs, so they stay as they are.
local function LocalZones(list)
    if not list then return nil end
    local out = {}
    for i, name in ipairs(list) do out[i] = ns.LocalZone(name) end
    return out
end

-- The event in a string, or nil and why not.
local function Decode(str)
    str = strtrim(str or "")
    if str:sub(1, #PREFIX) ~= PREFIX then return nil, "That isn't an event string. It starts with " .. PREFIX .. "." end
    local json = Unbase64(str:sub(#PREFIX + 1))
    local ev = json and ParseJSON(json)
    if type(ev) ~= "table" or ev.v ~= 1 then return nil, "That event string is damaged. Copy it again." end
    if type(ev.id) ~= "string" or type(ev.name) ~= "string" or not SCORINGS[ev.scoring] then
        return nil, "This version of R.E.E.L. can't count that event."
    end
    if ev.scoring == "best" and not (tonumber(ev.minutes) and ev.minutes >= 1) then
        return nil, "That event string is damaged. Copy it again."
    end
    if type(ev.start) ~= "string" or type(ev["end"]) ~= "string" or type(ev.window) ~= "table" then
        return nil, "That event string is damaged. Copy it again."
    end
    -- Spots: area IDs in subId/notSubId (sub/notSub keep English names for older versions).
    ev.zone, ev.fish, ev.sub = LocalZones(AsList(ev.zone)), AsList(ev.fish), AsList(ev.subId or ev.sub)
    for _, n in ipairs(ev.needs or {}) do
        n.zone, n.fish = LocalZones(AsList(n.zone)), AsList(n.fish)
        n.sub, n.notSub = AsList(n.subId or n.sub), AsList(n.notSubId or n.notSub)
    end
    return ev
end

local decoded = {} -- string -> event
local function Event(str)
    if decoded[str] == nil then decoded[str] = Decode(str) or false end
    return decoded[str] or nil
end

-- Server clock ------------------------------------------------------------------------

-- The server clock's minutes from UTC (GetGameTime against UTC), rounded to 15.
local function ServerOffset()
    if not GetGameTime then return 0 end
    local h, m = GetGameTime()
    local u = date("!*t", ns.Now())
    local d = ((h - u.hour) * 60 + (m - u.min)) % 1440
    if d > 720 then d = d - 1440 end
    return math.floor(d / 15 + 0.5) * 15
end

-- Date "YYYY-MM-DD" and minute of the day on the server clock.
local function Clock(t, offset)
    local u = t + offset * 60
    local c = date("!*t", u)
    return date("!%Y-%m-%d", u), c.hour * 60 + c.min
end

-- Unix time of a date's midnight in UTC (days from civil, so the player's own time zone
-- doesn't enter into it).
local function DateEpoch(d)
    local y, m, day = d:match("(%d+)-(%d+)-(%d+)")
    y, m, day = tonumber(y), tonumber(m), tonumber(day)
    if m <= 2 then y = y - 1 end
    local era = math.floor(y / 400)
    local yoe = y - era * 400
    local doy = math.floor((153 * ((m + 9) % 12) + 2) / 5) + day - 1
    local doe = yoe * 365 + math.floor(yoe / 4) - math.floor(yoe / 100) + doy
    return (era * 146097 + doe - 719468) * 86400
end

-- Seconds until the event's last date is over on the server clock.
local function TimeLeft(ev, offset)
    return DateEpoch(ev["end"]) + 86400 - offset * 60 - ns.Now()
end

local function HM(s) return tonumber(s:sub(1, 2)) * 60 + tonumber(s:sub(4, 5)) end

local function PrevDate(d)
    local y, m, day = d:match("(%d+)-(%d+)-(%d+)")
    local t = time({ year = tonumber(y), month = tonumber(m), day = tonumber(day), hour = 12 }) - 86400
    return date("%Y-%m-%d", t)
end

local function InWindow(ev, t, offset)
    local w = ev.window
    local d, min = Clock(t, offset)
    if w.kind == "days" then return d >= ev.start and d <= ev["end"] end
    local from, to = HM(w.from), HM(w.to)
    local inside
    if from < to then
        inside = min >= from and min < to
    else
        inside = min >= from or min < to
        if min < to then d = PrevDate(d) end
    end
    return inside and d >= ev.start and d <= ev["end"]
end

-- Matching catches ---------------------------------------------------------------------

-- A subzone in an event is an area ID (C_Map.GetAreaInfo gives its name in the client's
-- language, which is how catches record it) or, in older events, an English name.
local function SubKey(s)
    if type(s) == "number" then
        local ok, name = pcall(C_Map.GetAreaInfo, s)
        s = ok and type(name) == "string" and name ~= "" and name or nil
    end
    return s and (s:lower():gsub("^the ", "")) or nil
end

local function InList(list, v)
    for _, x in ipairs(list) do if x == v then return true end end
    return false
end

local function SubIn(list, sub)
    if not sub then return false end
    local k = SubKey(sub)
    for _, s in ipairs(list) do if SubKey(s) == k then return true end end
    return false
end

-- Row: { time, zone, subzone, x, y, itemID, qty, skill, level }
local function Matches(zones, fish, c)
    if zones and not InList(zones, c[2]) then return false end
    if fish then return InList(fish, c[6]) end
    return ns.FISH[c[6]] ~= nil
end

local function MatchesNeed(n, c, min)
    if not Matches(n.zone, n.fish, c) then return false end
    if n.hours then
        local f, t = HM(n.hours.from), HM(n.hours.to)
        if f <= t then if min < f or min >= t then return false end
        elseif min < f and min >= t then return false end
    end
    if n.notSub and SubIn(n.notSub, c[3]) then return false end
    if n.sub then return SubIn(n.sub, c[3]) end
    return true
end

-- This character's catches inside the event's window, oldest first, with each one's
-- minute of the day on the server clock.
local function Inside(ev, offset)
    local out = {}
    for _, c in ipairs(ns.Data().catches) do
        if InWindow(ev, c[1], offset)
            and (not ev.maxLevel or (c[9] and c[9] <= ev.maxLevel))
            and (not ev.sub or SubIn(ev.sub, c[3])) then
            local _, min = Clock(c[1], offset)
            out[#out + 1] = { c = c, min = min }
        end
    end
    return out
end

-- The tracker's text for one event, its lines, and the number (done lines, best, or fish).
local function Progress(ev, offset)
    local inside = Inside(ev, offset)
    local s = ev.scoring
    if s == "set" or s == "quest" then
        local done, details = 0, {}
        for i, n in ipairs(ev.needs or {}) do
            local count, seen, kinds = 0, {}, 0
            for _, e in ipairs(inside) do
                if MatchesNeed(n, e.c, e.min) then
                    if n.distinct then
                        local k = n.distinct == "zone" and e.c[2] or n.distinct == "sub" and SubKey(e.c[3] or "") or e.c[6]
                        if not seen[k] then seen[k] = true; kinds = kinds + 1 end
                    else
                        count = count + (e.c[7] or 1)
                    end
                end
            end
            local have = n.distinct and kinds or count
            if have >= n.n then done = done + 1 end
            details[#details + 1] = { text = string.format("%s: %d/%d", n.label or ("Line " .. i), math.min(have, n.n), n.n), done = have >= n.n }
        end
        return string.format("%d of %d done", done, #(ev.needs or {})), details, done
    end
    if s == "variety" and ev.variety then
        local zs, fs, nz, nf = {}, {}, 0, 0
        for _, e in ipairs(inside) do
            if ns.FISH[e.c[6]] then
                if not zs[e.c[2]] then zs[e.c[2]] = true; nz = nz + 1 end
                if not fs[e.c[6]] then fs[e.c[6]] = true; nf = nf + 1 end
            end
        end
        return string.format("%d of %d fish, %d of %d zones", math.min(nf, ev.variety.fish), ev.variety.fish, math.min(nz, ev.variety.zones), ev.variety.zones)
    end
    local total, times = 0, {}
    for _, e in ipairs(inside) do
        if Matches(ev.zone, ev.fish, e.c) then
            total = total + (e.c[7] or 1)
            for _ = 1, (e.c[7] or 1) do times[#times + 1] = e.c[1] end
        end
    end
    if s == "best30" or s == "best" then
        local minutes = s == "best" and tonumber(ev.minutes) or 30
        local best, k = 0, 1
        for i = 1, #times do
            while times[i] - times[k] > minutes * 60 do k = k + 1 end
            best = math.max(best, i - k + 1)
        end
        local recent, now = 0, ns.Now()
        for i = #times, 1, -1 do
            if now - times[i] > minutes * 60 then break end
            recent = recent + 1
        end
        local bestText = string.format("Best %d min: %d fish", minutes, best)
        return bestText, { { text = bestText }, { text = string.format("Last %d min: %d fish", minutes, recent) } }, best
    end
    if (s == "race" or s == "target") and ev.target then
        return string.format("%d of %d fish", math.min(total, ev.target), ev.target), nil, total
    end
    return string.format("%d fish", total), nil, total
end

-- Joined events ------------------------------------------------------------------------

local function Joined()
    local data = ns.Data()
    data.events = data.events or {}
    return data.events
end

-- Event ids the player took off the bar; they stay joined and in the export.
local function Untracked()
    local data = ns.Data()
    data.eventUntracked = data.eventUntracked or {}
    return data.eventUntracked
end

-- Joined event strings, for the export.
function ns.EventStrings()
    return Joined()
end

local function Today(offset) return (Clock(ns.Now(), offset)) end

-- Drop events that ended more than KEEP_DAYS ago.
local function Prune()
    local list = Joined()
    local cutoff = date("!%Y-%m-%d", ns.Now() - KEEP_DAYS * 86400)
    for i = #list, 1, -1 do
        local ev = Event(list[i])
        if not ev or ev["end"] < cutoff then table.remove(list, i) end
    end
end

local function Join(str)
    local ev, why = Decode(str)
    if not ev then ns.Print(why); return false end
    str = strtrim(str)
    local list = Joined()
    for i = #list, 1, -1 do
        local old = Event(list[i])
        if not old or old.id == ev.id then table.remove(list, i) end
    end
    if #list >= MAX_EVENTS then
        ns.Print(string.format("You're in %d events already. Leave one first.", MAX_EVENTS))
        return false
    end
    list[#list + 1] = str
    decoded[str] = ev
    ns.Print(string.format("Joined %s (%s to %s, server time). Your journal paste is scored for it.", ev.name, ev.start, ev["end"]))
    ns.UpdateBar()
    return true
end

local function Leave(index)
    local list = Joined()
    local ev = list[index] and Event(list[index])
    table.remove(list, index)
    if ev then Untracked()[ev.id] = nil end
    if ev then ns.Print("Left " .. ev.name .. ".") end
    ns.UpdateBar()
end

-- Bar ----------------------------------------------------------------------------------

-- Counting reads every catch, so each event's count is kept until a catch comes in or
-- the minute changes (a window opening or closing).
local cache = {} -- event string -> { n, minute, text }

local function CachedProgress(str, ev, offset)
    local n, minute = #ns.Data().catches, math.floor(ns.Now() / 60)
    local c = cache[str]
    if not (c and c.n == n and c.minute == minute) then
        local text, details = Progress(ev, offset)
        c = { n = n, minute = minute, text = text, details = details }
        cache[str] = c
    end
    return c.text, c.details
end

-- Event tracker ----------------------------------------------------------------------
-- Tracked events that are running, listed like the quest tracker: the name, then its
-- objectives. Drag the title to move it, click it to fold it up.

local TRACKER_WIDTH = 240
local tracker, title, lines = nil, nil, {}

ns.RegisterDefaults({ tracker = true, trackerCollapsed = false })

local function TrackerLine(i)
    if not lines[i] then
        lines[i] = tracker:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lines[i]:SetJustifyH("LEFT")
        lines[i]:SetWidth(TRACKER_WIDTH - 12)
    end
    return lines[i]
end

-- What the tracker shows: one block per running, tracked event.
local function TrackerBlocks()
    local offset = ServerOffset()
    local today = Today(offset)
    local blocks = {}
    for _, str in ipairs(Joined()) do
        local ev = Event(str)
        if ev and not Untracked()[ev.id] and today >= ev.start and today <= ev["end"] then
            local text, details = CachedProgress(str, ev, offset)
            local rows = {}
            if details then
                for _, d in ipairs(details) do rows[#rows + 1] = { text = d.text, done = d.done } end
            else
                rows[1] = { text = text }
            end
            local left = ns.FormatTime(TimeLeft(ev, offset)) .. " left"
            if ev.window.kind ~= "days" and not InWindow(ev, ns.Now(), offset) then left = left .. ", opens " .. ev.window.from end
            rows[#rows + 1] = { text = left, dim = true }
            blocks[#blocks + 1] = { name = ev.name, rows = rows }
        end
    end
    return blocks
end

function ns.UpdateTracker()
    if not tracker or not ns.Data() then return end
    local s = ReelDB.settings
    local blocks = s.tracker and TrackerBlocks() or {}
    if #blocks == 0 then tracker:Hide(); return end
    title:SetText((s.trackerCollapsed and "+ " or "- ") .. "Fishing events (" .. #blocks .. ")")
    local n, y = 0, -18
    if not s.trackerCollapsed then
        for _, b in ipairs(blocks) do
            n = n + 1
            local l = TrackerLine(n)
            l:SetFontObject("GameFontNormal")
            l:SetText(b.name)
            l:ClearAllPoints()
            l:SetPoint("TOPLEFT", 0, y - 6)
            y = y - 6 - l:GetStringHeight()
            for _, r in ipairs(b.rows) do
                n = n + 1
                l = TrackerLine(n)
                l:SetFontObject("GameFontHighlightSmall")
                l:SetText((r.done or r.dim) and ("|cff888888- " .. r.text .. "|r") or ("- " .. r.text))
                l:ClearAllPoints()
                l:SetPoint("TOPLEFT", 10, y - 2)
                y = y - 2 - l:GetStringHeight()
            end
        end
    end
    for i, l in ipairs(lines) do l:SetShown(i <= n) end
    tracker:SetHeight(-y + 4)
    tracker:Show()
end

ns.On("REEL_READY", function()
    local s = ReelDB.settings
    tracker = CreateFrame("Frame", "ReelEventTracker", UIParent)
    tracker:SetWidth(TRACKER_WIDTH)
    tracker:SetFrameStrata("LOW")
    tracker:SetMovable(true)
    tracker:SetClampedToScreen(true)
    local p = s.trackerPoint
    if p then tracker:SetPoint(p[1], UIParent, p[2], p[3], p[4]) else tracker:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -90, -250) end

    local head = CreateFrame("Button", nil, tracker)
    head:SetPoint("TOPLEFT")
    head:SetSize(TRACKER_WIDTH, 16)
    head:RegisterForDrag("LeftButton")
    head:RegisterForClicks("LeftButtonUp")
    head:SetScript("OnDragStart", function() tracker:StartMoving() end)
    head:SetScript("OnDragStop", function()
        tracker:StopMovingOrSizing()
        local point, _, relativePoint, x, y = tracker:GetPoint()
        s.trackerPoint = { point, relativePoint, x, y }
    end)
    head:SetScript("OnClick", function()
        s.trackerCollapsed = not s.trackerCollapsed
        ns.UpdateTracker()
    end)
    title = head:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT")
    title:SetJustifyH("LEFT")
    tracker:Hide()
    C_Timer.NewTicker(5, ns.UpdateTracker)
    ns.UpdateTracker()
end)
ns.On("REEL_DATA_CHANGED", function() ns.UpdateTracker() end)

-- Events tab ---------------------------------------------------------------------------
-- Direction A's Events screen (site/art/ui/mockup/index.html): Hal's calendar carried offline on
-- the left (what's running with this character's standing, today's and this week's challenge),
-- joining by code and the joined list on the right, then what's coming up; Export at the foot.

local C = W.C
local input, RefreshRows

-- What a joined event's row says under its name: progress and time left while it runs.
local function Status(str, ev)
    local offset = ServerOffset()
    local today = Today(offset)
    if today < ev.start then return "starts " .. ev.start end
    if today > ev["end"] then return "ended " .. ev["end"] end
    return CachedProgress(str, ev, offset) .. " · " .. ns.FormatTime(TimeLeft(ev, offset)) .. " left"
end
local GetItemIconCompat = C_Item and C_Item.GetItemIconByID or GetItemIcon
local MONTHS = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" }
local DAYS = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }

local function Parts(d)
    local y, m, day = d:match("(%d+)-(%d+)-(%d+)")
    local weekday = (math.floor(DateEpoch(d) / 86400) + 4) % 7 + 1 -- 1970-01-01 was a Thursday
    return tonumber(y), tonumber(m), tonumber(day), weekday
end

-- "November 4", "Fri November 20", "Monday November 9", "Sunday, November 15"
local function MonthDay(d) local _, m, day = Parts(d); return MONTHS[m] .. " " .. day end
local function ShortDay(d) local _, _, _, w = Parts(d); return DAYS[w]:sub(1, 3) .. " " .. MonthDay(d) end
local function LongDay(d) local _, _, _, w = Parts(d); return DAYS[w] .. " " .. MonthDay(d) end

local function Span(ev, Day)
    if ev.start == ev["end"] then return Day(ev.start) end
    return Day(ev.start) .. " to " .. Day(ev["end"])
end

-- A zone's name: the client's own (in its language) where it knows the map, else the calendar's.
local function ZoneName(id)
    local info = C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
    return info and info.name or (ns.CALENDAR_DATA.maps[id] or tostring(id))
end

-- "Durotar", "Hillsbrad Foothills, Duskwood or Ashenvale"
local function ZoneList(zones)
    if not zones or #zones == 0 then return nil end
    local names = {}
    for i, id in ipairs(zones) do names[i] = ZoneName(id) end
    if #names == 1 then return names[1] end
    return table.concat(names, ", ", 1, #names - 1) .. " or " .. names[#names]
end

local function IsJoined(id)
    for _, str in ipairs(Joined()) do
        local ev = Event(str)
        if ev and ev.id == id then return true end
    end
    return false
end

-- Map IDs as the zone names this client writes in each catch (the journal keeps GetZoneText(),
-- which is the map's own name, in the client's language).
local function ZoneNames(zones)
    if not zones then return nil end
    local out = {}
    for i, id in ipairs(zones) do out[i] = ZoneName(id) end
    return out
end

-- A calendar event as the counter reads it: whole dates on the server clock, and its zones (map
-- IDs in the calendar) as the names the catches carry.
local function Countable(ev)
    local c = {}
    for k, v in pairs(ev) do c[k] = v end
    c.window = { kind = "days" }
    c.zone = ZoneNames(ev.zone)
    if ev.needs then
        c.needs = {}
        for i, need in ipairs(ev.needs) do
            local n = {}
            for k, v in pairs(need) do n[k] = v end
            n.zone = ZoneNames(need.zone)
            c.needs[i] = n
        end
    end
    return c
end

-- This character's standing in a calendar event: the counter's text and lines, and the number.
-- Four corners (two parts) isn't something the counter can read, so it has none.
local function Standing(ev)
    if ev.parts then return nil end
    return Progress(Countable(ev), ServerOffset())
end

-- The page's frames.
local page = {}

local function Box(parent, hex, edgeAlpha)
    local f = CreateFrame("Frame", nil, parent)
    local bg = W.Solid(f, "BACKGROUND", hex or C.card)
    bg:SetAllPoints()
    W.Outline(f, "BORDER", "000000", 1, 0)
    W.Outline(f, "BORDER", C.amber, edgeAlpha or 0.14, 1, 1)
    return f
end

-- A small heading: uppercase and dim, with an optional note on the right.
local function Section(parent, width)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 16)
    f.text = W.Text(f, 9.5, C.dim)
    f.text:SetPoint("LEFT")
    f.note = W.Text(f, 10, C.dim)
    f.note:SetPoint("RIGHT")
    f.note:SetJustifyH("RIGHT")
    function f.Set(_, text, note) f.text:SetText(text:upper()); f.note:SetText(note or "") end
    return f
end

local LEFT_W, RIGHT_W = 395, 251
local ART_H = math.floor(LEFT_W * 125 / 512 + 0.5)

-- A "Running now" card: the event's painting, its name, dates, rule, the needs with a tick each,
-- the standing, and its badge.
local function RunningCard(parent)
    local card = Box(parent, C.card, 0.3)
    card:SetWidth(LEFT_W)
    card.art = card:CreateTexture(nil, "ARTWORK")
    card.art:SetPoint("TOPLEFT", 1, -1)
    card.art:SetSize(LEFT_W - 2, ART_H)
    card.art:SetTexCoord(0, 1, 0, 125 / 128)
    card.fade = W.Solid(card, "ARTWORK", C.card, 1, 1)
    card.fade:SetPoint("BOTTOMLEFT", card.art, "BOTTOMLEFT")
    card.fade:SetPoint("BOTTOMRIGHT", card.art, "BOTTOMRIGHT")
    card.fade:SetHeight(math.floor(ART_H * 0.65))
    W.Gradient(card.fade, "VERTICAL", C.card, 1, C.card, 0)
    local textW = LEFT_W - 24 - 51 - 12
    card.badge = card:CreateTexture(nil, "OVERLAY")
    card.badge:SetSize(51, 51)
    card.name = W.Text(card, 15, "ffffff", "OVERLAY")
    card.name:SetWidth(textW)
    card.when = W.Text(card, 10, C.amber2, "OVERLAY")
    card.when:SetWidth(textW)
    card.rule = W.Text(card, 10.5, C.ink2, "OVERLAY")
    card.rule:SetWidth(textW)
    card.rule:SetWordWrap(true)
    card.needs = {}
    for i = 1, 4 do
        local n = {}
        n.box = Box(card, C.pitch, 0.45)
        n.box:SetSize(12, 12)
        n.tick = n.box:CreateTexture(nil, "OVERLAY")
        n.tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        n.tick:SetSize(16, 16)
        n.tick:SetPoint("CENTER")
        n.text = W.Text(card, 10.5, C.ink, "OVERLAY")
        n.text:SetWidth(textW - 20)
        card.needs[i] = n
    end
    card.chip = CreateFrame("Frame", nil, card)
    local chipBg = W.Solid(card.chip, "BACKGROUND", C.amber)
    chipBg:SetAllPoints()
    card.chip.text = W.Text(card.chip, 10, "140e08", "OVERLAY")
    card.chip.text:SetShadowOffset(0, 0)
    card.chip.text:SetPoint("CENTER")
    return card
end

local function FillRunning(card, ev)
    local art = ev.art and (W.TEX .. "event-" .. ev.art)
    card.art:SetTexture(art)
    card.badge:SetTexture(ev.art and (W.TEX .. "badge-" .. ev.art) or nil)
    card.badge:SetShown(ev.art ~= nil)
    card.name:SetText(ev.name)
    card.when:SetText(Span(ev, MonthDay) .. (IsJoined(ev.id) and "  ·  joined" or ""))
    card.rule:SetText(ev.note or "")
    local y = -(ART_H + 1 - 22)
    card.name:ClearAllPoints(); card.name:SetPoint("TOPLEFT", 12, y)
    card.badge:ClearAllPoints(); card.badge:SetPoint("TOPRIGHT", -12, y - 2)
    y = y - 19
    card.when:ClearAllPoints(); card.when:SetPoint("TOPLEFT", 12, y)
    y = y - 15
    card.rule:ClearAllPoints(); card.rule:SetPoint("TOPLEFT", 12, y)
    y = y - math.ceil(card.rule:GetStringHeight()) - 4
    local text, details = Standing(ev)
    local quest = ev.scoring == "quest" or ev.scoring == "set"
    for i, n in ipairs(card.needs) do
        local d = quest and details and details[i]
        n.box:SetShown(d and true or false); n.text:SetShown(d and true or false)
        if d then
            n.tick:SetShown(d.done and true or false)
            n.box:ClearAllPoints(); n.box:SetPoint("TOPLEFT", 12, y - 2)
            n.text:ClearAllPoints(); n.text:SetPoint("TOPLEFT", 32, y - 1)
            n.text:SetText(d.text)
            y = y - 18
        end
    end
    card.chip:SetShown(text ~= nil)
    if text then
        local done, total = text:match("^(%d+) of (%d+) done$")
        if quest and done and done == total then text = "Done, " .. done .. " of " .. total end
        card.chip.text:SetText(text)
        card.chip:SetSize(math.ceil(card.chip.text:GetStringWidth()) + 16, 18)
        card.chip:ClearAllPoints(); card.chip:SetPoint("TOPLEFT", 12, y - 6)
        y = y - 6 - 18
    end
    card:SetHeight(math.max(-y + 12, ART_H + 51))
end

-- A challenge row: the fish's icon, Today or This week, the challenge, where, and the standing.
local function ChallengeRow(parent)
    local row = Box(parent, C.card, 0.14)
    row:SetWidth(LEFT_W)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(27, 27)
    row.icon:SetPoint("LEFT", 9, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local textW = LEFT_W - 9 - 27 - 9 - 80
    row.kind = W.Text(row, 9.5, C.dim)
    row.kind:SetPoint("TOPLEFT", 45, -8)
    row.name = W.Text(row, 11, C.ink)
    row.name:SetPoint("TOPLEFT", row.kind, "BOTTOMLEFT", 0, -2)
    row.name:SetWidth(textW)
    row.name:SetWordWrap(true)
    row.where = W.Text(row, 10, C.ink2)
    row.where:SetWidth(textW)
    row.where:SetWordWrap(true)
    row.big = W.Text(row, 16, C.amber2)
    row.big:SetPoint("TOPRIGHT", -10, -9)
    row.big:SetJustifyH("RIGHT")
    row.caption = W.Text(row, 10, C.ink2)
    row.caption:SetPoint("TOPRIGHT", row.big, "BOTTOMRIGHT", 0, -2)
    row.caption:SetJustifyH("RIGHT")
    return row
end

local function FillChallenge(row, ev, today)
    local daily = ev.kind == "daily"
    local fish = ev.fish and ev.fish[1]
    row.icon:SetTexture(fish and GetItemIconCompat(fish) or "Interface\\Icons\\Trade_Fishing")
    row.kind:SetText((daily and "Today" or (ev["end"] == today and "This week, ends tonight" or "This week")):upper())
    row.name:SetText(ev.name)
    local where = ZoneList(ev.zone)
    if daily then
        row.where:SetText(where or "Anywhere")
    else
        row.where:SetText(Span(ev, LongDay) .. ", " .. (where or "anywhere"))
    end
    row.where:ClearAllPoints(); row.where:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    local _, _, n = Progress(Countable(ev), ServerOffset())
    row.big:SetText(n or 0)
    if ev.scoring == "best30" then
        row.caption:SetText("best 30 min")
    elseif ev.scoring == "race" and ev.target then
        row.caption:SetText("of " .. ev.target)
    else
        row.caption:SetText(daily and "today" or "this week")
    end
    row:SetHeight(math.max(48, 8 + 12 + math.ceil(row.name:GetStringHeight()) + 4 + math.ceil(row.where:GetStringHeight()) + 9))
end

-- A "Coming up" card: a crop of the event's painting, its name, dates and rule.
local function ComingCard(parent)
    local card = Box(parent, C.card, 0.14)
    card:SetWidth(RIGHT_W)
    card.art = card:CreateTexture(nil, "ARTWORK")
    card.art:SetSize(89, 61)
    card.art:SetPoint("TOPLEFT", 6, -6)
    local textW = RIGHT_W - 6 - 89 - 9 - 6
    card.name = W.Text(card, 11.5, C.ink)
    card.name:SetPoint("TOPLEFT", card.art, "TOPRIGHT", 9, 0)
    card.name:SetWidth(textW)
    card.name:SetWordWrap(true)
    card.when = W.Text(card, 9.5, C.amber2)
    card.when:SetWidth(textW)
    card.when:SetWordWrap(true)
    card.rule = W.Text(card, 9.5, C.ink2)
    card.rule:SetWidth(textW)
    card.rule:SetWordWrap(true)
    return card
end

local function FillComing(card, ev)
    card.art:SetTexture(ev.art and (W.TEX .. "event-" .. ev.art) or nil)
    -- the painting at the card's shape (89x61 out of 512x125), centred on its subject
    local w = 125 * 89 / 61 / 512
    local left = ns.EVENT_ART_LEFT[ev.art] or (0.5 - w / 2)
    card.art:SetTexCoord(left, left + w, 0, 125 / 128)
    card.name:SetText(ev.name)
    card.when:SetText(Span(ev, ShortDay))
    card.rule:SetText(ev.note or "")
    card.when:ClearAllPoints(); card.when:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -2)
    card.rule:ClearAllPoints(); card.rule:SetPoint("TOPLEFT", card.when, "BOTTOMLEFT", 0, -2)
    local textH = card.name:GetStringHeight() + 2 + card.when:GetStringHeight() + 2 + card.rule:GetStringHeight()
    card:SetHeight(math.ceil(math.max(61, textH)) + 12)
end

-- A joined event: its name, then its standing and time left, with Untrack and Leave.
local function JoinedRow(parent, i)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(RIGHT_W - 24)
    row.label = W.Text(row, 10.5, "ffffff")
    row.label:SetPoint("TOPLEFT")
    row.label:SetWidth(RIGHT_W - 24)
    row.label:SetWordWrap(true)
    row.leave = W.OakButton(row, "Leave", function() Leave(i); RefreshRows(); ns.UpdateTracker() end, 20, 10.5)
    -- Untracked events stay joined and in the export, off the event tracker.
    row.track = W.OakButton(row, "Untrack", function()
        local ev = Joined()[i] and Event(Joined()[i])
        if not ev then return end
        local u = Untracked()
        u[ev.id] = not u[ev.id] or nil
        RefreshRows()
        ns.UpdateTracker()
    end, 20, 10.5)
    row.status = W.Text(row, 10, C.dim)
    row.status:SetWordWrap(true)
    return row
end

local function Layout()
    local p = page
    local offset = ServerOffset()
    local today = ns.Calendar.Today()
    p.sub:SetText((LongDay(today):gsub(" ", ", ", 1)))

    -- left: running now, then the challenges
    local y = 0
    p.runningHead:SetPoint("TOPLEFT", 0, y)
    y = y - 22
    local running = ns.Calendar.Running(today)
    for i, card in ipairs(p.running) do
        local ev = running[i]
        card:SetShown(ev ~= nil)
        if ev then
            FillRunning(card, ev)
            card:ClearAllPoints(); card:SetPoint("TOPLEFT", 0, y)
            y = y - card:GetHeight() - 8
        end
    end
    p.nothing:SetShown(#running == 0)
    if #running == 0 then
        p.nothing:ClearAllPoints(); p.nothing:SetPoint("TOPLEFT", 0, y)
        y = y - 20
    end
    y = y - 6
    p.chalHead:ClearAllPoints(); p.chalHead:SetPoint("TOPLEFT", 0, y)
    y = y - 22
    for i, ev in ipairs({ ns.Calendar.Daily(today), ns.Calendar.Weekly(today) }) do
        local row = p.challenges[i]
        FillChallenge(row, ev, today)
        row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, y)
        y = y - row:GetHeight() - 8
    end
    p.leftChild:SetHeight(-y)

    -- right: join, joined, coming up
    y = 0
    p.joinHead:SetPoint("TOPLEFT", 0, y)
    y = y - 22
    local by = -10
    p.how:ClearAllPoints(); p.how:SetPoint("TOPLEFT", 12, by)
    by = by - math.ceil(p.how:GetStringHeight()) - 8
    p.inputBox:ClearAllPoints(); p.inputBox:SetPoint("TOPLEFT", 12, by)
    p.join:ClearAllPoints(); p.join:SetPoint("TOPRIGHT", -12, by)
    by = by - 22 - 10
    p.joinedRule:ClearAllPoints(); p.joinedRule:SetPoint("TOPLEFT", 12, by); p.joinedRule:SetPoint("TOPRIGHT", -12, by)
    by = by - 8
    p.joinedHead:ClearAllPoints(); p.joinedHead:SetPoint("TOPLEFT", 12, by)
    by = by - 18
    local list = Joined()
    for i, row in ipairs(p.joined) do
        local ev = list[i] and Event(list[i])
        row:SetShown(ev ~= nil)
        if ev then
            local off = Untracked()[ev.id]
            row.label:SetText((off and "|cff8f8577" or "|cffffffff") .. ev.name .. "|r")
            row.track.text:SetText(off and "Track" or "Untrack")
            row.status:SetText(Status(list[i], ev))
            local nameH = math.ceil(row.label:GetStringHeight())
            row.leave:ClearAllPoints(); row.leave:SetPoint("TOPRIGHT", 0, -nameH - 3)
            row.track:ClearAllPoints(); row.track:SetPoint("RIGHT", row.leave, "LEFT", -4, 0)
            local statusW = RIGHT_W - 24 - row.leave:GetWidth() - row.track:GetWidth() - 12
            row.status:SetWidth(statusW)
            row.status:ClearAllPoints(); row.status:SetPoint("TOPLEFT", 0, -nameH - 6)
            local h = nameH + 3 + math.max(20, math.ceil(row.status:GetStringHeight()) + 3)
            row:SetHeight(h)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 12, by)
            by = by - h - 8
        end
    end
    p.none:SetShown(#list == 0)
    if #list == 0 then
        p.none:ClearAllPoints(); p.none:SetPoint("TOPLEFT", 12, by)
        by = by - 18
    end
    p.joinBox:SetHeight(-by + 4)
    p.joinBox:ClearAllPoints(); p.joinBox:SetPoint("TOPLEFT", 0, y)
    y = y - p.joinBox:GetHeight() - 14
    p.comingHead:ClearAllPoints(); p.comingHead:SetPoint("TOPLEFT", 0, y)
    y = y - 22
    local coming = ns.Calendar.Next(today, #p.coming)
    for i, card in ipairs(p.coming) do
        local ev = coming[i]
        card:SetShown(ev ~= nil)
        if ev then
            FillComing(card, ev)
            card:ClearAllPoints(); card:SetPoint("TOPLEFT", 0, y)
            y = y - card:GetHeight() - 8
        end
    end
    p.rightChild:SetHeight(-y)
end

RefreshRows = function()
    if not page.panel or not page.panel:IsVisible() then return end
    Layout()
end

-- A column that scrolls if it runs past the bottom.
local function Column(parent, width)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetWidth(width)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, 1)
    scroll:SetScrollChild(child)
    return scroll, child
end

ns.RegisterPage({
    name = "Events",
    order = 12,
    place = "events",
    build = function(panel)
        local p = page
        p.panel = panel

        -- the painting, the title and today's date
        local banner = CreateFrame("Frame", nil, panel)
        banner:SetPoint("TOPLEFT"); banner:SetPoint("TOPRIGHT")
        banner:SetHeight(78)
        local paint = banner:CreateTexture(nil, "BACKGROUND")
        paint:SetAllPoints()
        paint:SetTexture(W.TEX .. "banner-events")
        paint:SetTexCoord(0, 1, 0, 110 / 128)
        local medal = banner:CreateTexture(nil, "ARTWORK")
        medal:SetTexture(W.TEX .. "medal-events")
        medal:SetSize(ns.MEDAL_SIZE, ns.MEDAL_SIZE)
        medal:SetPoint("BOTTOMLEFT", ns.MEDAL_X, ns.MEDAL_Y)
        local title = W.Text(banner, 22, "ffffff")
        title:SetPoint("BOTTOMLEFT", ns.BANNER_TITLE_X, ns.BANNER_TITLE_Y)
        title:SetText("Events")
        p.sub = W.Text(banner, 10.5, C.ink2)
        p.sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

        -- the foot: Export, since pasting the journal is how events are scored
        local foot = CreateFrame("Frame", nil, panel)
        foot:SetPoint("BOTTOMLEFT"); foot:SetPoint("BOTTOMRIGHT")
        foot:SetHeight(34)
        local footBg = W.Solid(foot, "BACKGROUND", C.foot)
        footBg:SetAllPoints()
        local footLine = W.Solid(foot, "BORDER", C.amber, 0.22)
        footLine:SetPoint("TOPLEFT"); footLine:SetPoint("TOPRIGHT"); footLine:SetHeight(1)
        p.export = W.OakButton(foot, "Export", function() ns.ShowExport() end)
        p.export:SetPoint("LEFT", 14, 0)
        local hint = W.Text(foot, 10.5, C.dim)
        hint:SetPoint("RIGHT", -14, 0)
        hint:SetJustifyH("RIGHT")
        hint:SetText("Paste it on |cffcdb894halsudsworth.com|r to be scored")

        -- left column: Hal's calendar
        local left, leftChild = Column(panel, LEFT_W)
        left:SetPoint("TOPLEFT", banner, "BOTTOMLEFT", 14, -9)
        left:SetPoint("BOTTOMLEFT", foot, "TOPLEFT", 14, 10)
        p.leftChild = leftChild
        p.runningHead = Section(leftChild, LEFT_W)
        p.runningHead:Set("Running now", "Hal's calendar")
        p.running = {}
        for i = 1, 4 do p.running[i] = RunningCard(leftChild) end
        p.nothing = W.Text(leftChild, 10.5, C.dim)
        p.nothing:SetText("Nothing of Hal's is running today.")
        p.chalHead = Section(leftChild, LEFT_W)
        p.chalHead:Set("Challenges", "From the calendar")
        p.challenges = { ChallengeRow(leftChild), ChallengeRow(leftChild) }

        -- right column: join an event, what's joined, what's coming up
        local right, rightChild = Column(panel, RIGHT_W)
        right:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT", -36, -9)
        right:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -36, 10)
        p.rightChild = rightChild
        p.joinHead = Section(rightChild, RIGHT_W)
        p.joinHead:Set("Join an event")
        p.joinBox = Box(rightChild, C.card, 0.14)
        p.joinBox:SetWidth(RIGHT_W)
        p.how = W.Text(p.joinBox, 10.5, C.ink2)
        p.how:SetWidth(RIGHT_W - 24)
        p.how:SetWordWrap(true)
        p.how:SetText("On an event's or tournament's page at halsudsworth.com, click Copy event code, paste it here (Ctrl+V) and click Join. Joined events show in the event tracker while they run (drag its title to move it, click it to fold it), and your journal paste is scored for them.")
        local function Submit()
            if Join(input:GetText()) then input:SetText(""); input:ClearFocus(); RefreshRows(); ns.UpdateTracker() end
        end
        p.join = W.OakButton(p.joinBox, "Join", Submit, 22)
        p.inputBox = Box(p.joinBox, "070504", 0.25)
        p.inputBox:SetSize(RIGHT_W - 24 - p.join:GetWidth() - 8, 22)
        input = CreateFrame("EditBox", nil, p.inputBox)
        input:SetPoint("TOPLEFT", 7, 0)
        input:SetPoint("BOTTOMRIGHT", -7, 0)
        input:SetFont(W.FRIZ, 10.5, "")
        input:SetTextColor(W.Hex(C.ink))
        input:SetAutoFocus(false)
        input:SetMaxLetters(0)
        input:SetScript("OnEnterPressed", Submit)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        p.joinedRule = W.Solid(p.joinBox, "BORDER", C.rule, 0.075)
        p.joinedRule:SetHeight(1)
        p.joinedHead = W.Text(p.joinBox, 11.5, C.ink)
        p.joinedHead:SetText("Joined")
        p.none = W.Text(p.joinBox, 10.5, C.dim)
        p.none:SetText("None yet.")
        p.joined = {}
        for i = 1, MAX_EVENTS do p.joined[i] = JoinedRow(p.joinBox, i) end
        p.comingHead = Section(rightChild, RIGHT_W)
        p.comingHead:Set("Coming up")
        p.coming = { ComingCard(rightChild), ComingCard(rightChild) }

        return function()
            if ns.Data() then Prune() end
            input:SetText("")
            Layout()
        end
    end,
})

-- /reel event and the minimap menu open the tab.
function ns.ShowEvents()
    if not ns.Data() then return end
    ns.ShowPage("Events")
end

ns.On("REEL_DATA_CHANGED", RefreshRows)
ns.On("REEL_READY", function() if ns.Data() then Prune() end end)

ns.EventDecode, ns.EventJoin = Decode, Join -- for the load test
