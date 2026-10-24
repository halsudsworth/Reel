-- Fishing skill buffs on the bar: food and anything else that raises fishing
-- skill, each with its timer. With no such buff and a pole equipped, shows a
-- red "No food" (optional). Camp buffs have their own bar item (Camp.lua),
-- and buffs that only mention fishing, like Master Angler!, are left out.

local _, ns = ...

ns.RegisterDefaults({
    foodMissing = true, -- show "No food" on the bar
})

ns.RegisterBarSegment({
    key = "buffs",
    label = "Fishing skill buffs (food)",
    order = 25,
    text = function(s)
        local parts = {}
        for _, aura in ipairs(ns.PlayerBuffs()) do
            if ns.IsFishingSkillBuff(aura.spellId) then
                local exp = aura.expirationTime
                if exp and exp > 0 then
                    parts[#parts + 1] = aura.name .. " " .. ns.FormatTime(exp - GetTime())
                else
                    parts[#parts + 1] = aura.name
                end
            end
        end
        if #parts > 0 then
            return parts, true -- each buff is its own bar item
        end
        if s.foodMissing and ns.PoleEquipped() then
            return "|cffff4040No food|r", true
        end
    end,
    options = {
        { key = "foodMissing", label = "Show \"No food\" when missing" },
    },
})
