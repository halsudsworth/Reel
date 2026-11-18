-- General page: settings shared by every feature, the minimap button and catch data reset.
-- The presets and the About line are defined here and shown on the landing page in Options.

local _, ns = ...
local L = ns.L
local W = ns.W

-- Presets: one click sets the Clean View and Immersion toggles. Settings not
-- listed here are left alone (sound, bar items, lure choice...). The fishing
-- camera is never turned on by a preset because it needs a saved view first.
local PRESETS = {
    { name = L["Just the bar"], note = L["Nothing hidden. The bar, the lure button and the journal."],
      set = { cleanView = false, hideNames = false, fishingAutoLoot = false, hideCombatText = false,
              hideBobberTip = false, maxGraphics = false, cameraView = false, letterbox = false } },
    { name = L["Clean"], note = L["The interface fades while you fish; the bar and loot window stay."],
      set = { cleanView = true, keepBar = true, keepLoot = true, hideNames = false, fishingAutoLoot = false,
              hideCombatText = false, hideBobberTip = false, maxGraphics = false, cameraView = false, letterbox = false } },
    { name = L["Full immersion"], note = L["Everything fades, names and text go, auto-loot, max graphics, letterbox."],
      set = { cleanView = true, keepBar = true, keepLoot = false, hideNames = true, fishingAutoLoot = true,
              hideCombatText = true, hideBobberTip = true, maxGraphics = true, cameraView = false, letterbox = true } },
}

local function ApplyPreset(preset)
    local s = ReelDB.settings
    for key, value in pairs(preset.set) do s[key] = value end
    if not s.cleanView then ns.ExitCleanView() end
    ns.RefreshKeep() -- keepBar/keepLoot may have changed while Clean View is active
    ns.ApplySettings()
    ns.RefreshImmersion()
    ns.UpdateLetterbox()
    ns.Print(string.format(L["Preset: %s"], preset.name))
end

-- For the landing page in Options, which holds the preset buttons.
ns.PRESETS = PRESETS
ns.ApplyPreset = ApplyPreset
ns.PRESET_NOTE = L["A preset only changes the Clean View and Immersion toggles. Sound, bar and lure settings stay as they are."]

-- The About line, also on the landing page.
function ns.AboutLine()
    local getMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
    local version = getMeta and getMeta("Reel", "Version") or "?"
    return string.format(L["R.E.E.L. %s by Hal Sudsworth. Source and bug reports: github.com/halsudsworth/Reel. For a bug, type /reel debug, then /reload, and paste the debug block from WTF\\Account\\<account>\\SavedVariables\\Reel.lua into the issue."], version)
end

StaticPopupDialogs.REEL_RESET = {
    text = L["Clear R.E.E.L.'s catch data for every character on this account? Journals, records, derby coins and Riggle's winners all go. This can't be undone."],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        ns.ResetData()
        ns.Print(L["All catch data cleared."])
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

        -- (Presets and About are on R.E.E.L.'s landing page in Options: Options.lua.)
        local delay = W.Slider(panel, L["Done fishing after"], 5, 60, 5, "s",
            function() return s.restoreDelay end,
            function(v) s.restoreDelay = v end)
        -- The slider's label sits to its left; leave room for all of it.
        local labelRoom = math.ceil(delay.label:GetStringWidth()) + 8
        delay:SetPoint("TOPLEFT", panel, "TOPLEFT", labelRoom, -8)

        local note = W.Note(panel, L["How long after your last bobber is gone before R.E.E.L. counts you as done fishing. Your sound settings go back, the bar hides, and clean view can end."], ns.CONTENT_WIDTH - 4)
        note:SetPoint("TOPLEFT", delay, "BOTTOMLEFT", -labelRoom, -24)

        local size = W.Slider(panel, L["Window size"], 70, 150, 5, "%",
            function() return s.windowScale end,
            function(v) ns.SetWindowScale(v) end)
        size:SetPoint("TOPLEFT", note, "BOTTOMLEFT", W.Room(labelRoom, size), -18)

        local minimap = W.Checkbox(panel, L["Show minimap button"],
            function() return s.minimapButton end,
            function(v) s.minimapButton = v; ns.UpdateMinimapButton() end)
        minimap:SetPoint("TOPLEFT", note, "BOTTOMLEFT", 0, -56)

        local cooking = W.Checkbox(panel, L["Show cooking recipes on fish tooltips"],
            function() return s.cookingTips end,
            function(v) s.cookingTips = v end)
        cooking:SetPoint("TOPLEFT", minimap, "BOTTOMLEFT", 0, -4)

        local worldPins = W.Checkbox(panel, L["Show fishing trainers and vendors on the world map"],
            function() return s.mapPinsWorld end,
            function(v) s.mapPinsWorld = v; ns.RefreshMapPins() end)
        worldPins:SetPoint("TOPLEFT", cooking, "BOTTOMLEFT", 0, -4)

        local miniPins = W.Checkbox(panel, L["Show fishing trainers and vendors on the minimap"],
            function() return s.mapPinsMinimap end,
            function(v) s.mapPinsMinimap = v; ns.RefreshMapPins() end)
        miniPins:SetPoint("TOPLEFT", worldPins, "BOTTOMLEFT", 0, -4)

        local reset = W.Button(panel, L["Reset catch data..."], 150, ns.ConfirmReset)
        reset:SetPoint("TOPLEFT", miniPins, "BOTTOMLEFT", 4, -16)

        return function()
            delay.Refresh()
            size.Refresh()
            minimap.Refresh()
            cooking.Refresh()
            worldPins.Refresh()
            miniPins.Refresh()
        end
    end,
})
