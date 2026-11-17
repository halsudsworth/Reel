-- Hal's calendar: his annual events as dated editions, and the daily and weekly challenges.
-- No UI here; the Events tab reads these.
--
-- A port of site/server/lib/calendar.php: the same date gives the same events and the same
-- challenge as halsudsworth.com, down to the random numbers (the generator's 32-bit integer
-- math is done with plain arithmetic, since Lua 5.1 numbers are doubles). The tables come
-- from CalendarData.lua (tools/gen_calendar.py).
--
-- Dates are "YYYY-MM-DD" strings on the server clock, like the site's. Weeks run Monday to
-- Sunday. Zones are map IDs.
--
--   ns.Calendar.Today([now])          today's date on the server clock
--   ns.Calendar.Running(date)         Hal's editions running on that date, by start date
--   ns.Calendar.Next(date[, count])   editions starting after that date, soonest first (within 400 days)
--   ns.Calendar.Editions(from, to)    every edition overlapping [from, to], by start date
--   ns.Calendar.Daily(date)           that day's daily challenge
--   ns.Calendar.Weekly(date)          the weekly challenge of the week holding that date
--   ns.Calendar.MondayOf(date), ns.Calendar.AddDays(date, n), ns.Calendar.Series(id)
--   ns.Calendar.ZoneOf(mapID)         the map ID the calendar lists a zone under
--
-- An edition: { id = "tongas-survey-2026", series, year, kind = "hal", name, art, scoring,
--   start, ["end"], note, founding, zone, fish, sub, target, needs, parts, by = "Hal" }.
-- A challenge: { id = "daily-2026-11-15", kind = "daily" or "weekly", name, scoring,
--   start, ["end"], zone, fish, target, by = "the calendar" }.

local _, ns = ...
local L = ns.L

local Calendar = {}
ns.Calendar = Calendar

local function Data() return ns.CALENDAR_DATA end

local floor = math.floor

-- Dates ------------------------------------------------------------------------------

-- Days since 1970-01-01 for a proleptic Gregorian date (month 1 to 12).
local function DaysFromCivil(y, m, d)
    if m <= 2 then y = y - 1 end
    local era = floor(y / 400)
    local yoe = y - era * 400
    local doy = floor((153 * ((m + 9) % 12) + 2) / 5) + d - 1
    local doe = yoe * 365 + floor(yoe / 4) - floor(yoe / 100) + doy
    return era * 146097 + doe - 719468
end

local function CivilFromDays(z)
    z = z + 719468
    local era = floor(z / 146097)
    local doe = z - era * 146097
    local yoe = floor((doe - floor(doe / 1460) + floor(doe / 36524) - floor(doe / 146096)) / 365)
    local doy = doe - (365 * yoe + floor(yoe / 4) - floor(yoe / 100))
    local mp = floor((5 * doy + 2) / 153)
    local d = doy - floor((153 * mp + 2) / 5) + 1
    local m = mp < 10 and mp + 3 or mp - 9
    local y = yoe + era * 400
    if m <= 2 then y = y + 1 end
    return y, m, d
end

-- gmmktime(0, 0, 0, m, d, y) in days: month 13 is next January, day 0 the last of the month before.
local function Utc(y, m, d)
    local m0 = m - 1
    return DaysFromCivil(y + floor(m0 / 12), m0 % 12 + 1, 1) + d - 1
end

local function DayNumber(date)
    local y, m, d = date:match("^(%d+)-(%d+)-(%d+)$")
    return DaysFromCivil(tonumber(y), tonumber(m), tonumber(d))
end

local function DateString(n)
    local y, m, d = CivilFromDays(n)
    return string.format("%04d-%02d-%02d", y, m, d)
end

local function Weekday(n) return (n + 4) % 7 end -- 0 = Sunday; 1970-01-01 was a Thursday

function Calendar.AddDays(date, n) return DateString(DayNumber(date) + n) end

function Calendar.MondayOf(date)
    local n = DayNumber(date)
    return DateString(n - (Weekday(n) + 6) % 7)
end

