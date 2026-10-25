-- Immersion page: hides the game's own clutter while you fish and makes the
-- idle time look good. Clean View (CleanView.lua) fades the interface; this
-- covers what isn't interface: floating names, loot windows, combat text,
-- the bobber tooltip, graphics quality and the camera.
--
-- CVar-based options go through the fishing-mode override system in Core.lua
-- (on at the first cast, player's values back restoreDelay seconds after the
-- last bobber). The rest hook REEL_FISHING_BEGIN / REEL_FISHING_END.
-- The letterbox toggle is here too, but the bars belong to Clean View
-- (CleanView.lua) and only show while it is active.
--
-- CVar names and ranges were checked against Blizzard's Forever settings code
-- (Blizzard_SettingsDefinitions_Shared: Nameplates.lua, Graphics.lua,
-- Controls.lua). Camera views are the Key Bindings "Save View N" slots.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    hideNames = false,       -- floating names and nameplates off
    fishingAutoLoot = false, -- auto-loot on, so the loot window never opens
    hideCombatText = false,  -- damage numbers and the red error text off
    hideBobberTip = false,   -- no tooltip when the mouse crosses the bobber
    maxGraphics = false,     -- graphics quality up while fishing
    cameraView = false,      -- switch to a saved camera view while fishing
})

-- Floating names (UnitName*) and nameplates (nameplateShow*), all set to 0.
local NAME_CVARS = {
    "UnitNameOwn", "UnitNameNPC", "UnitNameInteractiveNPC", "UnitNameHostleNPC",
    "UnitNameFriendlySpecialNPCName", "UnitNameNonCombatCreatureName",
    "UnitNameFriendlyPlayerName", "UnitNameFriendlyMinionName",
    "UnitNameFriendlyPetName", "UnitNameFriendlyGuardianName", "UnitNameFriendlyTotemName",
    "UnitNameEnemyPlayerName", "UnitNameEnemyMinionName",
    "UnitNameEnemyPetName", "UnitNameEnemyGuardianName", "UnitNameEnemyTotemName",
    "UnitNamePlayerGuild",
    "nameplateShowAll", "nameplateShowSelf", "nameplateShowEnemies",
    "nameplateShowFriendlyPlayers", "nameplateShowFriendlyNpcs",
}

-- Graphics CVars with the top of their slider in Blizzard's Graphics panel.
-- The highest value this machine supports is used, so a weaker PC gets what
-- it can run rather than an error.
local GRAPHICS_CVARS = {
    { cvar = "graphicsLiquidDetail", max = 3 },
    { cvar = "graphicsPBRLiquidDetail", max = 2 },
    { cvar = "graphicsViewDistance", max = 9 },
    { cvar = "graphicsEnvironmentDetail", max = 9 },
    { cvar = "graphicsGroundClutter", max = 9 },
    { cvar = "graphicsShadowQuality", max = 5 },
    { cvar = "graphicsParticleDensity", max = 5 },
    { cvar = "graphicsSSAO", max = 4 },
    { cvar = "graphicsDepthEffects", max = 3 },
}

-- Camera view slots (Key Bindings > Camera > Save View / Set View). Views 2-5
-- are the player's; Reel uses the last two.
local FISHING_VIEW = 5 -- where the fishing camera is saved
local RETURN_VIEW = 4  -- where the camera you had before is kept

local function Supported(cvar, value)
    if not IsGraphicsSettingValueSupported then return true end
    return IsGraphicsSettingValueSupported(cvar, value, false) == nil
end

local function BestGraphicsValue(entry)
    for value = entry.max, 0, -1 do
        if Supported(entry.cvar, value) then return tostring(value) end
    end
end

ns.RegisterCVars(function(s, targets)
    if s.hideNames then
        for _, cvar in ipairs(NAME_CVARS) do targets[cvar] = "0" end
    end
    if s.fishingAutoLoot then
        targets.autoLootDefault = "1"
    end
    if s.hideCombatText then
        targets.enableFloatingCombatText = "0"
    end
    if s.maxGraphics then
        for _, entry in ipairs(GRAPHICS_CVARS) do
            local value = BestGraphicsValue(entry)
            if value then targets[entry.cvar] = value end
        end
    end
end)

-- Error text, bobber tooltip, camera -----------------------------------------

local errorsHidden = false
local cameraMoved = false

local function HideErrors(hide)
    if not UIErrorsFrame or hide == errorsHidden then return end
    errorsHidden = hide
    UIErrorsFrame:SetShown(not hide)
end

