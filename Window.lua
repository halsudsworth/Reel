-- Reel window (Direction A in site/art/ui/mockup/index.html): an oak frame with brass nails and
-- the brass nameplate over its top edge. Along the top: the Journal and Events tabs, then the
-- character picker (Journal only), a gear for the settings and a close button. Below: the
-- chosen place.
--
-- Pages register with ns.RegisterPage({
--     name  = "Sound",           page name (and, for a settings page, how Options.lua finds it)
--     order = 20,                its order among the pages
--     place = "journal",         "journal" or "events" for the two tabs; none for a settings page
--     build = function(panel)    create controls inside panel (built once)
--         return function() end  optional: called every time the page is shown
--     end,
-- })
--
-- Settings pages (no place) live in the game's Options > AddOns (Options.lua); the gear opens them.

local _, ns = ...
local L = ns.L
local W = ns.W
local C = W.C

local WIDTH, HEIGHT = 744, 624
local EDGE = 9          -- the oak frame around the panel
local BAR_H = 34        -- the title bar with the tabs
ns.WINDOW_MAIN_WIDTH = WIDTH - 2 * EDGE - 2 -- a place's width (the panel's inside)
-- a banner's medal and title (Journal tabs and Events): the same spot on every one
ns.MEDAL_SIZE, ns.MEDAL_X, ns.MEDAL_Y = 60, 15, 9
ns.BANNER_TITLE_X, ns.BANNER_TITLE_Y = 86, 30
ns.CONTENT_WIDTH = 300                        -- a settings page's usable width; Options.lua sets it per column

ns.RegisterDefaults({
    windowScale = 100, -- percent: the whole window grows or shrinks together (General page)
})

local pages = {}
local window, main, slot, gear
local tabs = {}

