-- How catches are saved. The game loads a SavedVariables file as one Lua chunk, and a chunk holds
-- at most 262,143 different constants: in game, a file of 270,000 catch rows failed to load
-- ("constant table overflow") and the game then wrote an empty table back over it, losing it all.
-- ReelDB is one file for every character, so the limit is shared.
--
-- Two things keep the file under it:
--   1. A catch's time is saved as the seconds since the catch before it (the first row keeps its
--      own time). Those gaps repeat endlessly, where the times themselves are new every catch.
--   2. At every logout the different values in the whole file are counted. At SAFE or more, the
--      oldest catches are packed into text blocks of BLOCK rows, one value each, oldest first,
--      character by character (most catches first) until the count is under SAFE again.
-- Nothing is ever dropped: at load every block is unpacked and every gap turned back into a time,
-- so in memory catches are the same full rows as always.
--
-- Load: ADDON_LOADED, before anything reads ReelDB. Save: REEL_SAVE, which Core fires after every
-- PLAYER_LOGOUT handler. Each character carries its own mark, catchGaps = 1, set in the same
-- statement that swaps in the converted rows, so a failure part way can't convert a character
-- twice; a character whose rows don't check out is left exactly as it is.
--
-- Saved per character, when catchGaps = 1:
--   catches     = rows { gap, zone, subzone, x, y, itemID, qty, skill, level }
--   catchBlocks = list of strings, oldest first, each BLOCK rows before the catches above:
--                 rows split by ";", fields by "," (gap, zone index, subzone index, x, y, item,
--                 qty, skill, level), empty for nil; zone and subzone index into catchNames
--   catchNames  = the zone and subzone names the blocks use

local _, ns = ...

local LIMIT = 262143 -- Lua 5.1's constants per chunk
local SAFE = 200000
local BLOCK = 1000

-- The line can be lowered for the load test (ns.saveSafe), to make packing happen on a small journal.
local function Safe() return ns.saveSafe or SAFE end

local function Row(r, t)
    return { t, r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9] } -- by index: x and y can be nil
end

local function Valid(list)
    if type(list) ~= "table" then return false end
    for i = 1, #list do
        if type(list[i]) ~= "table" or type(list[i][1]) ~= "number" then return false end
    end
    return true
end

-- Blocks -----------------------------------------------------------------------

local function Field(v)
    if v == nil then return "" end
    return tostring(v)
end

local function Pack(rows, from, to, names, index)
    local function Name(s)
        if s == nil then return "" end
        if not index[s] then names[#names + 1] = s; index[s] = #names end
        return index[s]
    end
    local out = {}
    for i = from, to do
        local r = rows[i]
        out[#out + 1] = table.concat({ Field(r[1]), Name(r[2]), Name(r[3]), Field(r[4]), Field(r[5]),
            Field(r[6]), Field(r[7]), Field(r[8]), Field(r[9]) }, ",")
    end
    return table.concat(out, ";")
end

