-- Clean view: fades out the whole interface while you fish, so you just see
-- the world. These always bring it back, whatever the settings: entering
-- combat (instantly), pressing Escape, typing /reel, and logging in.
--
-- It changes UIParent's alpha rather than hiding it, because alpha changes
-- aren't blocked in combat. Frames chosen under "Keep visible" are set to
-- ignore the parent's alpha. While faded, invisible action buttons can still
-- be clicked. Optional letterbox bars (black strips top and bottom) sit
-- behind everything else and follow the fade.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    cleanView = false,
    cleanStart = "cast",   -- "cast" (first cast) or "pole" (equipping the pole)
    cleanFade = 1,         -- seconds
    cleanExitPole = true,
    cleanExitIdle = false, -- restoreDelay seconds after the last bobber is gone
    cleanExitMove = false,
    keepBar = true,
    keepLoot = true,
    keepChat = false,
    keepMinimap = false,
    cleanWhisper = true,   -- show chat for a few seconds on a whisper
    cleanExitButton = true,
    cleanExitPoint = nil,  -- { point, relativePoint, x, y }
    letterbox = false,
    letterboxHeight = 10,  -- percent of the screen, each bar
})

local WHISPER_SECONDS = 5

local active = false
local target = 1
local flashUntil = 0
local original = {} -- frame -> its own IgnoreParentAlpha value before we touched it
local driver = CreateFrame("Frame")
local exitButton
local letterbox -- frame holding the two bars
local previewing = false -- the Clean View page is open, so the button can be placed

local function UpdateLetterbox()
    if not letterbox then return end
    local s = ReelDB.settings
    letterbox:SetShown(s.letterbox and active)
    local height = UIParent:GetHeight() * s.letterboxHeight / 100
    letterbox.top:SetHeight(height)
    letterbox.bottom:SetHeight(height)
end

ns.UpdateLetterbox = UpdateLetterbox -- the toggle lives on the Immersion page

local function BuildLetterbox()
    letterbox = CreateFrame("Frame", "ReelLetterbox", UIParent)
    letterbox:SetAllPoints()
    letterbox:SetFrameStrata("BACKGROUND")
    letterbox:SetIgnoreParentAlpha(true)
    letterbox.top = letterbox:CreateTexture(nil, "BACKGROUND")
    letterbox.top:SetColorTexture(0, 0, 0, 1)
    letterbox.top:SetPoint("TOPLEFT")
    letterbox.top:SetPoint("TOPRIGHT")
    letterbox.bottom = letterbox:CreateTexture(nil, "BACKGROUND")
    letterbox.bottom:SetColorTexture(0, 0, 0, 1)
    letterbox.bottom:SetPoint("BOTTOMLEFT")
    letterbox.bottom:SetPoint("BOTTOMRIGHT")
    letterbox:Hide()
end

local function UpdateExitButton()
    if not exitButton then return end
    exitButton:SetShown(ReelDB.settings.cleanExitButton and (active or previewing))
end

