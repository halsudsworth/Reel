-- Fishing bar: a small oak plate of live info, shown while fishing or while
-- any segment has something running (a lure, a camp timer). Drawn after
-- site/art/ui/mockup/bar-concepts.html (decided 2026-11-15, ROADMAP.md "Bar").
--
-- Three layouts (Bar page, Layout):
--   Vertical    two columns, a dim label and its value:   Fishing  225/225 +80
--               the lure button is a small icon in the     Lure     [o] 8:24
--               Lure row; a rule before the session rows   Session  23 fish
--   Horizontal  the same pairs as cells, label over value, in one row
--   Icons       each item's game icon with only its number; the words are in
--               the hover tooltip; a missing thing is a greyed icon and a red "none"
-- Rows go skill, then status (Tastyfish, lure, food, camp), then session (count,
-- pace, zone fish). The size comes from what the rows show (timer digits counted
-- as 8s) and never shrinks while the bar stays up, so nothing wobbles; an item
-- turned off takes no space.
--
-- There's no skill line ("No line: the row is the timer"): the cast countdown and the catch
-- timer are an amber wash behind the Fishing row (Vertical) or cell (Horizontal) that drains
-- from right to left, and the game's cooldown sweep over the skill icon (Icons).
--
-- A catch changes no size and moves no row: for a few seconds the skill text is the
-- fish ("Raw Rockscale Cod  237th"), the row runs the catch timer, the fish's icon shows
-- in the lure slot (Icons: in the skill icon), and the session count turns amber. Only the
-- skill row changes.
--
-- Features add segments with ns.RegisterBarSegment({
--     key   = "lure",           saved on/off setting
--     label = "Lure timer",     checkbox text on the Bar page
--     name  = "Lure",           the short label on the bar
--     group = "status",         "skill", "status" or "session"
--     order = 20,               position within its group
--     icon  = path or function(info) return path end,   for Icons
--     defaultOff = true,        optional: off until turned on on the Bar page
--     text  = function(settings)
--         return info, active   -- info nil: no row; active true keeps the bar
--     end,                      -- visible even when not fishing
--     options = { { key = "settingKey", label = "..." } },  sub-checkboxes on the Bar page
-- })
-- info = {
--     value    = "8:24",        what Vertical and Horizontal show
--     short    = "8:24",        what Icons shows (default: value)
--     tip      = "Lure 8:24",   the full wording, in the hover tooltip
--     missing  = true,          Icons: greyed icon
--     progress = 0.5,           the skill line under the value
--     pips     = { have, total },
--     countdown = { start, finish }, the skill line runs down from start to finish (GetTime)
--     button   = true,          the lure button sits in this row ("food": the food button)
--     icon     = texture,        a plain icon where a button would sit (Vertical, Horizontal),
--                                and the row's icon in Icons; greyed when missing
--     reserve  = "88:88 !!",     room kept for the widest thing this row can say
--     reserveShort = "88:88",    the same for Icons
-- }
--
-- The bar can hold secure buttons (apply lure, eat food), so its size and
-- visibility only change out of combat.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    bar = true,
    barLocked = false,
    barLayout = "horizontal", -- "vertical", "horizontal" or "icons"
    barScale = 100,  -- percent
    barPoint = nil,  -- { point, relativePoint, x, y }
    barHidden = {},  -- segment key -> true when turned off, false when turned on (for defaultOff items)
})

-- Hal's colours (site/art/ui/mockup)
local C = {
    ink = { 0.937, 0.890, 0.800 }, ink2 = { 0.804, 0.722, 0.580 }, dim = { 0.541, 0.478, 0.388 },
    amber = { 0.949, 0.698, 0.290 }, amber2 = { 1, 0.824, 0.478 },
    oakHi = { 0.431, 0.290, 0.173 }, oakLo = { 0.173, 0.110, 0.059 },
    panelTop = { 0.106, 0.078, 0.051 }, panelBottom = { 0.067, 0.047, 0.031 },
    ring = { 0.416, 0.329, 0.220 }, pipOff = { 0.165, 0.125, 0.094 },
    track = { 0, 0, 0 }, skillFrom = { 0.784, 0.525, 0.173 },
    rule = { 1, 0.886, 0.706 }, -- at 7.5%
}
ns.BAR_COLORS = C
ns.BAR_RED, ns.BAR_GREEN, ns.BAR_AMBER, ns.BAR_INK = "ffff4a3a", "ff4fd13a", "ffffd27a", "ffefe3cc"
local TEX = "Interface\\AddOns\\Reel\\Textures\\"
local GROUP_RANK = { skill = 1, status = 2, session = 3 }

local PLATE = 5
local SCROLL_HOLD = 1 -- seconds a long catch name holds at its start and at its end (Horizontal)               -- oak border around the inner panel
local PAD_L, PAD_T, PAD_R, PAD_B = 7, 7, 9, 7
local CATCH_SECONDS = 5

local segments = {}
local FillCountdown -- the cast countdown (Filling, below)
local bar, inner, catchFrame, measureValue, measureLabel
local items = {}      -- segment key -> drawn parts
local high = {}       -- widths and heights the bar has needed since it was shown
local layout          -- the last layout: rows in order, with their places
local catch           -- { icon, name, color, nth, ends }

