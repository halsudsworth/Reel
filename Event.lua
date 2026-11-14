-- /reel event: join a tournament or event by pasting its event string from halsudsworth.com.
--
-- The string is "!REELEV1!" and the base64 of a JSON document (site/FORMAT.md, "Event
-- string"). Joined strings are kept per character in data.events and go out with the
-- journal export, so halsudsworth.com scores the paste against them. While an event runs,
-- the fishing bar shows a counter worked out from this character's catches.
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
    ev.zone, ev.fish, ev.sub = AsList(ev.zone), AsList(ev.fish), AsList(ev.sub)
    for _, n in ipairs(ev.needs or {}) do n.zone, n.fish, n.sub, n.notSub = AsList(n.zone), AsList(n.fish), AsList(n.sub), AsList(n.notSub) end
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

local function SubKey(s) return s and s:lower():gsub("^the ", "") or nil end

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

-- The bar text for one event.
local function Progress(ev, offset)
    local inside = Inside(ev, offset)
    local s = ev.scoring
    if s == "set" or s == "quest" then
        local done = 0
        for _, n in ipairs(ev.needs or {}) do
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
            if (n.distinct and kinds or count) >= n.n then done = done + 1 end
        end
        return string.format("%d of %d done", done, #(ev.needs or {}))
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
        return string.format("%d fish in your best %d min", best, minutes)
    end
    if (s == "race" or s == "target") and ev.target then
        return string.format("%d of %d fish", math.min(total, ev.target), ev.target)
    end
    return string.format("%d fish", total)
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
        c = { n = n, minute = minute, text = Progress(ev, offset) }
        cache[str] = c
    end
    return c.text
end

ns.RegisterBarSegment({ key = "event", label = "Joined events", order = 6, text = function()
    if not ns.Data() then return end
    local offset = ServerOffset()
    local today = Today(offset)
    local lines = {}
    for _, str in ipairs(Joined()) do
        local ev = Event(str)
        if ev and not Untracked()[ev.id] and today >= ev.start and today <= ev["end"] then
            local t = ev.name .. ": " .. CachedProgress(str, ev, offset)
                .. " |cff888888· " .. ns.FormatTime(TimeLeft(ev, offset)) .. " left|r"
            if ev.window.kind ~= "days" and not InWindow(ev, ns.Now(), offset) then
                t = t .. " |cff888888(opens " .. ev.window.from .. ")|r"
            end
            lines[#lines + 1] = t
        end
    end
    if #lines > 0 then return lines end
end })

-- Events tab ---------------------------------------------------------------------------

local input, rows, none

-- What a joined event's row says after its name: progress and time left while it runs.
local function Status(str, ev)
    local offset = ServerOffset()
    local today = Today(offset)
    if today < ev.start then return "starts " .. ev.start end
    if today > ev["end"] then return "ended " .. ev["end"] end
    return CachedProgress(str, ev, offset) .. " · " .. ns.FormatTime(TimeLeft(ev, offset)) .. " left"
end

local function RefreshRows()
    if not rows then return end
    local list = Joined()
    for i, row in ipairs(rows) do
        local ev = list[i] and Event(list[i])
        if ev then
            local off = Untracked()[ev.id]
            row.label:SetText(string.format("%s%s|r  |cff888888%s|r", off and "|cff888888" or "|cffffffff", ev.name, Status(list[i], ev)))
            row.track:SetText(off and "Track" or "Untrack")
            row:Show()
        else
            row:Hide()
        end
    end
    none:SetShown(#list == 0)
end

ns.RegisterPage({
    name = "Events",
    order = 12,
    build = function(panel)
        local how = W.Note(panel, "Join an event or tournament: on its page at halsudsworth.com, click Copy event code, paste it here (Ctrl+V) and click Join. Joined events can be tracked on the fishing bar while they run, and your journal paste is scored for them.", ns.CONTENT_WIDTH - 4)
        how:SetPoint("TOPLEFT")

        input = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
        input:SetSize(ns.CONTENT_WIDTH - 100, 24)
        input:SetPoint("TOPLEFT", how, "BOTTOMLEFT", 6, -10)
        input:SetAutoFocus(false)
        input:SetMaxLetters(0)
        local function Submit()
            if Join(input:GetText()) then input:SetText(""); input:ClearFocus(); RefreshRows() end
        end
        input:SetScript("OnEnterPressed", Submit)
        input:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        local join = W.Button(panel, "Join", 70, Submit)
        join:SetPoint("LEFT", input, "RIGHT", 8, 0)

        local header = W.Label(panel, "Joined", "GameFontNormal")
        header:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -6, -16)
        none = W.Label(panel, "None yet.", "GameFontDisableSmall")
        none:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)

        rows = {}
        for i = 1, MAX_EVENTS do
            local row = CreateFrame("Frame", nil, panel)
            row:SetSize(ns.CONTENT_WIDTH - 4, 24)
            row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4 - (i - 1) * 26)
            local leave = W.Button(row, "Leave", 60, function() Leave(i); RefreshRows() end)
            leave:SetPoint("RIGHT")
            -- Untracked events stay joined and in the export, off the fishing bar.
            row.track = W.Button(row, "Untrack", 70, function()
                local ev = Joined()[i] and Event(Joined()[i])
                if not ev then return end
                local u = Untracked()
                u[ev.id] = not u[ev.id] or nil
                RefreshRows()
                ns.UpdateBar()
            end)
            row.track:SetPoint("RIGHT", leave, "LEFT", -4, 0)
            row.label = W.Label(row, "", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT")
            row.label:SetPoint("RIGHT", row.track, "LEFT", -6, 0)
            row.label:SetJustifyH("LEFT")
            row.label:SetWordWrap(false)
            rows[i] = row
        end

        return function()
            if ns.Data() then Prune() end
            input:SetText("")
            RefreshRows()
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