local function ChatFrames(list)
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        list[#list + 1] = _G["ChatFrame" .. i]
        list[#list + 1] = _G["ChatFrame" .. i .. "Tab"]
    end
    list[#list + 1] = GeneralDockManager
    list[#list + 1] = ChatFrame1EditBox
end

local function KeptFrames()
    local s = ReelDB.settings
    local list = { ReelFrame } -- the Reel window always stays usable
    if s.keepBar then list[#list + 1] = ns.bar end
    if s.keepLoot then list[#list + 1] = LootFrame end
    if s.keepChat or GetTime() < flashUntil then ChatFrames(list) end
    if s.keepMinimap then list[#list + 1] = MinimapCluster or Minimap end
    return list
end

local function SetIgnore(frame, ignore)
    if not frame or not frame.SetIgnoreParentAlpha then return end
    if original[frame] == nil then
        -- This client names the getter IsIgnoringParentAlpha.
        original[frame] = frame.IsIgnoringParentAlpha and frame:IsIgnoringParentAlpha() or false
    end
    frame:SetIgnoreParentAlpha(ignore or original[frame])
end

-- Kept frames ignore the fade; everything touched before goes back to normal.
local function ApplyKeep()
    local keep = {}
    for _, frame in ipairs(KeptFrames()) do keep[frame] = true end
    for frame in pairs(original) do SetIgnore(frame, keep[frame]) end
    for frame in pairs(keep) do SetIgnore(frame, true) end
end

local function RestoreKeep()
    for frame, value in pairs(original) do
        frame:SetIgnoreParentAlpha(value)
    end
    wipe(original)
end

local function FadeTo(alpha, instant)
    target = alpha
    local seconds = ReelDB.settings.cleanFade
    if instant or seconds <= 0 then
        driver:SetScript("OnUpdate", nil)
        UIParent:SetAlpha(alpha)
        if alpha == 1 then RestoreKeep() end
        return
    end
    driver:SetScript("OnUpdate", function(_, elapsed)
        local a = UIParent:GetAlpha()
        local step = elapsed / seconds
        a = a < target and math.min(target, a + step) or math.max(target, a - step)
        UIParent:SetAlpha(a)
        if a == target then
            driver:SetScript("OnUpdate", nil)
            if target == 1 then RestoreKeep() end
        end
    end)
end

local function Enter()
    if active or not ReelDB.settings.cleanView then return end
    active = true
    ApplyKeep()
    FadeTo(0)
    UpdateExitButton()
    UpdateLetterbox()
end

local function Exit(instant)
    if not active then return end
    active = false
    FadeTo(1, instant)
    UpdateExitButton()
    UpdateLetterbox()
end

-- Exit button: a small "Show UI" button that stays visible while faded.
-- Drag to move; a drag never counts as a click.
local function BuildExitButton()
    local s = ReelDB.settings
    local b = CreateFrame("Button", "ReelCleanExitButton", UIParent, "UIPanelButtonTemplate")
    b:SetSize(90, 22)
    b:SetText("Show UI")
    b:SetFrameStrata("HIGH")
    b:SetIgnoreParentAlpha(true)
    b:SetMovable(true)
    b:SetClampedToScreen(true)
    b:RegisterForDrag("LeftButton")
    local p = s.cleanExitPoint
    if p then
        b:SetPoint(p[1], UIParent, p[2], p[3], p[4])
    else
        b:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end
    b:SetScript("OnDragStart", function(self)
        self.dragging = true
        self:StartMoving()
    end)
    b:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        s.cleanExitPoint = { point, relativePoint, x, y }
        C_Timer.After(0, function() self.dragging = false end)
    end)
    b:SetScript("OnClick", function(self)
        if not self.dragging then Exit() end
    end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Leave clean view")
        GameTooltip:AddLine("Drag to move.", 1, 1, 1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    b:Hide()
    exitButton = b
end

function ReelToggleCleanView()
    if active then
        Exit()
    else
        active = false
        if not ReelDB.settings.cleanView then
            ns.Print("Turn on clean view on the Clean View page first.")
            return
        end
        Enter()
    end
end

BINDING_HEADER_REEL = "R.E.E.L."
BINDING_NAME_REEL_TOGGLE_CLEAN_VIEW = "Toggle clean view"

-- Enter ----------------------------------------------------------------------

ns.On("REEL_CAST", function()
    if not InCombatLockdown() then Enter() end
end)

ns.On("PLAYER_EQUIPMENT_CHANGED", function()
    local s = ReelDB.settings
    if ns.PoleEquipped() then
        if s.cleanStart == "pole" and not InCombatLockdown() then Enter() end
    elseif s.cleanExitPole then
        Exit()
    end
end)

-- Exit -----------------------------------------------------------------------

-- Returns true if clean view was on (so /reel can just bring the UI back).
function ns.ExitCleanView()
    if not active then return false end
    Exit(true)
    return true
end

ns.On("PLAYER_REGEN_DISABLED", function() Exit(true) end)

ns.On("PLAYER_STARTED_MOVING", function()
    if ReelDB.settings.cleanExitMove then Exit() end
end)

ns.On("REEL_READY", function()
    UIParent:SetAlpha(1) -- never start a session faded
    BuildExitButton()
    BuildLetterbox()

    -- Escape opens the game menu when nothing else is open.
    if GameMenuFrame then
        GameMenuFrame:HookScript("OnShow", function() ns.ExitCleanView() end)
    end

    C_Timer.NewTicker(1, function()
        if active and ReelDB.settings.cleanExitIdle and not ns.RecentlyFishing() then
            Exit()
        end
    end)
end)

-- Whispers --------------------------------------------------------------------

local function OnWhisper()
    local s = ReelDB.settings
    if not active or s.keepChat or not s.cleanWhisper then return end
    flashUntil = GetTime() + WHISPER_SECONDS
    ApplyKeep()
    C_Timer.After(WHISPER_SECONDS, function()
        if active and GetTime() >= flashUntil then ApplyKeep() end
    end)
end
ns.On("CHAT_MSG_WHISPER", OnWhisper)
ns.On("CHAT_MSG_BN_WHISPER", OnWhisper)

-- Page -----------------------------------------------------------------------

ns.RegisterPage({
    name = "Clean View",
    order = 60,
    build = function(panel)
        local s = ReelDB.settings
        local controls, dependent = {}, {}

        local function Refresh()
            for _, c in ipairs(controls) do c.Refresh() end
            for _, c in ipairs(dependent) do c:SetActive(s.cleanView) end
        end

        local function Changed()
            if active then ApplyKeep() end
            UpdateExitButton()
            UpdateLetterbox()
            Refresh()
        end

        -- Show the exit button while this page is open so it can be placed.
        panel:HookScript("OnShow", function()
            previewing = s.cleanView
            UpdateExitButton()
        end)
        panel:HookScript("OnHide", function()
            previewing = false
            UpdateExitButton()
        end)

        local enable = W.Checkbox(panel, "Enable clean view",
            function() return s.cleanView end,
            function(v)
                s.cleanView = v
                if not v then Exit() end
                previewing = v and panel:IsVisible()
                UpdateExitButton()
                Refresh()
            end)
        enable:SetPoint("TOPLEFT")
        controls[#controls + 1] = enable

        local note = W.Note(panel, "Fades out your interface while you fish. Entering combat always brings it back instantly.", ns.CONTENT_WIDTH - 30)
        note:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 26, 0)

        local start = W.Dropdown(panel, "Start on", 150, {
            { value = "cast", text = "My first cast" },
            { value = "pole", text = "Equipping my pole" },
        }, function() return s.cleanStart end, function(v) s.cleanStart = v end)
        start:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 70, -34)

        local fade = W.Slider(panel, "Fade time", 0, 3, 0.5, "s",
            function() return s.cleanFade end,
            function(v) s.cleanFade = v end)
        fade:SetPoint("TOPLEFT", start, "BOTTOMLEFT", 0, -14)
        controls[#controls + 1] = start
        controls[#controls + 1] = fade
        dependent[#dependent + 1] = start
        dependent[#dependent + 1] = fade

        local anchor
        local function Header(text, offset)
            local h = W.Label(panel, text, "GameFontNormal")
            h:SetPoint("TOPLEFT", anchor or enable, "BOTTOMLEFT", 0, offset)
            anchor = h
        end
        local function Box(label, key)
            local cb = W.Checkbox(panel, label,
                function() return s[key] end,
                function(v) s[key] = v; Changed() end)
            cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -1)
            anchor = cb
            controls[#controls + 1] = cb
            dependent[#dependent + 1] = cb
        end

        anchor = enable
        Header("Bring my UI back when", -100)
        local combat = W.Label(panel, "I enter combat (always on)", "GameFontDisable")
        combat:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 30, -6)
        local spacer = CreateFrame("Frame", nil, panel)
        spacer:SetSize(1, 1)
        spacer:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -16)
        anchor = spacer
        Box("I unequip my pole", "cleanExitPole")
        Box("I stop fishing for a bit (General > Done fishing after)", "cleanExitIdle")
        Box("I start moving", "cleanExitMove")

        local keyNote = W.Note(panel, "The button shows while this page is open so you can drag it into place. Escape and /reel always bring the UI back. Key Bindings > Reel > Toggle clean view also works.", ns.CONTENT_WIDTH - 4)
        keyNote:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
        anchor = keyNote

        Header("Keep visible in clean view", -10)
        Box("R.E.E.L. bar", "keepBar")
        Box("Loot window", "keepLoot")
        Box("Chat", "keepChat")
        Box("Minimap", "keepMinimap")
        Box("Show UI button", "cleanExitButton")
        Box("Show chat for 5s when someone whispers me", "cleanWhisper")

        return Refresh
    end,
})
