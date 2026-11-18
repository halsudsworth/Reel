-- One key for the whole loop. Bound under Options > Keybindings > AddOns > Fish:
--   no lure on the pole  -> applies your chosen lure (Bar page)
--   otherwise            -> casts Fishing
--   bobber out           -> the same key is the interact key, which reels in
--
-- The key is bound to a secure button whose macro is rewritten out of combat
-- (lure or cast). While a bobber is out the key is overridden to the game's
-- INTERACTTARGET binding, then put back when the channel ends. Also adds
-- bindings for applying a lure, for the window, and Quick recast: pull the
-- bobber in and cast again at once, never applying a lure.

local _, ns = ...
local L = ns.L
local W = ns.W

ns.RegisterDefaults({
    oneKeyLure = true, -- the Fish key applies a lure first when the pole has none
    controllerButton = "none", -- a gamepad button that is the Fish key while a pole is equipped
})

-- Gamepad buttons by WoW's key names, labelled the Xbox way (PAD1 is A/Cross).
local PAD_BUTTONS = {
    { value = "none", text = L["None"] },
    { value = "PAD1", text = "A" }, { value = "PAD2", text = "B" },
    { value = "PAD3", text = "X" }, { value = "PAD4", text = "Y" },
    { value = "PADLSHOULDER", text = "LB" }, { value = "PADRSHOULDER", text = "RB" },
    { value = "PADLTRIGGER", text = "LT" }, { value = "PADRTRIGGER", text = "RT" },
    { value = "PADDUP", text = L["D-pad up"] }, { value = "PADDDOWN", text = L["D-pad down"] },
    { value = "PADDLEFT", text = L["D-pad left"] }, { value = "PADDRIGHT", text = L["D-pad right"] },
}

_G["BINDING_NAME_CLICK ReelFishButton:LeftButton"] = L["Fish (lure, cast, reel in)"]
_G["BINDING_NAME_CLICK ReelRecastButton:LeftButton"] = L["Quick recast (no lure)"]
_G["BINDING_NAME_CLICK ReelLureKeyButton:LeftButton"] = L["Apply lure"]
BINDING_NAME_REEL_TOGGLE_WINDOW = L["Toggle the R.E.E.L. window"]

function ReelToggleWindow()
    ns.ToggleWindow()
end

local FISH_BINDING = "CLICK ReelFishButton:LeftButton"
local fishButton, lureKeyButton, recastButton, padOwner
local reeling = false -- the key is currently the interact key

local function LureMacro(lure)
    return "/use item:" .. lure.id .. "\n/use 16"
end

local function UpdateMacro()
    if not fishButton or InCombatLockdown() or not ns.fishingName then return end
    local chosen = ns.ChosenLure()
    local lure = ReelDB.settings.oneKeyLure and not ns.LureTimeLeft() and chosen
    if lure then
        fishButton:SetAttribute("macrotext", LureMacro(lure))
    else
        fishButton:SetAttribute("macrotext", "/cast " .. ns.fishingName)
    end
    -- The Apply lure key has its own key-down button; the bar's lure button
    -- is for the mouse and fires on both down and up.
    lureKeyButton:SetAttribute("macrotext", chosen and LureMacro(chosen) or "")
end

-- /stopcasting ends the channel (the bobber goes), then the cast starts a new one.
local function RecastMacro()
    return "/stopcasting\n/cast " .. ns.fishingName
end

-- The controller button, if one is picked and a fishing pole is equipped. Away from fishing
-- the button keeps its own job (A jumps), so it's only taken over with the pole in hand.
local function PadKey()
    local key = ReelDB.settings.controllerButton
    if key and key ~= "none" and ns.PoleEquipped() then return key end
end

-- The controller button is a second Fish key: an override binding, so the player's own
-- bindings (keyboard and controller) are never changed.
local function UpdatePad()
    if not padOwner or InCombatLockdown() then return end
    ClearOverrideBindings(padOwner)
    local key = PadKey()
    if key then SetOverrideBinding(padOwner, false, key, FISH_BINDING) end
end

-- While a bobber is out, the Fish key reels in instead (the keyboard key and the controller
-- button; this override has priority over the controller button's own).
local function SetReeling(on)
    if not fishButton or InCombatLockdown() or on == reeling then return end
    reeling = on
    ClearOverrideBindings(fishButton)
    if on then
        -- Each key on its own: a list with a gap in it ({ key1, nil, pad }) would stop ipairs early.
        local key1, key2 = GetBindingKey(FISH_BINDING)
        for _, key in pairs({ key1, key2, PadKey() }) do
            SetOverrideBinding(fishButton, true, key, "INTERACTTARGET")
        end
    end
end

local function KeyButton(name)
    local b = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    b:SetSize(1, 1)
    b:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -10, 10) -- offscreen
    b:SetAttribute("type", "macro")
    b:RegisterForClicks("AnyDown") -- down only, or a key press would run the macro twice
    return b
