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

local SCORINGS = { race = true, most = true, best30 = true, target = true, set = true, variety = true, quest = true }

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
        return string.format("%d/%d done", done, #(ev.needs or {}))
    end
    if s == "variety" and ev.variety then
        local zs, fs, nz, nf = {}, {}, 0, 0
        for _, e in ipairs(inside) do
            if ns.FISH[e.c[6]] then
                if not zs[e.c[2]] then zs[e.c[2]] = true; nz = nz + 1 end
                if not fs[e.c[6]] then fs[e.c[6]] = true; nf = nf + 1 end
            end
        end
        return string.format("%d/%d fish, %d/%d zones", math.min(nf, ev.variety.fish), ev.variety.fish, math.min(nz, ev.variety.zones), ev.variety.zones)
    end
    local total, times = 0, {}
    for _, e in ipairs(inside) do
        if Matches(ev.zone, ev.fish, e.c) then
            total = total + (e.c[7] or 1)
            for _ = 1, (e.c[7] or 1) do times[#times + 1] = e.c[1] end
        end
    end
    if s == "best30" then
        local best, k = 0, 1
        for i = 1, #times do
            while times[i] - times[k] > 1800 do k = k + 1 end
            best = math.max(best, i - k + 1)
        end
        return string.format("best 30 min: %d", best)
    end
    if (s == "race" or s == "target") and ev.target then
        return string.format("%d/%d", math.min(total, ev.target), ev.target)
    end
    return string.format("%d caught", total)
end

-- Joined events ------------------------------------------------------------------------

local function Joined()
    local data = ns.Data()
    data.events = data.events or {}
    return data.events
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
        if ev and today >= ev.start and today <= ev["end"] then
            local t = ev.name .. ": " .. CachedProgress(str, ev, offset)
            if ev.window.kind ~= "days" and not InWindow(ev, ns.Now(), offset) then
                t = t .. " |cff888888(opens " .. ev.window.from .. ")|r"
            end
            lines[#lines + 1] = t
        end
    end
    if #lines > 0 then return lines end
end })

-- The window ---------------------------------------------------------------------------

local box, input, rows

local function RefreshRows()
    local list = Joined()
    for i, row in ipairs(rows) do
        local ev = list[i] and Event(list[i])
        if ev then
            row.label:SetText(string.format("%s  |cff888888%s to %s|r", ev.name, ev.start, ev["end"]))
            row:Show()
        else
            row:Hide()
        end
    end
    box.none:SetShown(#list == 0)
end

local function BuildBox()
    box = CreateFrame("Frame", "ReelEventFrame", UIParent, "BasicFrameTemplateWithInset")
    box:SetSize(460, 130 + MAX_EVENTS * 24)
    box:SetPoint("CENTER")
    box:SetFrameStrata("DIALOG")
    box:EnableMouse(true)
    box:SetMovable(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", box.StartMoving)
    box:SetScript("OnDragStop", box.StopMovingOrSizing)
    tinsert(UISpecialFrames, "ReelEventFrame")

    local title = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("Events")

    local how = W.Label(box, "Paste an event string from halsudsworth.com (Ctrl+V), then Join.", "GameFontHighlight")
    how:SetPoint("TOPLEFT", 16, -36)

    input = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    input:SetSize(340, 24)
    input:SetPoint("TOPLEFT", 20, -60)
    input:SetAutoFocus(true)
    input:SetMaxLetters(0)
    local function Submit()
        if Join(input:GetText()) then input:SetText(""); RefreshRows() end
    end
    input:SetScript("OnEnterPressed", Submit)
    input:SetScript("OnEscapePressed", function() box:Hide() end)
    local join = W.Button(box, "Join", 70, Submit)
    join:SetPoint("LEFT", input, "RIGHT", 8, 0)

    local header = W.Label(box, "Joined", "GameFontNormal")
    header:SetPoint("TOPLEFT", 16, -96)
    box.none = W.Label(box, "None yet.", "GameFontDisableSmall")
    box.none:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)

    rows = {}
    for i = 1, MAX_EVENTS do
        local row = CreateFrame("Frame", nil, box)
        row:SetSize(420, 22)
        row:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4 - (i - 1) * 24)
        row.label = W.Label(row, "", "GameFontHighlightSmall")
        row.label:SetPoint("LEFT")
        local leave = W.Button(row, "Leave", 60, function() Leave(i); RefreshRows() end)
        leave:SetPoint("RIGHT")
        rows[i] = row
    end
end

function ns.ShowEvents()
    if not ns.Data() then return end
    if not box then BuildBox() end
    Prune()
    RefreshRows()
    input:SetText("")
    box:Show()
    input:SetFocus()
end

ns.On("REEL_READY", function() if ns.Data() then Prune() end end)

ns.EventDecode, ns.EventJoin = Decode, Join -- for the load test
