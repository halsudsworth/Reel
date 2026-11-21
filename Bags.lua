-- Bags: free bag space on the fishing bar, shown while fishing. Counts only bags that can hold
-- fish (bag family 0), so quivers, ammo pouches and soul bags are left out. Amber at LOW or fewer,
-- a red "Full" and a greyed icon at none. Mockups: site/art/ui/mockup/bags/ (2026-11-21).

local _, ns = ...
local L = ns.L

local LOW = 5
local ICON = "Interface\\Icons\\INV_Misc_Bag_08"
local AMBER, RED = "|cfff2b24a", "|cffff4a3a"

local GetFree = C_Container and C_Container.GetContainerNumFreeSlots or GetContainerNumFreeSlots

local function FreeSlots()
    if not GetFree then return nil end
    local free = 0
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local n, family = GetFree(bag)
        if n and (family == nil or family == 0) then free = free + n end
    end
    return free
end
ns.FreeBagSlots = FreeSlots

ns.RegisterBarSegment({
    key = "bags",
    label = L["Bag space"],
    name = L["Bags"],
    group = "status",
    order = 35,
    icon = ICON,
    text = function()
        if not ns.PoleOrPreview() then return end
        local free = FreeSlots()
        if not free then return end
        local n = string.format(L["%d free"], free)
        if free == 0 then
            local full = RED .. L["Full"] .. "|r"
            return { value = full, short = full, tip = L["Bags"] .. ": " .. L["Full"], missing = true, icon = ICON, reserve = n, reserveShort = "88" }
        end
        local value = free <= LOW and (AMBER .. n .. "|r") or n
        local short = free <= LOW and (AMBER .. free .. "|r") or tostring(free)
        return { value = value, short = short, tip = L["Bags"] .. ": " .. n, icon = ICON, reserve = string.format(L["%d free"], 88), reserveShort = "88" }
    end,
})
