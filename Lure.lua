-- Lures: countdown on the bar (red in the last WARN_SECONDS, "No lure" when
-- missing), and a button that applies the best lure in your bags to your
-- fishing pole: your best usable one, or one you pick. Both settings are on
-- the Bar page.
--
-- Bonus and skill values are from fan beta data (Forever fishing guides), not
-- Blizzard. Item IDs are from Wowhead's Forever database.

local _, ns = ...
local WARN_SECONDS = 30

ns.RegisterDefaults({
    lureButton = true,
    lureChoice = "best", -- "best", or the item ID of the lure to always use
})

-- Best first. req = Fishing skill needed to use it.
local LURES = {
    { id = 6533, name = "Aquadynamic Fish Attractor", bonus = 100, req = 100 },
    { id = 6532, name = "Bright Baubles", bonus = 75, req = 100 },
    { id = 7307, name = "Flesh Eating Worm", bonus = 75, req = 100 },
    { id = 6530, name = "Nightcrawlers", bonus = 50, req = 50 },
    { id = 6811, name = "Aquadynamic Fish Lens", bonus = 50, req = 50 },
    { id = 6529, name = "Shiny Bauble", bonus = 25, req = 0 },
}

-- Reads the icon from game files, so unlike GetItemInfo it works before the
-- item is cached.
local GetItemIconCompat = C_Item and C_Item.GetItemIconByID or GetItemIcon
local GetItemCountCompat = C_Item and C_Item.GetItemCount or GetItemCount

local button, buttonLure

-- Seconds left on the main-hand temporary enchant (the lure), or nil.
function ns.LureTimeLeft()
    local has, expiration = GetWeaponEnchantInfo()
    if has and expiration then return expiration / 1000 end
end

local function Usable(lure, rank)
    return rank >= lure.req and GetItemCountCompat(lure.id) > 0
end

-- The picked lure if you have it and can use it, otherwise your best one.
local function ChosenLure()
    local rank = ns.FishingSkill() or 0
    local choice = ReelDB.settings.lureChoice
    for _, lure in ipairs(LURES) do
        if lure.id == choice and Usable(lure, rank) then return lure end
    end
    for _, lure in ipairs(LURES) do
        if Usable(lure, rank) then return lure end
    end
end

ns.ChosenLure = ChosenLure

-- Choices for the Bar page dropdown.
function ns.LureOptions()
    local list = { { value = "best", text = "Best I have" } }
    for _, lure in ipairs(LURES) do
        list[#list + 1] = { value = lure.id, text = lure.name }
    end
    return list
end

local function UpdateButton()
    if not button then return end
    if buttonLure then
        button.count:SetText(GetItemCountCompat(buttonLure.id))
    end
    if InCombatLockdown() then return end
    local lure = ReelDB.settings.lureButton and ChosenLure() or nil
    if lure ~= buttonLure then
        buttonLure = lure
        if lure then
            -- Use the lure, then target the main hand (the pole) with it.
            button:SetAttribute("macrotext", "/use item:" .. lure.id .. "\n/use 16")
            local icon = GetItemIconCompat(lure.id)
            button.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            button.count:SetText(GetItemCountCompat(lure.id))
        end
    end
    button:SetShown(lure ~= nil)
end

ns.On("REEL_READY", function() ns.WhenOutOfCombat(function()
    button = CreateFrame("Button", "ReelLureButton", UIParent, "SecureActionButtonTemplate")
    button:SetAttribute("type", "macro")
    button:RegisterForClicks("AnyUp", "AnyDown")
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- trim the icon's built-in border
    button.count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    button.count:SetPoint("BOTTOMRIGHT", -1, 2)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetScript("OnEnter", function(self)
        if not buttonLure then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Apply " .. buttonLure.name)
        GameTooltip:AddLine(string.format("+%d Fishing, %d in bags", buttonLure.bonus, GetItemCountCompat(buttonLure.id)), 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Hide()
    ns.SetBarButton(button)
    C_Timer.NewTicker(1, UpdateButton)
end) end)

ns.UpdateLureButton = UpdateButton

ns.On("BAG_UPDATE_DELAYED", UpdateButton)
ns.On("PLAYER_REGEN_ENABLED", UpdateButton)

ns.RegisterBarSegment({ key = "lure", label = "Lure timer", order = 20, text = function(s)
    local left = ns.LureTimeLeft()
    if left then
        local t = "Lure " .. ns.FormatTime(left)
        if left <= WARN_SECONDS then t = "|cffff4040" .. t .. " !!|r" end
        return t, true
    end
    if ns.PoleEquipped() then
        if buttonLure then
            return "|cffff4040No lure|r - click the icon to add one", true
        elseif s.lureButton then
            return "|cffff4040No lure|r (none in bags)", true
        end
        return "|cffff4040No lure|r", true
    end
end })
