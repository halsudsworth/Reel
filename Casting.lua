-- Casting page: double-click in the world to cast Fishing.
--
-- Addons can't cast spells themselves, so on the second click's mouse-down
-- this binds the mouse button to a secure button that casts Fishing. The
-- player's own mouse-up then "clicks" it, and the binding is cleared after.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    doubleClick = true,
    castMouseButton = "RightButton",
    needPole = true,  -- only when a fishing pole is in the main hand
    clickSpeed = 400, -- max milliseconds between the two clicks
})

local MOUSE_BUTTONS = {
    { value = "RightButton", text = "Right button", key = "BUTTON2" },
    { value = "LeftButton", text = "Left button", key = "BUTTON1" },
    { value = "MiddleButton", text = "Middle button", key = "BUTTON3" },
    { value = "Button4", text = "Mouse button 4", key = "BUTTON4" },
    { value = "Button5", text = "Mouse button 5", key = "BUTTON5" },
}

local WEAPON_CLASS, FISHING_POLE_SUBCLASS = 2, 20
local GetItemInfoInstantCompat = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant

local castButton
local lastClick = 0

local function BindingKey(mouseButton)
    for _, option in ipairs(MOUSE_BUTTONS) do
        if option.value == mouseButton then return option.key end
    end
end

function ns.PoleEquipped()
    local id = GetInventoryItemID("player", INVSLOT_MAINHAND or 16)
    if not id then return false end
    local _, _, _, _, _, classID, subclassID = GetItemInfoInstantCompat(id)
    return classID == WEAPON_CLASS and subclassID == FISHING_POLE_SUBCLASS
end

local function ClearBinding()
    if not InCombatLockdown() then
        ClearOverrideBindings(castButton)
    end
end

local function OnWorldMouseDown(_, button)
    local s = ReelDB.settings
    if button ~= s.castMouseButton then return end
    if not castButton or not s.doubleClick or not ns.fishingName or InCombatLockdown() then return end
    if s.needPole and not ns.PoleEquipped() then return end
    if UnitExists("mouseover") then return end -- clicking an NPC or player

    local now = GetTime()
    if now - lastClick <= s.clickSpeed / 1000 then
        lastClick = 0
        SetOverrideBindingClick(castButton, true, BindingKey(button), "ReelCastButton")
        C_Timer.After(1, ClearBinding) -- in case the mouse-up never reaches it
    else
        lastClick = now
    end
end

ns.On("REEL_READY", function()
    if not ns.fishingName then return end
    -- A /reload in combat can't set up a secure button; wait for combat to end.
    ns.WhenOutOfCombat(function()
        castButton = CreateFrame("Button", "ReelCastButton", UIParent, "SecureActionButtonTemplate")
        castButton:SetSize(1, 1)
        castButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10) -- offscreen
        castButton:SetAttribute("type", "spell")
        castButton:SetAttribute("spell", ns.fishingName)
        castButton:RegisterForClicks("AnyUp", "AnyDown")
        castButton:SetScript("PostClick", ClearBinding)
    end)
    WorldFrame:HookScript("OnMouseDown", OnWorldMouseDown)
end)

-- A binding left behind when combat blocked the clear.
ns.On("PLAYER_REGEN_ENABLED", function() if castButton then ClearBinding() end end)

ns.RegisterPage({
    name = "Casting",
    order = 15,
    build = function(panel)
        local s = ReelDB.settings
        local doubleClick, mouseButton, needPole, speed

        local function Refresh()
            for _, c in ipairs({ doubleClick, mouseButton, needPole, speed }) do c.Refresh() end
            mouseButton:SetActive(s.doubleClick)
            needPole:SetActive(s.doubleClick)
            speed:SetActive(s.doubleClick)
        end

        doubleClick = W.Checkbox(panel, "Double-click to cast",
            function() return s.doubleClick end,
            function(v) s.doubleClick = v; Refresh() end)
        doubleClick:SetPoint("TOPLEFT")

        local note = W.Note(panel, "Double-click anywhere in the world to cast Fishing. Doesn't work in combat or when your cursor is over a character.", ns.CONTENT_WIDTH - 30)
        note:SetPoint("TOPLEFT", doubleClick, "BOTTOMLEFT", 26, 0)

        mouseButton = W.Dropdown(panel, "Mouse button", 140, MOUSE_BUTTONS,
            function() return s.castMouseButton end,
            function(v) s.castMouseButton = v; lastClick = 0 end)
        mouseButton:SetPoint("TOPLEFT", doubleClick, "BOTTOMLEFT", 90, -40)

        needPole = W.Checkbox(panel, "Only with a fishing pole equipped",
            function() return s.needPole end,
            function(v) s.needPole = v; Refresh() end)
        needPole:SetPoint("TOPLEFT", doubleClick, "BOTTOMLEFT", 0, -72)

        speed = W.Slider(panel, "Click speed", 200, 600, 50, "ms",
            function() return s.clickSpeed end,
            function(v) s.clickSpeed = v end)
        speed:SetPoint("TOPLEFT", needPole, "BOTTOMLEFT", 90, -14)

        local speedNote = W.Note(panel, "Longest gap allowed between the two clicks.", ns.CONTENT_WIDTH - 4)
        speedNote:SetPoint("TOPLEFT", needPole, "BOTTOMLEFT", 0, -40)

        local oneKeyLure = ns.BuildOneKeyOptions(panel, speedNote)

        return function()
            Refresh()
            oneKeyLure.Refresh()
        end
    end,
})