function ns.RegisterBarSegment(segment)
    segments[#segments + 1] = segment
    table.sort(segments, function(a, b)
        local ga, gb = GROUP_RANK[a.group or "status"], GROUP_RANK[b.group or "status"]
        if ga ~= gb then return ga < gb end
        return a.order < b.order
    end)
end

local function Hidden(s, seg)
    local h = s.barHidden[seg.key]
    if h == nil then return seg.defaultOff or false end
    return h
end

-- True when the bar item with this key is turned on on the Bar page.
function ns.BarItemOn(key)
    for _, seg in ipairs(segments) do
        if seg.key == key then return not Hidden(ReelDB.settings, seg) end
    end
    return false
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

-- Drawing helpers --------------------------------------------------------------

local function Color(c, a) return c[1], c[2], c[3], a or 1 end

local function Solid(parent, layer, sublevel, c, a)
    local t = parent:CreateTexture(nil, layer, nil, sublevel)
    t:SetColorTexture(Color(c, a))
    return t
end

-- A gradient fill; a client without SetGradient(orientation, color, color) gets the first colour flat.
-- VERTICAL runs from bottom (from) to top (to), HORIZONTAL from left to right.
local function Gradient(t, orientation, from, to, a1, a2)
    t:SetColorTexture(1, 1, 1, 1)
    local ok = CreateColor and pcall(t.SetGradient, t, orientation, CreateColor(Color(from, a1)), CreateColor(Color(to, a2)))
    if not ok then t:SetColorTexture(Color(from, a1)) end
end
ns.BarGradient = Gradient

-- 1px lines on the four sides of a frame, inset px in (negative: outside it).
local function Edge(frame, layer, sublevel, inset, c, a)
    local lines = {}
    for i = 1, 4 do lines[i] = Solid(frame, layer, sublevel, c, a) end
    local top, bottom, left, right = lines[1], lines[2], lines[3], lines[4]
    top:SetPoint("TOPLEFT", inset, -inset); top:SetPoint("TOPRIGHT", -inset, -inset); top:SetHeight(1)
    bottom:SetPoint("BOTTOMLEFT", inset, inset); bottom:SetPoint("BOTTOMRIGHT", -inset, inset); bottom:SetHeight(1)
    left:SetPoint("TOPLEFT", inset, -inset); left:SetPoint("BOTTOMLEFT", inset, inset); left:SetWidth(1)
    right:SetPoint("TOPRIGHT", -inset, -inset); right:SetPoint("BOTTOMRIGHT", -inset, inset); right:SetWidth(1)
    return lines
end
ns.BarEdge = Edge

-- Oiled oak with brass nails in the corners; the window uses the same plate.
function ns.OakPlate(frame)
    local base = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    base:SetAllPoints()
    Gradient(base, "VERTICAL", C.oakLo, C.oakHi)
    local grain = frame:CreateTexture(nil, "BACKGROUND", nil, -7)
    grain:SetAllPoints()
    grain:SetTexture(TEX .. "oak-grain", "REPEAT", "REPEAT")
    grain:SetHorizTile(true)
    grain:SetVertTile(true)
    Edge(frame, "BORDER", -8, 0, { 0, 0, 0 })
    for _, corner in ipairs({ { "TOPLEFT", 2, -2 }, { "TOPRIGHT", -2, -2 }, { "BOTTOMLEFT", 2, 2 }, { "BOTTOMRIGHT", -2, 2 } }) do
        local nail = frame:CreateTexture(nil, "ARTWORK", nil, 7)
        nail:SetTexture(TEX .. "nail")
        nail:SetSize(7, 7)
        nail:SetPoint(corner[1], corner[2], corner[3])
    end
end

local function Font(parent, template, c)
    local fs = parent:CreateFontString(nil, "OVERLAY", template)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetTextColor(Color(c))
    fs:SetShadowColor(0, 0, 0, 1)
    fs:SetShadowOffset(0, -1)
    return fs
end

-- Width of text in a font, colours stripped and every digit an 8, so a timer's width
-- doesn't change as it counts.
local function Stable(m, text)
    if not text or text == "" then return 0 end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%d", "8")
    m:SetText(text)
    return math.ceil(m:GetStringWidth())
end

local function Real(m, text)
    m:SetText(text or "")
    return m:GetStringWidth()
end

-- Never smaller than before while the bar stays up.
local function High(key, value)
    high[key] = math.max(high[key] or 0, value)
    return high[key]
end

local function Ordinal(n)
    local tens, ones = n % 100, n % 10
    if tens >= 11 and tens <= 13 then return n .. "th" end
    return n .. (ones == 1 and "st" or ones == 2 and "nd" or ones == 3 and "rd" or "th")
end

-- The catch -------------------------------------------------------------------

function ns.BarCatchShowing()
    return catch ~= nil and GetTime() < catch.ends
end

-- Called by the journal when fishing loot comes in: the first item and how many of it this
-- character has caught in all (zone and subzone are passed but no longer shown).
function ns.ShowCatch(itemID, link, count)
    local name = link and link:match("%[(.-)%]") or ("item " .. itemID)
    local color = link and link:match("|c(%x%x%x%x%x%x%x%x)") or "ffffffff"
    local GetIcon = C_Item and C_Item.GetItemIconByID or GetItemIcon
    catch = {
        icon = GetIcon and GetIcon(itemID) or "Interface\\Icons\\INV_Misc_QuestionMark",
        name = name, color = color, nth = Ordinal(count),
        ends = GetTime() + CATCH_SECONDS,
    }
    if catchFrame then catchFrame:Show() end
    local ok, err = pcall(ns.UpdateBar)
    -- For /reel debug: what the bar showed for the last catch, from the client itself.
    local f = catchFrame
    ReelDB.debugCatch = {
        time = date("%Y-%m-%d %H:%M:%S"), item = itemID, layout = ReelDB.settings.barLayout,
        barShown = bar and bar:IsShown(), barVisible = bar and bar:IsVisible(),
        barAlpha = bar and bar.GetEffectiveAlpha and bar:GetEffectiveAlpha(),
        catchShown = f and f:IsShown(), catchVisible = f and f:IsVisible(),
        catchAlpha = f and f.GetEffectiveAlpha and f:GetEffectiveAlpha(),
        nameShown = f and f.name:IsShown(), name = f and f.name:GetText(),
        caughtLabel = layout and layout.buttonRow and layout.buttonRow.item.label:GetText(),
        levels = f and string.format("bar %d, panel %d, catch %d", bar:GetFrameLevel(), inner:GetFrameLevel(), f:GetFrameLevel()),
        error = not ok and tostring(err) or nil,
    }
    if not ok then geterrorhandler()(err) end
end

-- Parts --------------------------------------------------------------------------

local function ShowTip(item)
    local info = item.info
    if not info then return end
    GameTooltip:SetOwner(item.frame, "ANCHOR_BOTTOM")
    if item.seg.group == "skill" and ns.BarCatchShowing() then
        GameTooltip:SetText("|c" .. catch.color .. catch.name .. "|r  |cffffd27a" .. catch.nth .. "|r")
    else
        GameTooltip:SetText(info.tip or info.value or item.seg.name or "")
    end
    GameTooltip:Show()
end

local function Item(seg)
    local item = items[seg.key]
    if item then return item end
    item = { seg = seg, pips = {}, mini = {} }
    -- A frame per row for its tooltip; it passes a drag on to the bar.
    local f = CreateFrame("Frame", nil, inner)
    f:SetFrameLevel(inner:GetFrameLevel() + 1)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() if not ReelDB.settings.barLocked then bar:StartMoving() end end)
    f:SetScript("OnDragStop", function() bar:StopMovingOrSizing(); SavePosition() end)
    f:SetScript("OnEnter", function() ShowTip(item) end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    item.frame = f
    item.label = Font(inner, "GameFontHighlightSmall", C.dim)
    item.value = Font(inner, "GameFontHighlight", C.ink)
    item.icon = inner:CreateTexture(nil, "ARTWORK")
    item.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    item.iconEdge = Edge(CreateFrame("Frame", nil, inner), "ARTWORK", 0, 0, C.ring)
    item.iconEdgeFrame = item.iconEdge[1]:GetParent()
    -- the timer wash behind a row's text: amber, 34% fading to 22% left to right
    item.wash = inner:CreateTexture(nil, "ARTWORK", nil, -1)
    Gradient(item.wash, "HORIZONTAL", C.amber, C.amber, 0.34, 0.22)
    item.sep = Solid(inner, "ARTWORK", 0, C.rule, 0.075)
    items[seg.key] = item
    return item
end

local function HideItem(item)
    item.frame:Hide(); item.label:Hide(); item.value:Hide(); item.icon:Hide(); item.iconEdgeFrame:Hide()
    item.wash:Hide(); item.sep:Hide()
    for _, p in ipairs(item.pips) do p:Hide() end
    for _, p in ipairs(item.mini) do p:Hide() end
end

local function At(region, x, y, w, h)
    region:ClearAllPoints()
    region:SetPoint("TOPLEFT", inner, "TOPLEFT", x, y)
    if w then region:SetWidth(w) end
    if h then region:SetHeight(h) end
end

local function IconPath(item)
    if item.info and item.info.icon then return item.info.icon end
    local icon = item.seg.icon
    if type(icon) == "function" then icon = icon(item.info) end
    return icon or "Interface\\Icons\\INV_Misc_QuestionMark"
end

-- Pips: n of them, have lit, from x along a row at y.
local function Pips(item, x, y, have, total)
    for i = 1, math.max(total, #item.pips) do
        local p = item.pips[i]
        if not p and i <= total then
            p = Solid(inner, "ARTWORK", 2, C.pipOff)
            item.pips[i] = p
        end
        if p then
            p:SetShown(i <= total)
            if i <= total then
                At(p, x + (i - 1) * 6, y, 4, 9)
                p:SetColorTexture(Color(i <= have and C.amber or C.pipOff))
            end
        end
    end
end

-- Icons: the pips as a strip along the bottom of the icon.
local function MiniPips(item, x, y, size, have, total)
    local each = total > 0 and (size - 4 - (total - 1)) / total or 0
    for i = 1, math.max(total, #item.mini) do
        local p = item.mini[i]
        if not p and i <= total then
            p = Solid(inner, "OVERLAY", 2, C.pipOff)
            item.mini[i] = p
        end
        if p then
            p:SetShown(i <= total)
            if i <= total then
                At(p, x + 2 + (i - 1) * (each + 1), y - size + 2 + 4, math.max(1, each), 4)
                p:SetColorTexture(Color(i <= have and C.amber or C.pipOff))
            end
        end
    end
end

-- Layout ------------------------------------------------------------------------

local barErrors = {} -- each failing bar item reported once

local function Run(s, seg)
    local ok, info, active = pcall(seg.text, s)
    if not ok then
        if not barErrors[seg.key] then barErrors[seg.key] = true; geterrorhandler()(info) end
        return nil, false
    end
    return info, active
end

-- A row with an icon beside its value: a button, or a plain icon.
local function HasIcon(info) return info.button or info.icon end

-- Which button a row holds: "lure" (info.button true) or the name it gives.
local function ButtonKey(info)
    if not info.button then return nil end
    return info.button == true and "lure" or info.button
end

-- The value's width, with room for the widest form the row has said it can take.
local function TextWidth(info, icons)
    if icons then
        return math.max(Stable(measureValue, info.short or info.value), Stable(measureValue, info.reserveShort or info.reserve))
    end
    return math.max(Stable(measureValue, info.value), Stable(measureValue, info.reserve))
end

local function PipsWidth(info)
    local total = info.pips and math.min(info.pips[2] or 0, 20) or 0
    return total > 0 and (6 + total * 6 - 2) or 0, total
end

-- The height of a line of value text (GameFontHighlight), as the client sets it.
local function TextH()
    measureValue:SetText("Fishing 0")
    return measureValue:GetStringHeight()
end

-- The empty part of that line below the digits' baseline (the numbers have no descenders), as a
-- share of the line. The font file isn't readable offline, so this is estimated from the user's
-- screenshot of the Icons strip (2560x1440, UI at 1x): 5.7px above the icons and 13.3px below the
-- digits; of that 7.6px difference, 3px was the number's reserved line, leaving about 4.6px under
-- the baseline of a 12px line.
local DIGIT_DROP = 4.6 / 12
ns.BAR_DIGIT_DROP = DIGIT_DROP

-- The height of the digits as they show: the line down to its baseline.
local function DigitsH() return TextH() * (1 - DIGIT_DROP) end

-- Vertical: label column, value column. Labels and values in the same font, on one line per
-- row; a row's icon or button centred on that line.
local function LayoutVertical(rows, L)
    local labelW, valueW = 0, 0
    local th = TextH()
    for _, r in ipairs(rows) do
        r.item.label:SetFontObject("GameFontHighlight")
        labelW = math.max(labelW, Stable(measureValue, r.seg.name))
        local pw = PipsWidth(r.info)
        r.textW = High("vt" .. r.seg.key, TextWidth(r.info))
        valueW = math.max(valueW, (HasIcon(r.info) and 28 or 0) + r.textW + pw)
    end
    labelW, valueW = High("vl", labelW), High("vv", valueW)
    local valueX = PAD_L + labelW + 14
    local y, prev = -PAD_T, nil
    for i, r in ipairs(rows) do
        if prev and prev.seg.group ~= "session" and r.seg.group == "session" then
            -- the rule between status and session
            At(r.item.sep, PAD_L, y - 3, nil, 1)
            r.item.sep:SetPoint("RIGHT", inner, "RIGHT", -PAD_R, 0)
            r.item.sep:Show()
            y = y - 3 - 1 - 3 - 3
        end
        local h = HasIcon(r.info) and math.max(22, math.ceil(th)) or math.max(16, math.ceil(th) + 2)
        r.top, r.height = y, h
        At(r.item.frame, PAD_L, y, labelW + 14 + valueW, h)
        -- the text line centred in the row: label and value share its top, so its baseline
        local textY = y - (h - th) / 2
        At(r.item.label, PAD_L, textY)
        r.labelX, r.labelY = PAD_L, textY
        local vx = valueX
        if HasIcon(r.info) then
            r.buttonX, r.buttonY, r.buttonSize = vx, y - (h - 22) / 2, 22
            vx = vx + 28
        end
        r.valueX, r.valueY = vx, textY
        if r.seg.group == "skill" then
            -- the wash covers the whole row across the bar, 2px above and below it
            r.washY, r.washH = y + 2, h + 4
        end
        At(r.item.value, r.valueX, r.valueY)
        r.pipX, r.pipY = vx + r.textW + 6, r.valueY - 3
        y = y - h - (i < #rows and 3 or 0)
        prev = r
    end
    L.width = PAD_L + labelW + 14 + valueW + PAD_R
    L.height = -y + PAD_B
    L.nameLeft, L.nameRight = PAD_L, L.width - PAD_R
end

-- Horizontal: each pair is a cell, label over value; a gap before the session cells.
local function LayoutHorizontal(rows, L)
    local x, prev = PAD_L, nil
    local cellH = 0
    local th = TextH()
    for _, r in ipairs(rows) do
        r.item.label:SetFontObject("GameFontHighlightSmall")
        local pw = PipsWidth(r.info)
        r.textW = High("ht" .. r.seg.key, TextWidth(r.info))
        local vw = (HasIcon(r.info) and 26 or 0) + r.textW + pw
        r.cellW = High("hc" .. r.seg.key, math.max(Stable(measureLabel, r.seg.name), vw))
        r.valueH = HasIcon(r.info) and 20 or 16
        cellH = math.max(cellH, 14 + 1 + r.valueH)
    end
    cellH = High("hh", cellH)
    for i, r in ipairs(rows) do
        local gap = prev and prev.seg.group ~= "session" and r.seg.group == "session"
        if gap then
            x = x + 11 + 3
            At(r.item.sep, x, -PAD_T, 1, cellH)
            r.item.sep:SetColorTexture(Color(C.amber, 0.3))
            r.item.sep:Show()
            x = x + 1 + 3 + 11
        elseif prev then
            x = x + 11
            At(r.item.sep, x, -PAD_T, 1, cellH)
            r.item.sep:SetColorTexture(Color(C.rule, 0.075))
            r.item.sep:Show()
            x = x + 1 + 11
        else
            x = x + 2
        end
        local contentH = 14 + 1 + r.valueH
        local top = -PAD_T - math.floor((cellH - contentH) / 2)
        r.cellX, r.cellTop = x, top
        At(r.item.frame, x, -PAD_T, r.cellW, cellH)
        r.labelX, r.labelY = x, top
        At(r.item.label, x, top)
        local vx, vy = x, top - 15
        if HasIcon(r.info) then
            r.buttonX, r.buttonY, r.buttonSize = vx, vy, 20
            vx = vx + 26
        end
        -- beside an icon, the value is centred on the icon
        r.valueX, r.valueY = vx, HasIcon(r.info) and vy - (20 - th) / 2 or vy
        At(r.item.value, r.valueX, r.valueY)
        if r.seg.group == "skill" then
            -- the wash covers the Fishing cell (its padding too), 3px above and below it, from
            -- 7px left of the cell's box (the first cell's box starts 2px left of its text)
            r.washX, r.washY, r.washW, r.washH = x - 2 - 7, -PAD_T + 3, 2 + r.cellW + 11, cellH + 6
        end
        r.pipX, r.pipY = vx + r.textW + 6, r.valueY - 3
        r.cellRight = x + r.cellW
        x = x + r.cellW
        prev = r
    end
    L.width = x + 11 + PAD_R
    L.height = PAD_T + cellH + PAD_B
end

-- Icons (bar-concepts.html, "B. One row, numbers under"): every icon side by side in one row,
-- each number centred under its icon in equal-width cells; an icon with nothing to say is just
-- the icon. A separator before the session icons. The skill line is a thin bar inside the bottom
-- of the skill icon ("Icons: the skill bar", 2), so every cell is icon over number.
local ICON = 26
local function LayoutIcons(rows, L)
    local x, prev, height = PAD_L, nil, 0
    for _, r in ipairs(rows) do
        r.item.label:SetFontObject("GameFontHighlightSmall")
        r.textW = High("it" .. r.seg.key, TextWidth(r.info, true))
        local valH = 0
        if r.textW > 0 then valH = 2 + 15 end
        r.cellH = ICON + valH
        height = math.max(height, r.cellH)
    end
    height = High("ih", height)
    -- The blocks as they show (the icon's top to the digits' baseline) centred in that height:
    -- the gap above the icons equals the gap below the digits. The bar's size doesn't change.
    local blockH = ICON
    for _, r in ipairs(rows) do if r.textW > 0 then blockH = math.max(blockH, ICON + 2 + DigitsH()) end end
    local top = -PAD_T - (height - blockH) / 2
    -- Every cell as wide as the widest reserved one (bar-concepts.html, "Icons spacing", C), so the
    -- icons are evenly spaced and nothing moves when a number changes.
    local cellW = 34
    for _, r in ipairs(rows) do cellW = math.max(cellW, math.max(ICON, r.textW) + 4) end
    cellW = High("icw", cellW)
    for _, r in ipairs(rows) do
        if prev and prev.seg.group ~= "session" and r.seg.group == "session" then
            x = x + 4 + 4
            At(r.item.sep, x, -PAD_T, 1, height)
            r.item.sep:SetColorTexture(Color(C.amber, 0.25))
            r.item.sep:Show()
            x = x + 1 + 4 + 4
        elseif prev then
            x = x + 4
        end
        r.cellX, r.cellTop, r.cellW = x, -PAD_T, cellW
        r.cellRight = x + cellW
        At(r.item.frame, x, -PAD_T, cellW, height)
        r.iconX, r.iconY = x + math.floor((cellW - ICON) / 2), top
        r.valueX, r.valueY = x + 2, top - ICON - 2
        At(r.item.value, r.valueX, r.valueY, cellW - 4)
        r.item.value:SetJustifyH("CENTER")
        x = x + cellW
        prev = r
    end
    L.width = x + PAD_R
    L.height = PAD_T + height + PAD_B
end

-- Icons (vertical): the same icons in a column, one row each, the number to the right of its
-- icon and centred on it. Rows the same height; the number column as wide as the widest number
-- (with the same reserves as the strip, so it doesn't jump); a rule between the item group and
-- the session group; the same padding on all four sides.
local function LayoutIconsColumn(rows, L)
    local numW = 0
    local th = TextH()
    for _, r in ipairs(rows) do
        r.item.label:SetFontObject("GameFontHighlightSmall")
        r.textW = High("it" .. r.seg.key, TextWidth(r.info, true))
        numW = math.max(numW, r.textW)
    end
    numW = High("icn", numW)
    local valueX = PAD_L + ICON + (numW > 0 and 6 or 0)
    local width = valueX + numW + PAD_L -- the right padding as the left
    local y, prev = -PAD_T, nil
    for i, r in ipairs(rows) do
        if prev and prev.seg.group ~= "session" and r.seg.group == "session" then
            y = y - 4
            At(r.item.sep, PAD_L, y, width - 2 * PAD_L, 1)
            r.item.sep:SetColorTexture(Color(C.amber, 0.25))
            r.item.sep:Show()
            y = y - 1 - 4
        elseif prev then
            y = y - 4
        end
        r.cellX, r.cellTop, r.cellW = PAD_L, y, valueX + numW - PAD_L
        r.cellRight = valueX + numW
        At(r.item.frame, PAD_L, y, r.cellW, ICON)
        r.iconX, r.iconY = PAD_L, y
        -- the digits (top of the line to the baseline) centred on the icon
        r.valueX, r.valueY = valueX, y - (ICON - DigitsH()) / 2
        At(r.item.value, r.valueX, r.valueY)
        y = y - ICON
        prev = r
    end
    L.width = width
    L.height = -y + PAD_T -- the bottom padding as the top
end

-- Fits the catch's name into its space. Never shrinks the font: the name drops its count
-- first, then is cut with an ellipsis at the end of its space.
local function FitText(fs, choices, width, measure)
    measure = measure or measureValue
    for _, t in ipairs(choices) do
        if Real(measure, t) <= width then
            fs:SetWidth(0)
            fs:SetText(t)
            return Real(measure, t)
        end
    end
    fs:SetWidth(math.max(1, width)) -- the client cuts the text with "..."
    fs:SetText(choices[#choices])
    return width
end

-- Icons (vertical) is tabled: kept here but not offered, and a saved choice of it draws as Icons
-- (horizontal). The load test turns it on to keep it working.
ns.ICONS_COLUMN = false

local function LayoutMode(s)
    if s.barLayout == "iconsColumn" and not ns.ICONS_COLUMN then return "icons" end
    return s.barLayout
end

local function Arrange(s, rows)
    for _, item in pairs(items) do HideItem(item) end
    local L = { rows = rows, mode = LayoutMode(s) }
    -- both Icons layouts: icons with numbers, buttons as icons, no labels, the sweep for timers
    L.icons = L.mode == "icons" or L.mode == "iconsColumn"
    for _, r in ipairs(rows) do r.item.value:SetWidth(0); r.item.value:SetJustifyH("LEFT") end
    if L.mode == "vertical" then LayoutVertical(rows, L)
    elseif L.mode == "icons" then LayoutIcons(rows, L)
    elseif L.mode == "iconsColumn" then LayoutIconsColumn(rows, L)
    else L.mode = "horizontal"; LayoutHorizontal(rows, L) end
    if #rows == 0 then L.width, L.height = 60, PAD_T + 16 + PAD_B end
    L.width, L.height = High("w", L.width), High("h", L.height)
    for _, r in ipairs(rows) do
        r.item.frame:Show()
        r.item.value:Show()
        if L.mode ~= "icons" then r.item.value:SetWidth(0); r.item.value:SetJustifyH("LEFT") end
        if not L.icons then r.item.label:SetText(r.seg.name); r.item.label:Show() end
        -- the Fishing label a shade brighter than the others, as drawn
        r.item.label:SetTextColor(Color(r.seg.group == "skill" and C.ink2 or C.dim))
    end
    inner:SetSize(L.width, L.height)
    bar:SetSize(L.width + 2 * PLATE, L.height + 2 * PLATE)
    -- The buttons: in their rows (Vertical, Horizontal) or as the row's icon (Icons).
    L.buttonRows = {}
    for _, r in ipairs(rows) do
        local key = ButtonKey(r.info)
        local button = key and bar.buttons[key]
        if button then
            local x, y, size = r.buttonX, r.buttonY, r.buttonSize
            if L.icons then x, y, size = r.iconX, r.iconY, ICON end
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", inner, "TOPLEFT", x, y)
            button:SetSize(size, size)
            L.buttonRows[key] = r
        end
    end
    L.buttonRow = L.buttonRows.lure
    return L
end

-- Filling ------------------------------------------------------------------------

-- The timer wash on the Fishing row (Vertical) or cell (Horizontal): share of the timer left,
-- from its left edge; nil hides it.
local function Wash(r, share)
    local w = r.item.wash
    if not share or layout.icons then w:Hide(); return end
    local x, width = r.washX or 0, r.washW or layout.width
    w:ClearAllPoints()
    w:SetPoint("TOPLEFT", inner, "TOPLEFT", x, r.washY)
    w:SetSize(math.max(1, width * math.min(1, math.max(0, share))), r.washH)
    w:Show()
end

-- The cast countdown: the part of the cast still to run, from the channel's real times.
FillCountdown = function(r)
    local c = r.info.countdown
    Wash(r, (c.finish - GetTime()) / (c.finish - c.start))
end

-- Icons: the game's cooldown sweep over the skill icon (the fish during a catch), started only
-- when the timer it shows changes so the sweep runs smoothly.
local sweepKey
local function Sweep(r, start, duration)
    local cd = catchFrame.cooldown
    if not (cd and r and start) then
        if cd and sweepKey then cd:Clear() end
        sweepKey = nil
        return
    end
    local key = start .. ":" .. duration
    cd:ClearAllPoints()
    cd:SetPoint("TOPLEFT", inner, "TOPLEFT", r.iconX, r.iconY)
    cd:SetSize(ICON, ICON)
    if key ~= sweepKey then
        cd:SetCooldown(start, duration)
        sweepKey = key
    end
end

-- The rows as last laid out, for the load test.
function ns.BarRows()
    return layout and layout.rows or {}
end

-- The layout as last drawn, for the load test.
function ns.BarLayout()
    return layout or {}
end

-- Every row as "Label: value", then the catch lines, for the load test.
function ns.BarText()
    local out = {}
    if not layout then return "" end
    for _, r in ipairs(layout.rows) do
        if r.item.value:IsShown() then
            out[#out + 1] = (r.seg.name or r.seg.key) .. ": " .. (r.item.value:GetText() or "")
        end
    end
    if catchFrame.label:IsShown() then out[#out + 1] = "catch label: " .. (catchFrame.label:GetText() or "") end
    if catchFrame.name:IsShown() then out[#out + 1] = "catch: " .. (catchFrame.name:GetText() or "") end
    return table.concat(out, "\n")
end

-- The catch in the skill row only: the fish's name and count in place of the skill (cut with
-- "..." at the row's or cell's end), the fish in the lure slot (Icons: the skill icon).
-- No other row or cell changes.
local catchHidden = {} -- what a catch hid, shown again when it ends (in combat too)

-- A catch text in its space, clipped to it and never cut: it starts with its beginning showing
-- and holds; if it's longer than the space it slides left once so its end shows, and holds there
-- before the catch clears. Text that fits doesn't move.
local function Scroll(clip, fs, text, x, y, w, h, measure)
    clip:ClearAllPoints(); clip:SetPoint("TOPLEFT", inner, "TOPLEFT", x, y)
    clip:SetSize(w, h)
    fs:SetWidth(0); fs:SetJustifyH("LEFT"); fs:SetText(text)
    local over = math.max(0, Real(measure, text) - w)
    local elapsed = CATCH_SECONDS - (catch.ends - GetTime())
    local moved = math.min(1, math.max(0, (elapsed - SCROLL_HOLD) / (CATCH_SECONDS - 2 * SCROLL_HOLD)))
    fs:ClearAllPoints(); fs:SetPoint("TOPLEFT", clip, "TOPLEFT", -over * moved, 0)
    clip:Show(); fs:Show()
end

local function DrawCatch(L, caught)
    local nameFs = catchFrame.name
    nameFs:Hide(); catchFrame.nameClip:Hide(); catchFrame.label:Hide(); catchFrame.clip:Hide()
    catchFrame.icon:Hide()
    -- Everything a catch hid comes back (also in combat, when the layout can't redo it).
    for region in pairs(catchHidden) do region:Show() end
    wipe(catchHidden)
    -- Vertical and Horizontal: the lure button's label reads "Lure", or "Caught" beside the
    -- fish (A2 in bar-concepts.html, "Catch: where the fish icon goes").
    local lureRow = not L.icons and L.buttonRow
    if lureRow then
        local label = lureRow.item.label
        label:SetText(lureRow.seg.name)
        label:SetWidth(0); label:SetJustifyH("LEFT")
        label:ClearAllPoints(); label:SetPoint("TOPLEFT", inner, "TOPLEFT", lureRow.labelX, lureRow.labelY)
    end
    local skill = L.rows[1] and L.rows[1].seg.group == "skill" and L.rows[1] or nil
    if not (caught and skill) then return end
    if lureRow then
        local label = lureRow.item.label
        label:SetText("Caught")
        if L.mode == "horizontal" then
            -- centred over the cell; it may run into the cell's padding but not past its dividers
            label:ClearAllPoints()
            label:SetPoint("TOPLEFT", inner, "TOPLEFT", lureRow.cellX - 11, lureRow.labelY)
            label:SetWidth(lureRow.cellW + 22)
            label:SetJustifyH("CENTER")
        end
    end
    local nth = "|c" .. catch.color .. catch.name .. "|r  |cffffd27a" .. catch.nth .. "|r"
    local plain = "|c" .. catch.color .. catch.name .. "|r"
    local mode = L.mode
    local nameX, nameY, nameRight
    if mode == "vertical" then
        -- across the Fishing row, label and value
        nameX, nameY, nameRight = L.nameLeft, skill.valueY, L.nameRight
        skill.item.label:Hide(); catchHidden[skill.item.label] = true
    elseif mode == "icons" then
        nameX, nameY, nameRight = skill.valueX, skill.valueY, skill.cellRight - 2
    elseif mode == "iconsColumn" then
        -- in the number column, cut where it ends
        nameX, nameY, nameRight = skill.valueX, skill.valueY, skill.cellRight
    else
        -- The Fishing cell: the fish's name in the label line, in the label's font, scrolled
        -- in the cell if it's longer; the count in the value line. The cell doesn't widen and
        -- every other cell stays as it is.
        Scroll(catchFrame.clip, catchFrame.label, plain, skill.labelX, skill.labelY, skill.cellW, 15, measureLabel)
        skill.item.label:Hide(); catchHidden[skill.item.label] = true
        nth = "|cffffd27a" .. catch.nth .. "|r"
        plain = nth
        nameX, nameY, nameRight = skill.cellX, skill.valueY, skill.cellRight
    end
    -- No lure button on the bar: the fish goes in front of the name (B in
    -- "Catch: where the fish icon goes"), so a catch always has its icon.
    local inlineIcon = not L.icons and not L.buttonRow
    if inlineIcon then nameX = nameX + 16 + 6 end
    local nameClip, w = catchFrame.nameClip, nameRight - nameX
    if L.icons then
        -- Icons: centred in the skill cell, cut where the cell ends. Icons (vertical): from the
        -- number column's start, cut where it ends.
        nameClip:ClearAllPoints(); nameClip:SetPoint("TOPLEFT", inner, "TOPLEFT", nameX, nameY)
        nameClip:SetSize(w, 18)
        FitText(nameFs, { nth, plain }, w)
        nameFs:SetWidth(w)
        nameFs:SetJustifyH(mode == "icons" and "CENTER" or "LEFT")
        nameFs:ClearAllPoints(); nameFs:SetPoint("TOPLEFT", nameClip, "TOPLEFT", 0, 0)
        nameClip:Show(); nameFs:Show()
    else
        -- Vertical: the name and its count; if they don't fit, the name alone, scrolled if it's
        -- still longer than the row. Horizontal: the count.
        Scroll(nameClip, nameFs, Real(measureValue, nth) <= w and nth or plain, nameX, nameY, w, 18, measureValue)
    end
    skill.item.value:Hide(); catchHidden[skill.item.value] = true
    -- The plain fish in the lure slot (Icons: in the skill icon); no glow in any layout.
    local x, y, size
    if L.icons then
        x, y, size = skill.iconX, skill.iconY, ICON
        skill.item.icon:Hide(); catchHidden[skill.item.icon] = true
    elseif inlineIcon then
        -- centred on the text line
        x, y, size = nameX - 16 - 6, nameY - TextH() / 2 + 8, 16
    elseif L.buttonRow then
        local r = L.buttonRow
        x, y, size = r.buttonX, r.buttonY, r.buttonSize
    end
    if x then
        catchFrame.icon:SetTexture(catch.icon)
        catchFrame.icon:ClearAllPoints(); catchFrame.icon:SetPoint("TOPLEFT", inner, "TOPLEFT", x, y)
        catchFrame.icon:SetSize(size, size)
        catchFrame.icon:Show()
    end
end

local wasShown, lastSettings = false, nil
local forFishing = false -- the bar's up for fishing, not only for the window or Options
local quiet = false      -- combat started with the bar up only for the window: clicks off, fades
local LURE_ONLY = { key = "lureButtonOnly", name = "Lure", group = "status", order = 20 }
function ns.UpdateBar()
    if not bar then return end
    local s = ReelDB.settings
    local rows = {}
    local active = false
    for _, seg in ipairs(segments) do
        if not Hidden(s, seg) then
            local info, segActive = Run(s, seg)
            if segActive then active = true end
            if info then
                local key = ButtonKey(info)
                if key and not (bar.buttons[key] and bar.buttons[key]:IsShown()) then info.button = nil end
                rows[#rows + 1] = { seg = seg, info = info, item = Item(seg) }
            end
        end
    end
    -- The lure button with no Lure row to sit in (the lure timer turned off): a row of its own,
    -- labelled "Lure" with the button as its only value, where the Lure row would be.
    local hasButtonRow = false
    for _, r in ipairs(rows) do if ButtonKey(r.info) == "lure" then hasButtonRow = true end end
    if bar.button and bar.button:IsShown() and not hasButtonRow then
        local at = #rows + 1
        for i, r in ipairs(rows) do
            if GROUP_RANK[r.seg.group or "status"] > 2 or (r.seg.group == "status" and r.seg.order > LURE_ONLY.order) then at = i; break end
        end
        table.insert(rows, at, { seg = LURE_ONLY, info = { value = "", tip = "Apply lure", button = true }, item = Item(LURE_ONLY) })
    end
    local caught = ns.BarCatchShowing()
    if caught then active = true end

    local hasButton = bar.button and bar.button:IsShown()
    if hasButton and ns.PoleEquipped() then active = true end
    local wanted = s.bar and (#rows > 0 or caught)
    forFishing = wanted and (active or ns.RecentlyFishing()) and true or false
    local shown = forFishing or (wanted and not s.barLocked and (ns.WindowShown() or ns.OptionsShown())) or false

    if not InCombatLockdown() then
        if quiet then -- combat is over: the bar takes clicks again
            quiet = false
            bar:SetAlpha(1)
            for _, b in pairs(bar.buttons) do b:EnableMouse(true) end
        end
        -- Sizes start over each time the bar comes up, and when its settings change.
        local sig = LayoutMode(s)
        for _, seg in ipairs(segments) do if not Hidden(s, seg) then sig = sig .. "," .. seg.key end end
        if (shown and not wasShown) or sig ~= lastSettings then wipe(high) end
        wasShown, lastSettings = shown, sig
        bar:SetShown(shown)
        bar:EnableMouse(not s.barLocked)
        if not shown then return end
        layout = Arrange(s, rows)
    else
        -- Up only for the window when combat started: it can't be hidden in combat (its secure
        -- buttons make it protected), so it fades with the window, its clicks already off.
        if quiet then bar:SetAlpha(shown and 1 or 0) end
        if not layout or (quiet and not shown) then return end
        -- In combat the layout can't change; fill the rows it has.
        local byKey = {}
        for _, r in ipairs(rows) do byKey[r.seg.key] = r end
        for _, r in ipairs(layout.rows) do r.info = byKey[r.seg.key] and byKey[r.seg.key].info or r.info end
        rows = layout.rows
    end

    local icons = layout.icons
    for _, r in ipairs(layout.rows) do
        local info, item = r.info, r.item
        item.info = info
        item.value:SetText((icons and info.short) or info.value or "")
        if icons then
            item.icon:SetTexture(IconPath(item))
            item.icon:SetDesaturated(info.missing and true or false)
            item.icon:SetVertexColor(info.missing and 0.45 or 1, info.missing and 0.45 or 1, info.missing and 0.45 or 1)
            local key = ButtonKey(info)
            local isButton = key ~= nil and layout.buttonRows[key] == r
            item.icon:SetShown(not isButton)
            At(item.icon, r.iconX, r.iconY, ICON, ICON)
            item.iconEdgeFrame:ClearAllPoints()
            item.iconEdgeFrame:SetPoint("TOPLEFT", inner, "TOPLEFT", r.iconX - 1, r.iconY + 1)
            item.iconEdgeFrame:SetSize(ICON + 2, ICON + 2)
            for _, e in ipairs(item.iconEdge) do e:SetColorTexture(Color(isButton and C.amber or C.ring)) end
            item.iconEdgeFrame:Show()
        end
        if not icons and info.icon and not ButtonKey(info) and r.buttonX then
            item.icon:SetTexture(info.icon)
            item.icon:SetDesaturated(info.missing and true or false)
            item.icon:SetVertexColor(info.missing and 0.45 or 1, info.missing and 0.45 or 1, info.missing and 0.45 or 1)
            At(item.icon, r.buttonX, r.buttonY, r.buttonSize, r.buttonSize)
            item.icon:Show()
        end
        if r.seg.group == "skill" then
            if info.countdown then FillCountdown(r) else Wash(r, nil) end
        end
        local total = info.pips and math.min(info.pips[2] or 0, 20) or 0
        local have = info.pips and info.pips[1] or 0
        if icons then
            MiniPips(item, r.iconX, r.iconY, ICON, have, total)
            for _, p in ipairs(item.pips) do p:Hide() end
        else
            Pips(item, r.pipX, r.pipY, have, total)
        end
    end
    DrawCatch(layout, caught)
    -- During a catch the row or cell runs the catch timer; Icons sweeps the skill icon (the fish).
    local skill = layout.rows[1] and layout.rows[1].seg.group == "skill" and layout.rows[1]
    if skill and caught then Wash(skill, (catch.ends - GetTime()) / CATCH_SECONDS) end
    if icons and skill then
        local c = skill.info.countdown
        if caught then Sweep(skill, catch.ends - CATCH_SECONDS, CATCH_SECONDS)
        elseif c then Sweep(skill, c.start, c.finish - c.start)
        else Sweep(nil) end
    else
        Sweep(nil)
    end
end

-- Lets a feature put its square button on the bar (placed by the layout in the row whose
-- info.button names it: true or "lure" for the lure button, "food" for the food button).
function ns.SetBarButton(button, key)
    key = key or "lure"
    button:SetParent(bar)
    button:SetSize(22, 22)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", bar, "TOPLEFT", PLATE + PAD_L, -(PLATE + PAD_T))
    button:SetFrameLevel(bar:GetFrameLevel() + 4)
    bar.buttons[key] = button
    if key == "lure" then bar.button = button end
end

local function BuildBar()
    bar = CreateFrame("Frame", "ReelBar", UIParent)
    bar.buttons = {}
    -- The cast countdown moves every frame; only the wash changes.
    bar:SetScript("OnUpdate", function()
        local skill = layout and layout.rows[1]
        if skill and skill.info and skill.info.countdown and not ns.BarCatchShowing() then FillCountdown(skill) end
    end)
    bar:SetSize(100, 40)
    bar:SetFrameStrata("MEDIUM")
    bar:SetMovable(true)
    bar:SetClampedToScreen(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function()
        bar:StopMovingOrSizing()
        SavePosition()
    end)
    ns.OakPlate(bar)

    -- The dark inner panel with its amber hairline.
    inner = CreateFrame("Frame", nil, bar)
    inner:SetPoint("TOPLEFT", PLATE, -PLATE)
    inner:SetFrameLevel(bar:GetFrameLevel() + 1)
    local bg = inner:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    Gradient(bg, "VERTICAL", C.panelBottom, C.panelTop)
    local shade = inner:CreateTexture(nil, "BACKGROUND", nil, -7)
    shade:SetPoint("TOPLEFT"); shade:SetPoint("TOPRIGHT"); shade:SetHeight(8)
    Gradient(shade, "VERTICAL", { 0, 0, 0 }, { 0, 0, 0 }, 0, 0.45)
    Edge(inner, "BORDER", 0, 0, { 0, 0, 0 })
    Edge(inner, "BORDER", 1, 1, C.amber, 0.22)

    measureValue = inner:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    measureValue:Hide()
    measureLabel = inner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    measureLabel:Hide()

    -- The catch: the fish's name in the skill row, its icon, an amber sheen
    -- along the top. Clicks go through to the lure button.
    catchFrame = CreateFrame("Frame", nil, bar)
    catchFrame:SetAllPoints(inner)
    catchFrame:SetFrameLevel(bar:GetFrameLevel() + 6)
    catchFrame:EnableMouse(false)
    -- the name (Horizontal: the count), clipped to its space so a long one can scroll
    catchFrame.nameClip = CreateFrame("Frame", nil, catchFrame)
    catchFrame.nameClip:SetClipsChildren(true)
    catchFrame.nameClip:Hide()
    catchFrame.name = catchFrame.nameClip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    catchFrame.name:SetJustifyH("LEFT"); catchFrame.name:SetWordWrap(false)
    catchFrame.name:SetShadowColor(0, 0, 0, 1); catchFrame.name:SetShadowOffset(0, -1)
    -- Horizontal: the fish's name in the Fishing cell's label line, in the label's font,
    -- clipped to the cell
    catchFrame.clip = CreateFrame("Frame", nil, catchFrame)
    catchFrame.clip:SetClipsChildren(true)
    catchFrame.clip:Hide()
    catchFrame.label = catchFrame.clip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    catchFrame.label:SetJustifyH("LEFT"); catchFrame.label:SetWordWrap(false)
    catchFrame.label:SetShadowColor(0, 0, 0, 1); catchFrame.label:SetShadowOffset(0, -1)
    catchFrame.icon = catchFrame:CreateTexture(nil, "ARTWORK")
    catchFrame.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    -- Icons: the catch timer inside the fish's icon
    -- Icons: the cooldown sweep for the cast countdown and the catch timer, over the icons
    local ok, cd = pcall(CreateFrame, "Cooldown", nil, catchFrame, "CooldownFrameTemplate")
    if ok and cd then
        cd:SetFrameLevel(catchFrame:GetFrameLevel() + 1)
        if cd.SetHideCountdownNumbers then cd:SetHideCountdownNumbers(true) end
        catchFrame.cooldown = cd
    end
    local sheenL = catchFrame:CreateTexture(nil, "OVERLAY")
    local sheenR = catchFrame:CreateTexture(nil, "OVERLAY")
    sheenL:SetPoint("TOPLEFT", 6, 1); sheenL:SetPoint("TOPRIGHT", catchFrame, "TOP", 0, 1); sheenL:SetHeight(1)
    sheenR:SetPoint("TOPLEFT", catchFrame, "TOP", 0, 1); sheenR:SetPoint("TOPRIGHT", -6, 1); sheenR:SetHeight(1)
    Gradient(sheenL, "HORIZONTAL", C.amber2, C.amber2, 0, 1)
    Gradient(sheenR, "HORIZONTAL", C.amber2, C.amber2, 1, 0)
    catchFrame:Hide()
    catchFrame:SetScript("OnUpdate", function()
        local left = catch and catch.ends - GetTime() or 0
        if left <= 0 then
            catchFrame:Hide()
            catch = nil
            ns.UpdateBar()
            return
        end
        local ok, err = pcall(ns.UpdateBar)
        if not ok then
            local d = ReelDB.debugCatch
            if d and not d.laterError then d.laterError = tostring(err); geterrorhandler()(err) end
        end
    end)
end

ns.On("REEL_READY", function()
    local s = ReelDB.settings
    if s.campTimer ~= nil then -- replaced by barHidden.camp in 0.6.0
        if s.campTimer == false then s.barHidden.camp = true end
        s.campTimer = nil
    end
    BuildBar()
    bar:SetScale(s.barScale / 100)
    Restore()
    bar:Hide()
    ns.bar = bar
    C_Timer.NewTicker(1, ns.UpdateBar)
end)

-- Combat is about to start (the last moment the bar can be changed): a bar that's up only for the
-- window or Options stops taking clicks, so it can fade out with them in combat.
ns.On("PLAYER_REGEN_DISABLED", function()
    if not bar or InCombatLockdown() then return end
    ns.UpdateBar()
    if bar:IsShown() and not forFishing then
        quiet = true
        bar:EnableMouse(false)
        for _, b in pairs(bar.buttons) do b:EnableMouse(false) end
    end
end)
ns.On("PLAYER_REGEN_ENABLED", function() ns.UpdateBar() end)
-- The cast countdown starts and stops with the bobber.
ns.On("UNIT_SPELLCAST_CHANNEL_START", function(unit) if unit == "player" then ns.UpdateBar() end end)
ns.On("UNIT_SPELLCAST_CHANNEL_STOP", function(unit) if unit == "player" then C_Timer.After(0, ns.UpdateBar) end end)

ns.RegisterPage({
    name = "Bar",
    order = 90,
    scrolls = true, -- the list can outgrow its column, so the page scrolls itself
    build = function(page)
        local s = ReelDB.settings
        local controls = {}

        -- One checkbox per bar item, so the list can outgrow the window: the page scrolls.
        local scroll = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT")
        scroll:SetPoint("BOTTOMRIGHT", -24, 0)
        local panel = CreateFrame("Frame", nil, scroll)
        panel:SetSize(ns.CONTENT_WIDTH - 24, 1)
        scroll:SetScrollChild(panel)

        local shown = W.Checkbox(panel, "Show fishing bar",
            function() return s.bar end,
            function(v) s.bar = v; ns.UpdateBar() end)
        shown:SetPoint("TOPLEFT")

        local locked = W.Checkbox(panel, "Lock bar position",
            function() return s.barLocked end,
            function(v) s.barLocked = v; ns.UpdateBar() end)
        locked:SetPoint("TOPLEFT", shown, "BOTTOMLEFT", 0, -4)

        local note = W.Note(panel, "While unlocked, the bar stays visible with this page or the R.E.E.L. window open so you can drag it into place.", ns.CONTENT_WIDTH - 54)
        note:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 26, 0)

        local layouts = {
            { value = "vertical", text = "Vertical" },
            { value = "horizontal", text = "Horizontal" },
            { value = "icons", text = "Icons (horizontal)" },
        }
        if ns.ICONS_COLUMN then layouts[#layouts + 1] = { value = "iconsColumn", text = "Icons (vertical)" } end
        local layout = W.Dropdown(panel, "Layout", 120, layouts, function() return LayoutMode(s) end,
           function(v) s.barLayout = v; ns.UpdateBar() end)
        layout:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 60, -40)

        local scale = W.Slider(panel, "Size", 70, 150, 5, "%",
            function() return s.barScale end,
            function(v)
                s.barScale = v
                -- The bar holds a secure button, so it can't be rescaled in combat.
                ns.WhenOutOfCombat(function() if ns.bar then ns.bar:SetScale(s.barScale / 100) end end)
            end)
        scale:SetPoint("TOPLEFT", layout, "BOTTOMLEFT", 0, -14)

        local header = W.Label(panel, "Show on bar", "GameFontNormal")
        header:SetPoint("TOPLEFT", locked, "BOTTOMLEFT", 0, -112)

        controls[1], controls[2], controls[3], controls[4] = shown, locked, layout, scale
        local subOptions = {} -- { checkbox, segment }
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
        local lureNote = W.Note(panel, "A picked lure falls back to your best one when you run out.", ns.CONTENT_WIDTH - 24 - 60)
        lureNote:SetPoint("TOPLEFT", lureChoice, "BOTTOMLEFT", 0, -2)
        anchor = lureNote -- the next row goes under the note

        for _, seg in ipairs(segments) do
            local cb = W.Checkbox(panel, seg.label,
                function() return not Hidden(s, seg) end,
                function(v)
                    if seg.defaultOff then s.barHidden[seg.key] = not v else s.barHidden[seg.key] = (not v) or nil end
                    ns.UpdateBar(); Refresh()
                end)
            Row(cb, 0)
            for _, option in ipairs(seg.options or {}) do
                local sub
                if option.choices then
                    -- a "Use" menu, like the lure's
                    sub = W.Dropdown(panel, option.label, 190, option.choices(),
                        function() return s[option.key] end,
                        function(v) s[option.key] = v; if option.changed then option.changed() end; ns.UpdateBar() end)
                    Row(sub, 60)
                    if option.note then
                        local n = W.Note(panel, option.note, ns.CONTENT_WIDTH - 24 - 60)
                        n:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -2)
                        anchor = n
                    end
                else
                    sub = W.Checkbox(panel, option.label,
                        function() return s[option.key] end,
                        function(v) s[option.key] = v; ns.UpdateBar() end)
                    Row(sub, 24)
                end
                subOptions[#subOptions + 1] = { sub, seg }
            end
        end

        Refresh = function()
            for _, c in ipairs(controls) do c.Refresh() end
            lureChoice:SetActive(s.lureButton)
            for _, entry in ipairs(subOptions) do
                entry[1]:SetActive(not Hidden(s, entry[2]))
            end
            -- The scroll height is the list's height, measured once the layout has settled.
            C_Timer.After(0, function()
                local top, bottom = panel:GetTop(), anchor:GetBottom()
                if top and bottom then panel:SetHeight(top - bottom + 8) end
            end)
        end
        return Refresh
    end,
})
