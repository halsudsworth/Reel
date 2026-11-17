-- Fishing skill buffs on the bar: food and anything else that raises fishing
-- skill, each with its timer. With no such buff and a pole equipped, shows a
-- red "No food" (optional). Camp buffs have their own bar item (Camp.lua),
-- and buffs that only mention fishing, like Master Angler!, are left out.
--
-- With no buff and a fishing food in your bags, the Food item's icon is a button
-- that eats your best one (or the one picked on the Bar page). It's also bound
-- under Key Bindings > AddOns > Eat fishing food. Never eats on its own.

local _, ns = ...
local L = ns.L

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

_G["BINDING_NAME_CLICK ReelFoodKeyButton:LeftButton"] = L["Eat fishing food"]

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
    local list = { { value = "best", text = L["Best I have"] } }
    for _, food in ipairs(FOODS) do
        list[#list + 1] = { value = food.id, text = food.name }
    end
    return list
end

-- The buff a fishing food gives is told apart by its English description ("fishing skill"),
-- which other languages don't have. So: after eating one of FOODS, the long buff that turns up
-- next is remembered by spell ID (ReelDB.fishingBuffs), and counts in any language from then on.
-- ns.LearnBuffAfter is shared with the camp (Camp.lua).
local watching = {} -- { store, spells = {spellID=true}, minDuration, until, before = {spellID=true} }

local function ItemSpellID(itemID)
    if not (C_Item and C_Item.GetItemSpell) then return end
    local ok, _, spellID = pcall(C_Item.GetItemSpell, itemID)
    return ok and spellID or nil
end

-- Watch for the buff that follows a cast of any of itemIDs' use spells (or of spellIDs), and
-- keep its spell ID in ReelDB[store].
function ns.LearnBuffAfter(store, itemIDs, minDuration, window, spellIDs)
    local w = { store = store, items = itemIDs, extra = spellIDs, minDuration = minDuration, window = window }
    watching[#watching + 1] = w
    return w
end

local function Casts(w, spellID)
    for _, id in ipairs(w.extra or {}) do if id == spellID then return true end end
    for _, item in ipairs(w.items) do if ItemSpellID(item) == spellID then return true end end
    return false
end

ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
    if unit ~= "player" or not spellID then return end
    for _, w in ipairs(watching) do
        if Casts(w, spellID) then
            w["until"] = GetTime() + w.window
            w.before = {}
            for _, aura in ipairs(ns.PlayerBuffs()) do if aura.spellId then w.before[aura.spellId] = true end end
        end
    end
end)

ns.On("UNIT_AURA", function(unit)
    if unit ~= "player" then return end
    for _, w in ipairs(watching) do
        if w["until"] and GetTime() <= w["until"] then
            for _, aura in ipairs(ns.PlayerBuffs()) do
                local id = aura.spellId
                if id and not w.before[id] and (aura.duration or 0) >= w.minDuration then
                    ReelDB[w.store] = ReelDB[w.store] or {}
                    ReelDB[w.store][id] = true
                    w["until"] = nil
                    break
                end
            end
        elseif w["until"] then
            w["until"] = nil
        end
    end
end)

local foodItems = {}
for i, food in ipairs(FOODS) do foodItems[i] = food.id end
-- Eating takes up to 30 seconds; food buffs last 15 minutes or more.
ns.LearnBuffAfter("fishingBuffs", foodItems, 600, 45)

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
        GameTooltip:SetText(string.format(L["Eat %s"], buttonFood.name))
        GameTooltip:AddLine(string.format(L["+%d Fishing, %d in bags"], buttonFood.bonus, GetItemCountCompat(buttonFood.id)), 1, 1, 1)
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
    label = L["Food buff"],
    name = L["Food"],
    group = "status",
    order = 25,
    icon = function() return buttonFood and GetItemIconCompat(buttonFood.id) or "Interface\\Icons\\INV_Misc_Food_47" end,
    text = function(s)
        local tips, first, icon = {}, nil, nil
        for _, aura in ipairs(FishingBuffs()) do
            local exp = aura.expirationTime
            local t = (exp and exp > 0) and ns.FormatTime(exp - GetTime()) or L["on"]
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
                local tip = string.format(L["No food: click to eat %s"], buttonFood.name)
                if s.foodMissing then
                    return { value = "|cffff4a3a" .. L["None"] .. "|r", short = "|cffff4a3a" .. L["None"] .. "|r", tip = tip, button = "food", reserve = "88:88" }, true
                end
                return { value = "", short = "", tip = tip, button = "food", reserve = "88:88" }, true
            end
            -- With "No food" turned off, no buff means no row at all.
            if s.foodMissing then
                return { value = "|cffff4a3a" .. L["None"] .. "|r", short = "|cffff4a3a" .. L["None"] .. "|r", tip = L["No food"], missing = true, reserve = "88:88", icon = FOOD_ICON }, true
            end
        end
    end,
    options = {
        { key = "foodMissing", label = L["Show \"None\" when missing"] },
        { key = "foodChoice", label = L["Use"], choices = function() return ns.FoodOptions() end,
          note = L["A picked food falls back to your best one when you run out."],
          changed = function() UpdateButton() end },
    },
})
