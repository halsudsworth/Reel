-- Reel window: a sidebar of pages on the left, the selected page on the right.
--
-- Pages register with ns.RegisterPage({
--     name  = "Sound",           sidebar label and page title
--     order = 20,                position in the sidebar
--     build = function(panel)    create controls inside panel (built once)
--         return function() end  optional: called every time the page is shown
--     end,
-- })

local _, ns = ...

local WIDTH, HEIGHT = 680, 500
local SIDEBAR = 120
ns.CONTENT_WIDTH = WIDTH - SIDEBAR - 36 -- usable width inside a page (8 + 14 + 14 of insets)

local pages = {}
local window, content, pageTitle

function ns.RegisterPage(page)
    pages[#pages + 1] = page
    table.sort(pages, function(a, b) return a.order < b.order end)
end

local function Select(page)
    if not page.panel then
        page.panel = CreateFrame("Frame", nil, content)
        page.panel:SetPoint("TOPLEFT", 0, -30)
        page.panel:SetPoint("BOTTOMRIGHT")
        page.refresh = page.build(page.panel)
    end
    for _, p in ipairs(pages) do
        if p.panel then p.panel:SetShown(p == page) end
        if p == page then p.button:LockHighlight() else p.button:UnlockHighlight() end
    end
    pageTitle:SetText(page.name)
    if page.refresh then page.refresh() end
    ReelDB.settings.lastPage = page.name
end

local function SidebarButton(parent, page, index)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(SIDEBAR - 8, 22)
    b:SetPoint("TOPLEFT", 4, -4 - (index - 1) * 24)
    b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    local text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", 8, 0)
    text:SetText(page.name)
    b:SetScript("OnClick", function() Select(page) end)
    return b
end

local function BuildWindow()
    window = CreateFrame("Frame", "ReelFrame", UIParent, "BasicFrameTemplateWithInset")
    window:SetSize(WIDTH, HEIGHT)
    window:SetPoint("CENTER")
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetFrameStrata("MEDIUM")
    window:Hide()
    tinsert(UISpecialFrames, "ReelFrame") -- close with Escape
    if ns.RefreshKeep then ns.RefreshKeep() end -- built during clean view: don't inherit the fade

    local title = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -5)
    title:SetText("R.E.E.L.")

    local sidebar = CreateFrame("Frame", nil, window)
    sidebar:SetPoint("TOPLEFT", 8, -28)
    sidebar:SetPoint("BOTTOMLEFT", 8, 8)
    sidebar:SetWidth(SIDEBAR)

    local divider = window:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(1, 1, 1, 0.15)
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, -4)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 4)
    divider:SetWidth(1)

    content = CreateFrame("Frame", nil, window)
    content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 14, -6)
    content:SetPoint("BOTTOMRIGHT", -14, 10)

    pageTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    pageTitle:SetPoint("TOPLEFT")

    for i, page in ipairs(pages) do
        page.button = SidebarButton(sidebar, page, i)
    end

    window:SetScript("OnShow", function()
        local last = ReelDB.settings.lastPage
        for _, page in ipairs(pages) do
            if page.name == last then return Select(page) end
        end
        Select(pages[1])
    end)
end

function ns.ToggleWindow()
    if not window then BuildWindow() end
    window:SetShown(not window:IsShown())
    ns.UpdateBar()
end

function ns.WindowShown()
    return window ~= nil and window:IsShown()
end