end

ns.On("REEL_READY", function() ns.WhenOutOfCombat(function()
    fishButton = KeyButton("ReelFishButton")
    lureKeyButton = KeyButton("ReelLureKeyButton")
    recastButton = KeyButton("ReelRecastButton")
    padOwner = CreateFrame("Frame")
    UpdatePad()
    if ns.fishingName then recastButton:SetAttribute("macrotext", RecastMacro()) end
    UpdateMacro()
    C_Timer.NewTicker(1, UpdateMacro)
end) end)

ns.On("BAG_UPDATE_DELAYED", UpdateMacro)
ns.On("UNIT_INVENTORY_CHANGED", function(unit) if unit == "player" then UpdateMacro(); UpdatePad() end end)
ns.On("PLAYER_EQUIPMENT_CHANGED", UpdatePad)
ns.On("UPDATE_BINDINGS", function()
    if reeling and not InCombatLockdown() then reeling = false; SetReeling(true) end
end)

-- The cast event can arrive while the Fish key is still held from the press
-- that cast; switching the binding under a held key could make the release
-- reel in at once. A bite takes seconds, so wait for the key to come up.
-- Reeling in uses the game's soft interact, which is gamepad-only (SoftTargetInteract 1)
-- until the player turns on Enable Interact Key; the client won't let an addon change it.
local INTERACT_PATH = L["Options > Gameplay > Controls"]
local warnedInteract = false
local function CheckInteractKey()
    if warnedInteract or not (GetBindingKey(FISH_BINDING) or PadKey()) then return end
    local value = tonumber((C_CVar and C_CVar.GetCVar or GetCVar)("SoftTargetInteract"))
    if value and value < 2 then
        warnedInteract = true
        ns.Print(string.format(L["To reel in with the Fish key, turn on Enable Interact Key in %s."], INTERACT_PATH))
    end
end

ns.On("REEL_CAST", function()
    CheckInteractKey()
    C_Timer.After(0.5, function()
        if ns.Channeling() then SetReeling(true) end
    end)
end)
ns.On("UNIT_SPELLCAST_CHANNEL_STOP", function(unit)
    if unit == "player" then SetReeling(false) end
end)
ns.On("PLAYER_REGEN_ENABLED", function()
    -- combat may have blocked a switch either way; start clean and settle on
    -- whatever is true now
    if fishButton then
        ClearOverrideBindings(fishButton)
        reeling = false
        if ns.Channeling() then SetReeling(true) end
    end
    UpdateMacro()
    UpdatePad()
end)

-- Casting page addition -------------------------------------------------------

function ns.BuildOneKeyOptions(panel, anchor)
    local s = ReelDB.settings
    local header = W.Label(panel, L["One key"], "GameFontNormal")
    header:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
    local lure = W.Checkbox(panel, L["Apply a lure first when the pole has none"],
        function() return s.oneKeyLure end,
        function(v) s.oneKeyLure = v; UpdateMacro() end)
    lure:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
    local note = W.Note(panel, string.format(L["Bind the key under Options > Keybindings > AddOns > Fish. It applies a lure, casts, and while the bobber is out it reels in (it uses the game's interact action, so turn on Enable Interact Key in %s). Quick recast pulls the bobber in and casts again at once, without a lure. Apply lure and Toggle window can be bound there too."], INTERACT_PATH), ns.CONTENT_WIDTH - 4)
    note:SetPoint("TOPLEFT", lure, "BOTTOMLEFT", 0, -2)
    local pad = W.Dropdown(panel, L["Controller button"], 130, PAD_BUTTONS,
        function() return s.controllerButton end,
        function(v) s.controllerButton = v; UpdatePad() end)
    pad:SetPoint("TOPLEFT", note, "BOTTOMLEFT", W.Room(120, pad), -10)
    local padNote = W.Note(panel, L["The Fish key on a controller, while a fishing pole is equipped. Without a pole the button does what it normally does."], ns.CONTENT_WIDTH - 4)
    padNote:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -38)
    return { Refresh = function() lure.Refresh(); pad.Refresh() end }
end
