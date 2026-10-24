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

ns.RegisterDefaults({
    campMissing = false, -- show "No camp buff" on the bar
})

function ns.IsCampBuff(name, spellID)
    return KNOWN_BUFFS[spellID] or (name and name:match("^%a+ Fishing$") ~= nil)
end

-- Returns name and seconds left of the active camp buff, or nil.
local function CampBuff()
    for _, aura in ipairs(ns.PlayerBuffs()) do
        if ns.IsCampBuff(aura.name, aura.spellId) then
            local left = aura.expirationTime and aura.expirationTime > 0 and aura.expirationTime - GetTime()
            return aura.name, left
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

ns.RegisterBarSegment({
    key = "camp",
    label = "Camp buff",
    order = 30,
    text = function(s)
        local name, left = CampBuff()
        if name then
            if left then return name .. " " .. ns.FormatTime(left), true end
            return name, true
        end
        local placed, cdLeft = Cooldown()
        if placed then
            return PLACE_SPELLS[placed] .. " ready in " .. ns.FormatTime(cdLeft), true
        end
        if s.campMissing and ns.PoleEquipped() then
            return "|cffff4040No camp buff|r", true
        end
    end,
    options = {
        { key = "campMissing", label = "Show \"No camp buff\" when missing" },
    },
})