local function MoveCamera(fishing)
    if not (SaveView and SetView) or fishing == cameraMoved then return end
    cameraMoved = fishing
    if fishing then
        SaveView(RETURN_VIEW)
        SetView(FISHING_VIEW)
    else
        SetView(RETURN_VIEW)
    end
end

-- On every cast, not just the first: combat puts the camera and the error
-- text back, and the next cast should take them again.
ns.On("REEL_CAST", function()
    local s = ReelDB.settings
    if s.hideCombatText then HideErrors(true) end
    if s.cameraView then MoveCamera(true) end
end)

ns.On("REEL_FISHING_END", function()
    HideErrors(false)
    MoveCamera(false)
end)

-- Combat brings the error text back right away ("Spell is not ready yet"
-- matters when a crocolisk shows up) and leaves the camera where you had it.
ns.On("PLAYER_REGEN_DISABLED", function()
    HideErrors(false)
    MoveCamera(false)
end)

ns.On("REEL_READY", function()
    -- Object tooltips (the bobber is a game object) are dropped while a
    -- bobber is out. Other objects' tooltips come back between casts.
    if TooltipDataProcessor and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Object then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, function(tooltip)
            if tooltip == GameTooltip and ReelDB.settings.hideBobberTip and ns.Channeling() then
                tooltip:Hide()
            end
        end)
    end
end)

-- Page -----------------------------------------------------------------------

ns.RegisterPage({
    name = "Immersion",
    order = 65,
    build = function(panel)
        local s = ReelDB.settings
        local controls = {}

        local function Refresh()
            for _, c in ipairs(controls) do c.Refresh() end
        end

        local function Changed()
            ns.ApplySettings()
            if ns.IsFishing() then
                HideErrors(s.hideCombatText)
                MoveCamera(s.cameraView)
            end
            ns.UpdateLetterbox()
            Refresh()
        end

        local anchor
        local function Header(text, offset)
            local h = W.Label(panel, text, "GameFontNormal")
            if anchor then
                h:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, offset)
            else
                h:SetPoint("TOPLEFT")
            end
            anchor = h
        end
        local function Box(label, key, note)
            local cb = W.Checkbox(panel, label,
                function() return s[key] end,
                function(v) s[key] = v; Changed() end)
            cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
            anchor = cb
            controls[#controls + 1] = cb
            if note then
                local n = W.Note(panel, note, ns.CONTENT_WIDTH - 30)
                n:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 26, 2)
                local spacer = CreateFrame("Frame", nil, panel)
                spacer:SetSize(1, 1)
                spacer:SetPoint("TOPLEFT", n, "BOTTOMLEFT", -26, -2)
                anchor = spacer
            end
            return cb
        end

        Header("Hide while fishing")
        Box("Floating names and nameplates", "hideNames")
        Box("Auto-loot while fishing", "fishingAutoLoot",
            "Catches go straight to your bags and show on the bar.")
        Box("Combat text and error messages", "hideCombatText",
            "Damage numbers and the red \"You can't do that yet\" text. Error text comes back if you enter combat.")
        Box("Bobber tooltip", "hideBobberTip")

        Header("Look", -12)
        Box("Max graphics quality", "maxGraphics",
            "Water, view distance, ground detail, shadows, particles and lighting go to the highest setting this PC supports, then back to your own.")
        Box("Fishing camera", "cameraView",
            string.format("Switches to camera view %d at your first cast and back when you're done. Set up the view once with the button below; it uses Key Bindings > Camera > Save View %d, and view %d holds the camera you had before.", FISHING_VIEW, FISHING_VIEW, RETURN_VIEW))

        local save = W.Button(panel, "Save current camera as fishing view", 260, function()
            if SaveView then
                SaveView(FISHING_VIEW)
                ns.Print(string.format("Camera saved as view %d.", FISHING_VIEW))
            else
                ns.Print("This client has no camera views.")
            end
        end)
        save:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 30, -6)
        local spacer = CreateFrame("Frame", nil, panel)
        spacer:SetSize(1, 1)
        spacer:SetPoint("TOPLEFT", save, "BOTTOMLEFT", -30, -4)
        anchor = spacer

        Box("Letterbox bars in Clean View", "letterbox",
            "Cinematic black strips top and bottom while the interface is faded.")
        local height = W.Slider(panel, "Bar height", 5, 20, 1, "%",
            function() return s.letterboxHeight end,
            function(v) s.letterboxHeight = v; ns.UpdateLetterbox() end)
        height:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 100, -10)
        controls[#controls + 1] = height

        return Refresh
    end,
})
