-- Luremaster (Forever Professions legacy perk): chance of an extra fish while
-- a lure is active, 25% per rank, 2 ranks. Counts bonus fish per session,
-- shown in the bar's Caught item and on the Stats page.
--
-- The game doesn't flag the extra fish, so this counts the extras whenever a
-- catch holds 2 or more of an item while a lure is on. It's an estimate.

local _, ns = ...

local LUREMASTER_SPELL_ID = 1225455 -- wowhead.com/forever/spell=1225455

function ns.HasLuremaster()
    return IsPlayerSpell and IsPlayerSpell(LUREMASTER_SPELL_ID) or false
end

-- Bonus fish this session (kept with the session, see Log.lua).
function ns.LuremasterCount()
    return ns.session.bonus
end

local counted = false -- one count per cast, like Log.lua
ns.On("REEL_CAST", function() counted = false end)

ns.On("LOOT_OPENED", function()
    if not IsFishingLoot() or counted or not ns.HasLuremaster() or not ns.LureTimeLeft() then return end
    counted = true
    local session, added = ns.session, false
    for slot = 1, GetNumLootItems() do
        if GetLootSlotLink(slot) then
            local _, _, qty = GetLootSlotInfo(slot)
            if qty and qty >= 2 then
                session.bonus = session.bonus + qty - 1
                added = true
            end
        end
    end
    if added then ns.Fire("REEL_DATA_CHANGED") end
end)
