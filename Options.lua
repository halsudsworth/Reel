-- R.E.E.L.'s settings in the game's Options > AddOns (Settings canvas categories): R.E.E.L. with
-- four pages, as the mockup groups them (site/art/ui/mockup/index.html, screens 8 to 11):
--   At the water   Casting (with One key) | Bar
--   Clean View     Clean View | Immersion
--   Sound
--   General
-- Each page hosts the settings pages registered with ns.RegisterPage (no place), built the first
-- time it's shown. Inside Blizzard's frame the page keeps only Hal's type and amber.
--
--   ns.OpenOptions([name])   opens R.E.E.L. in Options, or one of its pages by name

local _, ns = ...
local W = ns.W
local C = W.C

-- The Options canvas (Blizzard_SettingsPanel.xml: a 920x724 panel less the category list).
local CANVAS_W, CANVAS_H = 665, 600
local PAD, GAP, HEAD = 16, 20, 54

local PAGES = {
    { name = "At the water", columns = { { page = "Casting", title = "Casting" }, { page = "Bar", title = "Bar" } } },
    { name = "Clean View", columns = { { page = "Clean View" }, { page = "Immersion", title = "Immersion" } } },
    { name = "Sound", columns = { { page = "Sound" } } },
    { name = "General", columns = { { page = "General" } } },
}

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

local function Register()
    if root or not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    -- R.E.E.L.'s own entry: the nameplate and its four pages
    rootFrame = CreateFrame("Frame")
    rootFrame:Hide()
    local plate = rootFrame:CreateTexture(nil, "ARTWORK")
    plate:SetTexture(W.TEX .. "nameplate")
    plate:SetTexCoord(0, 1, 0, 62 / 64)
    plate:SetSize(201, 49)
    plate:SetPoint("TOPLEFT", PAD, -16)
    local line = W.Text(rootFrame, 12, C.ink2)
    line:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 0, -14)
    line:SetText("R.E.E.L.'s settings are on four pages:")
    root = Settings.RegisterCanvasLayoutCategory(rootFrame, "R.E.E.L.")
    local anchor = line
    for _, def in ipairs(PAGES) do
        def.frame = PageFrame(def.name)
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
        def.category = Settings.RegisterCanvasLayoutSubcategory(root, def.frame, def.name)
        local b = W.OakButton(rootFrame, def.name, function() ns.OpenOptions(def.name) end)
        b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, anchor == line and -10 or -6)
        anchor = b
        def.button = b
    end
    Settings.RegisterAddOnCategory(root)
end

-- Opens R.E.E.L. in Options, or one of its pages by name.
function ns.OpenOptions(name)
    Register()
    if not root then
        ns.Print("This client has no Options > AddOns to open.")
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