function ns.RegisterPage(page)
    pages[#pages + 1] = page
    table.sort(pages, function(a, b) return a.order < b.order end)
end

local function PageNamed(name)
    for _, page in ipairs(pages) do if page.name == name then return page end end
end
ns.PageNamed = PageNamed

local function PlacePage(place)
    for _, page in ipairs(pages) do if page.place == place then return page end end
end

local function Select(page)
    if not (page and page.place) then page = PlacePage("journal") end
    if not page.panel then
        page.panel = CreateFrame("Frame", nil, main)
        page.panel:SetAllPoints(main)
        page.refresh = page.build(page.panel)
    end
    for _, p in ipairs(pages) do
        if p.place and p.panel then p.panel:SetShown(p == page) end
    end
    for place, tab in pairs(tabs) do tab:SetChosen(page.place == place) end
    slot:SetShown(page.place == "journal")
    if page.refresh then page.refresh() end
    ReelDB.settings.lastPage = page.name
end

-- A square oak button in the title bar (gear, close).
local function TitleButton(parent, onClick)
    local b = W.OakButton(parent, "", onClick, 20)
    b:SetSize(20, 20)
    return b
end

-- The window's size: one scale for everything in it, so every tab's layout stays as drawn.
function ns.SetWindowScale(percent)
    ReelDB.settings.windowScale = percent
    if window then window:SetScale(percent / 100) end
end

local function BuildWindow()
    window = CreateFrame("Frame", "ReelFrame", UIParent)
    window:SetSize(WIDTH, HEIGHT)
    window:SetScale((ReelDB.settings.windowScale or 100) / 100)
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
    ns.OakPlate(window)

    -- The size grip in the bottom-right corner: dragging it scales the whole window (70-150%),
    -- its top-left corner staying put, the same setting as the General page's Window size.
    local grip = CreateFrame("Button", nil, window)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    grip:SetFrameLevel(window:GetFrameLevel() + 20)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    local left, top -- the window's top-left corner in UIParent's units while dragging
    local function Follow()
        local x = GetCursorPosition() / UIParent:GetEffectiveScale()
        local percent = math.floor((x - left) / WIDTH * 100 / 5 + 0.5) * 5
        percent = math.max(70, math.min(150, percent))
        local scale = percent / 100
        window:SetScale(scale)
        window:ClearAllPoints()
        window:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / scale, top / scale)
        ReelDB.settings.windowScale = percent
    end
    grip:SetScript("OnMouseDown", function()
        local scale = window:GetScale()
        left, top = window:GetLeft() * scale, window:GetTop() * scale
        grip:SetScript("OnUpdate", Follow)
    end)
    grip:SetScript("OnMouseUp", function() grip:SetScript("OnUpdate", nil) end)

    -- the brass nameplate over the top edge
    local sign = CreateFrame("Frame", nil, window)
    sign:SetSize(201, 49)
    sign:SetPoint("TOP", 0, 24)
    sign:SetFrameLevel(window:GetFrameLevel() + 20)
    local plate = sign:CreateTexture(nil, "ARTWORK")
    plate:SetAllPoints()
    plate:SetTexture(W.TEX .. "nameplate")
    plate:SetTexCoord(0, 1, 0, 62 / 64)
    window.nameplate = plate

    -- the panel inside the frame: char-black, a black edge and a faint amber line
    local inner = CreateFrame("Frame", nil, window)
    inner:SetPoint("TOPLEFT", EDGE, -EDGE)
    inner:SetPoint("BOTTOMRIGHT", -EDGE, EDGE)
    local bg = W.Solid(inner, "BACKGROUND", C.char)
    bg:SetAllPoints()
    W.Outline(inner, "BORDER", "000000", 1, 0)
    W.Outline(inner, "BORDER", C.amber, 0.2, 1, 1)

    -- the title bar: the two places, then picker, gear, close
    local bar = CreateFrame("Frame", nil, inner)
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(BAR_H)
    local barBg = W.Solid(bar, "BACKGROUND", C.bar)
    barBg:SetAllPoints()
    local barLine = W.Solid(bar, "BORDER", C.amber, 0.35)
    barLine:SetPoint("BOTTOMLEFT"); barLine:SetPoint("BOTTOMRIGHT"); barLine:SetHeight(1)
    local x = 12
    for _, place in ipairs({ { "journal", L["Journal"] }, { "events", L["Events"] } }) do
        local tab = W.OakTab(bar, place[2], 13, 26, function() Select(PlacePage(place[1])) end)
        tab:SetPoint("BOTTOMLEFT", x, 1)
        x = x + tab:GetWidth() + 4
        tabs[place[1]] = tab
    end
    local close = TitleButton(bar, function() window:Hide(); ns.UpdateBar() end)
    close:SetPoint("RIGHT", -10, 0)
    close.text:SetText("×")
    gear = TitleButton(bar, function() ns.OpenOptions() end)
    gear:SetPoint("RIGHT", close, "LEFT", -6, 0)
    local cog = gear:CreateTexture(nil, "ARTWORK")
    cog:SetTexture(W.TEX .. "gear")
    cog:SetSize(16, 16)
    cog:SetPoint("CENTER")
    gear.cog = cog
    gear:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["Settings"])
        GameTooltip:Show()
    end)
    gear:SetScript("OnLeave", function() GameTooltip:Hide() end)
    window.gear, window.close = gear, close
    -- where the Journal puts its character picker
    slot = CreateFrame("Frame", nil, bar)
    slot:SetSize(150, 20)
    slot:SetPoint("RIGHT", gear, "LEFT", -10, 0)

    -- below the title bar: the chosen place
    main = CreateFrame("Frame", nil, inner)
    main:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -1)
    main:SetPoint("BOTTOMRIGHT", -1, 1)

    -- the bar follows the window at once, however it closes (Escape too)
    window:SetScript("OnHide", function() ns.UpdateBar() end)
    window:SetScript("OnShow", function()
        Select(PageNamed(ReelDB.settings.lastPage) or PlacePage("journal"))
    end)
end

-- Where the Journal puts its character picker (in the title bar), once the window is built.
function ns.WindowSlot()
    return slot
end

function ns.ToggleWindow()
    if not window then BuildWindow() end
    window:SetShown(not window:IsShown())
    ns.UpdateBar()
end

-- Opens the window on a page, by name; a settings page opens in Options.
function ns.ShowPage(name)
    local page = PageNamed(name)
    if page and not page.place then return ns.OpenOptions(ns.OptionsPageOf(name)) end
    if not window then BuildWindow() end
    ReelDB.settings.lastPage = name
    if window:IsShown() then
        Select(PageNamed(name))
    else
        window:Show() -- OnShow selects lastPage
    end
    ns.UpdateBar()
end

function ns.WindowShown()
    return window ~= nil and window:IsShown()
end
