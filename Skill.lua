-- Fishing skill: base skill plus bonus, shown on the bar.
--
-- On this client the profession API only reports part of the bonus, so the
-- bonus is added up directly:
--   gear  - "Fishing +N" lines on equipped item tooltips ("Increased Fishing
--           +5", "Enchanted: Fishing +2", and lures on the pole)
--   buffs - the effect value of buffs that mention "fishing skill" (Well Fed)

local _, ns = ...

local GEAR_SLOTS = 19
local gearBonus, gearChecked = 0, 0

local function GearBonus()
    if GetTime() - gearChecked < 2 then return gearBonus end
    gearChecked = GetTime()
    gearBonus = 0
    if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return 0 end
    for slot = 1, GEAR_SLOTS do
        local info = C_TooltipInfo.GetInventoryItem("player", slot)
        for _, line in ipairs(info and info.lines or {}) do
            local amount = line.leftText and line.leftText:match("[Ff]ishing[^%d%+]*%+(%d+)")
            if amount then gearBonus = gearBonus + tonumber(amount) end
        end
    end
    return gearBonus
end

local buffIsSkill = {} -- spellID -> true/false once the description loads

-- True for buffs whose description mentions "fishing skill" (e.g. Well Fed).
function ns.IsFishingSkillBuff(spellID)
    if not spellID then return false end
    if buffIsSkill[spellID] == nil then
        local desc = C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(spellID)
        if not desc or desc == "" then
            if C_Spell and C_Spell.RequestLoadSpellData then
                C_Spell.RequestLoadSpellData(spellID)
            end
            return false -- check again next time
        end
        buffIsSkill[spellID] = desc:lower():find("fishing skill") ~= nil
    end
    return buffIsSkill[spellID]
end

local function BuffBonus()
    local total = 0
    for _, aura in ipairs(ns.PlayerBuffs()) do
        if ns.IsFishingSkillBuff(aura.spellId) and aura.points and aura.points[1] then
            total = total + aura.points[1]
        end
    end
    return total
end

-- Returns base rank, bonus, and max rank, or nil if the skill isn't found.
function ns.FishingSkill()
    if not GetProfessions then return end
    local _, _, _, fishing = GetProfessions()
    if not fishing then return end
    local _, _, rank, maxRank = GetProfessionInfo(fishing)
    return rank, GearBonus() + BuffBonus(), maxRank
end

ns.On("UNIT_INVENTORY_CHANGED", function(unit)
    if unit == "player" then gearChecked = 0 end
end)

-- "Fishing 148/150 +100": base skill, the cap your training allows, and the
-- bonus from gear and food on top. Only the base counts toward the cap.
ns.RegisterBarSegment({ key = "skill", label = "Fishing skill", order = 10, text = function()
    local rank, bonus, maxRank = ns.FishingSkill()
    if not rank then return "Fishing ?" end
    local t = "Fishing " .. rank
    if maxRank and maxRank > 0 then t = t .. "/" .. maxRank end
    if bonus > 0 then t = t .. string.format(" |cff40ff40+%d|r", bonus) end
    return t
end })
