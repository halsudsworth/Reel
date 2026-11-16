-- Camp objects (Fish Bowl, Fishing Rack, Fishing Hut), shown on the bar:
--   buff on        "Uncommon Fishing 42:10"
--   no buff, placed less than an hour ago   "Rack ready in 12:00"
--   no buff        "No camp buff" (red, optional, only with a pole equipped)
--
-- "Uncommon Fishing" (spell 1280341) is the Fishing Rack buff, confirmed from
-- the client. The Hut's buff isn't confirmed, so any buff named
-- "<word> Fishing" (e.g. "Rare Fishing") is treated as a camp buff too.
--
-- The one-hour cooldown is from fan guides. Placement is detected by spell
-- name; "Fishing Rack" is confirmed on Wowhead (spell 1262990), the others
-- are not.

local _, ns = ...

local COOLDOWN = 3600
local KNOWN_BUFFS = { [1280341] = true } -- Uncommon Fishing (Fishing Rack)
local PLACE_SPELLS = { ["Fish Bowl"] = "Bowl", ["Fishing Rack"] = "Rack", ["Fishing Hut"] = "Hut" }
-- The camp items, for their icons on the bar (item IDs from site/data/gear.json "camp").
local CAMP_ITEMS = { ["Fish Bowl"] = 279967, ["Fishing Rack"] = 279965, ["Fishing Hut"] = 279966 }
local RACK = 279965 -- the camp whose buff is known (Uncommon Fishing)
local GetItemIconCompat = C_Item and C_Item.GetItemIconByID or GetItemIcon

local function CampIcon(itemID)
    return GetItemIconCompat(itemID) or "Interface\\Icons\\INV_FishingChair"
end

ns.RegisterDefaults({
    campMissing = false, -- show "No camp buff" on the bar
})

function ns.IsCampBuff(name, spellID)
    return KNOWN_BUFFS[spellID] or (name and name:match("^%a+ Fishing$") ~= nil)
end

-- Returns name, seconds left and icon of the active camp buff, or nil.
local function CampBuff()
    for _, aura in ipairs(ns.PlayerBuffs()) do
        if ns.IsCampBuff(aura.name, aura.spellId) then
            local left = aura.expirationTime and aura.expirationTime > 0 and aura.expirationTime - GetTime()
            return aura.name, left, aura.icon
        end
    end
end

-- Returns the placed object's name and seconds until it can be placed again,
-- or nil once the cooldown is over.
local function Cooldown()
    local camp = ReelDB.camp
    if not camp then return end
    local left = camp.placed + COOLDOWN - time()
    if left <= 0 then
        ReelDB.camp = nil
        return
    end
    return camp.name, left
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
    if unit ~= "player" then return end
    local name = ns.SpellName(spellID)
    if name and PLACE_SPELLS[name] then
        ReelDB.camp = { name = name, placed = time() }
    end
end)

-- Camp: the camp buff's timer, the camp's cooldown (dim), or a red "None"; the words are in the tooltip.
ns.RegisterBarSegment({
    key = "camp",
    label = "Camp buff",
    name = "Camp",
    group = "status",
    order = 30,
    icon = "Interface\\Icons\\INV_FishingChair",
    text = function(s)
        -- Like Lure and Food: the buff's own icon with its timer; otherwise the camp's icon greyed.
        local name, left, icon = CampBuff()
        if name then
            icon = icon or CampIcon(RACK)
            if left then return { value = ns.FormatTime(left), tip = name .. " " .. ns.FormatTime(left), reserve = "88:88", icon = icon }, true end
            return { value = "on", tip = name, reserve = "88:88", icon = icon }, true
        end
        local placed, cdLeft = Cooldown()
        if placed then
            local t = ns.FormatTime(cdLeft)
            return { value = "|cff8a7a63" .. t .. "|r", tip = PLACE_SPELLS[placed] .. " ready in " .. t, missing = true, reserve = "88:88",
                icon = CampIcon(CAMP_ITEMS[placed] or RACK) }, true
        end
        if ns.PoleEquipped() then
            -- With "No camp buff" turned off, no camp means no row at all.
            if s.campMissing then
                return { value = "|cffff4a3aNone|r", short = "|cffff4a3aNone|r", tip = "No camp buff", missing = true, reserve = "88:88", icon = CampIcon(RACK) }, true
            end
        end
    end,
    options = {
        { key = "campMissing", label = "Show \"No camp buff\" when missing" },
    },
})
