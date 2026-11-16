-- Shared controls for Reel pages. Each control has Refresh() to re-read its
-- setting and SetActive(bool) to enable or grey it out.

local _, ns = ...

local W = {}
ns.W = W

-- Settings text in Hal's colours: headings amber, labels ink, notes dim.
local LABEL_COLOURS = { GameFontNormal = "f2b24a", GameFontHighlight = "efe3cc", GameFontDisableSmall = "8a7a63" }

function W.Label(parent, text, template)
    template = template or "GameFontNormal"
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
    local hex = LABEL_COLOURS[template]
    if hex then fs:SetTextColor(tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255) end
    return fs
end

-- Small grey wrapped text, used under a control to explain it.
function W.Note(parent, text, width)
    local fs = W.Label(parent, text, "GameFontDisableSmall")
    fs:SetWidth(width)
    return fs
end

function W.Checkbox(parent, text, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    local label = W.Label(cb, text, "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    cb.Refresh = function() cb:SetChecked(get()) end
    cb.SetActive = function(_, active)
        cb:SetEnabled(active)
        label:SetAlpha(active and 1 or 0.4)
    end
    return cb
end

function W.Slider(parent, text, min, max, step, suffix, get, set)
    local s = CreateFrame("Slider", nil, parent)
    s:SetOrientation("HORIZONTAL")
    s:SetSize(160, 16)
    s:SetMinMaxValues(min, max)
    s:SetValueStep(step)
    if s.SetObeyStepOnDrag then s:SetObeyStepOnDrag(true) end
    s:EnableMouse(true)

    local track = s:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(0, 0, 0, 0.6)
    track:SetPoint("LEFT")
    track:SetPoint("RIGHT")
    track:SetHeight(6)
    s:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")

    local label = W.Label(s, text, "GameFontHighlight")
    label:SetPoint("RIGHT", s, "LEFT", -8, 0)
    s.label = label
    local value = W.Label(s, "", "GameFontHighlight")
    value:SetPoint("LEFT", s, "RIGHT", 8, 0)

    s:SetScript("OnValueChanged", function(_, v)
        v = math.floor(v / step + 0.5) * step
        value:SetText(v .. suffix)
        if v ~= get() then set(v) end
    end)
    s.Refresh = function()
        s:SetValue(get())
        value:SetText(get() .. suffix)
    end
    s.SetActive = function(_, active)
        if active then s:Enable() else s:Disable() end
        s:SetAlpha(active and 1 or 0.4)
    end
    return s
end

-- The drop-down menu under a button: options is a list of { value = ..., text = "..." }, or a
-- function returning one (called each time the menu opens, for lists that change).
local function Menu(b, width, options, get, set)
    local menu = CreateFrame("Frame", nil, b)
    menu:SetFrameStrata("DIALOG")
    menu:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, -2)
    menu:EnableMouse(true)
    menu:Hide()
    local bg = menu:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    bg:SetAllPoints()

    local function Options()
        return type(options) == "function" and options() or options
    end

    local items = {}
    local function BuildMenu()
        local list = Options()
        for i, option in ipairs(list) do
            local item = items[i]
            if not item then
                item = CreateFrame("Button", nil, menu)
                item:SetSize(width - 8, 20)
                item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 20)
                item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                item.text = W.Label(item, "", "GameFontHighlight")
                item.text:SetPoint("LEFT", 6, 0)
                item:SetScript("OnClick", function(self)
                    menu:Hide()
                    set(self.value)
                    b.Refresh()
                end)
                items[i] = item
            end
            item.value = option.value
            item.text:SetText(option.text)
            item:Show()
        end
        for i = #list + 1, #items do items[i]:Hide() end
        menu:SetSize(width, #list * 20 + 8)
    end

    b:SetScript("OnClick", function()
        if not menu:IsShown() then BuildMenu() end
        menu:SetShown(not menu:IsShown())
    end)
    b:SetScript("OnHide", function() menu:Hide() end)
    b.Refresh = function()
        for _, option in ipairs(Options()) do
            if option.value == get() then (b.SetLabel or b.SetText)(b, option.text) end
        end
    end
    return menu
end

-- options: list of { value = ..., text = "..." }, or a function returning one
-- (called each time the menu opens, for lists that change).
function W.Dropdown(parent, text, width, options, get, set)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    local label = W.Label(b, text, "GameFontHighlight")
    label:SetPoint("RIGHT", b, "LEFT", -8, 0)
    local menu = Menu(b, width, options, get, set)
    b.SetActive = function(_, active)
        b:SetEnabled(active)
        label:SetAlpha(active and 1 or 0.4)
        if not active then menu:Hide() end
    end
    return b
end

function W.Button(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

-- The window's own look (Direction A in site/art/ui/mockup/index.html): oiled oak, char-black
-- panels, lantern amber, Friz Quadrata for titles and tabs ----------------------------------

W.TEX = "Interface\\AddOns\\Reel\\Textures\\"
W.FRIZ = "Fonts\\FRIZQT__.TTF"
W.C = {
    ink = "efe3cc", ink2 = "cdb894", dim = "8a7a63", amber = "f2b24a", amber2 = "ffd27a",
    char = "120d09", pitch = "0b0805", bar = "0d0906", foot = "0e0a07", card = "0f0b08",
    slot = "16100b", tabTop = "6a4628", tabBottom = "3d2817", oakHi = "6e4a2c", oakLo = "2c1c0f",
    track = "2a2018", barFrom = "a8702a", grey = "8f8577", rule = "ffe2b4",
}

-- "efe3cc" -> r, g, b, a
function W.Hex(hex, a)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255, a or 1
end

function W.Solid(parent, layer, hex, a, sub)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
    t:SetColorTexture(W.Hex(hex, a))
    return t
end

-- A gradient fill: horizontal from left to right, vertical from bottom to top.
function W.Gradient(t, dir, hex1, a1, hex2, a2)
    t:SetColorTexture(1, 1, 1, 1)
    if CreateColor and t.SetGradient then
        pcall(t.SetGradient, t, dir, CreateColor(W.Hex(hex1, a1)), CreateColor(W.Hex(hex2, a2)))
    end
end

-- A one-pixel line around a frame, inset by n (0 = on its edge).
function W.Outline(frame, layer, hex, a, n, sub)
    n = n or 0
    local lines = {}
    for i, side in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, -1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 1 }, { "TOPLEFT", "BOTTOMLEFT", 1, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", -1, 0 } }) do
        local t = W.Solid(frame, layer, hex, a, sub)
        local h = i <= 2
        t:SetPoint(side[1], (side[1]:find("LEFT") and n or -n), (side[1]:find("TOP") and -n or n))
        t:SetPoint(side[2], (side[2]:find("LEFT") and n or -n), (side[2]:find("TOP") and -n or n))
        if h then t:SetHeight(1) else t:SetWidth(1) end
        lines[i] = t
    end
    return lines
end

-- Text in Friz Quadrata at a size, with the game's shadow.
function W.Text(parent, size, hex, layer)
    local fs = parent:CreateFontString(nil, layer or "OVERLAY")
    fs:SetFont(W.FRIZ, size, "")
    fs:SetTextColor(W.Hex(hex or W.C.ink))
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(1, -1)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    return fs
end

-- An oak button: dark oak, a black edge, a faint amber line inside, amber Friz text.
function W.OakButton(parent, text, onClick, height, size)
    local b = CreateFrame("Button", nil, parent)
    local fs = W.Text(b, size or 11.5, W.C.amber2)
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText(text)
    b.text = fs
    b:SetSize(math.max(40, math.ceil(fs:GetStringWidth()) + 28), height or 22)
    local bg = W.Solid(b, "BACKGROUND", W.C.oakLo)
    bg:SetAllPoints()
    W.Gradient(bg, "VERTICAL", W.C.oakLo, 1, W.C.oakHi, 1)
    W.Outline(b, "BORDER", "000000", 1, 0)
    W.Outline(b, "BORDER", W.C.amber, 0.3, 1, 1)
    local shine = W.Solid(b, "ARTWORK", "ffdcaa", 0.22)
    shine:SetPoint("TOPLEFT", 2, -2); shine:SetPoint("TOPRIGHT", -2, -2); shine:SetHeight(1)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(W.Hex(W.C.amber, 0.12))
    b:SetScript("OnClick", onClick)
    return b
end

-- A tab: oak when not chosen, the lit tab (taller, amber line along its foot) when chosen.
function W.OakTab(parent, text, size, height, onClick)
    local b = CreateFrame("Button", nil, parent)
    local fs = W.Text(b, size, W.C.ink2)
    fs:SetPoint("CENTER", 0, 0)
    fs:SetText(text)
    b.text = fs
    local width = math.ceil(fs:GetStringWidth()) + 2 * math.floor(size * 1.25)
    b:SetSize(width, height)
    local off = W.Solid(b, "BACKGROUND", W.C.oakLo)
    off:SetAllPoints()
    W.Gradient(off, "VERTICAL", W.C.oakLo, 1, "4a301b", 1)
    local on = W.Solid(b, "BACKGROUND", W.C.tabBottom, 1, 1)
    on:SetAllPoints()
    W.Gradient(on, "VERTICAL", W.C.tabBottom, 1, W.C.tabTop, 1)
    local foot = W.Solid(b, "ARTWORK", W.C.amber, 1)
    foot:SetPoint("BOTTOMLEFT", 1, 0); foot:SetPoint("BOTTOMRIGHT", -1, 0); foot:SetHeight(2)
    local edge = {}
    for i, side in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
        local t = W.Solid(b, "BORDER", "000000", 1)
        t:SetPoint(side[1]); t:SetPoint(side[2])
        if side[3] then t:SetHeight(1) else t:SetWidth(1) end
        edge[i] = t
    end
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(W.Hex(W.C.amber, 0.08))
    function b.SetChosen(_, chosen)
        on:SetShown(chosen); foot:SetShown(chosen); off:SetShown(not chosen)
        fs:SetTextColor(W.Hex(chosen and W.C.amber2 or W.C.ink2))
        b:SetHeight(chosen and height + 3 or height)
        b.chosen = chosen
    end
    b:SetChosen(false)
    b:SetScript("OnClick", onClick)
    return b
end

-- A small dark box with an amber + or - (a row that opens).
function W.ToggleBox(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(12, 12)
    local bg = W.Solid(f, "BACKGROUND", W.C.pitch)
    bg:SetAllPoints()
    W.Outline(f, "BORDER", "000000", 1, 0)
    W.Outline(f, "BORDER", W.C.amber, 0.3, 1, 1)
    f.text = W.Text(f, 10, W.C.amber2)
    f.text:SetPoint("CENTER", 0, 0)
    function f.Set(_, open) f.text:SetText(open and "-" or "+") end
    return f
end

-- A checkbox in the window's style: a small dark box, an amber tick, Friz label.
function W.OakCheck(parent, text, get, set)
    local b = CreateFrame("Button", nil, parent)
    local box = CreateFrame("Frame", nil, b)
    box:SetSize(12, 12)
    box:SetPoint("LEFT", 0, 0)
    local bg = W.Solid(box, "BACKGROUND", W.C.pitch)
    bg:SetAllPoints()
    W.Outline(box, "BORDER", "000000", 1, 0)
    W.Outline(box, "BORDER", W.C.amber, 0.3, 1, 1)
    local tick = box:CreateTexture(nil, "ARTWORK")
    tick:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    tick:SetPoint("CENTER", 0, 0)
    tick:SetSize(16, 16)
    local label = W.Text(b, 10.5, W.C.ink2)
    label:SetPoint("LEFT", box, "RIGHT", 7, 0)
    label:SetText(text)
    b:SetSize(12 + 7 + math.ceil(label:GetStringWidth()) + 4, 16)
    b.tick = tick
    b.Refresh = function() tick:SetShown(get() and true or false) end
    b:SetScript("OnClick", function() set(not get()); b.Refresh() end)
    return b
end

-- A picker in the window's title bar: a dark box with the choice and an amber caret.
function W.Picker(parent, width, options, get, set)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 20)
    local bg = W.Solid(b, "BACKGROUND", W.C.pitch)
    bg:SetAllPoints()
    W.Outline(b, "BORDER", "000000", 1, 0)
    W.Outline(b, "BORDER", W.C.amber, 0.2, 1, 1)
    local fs = W.Text(b, 10.5, W.C.ink)
    fs:SetPoint("LEFT", 9, 0)
    fs:SetPoint("RIGHT", -20, 0)
    b.label = fs
    function b.SetLabel(_, text) fs:SetText(text) end
    -- the caret: a small amber triangle pointing down
    for i, w in ipairs({ 7, 5, 3, 1 }) do
        local t = W.Solid(b, "ARTWORK", W.C.amber, 1)
        t:SetSize(w, 1)
        t:SetPoint("RIGHT", -8 - (7 - w) / 2, 2 - i)
    end
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(W.Hex(W.C.amber, 0.08))
    Menu(b, width, options, get, set)
    return b
end
