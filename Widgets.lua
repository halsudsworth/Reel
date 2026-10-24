-- Shared controls for Reel pages. Each control has Refresh() to re-read its
-- setting and SetActive(bool) to enable or grey it out.

local _, ns = ...

local W = {}
ns.W = W

function W.Label(parent, text, template)
    local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
    fs:SetText(text)
    fs:SetJustifyH("LEFT")
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

-- options: list of { value = ..., text = "..." }, or a function returning one
-- (called each time the menu opens, for lists that change).
function W.Dropdown(parent, text, width, options, get, set)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22)
    local label = W.Label(b, text, "GameFontHighlight")
    label:SetPoint("RIGHT", b, "LEFT", -8, 0)

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
            if option.value == get() then b:SetText(option.text) end
        end
    end
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