local function Unpack(block, names, out)
    for row in block:gmatch("[^;]+") do
        local f, k = {}, 0
        for v in (row .. ","):gmatch("([^,]*),") do k = k + 1; f[k] = v end
        local function N(i) return f[i] ~= "" and tonumber(f[i]) or nil end
        local function S(i) return f[i] ~= "" and names[tonumber(f[i])] or nil end
        local gap = N(1)
        if not gap then error("R.E.E.L.: a packed catch block is damaged") end
        out[#out + 1] = { gap, S(2), S(3), N(4), N(5), N(6), N(7), N(8), N(9) }
    end
end

-- Load: blocks unpacked, gaps back to times --------------------------------------

function ns.CatchesFromSaved(d)
    if d.catchGaps ~= 1 or not Valid(d.catches) then return false end
    local rows = {}
    for _, block in ipairs(type(d.catchBlocks) == "table" and d.catchBlocks or {}) do
        Unpack(block, d.catchNames or {}, rows)
    end
    for _, r in ipairs(d.catches) do rows[#rows + 1] = r end
    local out, t = {}, 0
    for i, r in ipairs(rows) do
        t = t + r[1]
        out[i] = Row(r, t)
    end
    d.catches, d.catchBlocks, d.catchNames, d.catchGaps = out, nil, nil, nil
    return true
end

-- Save: times to gaps -------------------------------------------------------------

function ns.CatchesToSaved(d)
    if d.catchGaps ~= nil or not Valid(d.catches) then return false end
    local out, prev = {}, 0
    for i, r in ipairs(d.catches) do
        out[i] = Row(r, r[1] - prev)
        prev = r[1]
    end
    d.catches, d.catchGaps = out, 1
    return true
end

-- Packs a saved (gap) character's oldest rows into blocks, keeping the newest `keep` rows as they are.
local function PackOldest(d, keep)
    if d.catchGaps ~= 1 then return end
    local rows = d.catches
    local n = math.floor(math.max(0, #rows - keep) / BLOCK) * BLOCK
    if n == 0 then return end
    local blocks = {}
    for i, b in ipairs(d.catchBlocks or {}) do blocks[i] = b end
    local names, index = {}, {}
    for i, s in ipairs(d.catchNames or {}) do names[i] = s; index[s] = i end
    for from = 1, n, BLOCK do blocks[#blocks + 1] = Pack(rows, from, from + BLOCK - 1, names, index) end
    local rest = {}
    for i = n + 1, #rows do rest[#rest + 1] = rows[i] end
    d.catches, d.catchBlocks, d.catchNames = rest, blocks, names
end

-- Counting -------------------------------------------------------------------------
-- The different numbers and strings the game will write for ReelDB: every value, every string key,
-- and every number key outside a list's 1..n run (those are written as [k] = ...).

function ns.SavedConstants()
    local seen, n = {}, 0
    local done = {}
    local function Add(v)
        if not seen[v] then seen[v] = true; n = n + 1 end
    end
    local function Walk(t)
        if done[t] then return end
        done[t] = true
        local len = #t
        for k, v in pairs(t) do
            local tk = type(k)
            if tk == "string" or (tk == "number" and (k < 1 or k > len or k ~= math.floor(k))) then Add(k) end
            local tv = type(v)
            if tv == "number" or tv == "string" then Add(v)
            elseif tv == "table" then Walk(v) end
        end
    end
    if type(ReelDB) == "table" then Walk(ReelDB) end
    return n
end

local function Each(fn)
    if type(ReelDB) ~= "table" or type(ReelDB.chars) ~= "table" then return end
    for _, d in pairs(ReelDB.chars) do
        if type(d) == "table" then
            local ok, err = pcall(fn, d)
            if not ok then geterrorhandler()(err) end
        end
    end
end

ns.On("ADDON_LOADED", function(name)
    if name == "Reel" then Each(ns.CatchesFromSaved) end
end)

ns.On("REEL_SAVE", function()
    Each(ns.CatchesToSaved)
    -- Small journals can't come near the limit; counting a big one walks the whole file.
    local rows = 0
    for _, d in pairs(type(ReelDB) == "table" and ReelDB.chars or {}) do
        if type(d) == "table" and type(d.catches) == "table" then rows = rows + #d.catches end
    end
    if rows * 10 < Safe() then return end
    local count = ns.SavedConstants()
    if count < Safe() then return end
    local list = {}
    for _, d in pairs(ReelDB.chars) do if type(d) == "table" and d.catchGaps == 1 then list[#list + 1] = d end end
    table.sort(list, function(a, b) return #a.catches > #b.catches end)
    for _, d in ipairs(list) do
        local ok, err = pcall(PackOldest, d, BLOCK)
        if not ok then geterrorhandler()(err) end
        count = ns.SavedConstants()
        if count < Safe() then return end
    end
    if count >= LIMIT then
        geterrorhandler()("R.E.E.L.: the saved journal is over the game's limit even packed (" .. count .. " values)")
    end
end)