-- The n-th weekday (0 = Sunday) of a month; n = -1 is the last.
local function NthWeekday(y, m, dow, n)
    if n > 0 then
        local first = Utc(y, m, 1)
        return Utc(y, m, 1 + (dow - Weekday(first) + 7) % 7 + (n - 1) * 7)
    end
    local last = Utc(y, m + 1, 0)
    local _, _, lastDay = CivilFromDays(last)
    return Utc(y, m, lastDay - (Weekday(last) - dow + 7) % 7)
end

local function EditionDates(rule, y)
    local k = rule.kind
    if k == "month" then return DateString(Utc(y, rule.month, 1)), DateString(Utc(y, rule.month + 1, 0)) end
    if k == "week" then local s = NthWeekday(y, rule.month, 1, rule.n); return DateString(s), DateString(s + 6) end
    if k == "weekend" then local s = NthWeekday(y, rule.month, 5, rule.n); return DateString(s), DateString(s + 2) end
    if k == "saturday" then local s = DateString(NthWeekday(y, rule.month, 6, rule.n)); return s, s end
    error("unknown rule " .. tostring(k))
end

-- The server clock's minutes from UTC (GetGameTime against UTC), rounded to 15, -720 to 720.
-- The same reading as Event.lua's and the export's "stz".
function Calendar.ServerOffset(now)
    if not GetGameTime then return 0 end
    local h, m = GetGameTime()
    local u = floor(now % 86400 / 60)
    local d = (h * 60 + m - u) % 1440
    if d > 720 then d = d - 1440 end
    return floor(d / 15 + 0.5) * 15
end

-- Today on the server clock: the site's today(), the date in the region's server time zone.
function Calendar.Today(now)
    now = now or ns.Now()
    return DateString(floor((now + Calendar.ServerOffset(now) * 60) / 86400))
end

-- Hal's editions --------------------------------------------------------------------------

function Calendar.Series(id)
    for _, s in ipairs(Data().series) do
        if s.id == id then return s end
    end
end

