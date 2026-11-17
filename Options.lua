-- R.E.E.L.'s settings in the game's Options > AddOns (Settings canvas categories): R.E.E.L. with
-- one page per settings page, alphabetically: Bar, Casting (with One key), Clean View, General,
-- Immersion, Sound. Each page is one column at the canvas width, scrolling as a whole when it's
-- long, built the first time it's shown. Inside Blizzard's frame the page keeps only Hal's type
-- and amber.
--
--   ns.OpenOptions([name])   opens R.E.E.L. in Options, or one of its pages by name

local _, ns = ...
local L = ns.L
local W = ns.W
local C = W.C

-- The Options canvas (Blizzard_SettingsPanel.xml: a 920x724 panel less the category list).
local CANVAS_W, CANVAS_H = 665, 600
local PAD, GAP, HEAD = 16, 20, 54

local PAGES = {}
-- Page names are keys (ns.PageNamed, ns.OpenOptions); they are shown through L[def.name].
for _, name in ipairs({ "Bar", "Casting", "Clean View", "General", "Immersion", "Sound" }) do
    PAGES[#PAGES + 1] = { name = name, columns = { { page = name } } }
end

local root, rootFrame
local shownCount = 0 -- R.E.E.L. pages open in Options (the unlocked bar stays up meanwhile)

-- Is one of R.E.E.L.'s Options pages open?
function ns.OptionsShown()
    return shownCount > 0
end

-- A column's content height: down to its lowest control, once the layout has settled.
local function Fit(scroll, child)
    local top = child:GetTop()
    if not top then return end
    local lowest = top
    for _, r in ipairs({ child:GetRegions() }) do
        if r:IsShown() and r:GetBottom() then lowest = math.min(lowest, r:GetBottom()) end
    end
    for _, f in ipairs({ child:GetChildren() }) do
        if f:IsShown() and f:GetBottom() then lowest = math.min(lowest, f:GetBottom()) end
    end
    child:SetHeight(math.max(scroll:GetHeight() or 1, top - lowest + 8))
end

-- Builds a page's columns: each one an old settings page, under its own small title.
local function BuildPage(def)
    local frame = def.frame
    local cols = #def.columns
    local colW = math.floor((CANVAS_W - 2 * PAD - GAP * (cols - 1)) / cols)
    def.refresh = {}
    for i, col in ipairs(def.columns) do
        local page = ns.PageNamed(col.page)
        local x = PAD + (i - 1) * (colW + GAP)
        local top = -HEAD
        if col.title then
            local t = W.Text(frame, 14, C.amber2)
            t:SetPoint("TOPLEFT", x, top)
            t:SetText(col.title)
            top = top - 24
        end
        local holder
        if page.scrolls then
            -- the page scrolls itself (Bar)
            holder = CreateFrame("Frame", nil, frame)
            holder:SetPoint("TOPLEFT", x, top)
            holder:SetSize(colW, CANVAS_H + top - 10)
            ns.CONTENT_WIDTH = colW
        else
            local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
            scroll:SetPoint("TOPLEFT", x, top)
            scroll:SetSize(colW - 22, CANVAS_H + top - 10)
            holder = CreateFrame("Frame", nil, scroll)
            holder:SetSize(colW - 22, 1)
            scroll:SetScrollChild(holder)
            ns.CONTENT_WIDTH = colW - 22
            col.scroll = scroll
        end
        local refresh = page.build(holder)
        page.panel = holder
        col.holder = holder
        def.refresh[#def.refresh + 1] = refresh
    end
end

-- A page's frame: its title in Hal's type, "R.E.E.L." on the right, an amber rule under them.
local function PageFrame(name)
    local frame = CreateFrame("Frame")
    frame:Hide()
    local title = W.Text(frame, 20, C.amber2)
    title:SetPoint("TOPLEFT", PAD, -16)
    title:SetText(name)
    local tag = W.Text(frame, 11, C.dim)
    tag:SetPoint("TOPRIGHT", -PAD, -22)
    tag:SetJustifyH("RIGHT")
    tag:SetText("R.E.E.L.")
    local rule = W.Solid(frame, "ARTWORK", C.amber, 0.25)
    rule:SetPoint("TOPLEFT", PAD, -44)
    rule:SetPoint("TOPRIGHT", -PAD, -44)
    rule:SetHeight(1)
    return frame
end

-- R.E.E.L.'s key bindings (Bindings.xml), named by their BINDING_NAME strings, in two columns.
local BINDINGS = {
    "CLICK ReelFishButton:LeftButton", "REEL_TOGGLE_WINDOW",
    "CLICK ReelRecastButton:LeftButton", "REEL_TOGGLE_CLEAN_VIEW",
    "CLICK ReelLureKeyButton:LeftButton", "CLICK ReelFoodKeyButton:LeftButton",
}

-- A heading on the landing page.
local function Heading(parent, text, y)
    local h = W.Text(parent, 13, C.amber2)
    h:SetPoint("TOPLEFT", PAD, y)
    h:SetText(text)
    return h
end

-- Opens the game's Key Bindings at the AddOns section, where R.E.E.L.'s bindings are
-- (Bindings.xml puts them in category ADDONS under the R.E.E.L. header). Blizzard's own code
-- opens a section the same way (Blizzard_RPE_TurnStrafe: Settings.OpenToCategory with the
-- section's name to scroll to).
local function OpenKeyBindings()
    if Settings and Settings.KEYBINDINGS_CATEGORY_ID then
        Settings.OpenToCategory(Settings.KEYBINDINGS_CATEGORY_ID, ADDONS)
    else
        ns.Print(L["This client has no Key Bindings page to open."])
    end
end

-- The landing page (site/art/ui/mockup/options-home.html): the nameplate, the presets, the key
-- bindings with their keys, the journal's export, the About line and the six pages as links.
-- Everything sits at a fixed place and fits the canvas.
local function BuildLanding(frame)
    local plate = frame:CreateTexture(nil, "ARTWORK")
    plate:SetTexture(W.TEX .. "nameplate")
    plate:SetTexCoord(0, 1, 0, 62 / 64)
    plate:SetSize(134, 33)
    plate:SetPoint("TOPLEFT", PAD, -14)

    -- Presets
    Heading(frame, L["Presets"], -58)
    frame.presets = {}
    for i, preset in ipairs(ns.PRESETS) do
        local y = -76 - (i - 1) * 26
        local b = W.Button(frame, preset.name, 124, function() ns.ApplyPreset(preset) end)
        b:SetPoint("TOPLEFT", PAD + 2, y)
        local n = W.Note(frame, preset.note, CANVAS_W - 2 * PAD - 140)
        n:SetPoint("LEFT", b, "RIGHT", 10, 0)
        frame.presets[i] = b
    end
    local presetNote = W.Note(frame, ns.PRESET_NOTE, CANVAS_W - 2 * PAD)
    presetNote:SetPoint("TOPLEFT", PAD, -156)

    -- Key bindings: name on the left, its key in a cap on the right, two columns
    Heading(frame, L["Key bindings"], -178)
    frame.caps = {}
    local colW = (CANVAS_W - 2 * PAD - 30) / 2
    for i, command in ipairs(BINDINGS) do
        local col, row = (i - 1) % 2, math.floor((i - 1) / 2)
        local x, y = PAD + col * (colW + 30), -198 - row * 26
        local name = W.Text(frame, 11.5, C.ink)
        name:SetPoint("TOPLEFT", x, y - 4)
        name:SetText(_G["BINDING_NAME_" .. command] or command)
        local cap = CreateFrame("Frame", nil, frame)
        cap:SetHeight(16)
        cap:SetPoint("TOPRIGHT", frame, "TOPLEFT", x + colW, y - 2)
        local bg = W.Solid(cap, "BACKGROUND", C.pitch)
        bg:SetAllPoints()
        W.Outline(cap, "BORDER", C.amber, 0.25)
        cap.text = W.Text(cap, 10, C.ink)
        cap.text:SetPoint("CENTER")
        cap.command = command
        local rule = W.Solid(frame, "ARTWORK", C.amber, 0.08)
        rule:SetPoint("TOPLEFT", x, y - 23)
        rule:SetSize(colW, 1)
        frame.caps[i] = cap
    end
    local openKeys = W.Button(frame, L["Open Key Bindings"], 150, OpenKeyBindings)
    openKeys:SetPoint("TOPLEFT", PAD + 2, -280)
    frame.openKeys = openKeys

    -- Your journal: the R.E.E.L. window's Export, here too
    Heading(frame, L["Your journal"], -314)
    local export = W.OakButton(frame, L["Export"], function() ns.ShowExport() end)
    export:SetPoint("TOPLEFT", PAD, -334)
    frame.export = export
    local hint = W.Text(frame, 10.5, C.dim)
    hint:SetPoint("LEFT", export, "RIGHT", 12, 0)
    hint:SetText(L["Paste it on |cffcdb894halsudsworth.com|r"])

    -- About
    Heading(frame, L["About"], -368)
    local about = W.Note(frame, ns.AboutLine(), CANVAS_W - 2 * PAD)
    about:SetPoint("TOPLEFT", PAD, -386)
    frame.about = about

    -- The pages, as a row of links
    local label = W.Text(frame, 10.5, C.dim)
    label:SetPoint("TOPLEFT", PAD, -428)
    label:SetText(L["Pages:"])
    local anchor, anchorPoint, gap = label, "RIGHT", 8
    for _, def in ipairs(PAGES) do
        local link = CreateFrame("Button", nil, frame)
        local fs = W.Text(link, 11, C.ink2)
        fs:SetPoint("LEFT")
        fs:SetText(L[def.name])
        link:SetSize(math.ceil(fs:GetStringWidth()) + 2, 16)
        link:SetPoint("LEFT", anchor, anchorPoint, gap, 0)
        link:SetScript("OnEnter", function() fs:SetTextColor(W.Hex(C.amber2)) end)
        link:SetScript("OnLeave", function() fs:SetTextColor(W.Hex(C.ink2)) end)
        link:SetScript("OnClick", function() ns.OpenOptions(def.name) end)
        link.text = fs
        def.link = link
        anchor, anchorPoint, gap = link, "RIGHT", 12
    end
    frame.contentBottom = 444 -- px from the canvas top: the pages row's foot
end

-- The key caps show the live bindings: on show, and whenever bindings change.
local function RefreshCaps()
    if not (rootFrame and rootFrame.caps) then return end
    for _, cap in ipairs(rootFrame.caps) do
        local key = GetBindingKey(cap.command)
        if key then
            cap.text:SetText(GetBindingText and GetBindingText(key) or key)
            cap.text:SetTextColor(W.Hex(C.ink))
        else
            cap.text:SetText(L["Not bound"])
            cap.text:SetTextColor(W.Hex(C.dim))
        end
        cap:SetWidth(math.max(22, math.ceil(cap.text:GetStringWidth()) + 12))
    end
end
ns.On("UPDATE_BINDINGS", RefreshCaps)

local function Register()
    if root or not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    -- R.E.E.L.'s own entry: the landing page
    rootFrame = CreateFrame("Frame")
    rootFrame:Hide()
    rootFrame:SetScript("OnShow", RefreshCaps)
    root = Settings.RegisterCanvasLayoutCategory(rootFrame, "R.E.E.L.")
    for _, def in ipairs(PAGES) do
        def.frame = PageFrame(L[def.name])
        def.frame:SetScript("OnShow", function()
            if not def.refresh then BuildPage(def) end
            for _, refresh in ipairs(def.refresh) do if refresh then refresh() end end
            for _, col in ipairs(def.columns) do
                if col.scroll then C_Timer.After(0, function() Fit(col.scroll, col.holder) end) end
            end
            shownCount = shownCount + 1
            ns.UpdateBar()
        end)
        def.frame:SetScript("OnHide", function()
            shownCount = math.max(0, shownCount - 1)
            ns.UpdateBar()
        end)
        def.category = Settings.RegisterCanvasLayoutSubcategory(root, def.frame, L[def.name])
    end
    BuildLanding(rootFrame)
    Settings.RegisterAddOnCategory(root)
end

ns.OptionsLanding = function() return rootFrame end -- for the load test

-- Opens R.E.E.L. in Options, or one of its pages by name.
function ns.OpenOptions(name)
    Register()
    if not root then
        ns.Print(L["This client has no Options > AddOns to open."])
        return
    end
    local category = root
    for _, def in ipairs(PAGES) do if def.name == name then category = def.category end end
    Settings.OpenToCategory(category:GetID())
end

-- The page of Options a settings page lives on.
function ns.OptionsPageOf(pageName)
    for _, def in ipairs(PAGES) do
        for _, col in ipairs(def.columns) do if col.page == pageName then return def.name end end
    end
end

ns.On("REEL_READY", Register)
ns.OptionsPages = PAGES -- for the load test
