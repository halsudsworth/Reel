-- Fishing skill buffs on the bar: food and anything else that raises fishing
-- skill, each with its timer. With no such buff and a pole equipped, shows a
-- red "No food" (optional). Camp buffs have their own bar item (Camp.lua),
-- and buffs that only mention fishing, like Master Angler!, are left out.
--
-- With no buff and a fishing food in your bags, the Food item's icon is a button
-- that eats your best one (or the one picked on the Bar page). It's also bound
-- under Key Bindings > AddOns > Eat fishing food. Never eats on its own.

local _, ns = ...

ns.RegisterDefaults({
    foodMissing = true, -- show "No food" on the bar
    foodChoice = "best", -- "best", or the item ID of the food to always eat
})

-- Foods that raise fishing skill, best first. From site/data/gear.json ("food": the beta item and
-- spell tooltips and the Forever fishing guide, 2026-11-02). level = character level to eat it.
local FOODS = {
    { id = 13930, name = "Filet of Redgill", bonus = 18, level = 35 },
    { id = 8957, name = "Spinefin Halibut", bonus = 18, level = 45 },
    { id = 4594, name = "Rockscale Cod", bonus = 12, level = 25 },
    { id = 4593, name = "Bristle Whisker Catfish", bonus = 8, level = 15 },
    { id = 5476, name = "Fillet of Frenzy", bonus = 5, level = 5 },
    { id = 6316, name = "Loch Frenzy Delight", bonus = 3, level = 5 },
}
ns.FISHING_FOODS = FOODS

_G["BINDING_NAME_CLICK ReelFoodKeyButton:LeftButton"] = "Eat fishing food"

local GetItemIconCompat = C_Item and C_Item.GetItemIconByID or GetItemIcon
local GetItemCountCompat = C_Item and C_Item.GetItemCount or GetItemCount

local button, keyButton, buttonFood
local FOOD_ICON = "Interface\\Icons\\INV_Misc_Food_47"

local function Usable(food, level)
    return level >= food.level and GetItemCountCompat(food.id) > 0
end

-- The picked food if you have it and can eat it, otherwise the best you have: highest bonus,
-- then the one you have most of.
local function ChosenFood()
    local level = UnitLevel("player") or 0
    local choice = ReelDB.settings.foodChoice
    for _, food in ipairs(FOODS) do
        if food.id == choice and Usable(food, level) then return food end
    end
    local best
    for _, food in ipairs(FOODS) do
        if Usable(food, level) and (not best or food.bonus > best.bonus
            or (food.bonus == best.bonus and GetItemCountCompat(food.id) > GetItemCountCompat(best.id))) then
            best = food
        end
    end
    return best
end
ns.ChosenFood = ChosenFood

-- Choices for the Bar page's "Use" menu.
function ns.FoodOptions()
    local list = { { value = "best", text = "Best I have" } }
    for _, food in ipairs(FOODS) do
        list[#list + 1] = { value = food.id, text = food.name }
    end
    return list
end

local function FishingBuffs()
    local list = {}
    for _, aura in ipairs(ns.PlayerBuffs()) do
        if ns.IsFishingSkillBuff(aura.spellId) then list[#list + 1] = aura end
    end
    return list
end

-- The button shows with a pole in hand, the Food item on the bar, no fishing buff running,
-- and something to eat. Its look and macro change only out of combat.
local function UpdateButton()
    if not button then return end
    if buttonFood then button.count:SetText(GetItemCountCompat(buttonFood.id)) end
    if InCombatLockdown() then return end
    local food = ChosenFood()
    keyButton:SetAttribute("macrotext", food and ("/use item:" .. food.id) or "")
    local want = food and ns.PoleEquipped() and ns.BarItemOn("buffs") and #FishingBuffs() == 0 and food or nil
    if want ~= buttonFood then
        buttonFood = want
        if want then
            button:SetAttribute("macrotext", "/use item:" .. want.id)
            button.icon:SetTexture(GetItemIconCompat(want.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.count:SetText(GetItemCountCompat(want.id))
        end
    end
    button:SetShown(want ~= nil)
end
ns.UpdateFoodButton = UpdateButton

local function NewButton(name)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetAttribute("type", "macro")
    return b
end

ns.On("REEL_READY", function() ns.WhenOutOfCombat(function()
    button = NewButton("ReelFoodButton")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -1, 2)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnEnter", function(self)
        if not buttonFood then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Eat " .. buttonFood.name)
        GameTooltip:AddLine(string.format("+%d Fishing, %d in bags", buttonFood.bonus, GetItemCountCompat(buttonFood.id)), 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Hide()
    ns.SetBarButton(button, "food")
    -- The key binding has its own key-down button, like Apply lure's.
    keyButton = NewButton("ReelFoodKeyButton")
    keyButton:SetSize(1, 1)
    keyButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10) -- offscreen
    keyButton:RegisterForClicks("AnyDown")
    UpdateButton()
    C_Timer.NewTicker(1, UpdateButton)
end) end)

ns.On("BAG_UPDATE_DELAYED", UpdateButton)
ns.On("PLAYER_REGEN_ENABLED", UpdateButton)
ns.On("UNIT_INVENTORY_CHANGED", function(unit) if unit == "player" then UpdateButton() end end)

-- Food: the buff's timer ("14:51") or a red "None"; the buff's name is in the tooltip.
-- With no buff and food in bags, the food button sits in this row.
ns.RegisterBarSegment({
    key = "buffs",
    label = "Food buff",
    name = "Food",
    group = "status",
    order = 25,
    icon = function() return buttonFood and GetItemIconCompat(buttonFood.id) or "Interface\\Icons\\INV_Misc_Food_47" end,
    text = function(s)
        local tips, first, icon = {}, nil, nil
        for _, aura in ipairs(FishingBuffs()) do
            local exp = aura.expirationTime
            local t = (exp and exp > 0) and ns.FormatTime(exp - GetTime()) or "on"
            first = first or t
            icon = icon or aura.icon
            tips[#tips + 1] = (exp and exp > 0) and (aura.name .. " " .. t) or aura.name
        end
        if first then
            -- the buff's own icon, plain (not a button)
            return { value = first, tip = table.concat(tips, "\n"), reserve = "88:88", icon = icon or FOOD_ICON }, true
        end
        if ns.PoleOrPreview() then
            if buttonFood then
                local tip = "No food: click to eat " .. buttonFood.name
                if s.foodMissing then
                    return { value = "|cffff4a3aNone|r", short = "|cffff4a3aNone|r", tip = tip, button = "food", reserve = "88:88" }, true
                end
                return { value = "", short = "", tip = tip, button = "food", reserve = "88:88" }, true
            end
            -- With "No food" turned off, no buff means no row at all.
            if s.foodMissing then
                return { value = "|cffff4a3aNone|r", short = "|cffff4a3aNone|r", tip = "No food", missing = true, reserve = "88:88", icon = FOOD_ICON }, true
            end
        end
    end,
    options = {
        { key = "foodMissing", label = "Show \"None\" when missing" },
        { key = "foodChoice", label = "Use", choices = function() return ns.FoodOptions() end,
          note = "A picked food falls back to your best one when you run out.",
          changed = function() UpdateButton() end },
    },
})
