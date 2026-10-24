-- Fishing bar: a small movable strip of live info, shown while fishing or
-- while any segment has something running (a lure, a camp timer).
--
-- Features add segments with ns.RegisterBarSegment({
--     key   = "lure",           saved on/off setting
--     label = "Lure timer",     checkbox text on the Bar page
--     order = 20,               position on the bar
--     text  = function(settings)
--         return text, active   -- text: a string, a list of strings (one bar
--     end,                      -- item each), or nil to hide; active true
--                               -- keeps the bar visible even when not fishing
--     options = {               optional sub-checkboxes under it on the Bar
--         { key = "settingKey", label = "..." },   page (boolean settings the
--     },                                           feature registers itself)
-- })
--
-- The bar can hold a secure button (the lure button), so its size and
-- visibility only change out of combat.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    bar = true,
    barLocked = false,
    barLayout = "horizontal", -- or "vertical": one item per line
    barPoint = nil,  -- { point, relativePoint, x, y }
    barHidden = {},  -- segment key -> true when turned off
})

local BUTTON_MIN, BUTTON_MAX, BUTTON_PAD = 30, 40, 3

local segments = {}
local bar, text

function ns.RegisterBarSegment(segment)
    segments[#segments + 1] = segment
    table.sort(segments, function(a, b) return a.order < b.order end)
end

local function SavePosition()
    local point, _, relativePoint, x, y = bar:GetPoint()
    ReelDB.settings.barPoint = { point, relativePoint, x, y }
end

local function Restore()
    local p = ReelDB.settings.barPoint
    bar:ClearAllPoints()
    if p then
        bar:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        bar:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
end

function ns.UpdateBar()
    if not bar then return end
    local s = ReelDB.settings
    local parts, active = {}, false
    for _, seg in ipairs(segments) do
        if not s.barHidden[seg.key] then
            local segText, segActive = seg.text(s)
            if type(segText) == "table" then
                for _, t in ipairs(segText) do parts[#parts + 1] = t end
            elseif segText then
                parts[#parts + 1] = segText
            end
            if segActive then active = true end
        end
    end
    local vertical = s.barLayout == "vertical"
    text:SetText(table.concat(parts, vertical and "\n" or "  |cff666666|||r  "))

    if InCombatLockdown() then return end
    -- The button counts as content, so it stays usable with every item hidden.
    local hasButton = bar.button and bar.button:IsShown()
    if hasButton and ns.PoleEquipped() then active = true end
    local shown = s.bar and (#parts > 0 or hasButton)
        and (active or ns.RecentlyFishing() or not s.barLocked and ns.WindowShown())
    bar:SetShown(shown)
    local height = math.max(BUTTON_MIN + 2 * BUTTON_PAD, text:GetStringHeight() + 16)
    bar:SetHeight(height)
    local left = 8
    if bar.button and bar.button:IsShown() then
        -- The button fills the bar's height, up to BUTTON_MAX in tall layouts.
        local size = math.min(BUTTON_MAX, height - 2 * BUTTON_PAD)
        bar.button:SetSize(size, size)
        left = BUTTON_PAD + size + 8
    end
    text:ClearAllPoints()
    text:SetPoint("LEFT", left, 0)
    bar:SetWidth(left + text:GetStringWidth() + 10)
    bar:EnableMouse(not s.barLocked)
end

-- Lets a feature put a square button at the left end of the bar.
function ns.SetBarButton(button)
    button:SetParent(bar)
    button:SetSize(BUTTON_MIN, BUTTON_MIN)
    button:ClearAllPoints()
    button:SetPoint("LEFT", BUTTON_PAD, 0)
    bar.button = button
end

ns.On("REEL_READY", function()
    local s = ReelDB.settings
    if s.campTimer ~= nil then -- replaced by barHidden.camp in 0.6.0
        if s.campTimer == false then s.barHidden.camp = true end
        s.campTimer = nil
    end

    bar = CreateFrame("Frame", "ReelBar", UIParent)
    bar:SetHeight(30)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function()
        bar:StopMovingOrSizing()
        SavePosition()
    end)
    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0.6)
    bg:SetAllPoints()
    text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    Restore()
    bar:Hide()
    ns.bar = bar
    C_Timer.NewTicker(1, ns.UpdateBar)
end)

ns.On("PLAYER_REGEN_ENABLED", function() ns.UpdateBar() end)

ns.RegisterPage({
    name = "Bar",
    order = 90,
    build = function(panel)
        local s = ReelDB.settings
        local controls = {}

        local shown = W.Checkbox(panel, "Show fishing bar",
            function() return s.bar end,
            function(v) s.bar = v; ns.UpdateBar() end)
        shown:SetPoint("TOPLEFT")

        local locked = W.Checkbox(panel, "Lock bar position",
            function() return s.barLocked end,
            function(v) s.barLocked = v; ns.UpdateBar() end)
        locked:SetPoint("TOPLEFT", shown, "BOTTOMLEFT", 0, -4)

        local note = W.Note(panel, "While unlocked, the bar stays visible with this window open so you can drag it into place.", ns.CONTENT_WIDTH - 30)
        note:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 26, 0)

        local layout = W.Dropdown(panel, "Layout", 120, {
            { value = "horizontal", text = "Horizontal" },
            { value = "vertical", text = "Vertical" },
        }, function() return s.barLayout end,
           function(v) s.barLayout = v; ns.UpdateBar() end)
        layout:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 60, -40)

        local header = W.Label(panel, "Show on bar", "GameFontNormal")
        header:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 0, -76)

        controls[1], controls[2], controls[3] = shown, locked, layout
        local subOptions = {} -- { checkbox, segment key }
        local Refresh

        -- Each row anchors to the previous one; sub-options are indented.
        local anchor, indent = header, 0
        local function Row(cb, x, first)
            cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x - indent, first and -6 or -2)
            anchor, indent = cb, x
            controls[#controls + 1] = cb
        end

        local lureButton = W.Checkbox(panel, "Apply-lure button",
            function() return s.lureButton end,
            function(v) s.lureButton = v; ns.UpdateLureButton(); ns.UpdateBar(); Refresh() end)
        Row(lureButton, 0, true)
        local lureChoice = W.Dropdown(panel, "Use", 190, ns.LureOptions(),
            function() return s.lureChoice end,
            function(v) s.lureChoice = v; ns.UpdateLureButton(); ns.UpdateBar() end)
        Row(lureChoice, 60)
        local lureNote = W.Note(panel, "A picked lure falls back to your best one when you run out.", ns.CONTENT_WIDTH - 260)
        lureNote:SetPoint("LEFT", lureChoice, "RIGHT", 10, 0)

        for _, seg in ipairs(segments) do
            local cb = W.Checkbox(panel, seg.label,
                function() return not s.barHidden[seg.key] end,
                function(v) s.barHidden[seg.key] = (not v) or nil; ns.UpdateBar(); Refresh() end)
            Row(cb, 0)
            for _, option in ipairs(seg.options or {}) do
                local sub = W.Checkbox(panel, option.label,
                    function() return s[option.key] end,
                    function(v) s[option.key] = v; ns.UpdateBar() end)
                Row(sub, 24)
                subOptions[#subOptions + 1] = { sub, seg.key }
            end
        end

        Refresh = function()
            for _, c in ipairs(controls) do c.Refresh() end
            lureChoice:SetActive(s.lureButton)
            for _, entry in ipairs(subOptions) do
                entry[1]:SetActive(not s.barHidden[entry[2]])
            end
        end
        return Refresh
    end,
})
