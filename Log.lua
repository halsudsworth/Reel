-- Catch log: counts casts, catches, and items per zone and sub-zone, keeps a
-- lifetime journal of every item caught, records, and a history of sessions.
--
-- A session runs from login to logout and survives /reload. Logging back in
-- within JOIN_SECONDS of logging out (a disconnect, say) continues it.
--
-- Saved per character, in ReelDB.chars[name] (ns.Data() returns it):
--   zones[zone][sub] = { casts, catches, items }
--   fish[itemID]     = { count, link, quality, first, firstZone, last }
--   sessions         = list, oldest first; the last one is current:
--                      { start, first, last, seen, casts, catches,
--                        fish, bonus, items, zones = { zone -> fish } }
--   records.stack    = { qty, link, time, zone }

local _, ns = ...

local JOIN_SECONDS = 600

local data -- this character's saved data

function ns.Data()
    return data
end

local function InitData(d)
    d.zones = d.zones or {}
    d.fish = d.fish or {}
    d.sessions = d.sessions or {}
    d.records = d.records or {}
    return d
end
ns.InitData = InitData -- Stats uses it on other characters' tables too

local function NewSession()
    return { start = time(), casts = 0, catches = 0, fish = 0, bonus = 0, items = {}, zones = {} }
end

-- Placeholder until the saved session is picked on PLAYER_ENTERING_WORLD.
ns.session = NewSession()

function ns.ZoneEntry()
    local zone = GetZoneText() or "Unknown"
    local sub = GetSubZoneText()
    if not sub or sub == "" then sub = zone end
    data.zones[zone] = data.zones[zone] or {}
    local entry = data.zones[zone][sub]
    if not entry then
        entry = { casts = 0, catches = 0, items = {} }
        data.zones[zone][sub] = entry
    end
    return entry, zone, sub
end

function ns.SortedItems(items)
    local list = {}
    for _, item in pairs(items) do
        list[#list + 1] = item
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list
end

local function AddItem(items, id, link, qty, quality)
    local item = items[id]
    if not item then
        item = { count = 0 }
        items[id] = item
    end
    item.count = item.count + qty
    item.link = link
    item.quality = quality
    return item
end

-- Starts a fresh session. The current one is dropped if nothing was cast.
function ns.StartSession()
    local list = data.sessions
    local current = list[#list]
    if current and current.casts == 0 then list[#list] = nil end
    ns.session = NewSession()
    list[#list + 1] = ns.session
    ns.Fire("REEL_DATA_CHANGED")
end

-- Clears every character's catch data.
function ns.ResetData()
    ReelDB.chars = {}
    data = InitData({})
    ReelDB.chars[ns.CharKey()] = data
    ns.StartSession()
end

-- Forever has no realms, and UnitName returns the first and last names, so
-- the full name ("Biscuits Mcgravy") identifies a character.
function ns.CharKey()
    local first, last = UnitName("player")
    if last and last ~= "" then return first .. " " .. last end
    return first
end

ns.On("REEL_READY", function()
    -- Catch data used to be shared by every character; that beta data is dropped.
    ReelDB.zones, ReelDB.fish, ReelDB.sessions, ReelDB.records = nil, nil, nil, nil
    ReelDB.chars = ReelDB.chars or {}
    local key = ns.CharKey()
    -- Early 0.9.0 keys were "First-Realm" or "First"; each character moves its
    -- own over when it logs in.
    local first = UnitName("player")
    local old = {}
    for k in pairs(ReelDB.chars) do
        if k ~= key and (k == first or k:match("^(.-)%-") == first) then old[#old + 1] = k end
    end
    for _, k in ipairs(old) do
        ReelDB.chars[key] = ReelDB.chars[key] or ReelDB.chars[k]
        ReelDB.chars[k] = nil
    end
    data = InitData(ReelDB.chars[key] or {})
    ReelDB.chars[key] = data
end)

local picked = false
ns.On("PLAYER_ENTERING_WORLD", function(isInitialLogin)
    if picked then return end -- also fires on every loading screen
    picked = true
    local list = data.sessions
    local current = list[#list]
    local resume = current and (not isInitialLogin
        or (current.seen and time() - current.seen <= JOIN_SECONDS))
    if resume then
        ns.session = current
        ns.Fire("REEL_DATA_CHANGED")
    else
        ns.StartSession()
    end
end)

ns.On("PLAYER_LOGOUT", function()
    ns.session.seen = time()
end)

ns.On("REEL_CAST", function()
    local session = ns.session
    session.casts = session.casts + 1
    session.first = session.first or time()
    session.last = time()
    local entry = ns.ZoneEntry()
    entry.casts = entry.casts + 1
    ns.Fire("REEL_DATA_CHANGED")
end)

-- One catch per cast: the loot window can open twice for one bobber
-- (closed and reopened with a full bag), and that must not count twice.
local counted = false
ns.On("REEL_CAST", function() counted = false end)

ns.On("LOOT_OPENED", function()
    if not IsFishingLoot() or counted then return end
    counted = true
    local now = time()
    local session = ns.session
    local entry, zone = ns.ZoneEntry()
    entry.catches = entry.catches + 1
    session.catches = session.catches + 1
    session.last = now
    for slot = 1, GetNumLootItems() do
        local link = GetLootSlotLink(slot)
        local id = link and tonumber(link:match("item:(%d+)"))
        if id then
            local _, _, qty, _, quality = GetLootSlotInfo(slot)
            qty = qty or 1
            AddItem(entry.items, id, link, qty, quality)
            AddItem(session.items, id, link, qty, quality)
            session.fish = session.fish + qty
            session.zones[zone] = (session.zones[zone] or 0) + qty

            local fish = AddItem(data.fish, id, link, qty, quality)
            if not fish.first then
                fish.first, fish.firstZone = now, zone
            end
            fish.last = now

            local stack = data.records.stack
            if not stack or qty > stack.qty then
                data.records.stack = { qty = qty, link = link, time = now, zone = zone }
            end
        end
    end
    ns.Fire("REEL_DATA_CHANGED")
end)

-- "Caught 42 (+6 bonus)"; the bonus part only with Luremaster.
ns.RegisterBarSegment({
    key = "session",
    label = "Fish caught this session",
    order = 40,
    text = function()
        local t = "Caught " .. ns.session.fish
        if ns.HasLuremaster() then
            t = t .. string.format(" |cff40ff40(+%d bonus)|r", ns.LuremasterCount())
        end
        return t
    end,
})
