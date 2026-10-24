-- General page: settings shared by every feature, plus the minimap button and
-- catch data reset.

local _, ns = ...
local W = ns.W

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

        local delay = W.Slider(panel, "Done fishing after", 5, 60, 5, "s",
            function() return s.restoreDelay end,
            function(v) s.restoreDelay = v end)
        delay:SetPoint("TOPLEFT", 90, -8)

        local note = W.Note(panel, "How long after your last bobber is gone before R.E.E.L. counts you as done fishing. Your sound settings go back, the bar hides, and clean view can end.", ns.CONTENT_WIDTH - 4)
        note:SetPoint("TOPLEFT", 0, -32)

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
