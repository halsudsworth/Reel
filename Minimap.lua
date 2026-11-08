-- Minimap button: click to open Reel, right-click for quick settings, drag to move around the
-- minimap edge.

local _, ns = ...

ns.RegisterDefaults({
    minimapButton = true,
    minimapAngle = 225, -- degrees around the minimap
})

local btn

local function Place()
    local angle = math.rad(ReelDB.settings.minimapAngle)
    local radius = Minimap:GetWidth() / 2 + 5
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function FollowCursor()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    ReelDB.settings.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx))
    Place()
end

-- Right-click menu: the settings people flip mid-session. It closes on a second right-click,
-- on Export, or a moment after the mouse leaves it.
local menu
local QUICK = {
    { text = "Show R.E.E.L. bar", get = function(s) return s.bar end,
      set = function(s, v) s.bar = v; ns.UpdateBar() end },
    { text = "Lock R.E.E.L. bar", get = function(s) return s.barLocked end,
      set = function(s, v) s.barLocked = v; ns.UpdateBar() end },
    { text = "Clean View", get = function(s) return s.cleanView end,
      set = function(_, v) ns.SetCleanView(v) end },
    { text = "Splash booster", get = function(s) return s.boost end,
      set = function(s, v) s.boost = v; ns.ApplySettings() end },
    { text = "Export journal", run = function() ns.ShowExport() end },
}

local function RefreshMenu()
    local s = ReelDB.settings
    for _, item in ipairs(menu.items) do
        if item.entry.get then item.check:SetShown(item.entry.get(s) and true or false) end
    end
end

local function BuildMenu()
    menu = CreateFrame("Frame", "ReelMinimapMenu", UIParent)
    menu:SetFrameStrata("DIALOG")
    menu:SetClampedToScreen(true)
    menu:EnableMouse(true)
    menu:Hide()
    local bg = menu:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    bg:SetAllPoints()
    menu.items = {}
    local width = 170
    for i, entry in ipairs(QUICK) do
        local item = CreateFrame("Button", nil, menu)
        item:SetSize(width - 8, 20)
        item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 20)
        item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        item.check = item:CreateTexture(nil, "ARTWORK")
        item.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        item.check:SetSize(16, 16)
        item.check:SetPoint("LEFT", 2, 0)
        item.check:Hide()
        local label = item:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        label:SetPoint("LEFT", 22, 0)
        label:SetText(entry.text)
        item.entry = entry
        item:SetScript("OnClick", function()
            if entry.run then
                menu:Hide()
                entry.run()
                return
            end
            local s = ReelDB.settings
            entry.set(s, not entry.get(s))
            RefreshMenu()
        end)
        menu.items[i] = item
    end
    menu:SetSize(width, #QUICK * 20 + 8)
    -- Close a moment after the mouse leaves both the menu and the button.
    local away = 0
    menu:SetScript("OnShow", function() away = 0 end)
    menu:SetScript("OnUpdate", function(self, elapsed)
        if self:IsMouseOver() or btn:IsMouseOver() then away = 0 return end
        away = away + elapsed
        if away > 1 then self:Hide() end
    end)
    tinsert(UISpecialFrames, "ReelMinimapMenu") -- Escape closes it
end

local function ToggleMenu()
    if not menu then BuildMenu() end
    if menu:IsShown() then return menu:Hide() end
    GameTooltip:Hide()
    menu:ClearAllPoints()
    menu:SetPoint("TOPRIGHT", btn, "BOTTOMLEFT", 8, 8)
    RefreshMenu()
    menu:Show()
end

local function Build()
    btn = CreateFrame("Button", "ReelMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\Trade_Fishing")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 7, -5)
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")

    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", FollowCursor) end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnClick", function(_, button)
        if button == "RightButton" then return ToggleMenu() end
        if menu then menu:Hide() end
        ns.ToggleWindow()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("R.E.E.L.")
        GameTooltip:AddLine("Click to open. Right-click for quick settings. Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Place()
end

function ns.UpdateMinimapButton()
    if not btn then Build() end
    btn:SetShown(ReelDB.settings.minimapButton)
    if menu and not btn:IsShown() then menu:Hide() end
end

ns.On("REEL_READY", ns.UpdateMinimapButton)
