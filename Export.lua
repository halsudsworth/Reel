-- /reel export: this character's journal as one string to paste on halsudsworth.com.
-- The string is "!REEL1!" and the base64 of a JSON document; site/FORMAT.md in the
-- addon's repository is the contract. Times are the server's clock (ns.Now).

local _, ns = ...

local PREFIX = "!REEL1!"

-- JSON ----------------------------------------------------------------------

local ESCAPES = { ['"'] = '\\"', ["\\"] = "\\\\", ["\n"] = "\\n", ["\r"] = "\\r", ["\t"] = "\\t" }

local function Str(s)
    s = tostring(s):gsub('[%c"\\]', function(c)
        return ESCAPES[c] or string.format("\\u%04x", c:byte())
    end)
    return '"' .. s .. '"'
end

-- Whole numbers without a decimal point; map positions to one decimal.
local function Num(n)
    if n == nil then return "null" end
    if n == math.floor(n) then return string.format("%d", n) end
    return string.format("%.1f", n)
end

local function List(values)
    return "[" .. table.concat(values, ",") .. "]"
end

-- { [itemID] = count } as a JSON object with string keys.
local function Counts(counts)
    local ids = {}
    for id in pairs(counts) do ids[#ids + 1] = id end
    table.sort(ids)
    local out = {}
    for _, id in ipairs(ids) do out[#out + 1] = '"' .. id .. '":' .. Num(counts[id]) end
    return "{" .. table.concat(out, ",") .. "}"
end

-- Base64 (RFC 4648, with padding) -------------------------------------------

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64(s)
    local out = {}
    for i = 1, #s, 3 do
        local a, b, c = s:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64
        local c3, c4 = math.floor(n / 64) % 64, n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end
ns.Base64 = Base64

-- The character -------------------------------------------------------------

local REGIONS = { "us", "kr", "eu", "tw", "cn" }

local function Region()
    local name = GetCurrentRegionName and GetCurrentRegionName()
    if name and name ~= "" then return name:lower() end
    return GetCurrentRegion and REGIONS[GetCurrentRegion()] or ""
end

-- Nil where the client has no game rules to ask.
local function Ruleset()
    local rules = Enum and Enum.GameRule
    if not (C_GameRules and C_GameRules.IsGameRuleActive and rules) then return end
    local function On(rule) return rule ~= nil and C_GameRules.IsGameRuleActive(rule) end
    if On(rules.HardcoreRuleset) then return "Hardcore" end
    local rp, pvp = On(rules.RPRuleset), On(rules.PvPRuleset)
    if rp and pvp then return "Roleplay-PvP" end
    if rp then return "Roleplay" end
    if pvp then return "PvP" end
    return "Normal"
end

-- Minutes from UTC, -720 to 720.
local function Wrap(minutes)
    minutes = minutes % 1440
    if minutes > 720 then minutes = minutes - 1440 end
    return minutes
end

-- The player's computer clock against UTC.
local function LocalOffset(now)
    local l, u = date("*t", now), date("!*t", now)
    return Wrap((l.hour - u.hour) * 60 + (l.min - u.min))
end

-- The server's clock against UTC, rounded to 15 minutes.
local function ServerOffset(now)
    if not GetGameTime then return 0 end
    local h, m = GetGameTime()
    local u = date("!*t", now)
    return math.floor(Wrap((h - u.hour) * 60 + (m - u.min)) / 15 + 0.5) * 15
end

-- The document --------------------------------------------------------------

function ns.ExportString()
    local data = ns.Data()
    local now = ns.Now()
    local name, secondary = UnitName("player")
    local rank, _, maxRank = ns.FishingSkill()

    local zl, zi = {}, {}
    local function Zone(z)
        if not zi[z] then zl[#zl + 1] = z; zi[z] = #zl - 1 end
        return zi[z]
    end
    local sl, si = {}, {}
    local function Sub(s)
        if not s then return nil end
        if not si[s] then sl[#sl + 1] = s; si[s] = #sl - 1 end
        return si[s]
    end

    local zones = {}
    for zone, subs in pairs(data.zones) do
        for sub, entry in pairs(subs) do
            local counts = {}
            for id, item in pairs(entry.items) do counts[id] = item.count end
            zones[#zones + 1] = List({ Num(Zone(zone)), Str(sub), Num(entry.casts), Num(entry.catches), Counts(counts) })
        end
    end

    local sessions = {}
    for _, s in ipairs(data.sessions) do
        if s.casts > 0 then
            sessions[#sessions + 1] = List({ Num(s.start), Num(s.first or s.start), Num(s.last or s.start), Num(s.casts), Num(s.catches), Num(s.fish) })
        end
    end

    -- Row: time, zone, x, y, item, qty, skill, level, subzone.
    local catches = {}
    for _, c in ipairs(data.catches) do
        catches[#catches + 1] = List({ Num(c[1]), Num(Zone(c[2])), Num(c[4]), Num(c[5]), Num(c[6]), Num(c[7]), Num(c[8]), Num(c[9]), Num(Sub(c[3])) })
    end

    local wins = {}
    for _, w in ipairs(data.wins or {}) do wins[#wins + 1] = List({ Num(w[1]), Str(w[2]) }) end

    local zlist, slist = {}, {}
    for i, z in ipairs(zl) do zlist[i] = Str(z) end
    for i, s in ipairs(sl) do slist[i] = Str(s) end

    local fields = {
        '"v":1',
        '"id":' .. Str(data.id),
        '"name":' .. Str(name or ""),
        '"secondary":' .. Str(secondary or ""),
        '"region":' .. Str(Region()),
        '"faction":' .. Str(UnitFactionGroup("player") or ""),
        '"class":' .. Str(select(2, UnitClass("player")) or ""),
        '"skill":' .. Num(rank),
        '"skillMax":' .. Num(maxRank),
        '"level":' .. Num(UnitLevel("player")),
        '"made":' .. Num(now),
        '"tz":' .. Num(LocalOffset(now)),
        '"stz":' .. Num(ServerOffset(now)),
        '"zl":' .. List(zlist),
        '"sl":' .. List(slist),
        '"zones":' .. List(zones),
        '"sessions":' .. List(sessions),
        '"catches":' .. List(catches),
        '"wins":' .. List(wins),
        '"events":[]',
    }
    local ruleset = Ruleset()
    if ruleset then table.insert(fields, 6, '"ruleset":' .. Str(ruleset)) end
    return PREFIX .. Base64("{" .. table.concat(fields, ",") .. "}"), #data.catches
end

-- The window ----------------------------------------------------------------
-- One selected line holding the whole string, so Ctrl+C copies all of it.

local box, text, info

local function BuildBox()
    box = CreateFrame("Frame", "ReelExportFrame", UIParent, "BasicFrameTemplateWithInset")
    box:SetSize(460, 150)
    box:SetPoint("CENTER")
    box:SetFrameStrata("DIALOG")
    box:EnableMouse(true)
    box:SetMovable(true)
    box:RegisterForDrag("LeftButton")
    box:SetScript("OnDragStart", box.StartMoving)
    box:SetScript("OnDragStop", box.StopMovingOrSizing)
    tinsert(UISpecialFrames, "ReelExportFrame") -- close with Escape

    local title = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("Your journal")

    local how = ns.W.Label(box, "Ctrl+C to copy, then paste it at halsudsworth.com/paste", "GameFontHighlight")
    how:SetPoint("TOPLEFT", 16, -36)

    text = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    text:SetSize(420, 24)
    text:SetPoint("TOPLEFT", 20, -60)
    text:SetAutoFocus(true)
    text:SetMaxLetters(0)
    -- Typing in it puts the string back.
    text:SetScript("OnTextChanged", function(self, user)
        if user then self:SetText(box.value); self:HighlightText() end
    end)
    text:SetScript("OnEscapePressed", function() box:Hide() end)

    info = ns.W.Label(box, "", "GameFontDisableSmall")
    info:SetPoint("TOPLEFT", 16, -94)
end

function ns.ShowExport()
    local ok, value, count = pcall(ns.ExportString)
    if not ok then
        geterrorhandler()(value)
        ns.Print("The journal couldn't be exported.")
        return
    end
    if not box then BuildBox() end
    box.value = value
    text:SetText(value)
    text:HighlightText()
    text:SetFocus()
    info:SetText(string.format("%d catches, %d KB", count, math.ceil(#value / 1024)))
    box:Show()
end
