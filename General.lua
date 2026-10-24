-- General page: presets, settings shared by every feature, the minimap button
-- and catch data reset.

local _, ns = ...
local W = ns.W

-- Presets: one click sets the Clean View and Immersion toggles. Settings not
-- listed here are left alone (sound, bar items, lure choice...). The fishing
-- camera is never turned on by a preset because it needs a saved view first.
local PRESETS = {
    { name = "Just the bar", note = "Nothing hidden. The bar, the lure button and the journal.",
      set = { cleanView = false, hideNames = false, fishingAutoLoot = false, hideCombatText = false,
              hideBobberTip = false, maxGraphics = false, cameraView = false, letterbox = false } },
    { name = "Clean", note = "The interface fades while you fish; the bar and loot window stay.",
      set = { cleanView = true, keepBar = true, keepLoot = true, hideNames = false, fishingAutoLoot = false,
              hideCombatText = false, hideBobberTip = false, maxGraphics = false, cameraView = false, letterbox = false } },
    { name = "Full immersion", note = "Everything fades, names and text go, auto-loot, max graphics, letterbox.",
      set = { cleanView = true, keepBar = true, keepLoot = false, hideNames = true, fishingAutoLoot = true,
              hideCombatText = true, hideBobberTip = true, maxGraphics = true, cameraView = false, letterbox = true } },
}

local function ApplyPreset(preset)
    local s = ReelDB.settings
    for key, value in pairs(preset.set) do s[key] = value end
    if not s.cleanView then ns.ExitCleanView() end
    ns.ApplySettings()
    ns.UpdateLetterbox()
    ns.Print("Preset: " .. preset.name)
end

StaticPopupDialogs.REEL_RESET = {
    text = "Clear all R.E.E.L. catch data? This can't be undone.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns.ResetData()
        ns.Print("All catch data cleared.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function ns.ConfirmReset()
    StaticPopup_Show("REEL_RESET")
end

ns.RegisterPage({
    name = "General",
    order = 100,
    build = function(panel)
        local s = ReelDB.settings

        local header = W.Label(panel, "Presets", "GameFontNormal")
        header:SetPoint("TOPLEFT")
        local anchor = header
        for i, preset in ipairs(PRESETS) do
            local b = W.Button(panel, preset.name, 120, function() ApplyPreset(preset) end)
            b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", i == 1 and 4 or 0, i == 1 and -6 or -4)
            local n = W.Note(panel, preset.note, ns.CONTENT_WIDTH - 140)
            n:SetPoint("LEFT", b, "RIGHT", 10, 0)
            anchor = b
        end
        local presetNote = W.Note(panel, "A preset only changes the Clean View and Immersion toggles. Sound, bar and lure settings stay as they are.", ns.CONTENT_WIDTH - 4)
        presetNote:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -4, -8)

        local delay = W.Slider(panel, "Done fishing after", 5, 60, 5, "s",
            function() return s.restoreDelay end,
            function(v) s.restoreDelay = v end)
        delay:SetPoint("TOPLEFT", presetNote, "BOTTOMLEFT", 90, -24)

        local note = W.Note(panel, "How long after your last bobber is gone before R.E.E.L. counts you as done fishing. Your sound settings go back, the bar hides, and clean view can end.", ns.CONTENT_WIDTH - 4)
        note:SetPoint("TOPLEFT", delay, "BOTTOMLEFT", -90, -24)

        local minimap = W.Checkbox(panel, "Show minimap button",
            function() return s.minimapButton end,
            function(v) s.minimapButton = v; ns.UpdateMinimapButton() end)
        minimap:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -16)

        local cooking = W.Checkbox(panel, "Show cooking recipes on fish tooltips",
            function() return s.cookingTips end,
            function(v) s.cookingTips = v end)
        cooking:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 0, -4)

        local reset = W.Button(panel, "Reset catch data...", 150, ns.ConfirmReset)
        reset:SetPoint("TOPLEFT", cooking, "BOTTOMLEFT", 4, -16)

        return function()
            delay.Refresh()
            minimap.Refresh()
            cooking.Refresh()
        end
    end,
})