-- Every edition of every series that overlaps [from, to], none before calStart, by start date.
-- Editions with the same start keep the series order, as the site's stable sort does.
function Calendar.Editions(from, to)
    local D = Data()
    local out = {}
    local y0, y1 = tonumber(from:sub(1, 4)) - 1, tonumber(to:sub(1, 4)) + 1
    for _, s in ipairs(D.series) do
        for y = y0, y1 do
            local o = s.years and s.years[y] or {}
            local start, finish
            if o.start then start, finish = o.start, o["end"] else start, finish = EditionDates(s.rule, y) end
            if not (finish < from or start > to or start < D.calStart) then
                local ev = {
                    id = s.id .. "-" .. y, series = s.id, year = y, kind = "hal", by = "Hal",
                    name = s.name, art = s.art, scoring = s.scoring, start = start, ["end"] = finish,
                    note = o.note or s.note, founding = o.founding or false,
                    zone = s.zone, fish = s.fish, sub = s.sub, target = s.target, needs = s.needs, parts = s.parts,
                    order = #out + 1,
                }
                out[#out + 1] = ev
            end
        end
    end
    table.sort(out, function(a, b)
        if a.start ~= b.start then return a.start < b.start end
        return a.order < b.order
    end)
    for _, ev in ipairs(out) do ev.order = nil end
    return out
end

function Calendar.Running(date)
    return Calendar.Editions(date, date)
end

function Calendar.Next(date, count)
    local out = {}
    for _, ev in ipairs(Calendar.Editions(Calendar.AddDays(date, 1), Calendar.AddDays(date, 400))) do
        if ev.start > date then
            out[#out + 1] = ev
            if count and #out >= count then break end
        end
    end
    return out
end

-- JavaScript 32-bit math on unsigned values 0 to 2^32 - 1 -----------------------------------

local TWO32 = 4294967296
local XOR4, OR4 = {}, {}
for a = 0, 15 do
    for b = 0, 15 do
        local x, o, p, aa, bb = 0, 0, 1, a, b
        for _ = 1, 4 do
            local ba, bb1 = aa % 2, bb % 2
            if ba ~= bb1 then x = x + p end
            if ba == 1 or bb1 == 1 then o = o + p end
            aa, bb, p = (aa - ba) / 2, (bb - bb1) / 2, p * 2
        end
        XOR4[a * 16 + b], OR4[a * 16 + b] = x, o
    end
end

local function Bits(t, a, b)
    local r, p = 0, 1
    for _ = 1, 8 do
        local na, nb = a % 16, b % 16
        r = r + t[na * 16 + nb] * p
        a, b, p = (a - na) / 16, (b - nb) / 16, p * 16
    end
    return r
end
local function Xor(a, b) return Bits(XOR4, a, b) end
local function Or(a, b) return Bits(OR4, a, b) end
local function Shr(a, n) return floor(a / 2 ^ n) end

-- Math.imul, kept below 2^53 so every step is exact.
local function Imul(a, b)
    local lo = (a % 65536) * b
    local hi = (floor(a / 65536) * b) % 65536
    return (lo + hi * 65536) % TWO32
end

-- calendar.php rng(): an FNV-1a seed, then a mulberry32-style step. Returns 0 <= r < 1.
local function Rng(seedText)
    local h = 2166136261
    for i = 1, #seedText do h = Imul(Xor(h, seedText:byte(i)), 16777619) end
    return function()
        h = (h + 0x6d2b79f5) % TWO32
        local t = h
        t = Imul(Xor(t, Shr(t, 15)), Or(t, 1))
        t = Xor(t, (t + Imul(Xor(t, Shr(t, 7)), Or(t, 61))) % TWO32)
        return Xor(t, Shr(t, 14)) / TWO32
    end
end

local function Pick(r, list) return list[floor(r() * #list) + 1] end

-- Challenges --------------------------------------------------------------------------------

local FORMATS = { "best30", "race", "most" }
-- Days before 1970 count back from 0; floored modulo keeps the index in 0 to 2 either way.
local function FormatFor(n) return FORMATS[n % 3 + 1] end
-- PHP intdiv: rounds toward zero.
local function IntDiv(a, b) local q = a / b; return q >= 0 and floor(q) or -floor(-q) end

local function Copy(list)
    if not list then return nil end
    local out = {}
    for i, v in ipairs(list) do out[i] = v end
    return out
end

local function Challenge(kind, start, finish, format, r)
    local D = Data()
    local ev
    if format == "most" then
        local fish = Pick(r, D.wide)
        ev = { name = string.format(L["Most %s"], D.fishNames[fish]), fish = { fish }, scoring = "most" }
    else
        local p = Pick(r, D.pairs)
        local zone, fish = p[1], p[2]
        local fname, zname = D.fishNames[fish], D.maps[zone]
        if format == "race" then
            local target = kind == "daily" and 20 or 60
            ev = { name = string.format(L["Race to %d %s, %s"], target, fname, zname), zone = { zone }, fish = { fish }, target = target, scoring = "race" }
        else
            ev = { name = string.format(L["Best 30 minutes: %s in %s"], fname, zname), zone = { zone }, fish = { fish }, scoring = "best30" }
        end
    end
    ev.id, ev.kind, ev.start, ev["end"], ev.by = kind .. "-" .. start, kind, start, finish, "the calendar"
    return ev
end

local function Launch(t, kind, start, finish)
    return {
        id = kind .. "-" .. start, kind = kind, name = t.name, scoring = t.scoring, start = start, ["end"] = finish,
        zone = Copy(t.zone), fish = Copy(t.fish), target = t.target, by = "the calendar",
    }
end

function Calendar.Daily(date)
    local t = Data().launchDays[date]
    if t then return Launch(t, "daily", date, date) end
    return Challenge("daily", date, date, FormatFor(DayNumber(date)), Rng("daily " .. date))
end

-- The week's challenge; any date in the week works, the challenge is the Monday's.
function Calendar.Weekly(date)
    local monday = Calendar.MondayOf(date)
    local finish = Calendar.AddDays(monday, 6)
    local t = Data().launchWeeks[monday]
    if t then return Launch(t, "weekly", monday, finish) end
    return Challenge("weekly", monday, finish, FormatFor(IntDiv(DayNumber(monday), 7)), Rng("weekly " .. monday))
end

function Calendar.ZoneOf(mapID)
    return Data().mapAlias[mapID] or mapID
end
