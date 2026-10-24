-- One key for the whole loop. Bound under Key Bindings > R.E.E.L. > Fish:
--   no lure on the pole  -> applies your chosen lure (Bar page)
--   otherwise            -> casts Fishing
--   bobber out           -> the same key is the interact key, which reels in
--
-- The key is bound to a secure button whose macro is rewritten out of combat
-- (lure or cast). While a bobber is out the key is overridden to the game's
-- INTERACTTARGET binding, then put back when the channel ends. Also adds
-- bindings for the lure button and the window.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    oneKeyLure = true, -- the Fish key applies a lure first when the pole has none
})

BINDING_NAME_CLICK_ReelFishButton_LeftButton = "Fish (lure, cast, reel in)"
BINDING_NAME_CLICK_ReelLureButton_LeftButton = "Apply lure"
BINDING_NAME_REEL_TOGGLE_WINDOW = "Toggle the R.E.E.L. window"

function ReelToggleWindow()
    ns.ToggleWindow()
end

local FISH_BINDING = "CLICK ReelFishButton:LeftButton"
local fishButton
local reeling = false -- the key is currently the interact key

local function UpdateMacro()
    if not fishButton or InCombatLockdown() or not ns.fishingName then return end
    local lure = ReelDB.settings.oneKeyLure and not ns.LureTimeLeft() and ns.ChosenLure()
    if lure then
        fishButton:SetAttribute("macrotext", "/use item:" .. lure.id .. "\n/use 16")
    else
        fishButton:SetAttribute("macrotext", "/cast " .. ns.fishingName)
    end
end

-- While a bobber is out, the Fish key reels in instead.
local function SetReeling(on)
    if not fishButton or InCombatLockdown() or on == reeling then return end
    reeling = on
    ClearOverrideBindings(fishButton)
    if on then
        local key1, key2 = GetBindingKey(FISH_BINDING)
        for _, key in ipairs({ key1, key2 }) do
            SetOverrideBinding(fishButton, true, key, "INTERACTTARGET")
        end
    end
end

ns.On("REEL_READY", function()
    fishButton = CreateFrame("Button", "ReelFishButton", UIParent, "SecureActionButtonTemplate")
    fishButton:SetSize(1, 1)
    fishButton:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10) -- offscreen
    fishButton:SetAttribute("type", "macro")
    fishButton:RegisterForClicks("AnyDown") -- down only, or a key press would run the macro twice
    UpdateMacro()
    C_Timer.NewTicker(1, UpdateMacro)
end)

ns.On("BAG_UPDATE_DELAYED", UpdateMacro)
ns.On("UNIT_INVENTORY_CHANGED", function(unit) if unit == "player" then UpdateMacro() end end)
ns.On("UPDATE_BINDINGS", function() if reeling then reeling = false; SetReeling(true) end end)

ns.On("REEL_CAST", function() SetReeling(true) end)
ns.On("UNIT_SPELLCAST_CHANNEL_STOP", function(unit)
    if unit == "player" then SetReeling(false) end
end)
ns.On("PLAYER_REGEN_ENABLED", function()
    -- combat blocked the switch; settle on whatever is true now
    if not ns.Channeling() then SetReeling(false) end
    UpdateMacro()
end)

-- Casting page addition -------------------------------------------------------

function ns.BuildOneKeyOptions(panel, anchor)
    local s = ReelDB.settings
    local header = W.Label(panel, "One key", "GameFontNormal")
    header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    local lure = W.Checkbox(panel, "Apply a lure first when the pole has none",
        function() return s.oneKeyLure end,
        function(v) s.oneKeyLure = v; UpdateMacro() end)
    lure:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    local note = W.Note(panel, "Bind the key under Key Bindings > R.E.E.L. > Fish. It applies a lure, casts, and while the bobber is out it reels in (it uses the game's Interact With Target action, so soft targeting must be on in Options > Gameplay). Apply lure and Toggle window can be bound there too.", ns.CONTENT_WIDTH - 4)
    note:SetPoint("TOPLEFT", lure, "BOTTOMLEFT", 0, -2)
    return lure
end
