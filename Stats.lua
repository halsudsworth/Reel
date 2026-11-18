-- The Journal (the window's Journal tab; Direction A in site/art/ui/mockup/index.html): one of
-- Hal's paintings with the tab's title, four tabs, and an Export button at the foot.
--   Fish      every item ever caught, with its icon, a count bar, where it was first caught and
--             what the catch is worth (click a header to sort; click a fish for its first and
--             last catch), then the known fish not caught yet (FishData.lua)
--   Zones     zones, click to open sub-zones, click again for their catches
--   Sessions  sessions grouped by day, with catches per hour, time per catch and value per
--             hour; click one for its catches, listed across the whole width
--   Records   the rare finds in tackle trays (Treasures, Pools and wreckage, Stranglethorn
--             Extravaganza, Rare fish), the derby fish, the feats, and the records (best
--             session, biggest stack, rarest catch, totals, derby coins)
-- Value: Auctionator's last-scanned price where it has one, else the vendor price.
-- A picker in the window's title bar chooses a character with catch data, or all of them.

local _, ns = ...
local L = ns.L
local W = ns.W
local C = W.C

ns.RegisterDefaults({
    statsTab = "fish",
    statsScope = "char", -- "all", or a character key; anything else means the current one
    statsUncaught = true,
})

local ROW_HEIGHT = 18
local INDENT = 14
local GREY = "|cff888888"

local panel, current, newSession, uncaught, banner

-- Day and month names from the string table (date() gives English ones), short forms cut to
-- three letters.
local DAY_KEYS = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" }
local MONTH_KEYS = { "January", "February", "March", "April", "May", "June", "July", "August",
    "September", "October", "November", "December" }
local function ShortMonth(m) return ns.FirstLetters(L[MONTH_KEYS[m]], 3) end

-- "Nov 8", in the order the language writes a date ("8. Nov").
local function ShortDate(t)
    if not t then return "-" end
    local d = date("*t", t)
    return string.format(L["%s %d"], ShortMonth(d.month), d.day)
end

-- A zone name as saved (any language) in this client's language.
local function ZoneText(zone)
    return zone and ns.LocalZone(ns.EnglishZone(zone))
end

local function When(t, zone)
    if not t then return "-" end
    return zone and (ShortDate(t) .. "   " .. ZoneText(zone)) or ShortDate(t)
end

local function ClockTime(t)
    -- the clock format is translated: "7:32 PM" in English, "19:32" in German
    return (date(L["%I:%M %p"], t):gsub("^0", ""))
end

-- 12345 copper -> "1g 23s", the two largest coins.
local function Money(copper)
    copper = math.floor(copper + 0.5)
    local g, sv, c = math.floor(copper / 10000), math.floor(copper % 10000 / 100), copper % 100
    local GOLD, SILVER, COPPER = "|cffffd700g|r", "|cffc7c7cfs|r", "|cffeda55fc|r"
    if g > 0 then return g .. GOLD .. (sv > 0 and (" " .. sv .. SILVER) or "") end
    if sv > 0 then return sv .. SILVER .. (c > 0 and (" " .. c .. COPPER) or "") end
    return c .. COPPER
end

-- One item's price in copper and true when it's an auction price: Auctionator's (its public
-- API, when installed) if it has one, else the vendor price. Poor-quality (grey) items always
-- count at the vendor price: they're sold to vendors, and one silly listing (an Old Teamster's
-- Skull at 20g) shouldn't make a session worth a fortune. quality: the journal's own record of
-- it, for when the client hasn't loaded the item. Nil when the price isn't known yet; the client
-- hands item info out only once it has loaded it.
local GetItemInfoCompat = C_Item and C_Item.GetItemInfo or GetItemInfo

-- A saved link in this client's language: the journal keeps each catch's link as it was caught,
-- so catches from an English session read "[Raw Rockscale Cod]" on a German client. The item's
-- own link is used once the client has it; until then the saved one.
local ENGLISH = GetLocale():find("^en") ~= nil
local function LocalLink(link)
    if ENGLISH then return link end
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if not id then return link end
    local _, current = GetItemInfoCompat(id)
    if current then return current end
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return link
end
-- An item's name in this client's language by its ID, or the English fallback.
-- Subzones in any language, like zones: the journal keeps the client's subzone name, so they're
-- grouped by their English name (AreaData.lua's area IDs) and shown in this client's language.
local subToEnglish = {}
local function AreaName(id)
    if not (C_Map and C_Map.GetAreaInfo) then return end
    local ok, name = pcall(C_Map.GetAreaInfo, id)
    if ok and type(name) == "string" and name ~= "" then return name end
end
local function EnglishSub(zone, sub)
    local ids = ns.AREA_IDS and ns.AREA_IDS[zone]
    if not ids or ids[sub] then return sub end
    local names = subToEnglish[zone]
    if not names then
        names = {}
        for english, id in pairs(ids) do
            local here = AreaName(id)
            if here then names[here] = english end
        end
        subToEnglish[zone] = names
    end
    return names[sub] or sub
end
local function SubText(zone, sub)
    if ENGLISH then return sub end
    local id = ns.AREA_IDS and ns.AREA_IDS[zone] and ns.AREA_IDS[zone][sub]
    return id and AreaName(id) or sub
end

local function LocalName(id, fallback)
    if ENGLISH then return fallback end
    local name = GetItemInfoCompat(id)
    return name or fallback
end
local function Price(id, quality)
    local _, _, q, _, _, _, _, _, _, _, vendor = GetItemInfoCompat(id)
    if q ~= nil then quality = q end
    local api = Auctionator and Auctionator.API and Auctionator.API.v1
    if quality ~= 0 and api and api.GetAuctionPriceByItemID then
        local ok, price = pcall(api.GetAuctionPriceByItemID, "Reel", id)
        if ok and type(price) == "number" and price > 0 then return price, true end
    end
    return vendor
end

-- What an items table is worth in copper, and whether every item's price was known.
local function ItemsValue(items)
    local total, complete = 0, true
    for id, item in pairs(items) do
        local price = Price(id, item.quality)
        if price then total = total + price * item.count else complete = false end
    end
    return total, complete
end

-- Fish tab cell: count x price, marked a (auction) or v (vendor).
local AUCTION_MARK, VENDOR_MARK = " |cff888888a|r", " |cff888888v|r"
local function ValueCell(id, count, quality)
    local price, auction = Price(id, quality)
    if not price then return GREY .. "...|r" end
    if price == 0 then return "-" end
    return Money(price * count) .. (auction and AUCTION_MARK or VENDOR_MARK)
end

local function ItemName(link)
    return link and LocalLink(link):match("%[(.-)%]") or ""
end

local function Arrow(open)
    return GREY .. (open and "- " or "+ ") .. "|r"
end

local function Rate(catches, casts)
    if casts == 0 then return "-" end
    return string.format("%d%%", catches / casts * 100)
end

-- Link of the item caught most often in an items table.
local function Top(items)
    local best
    for _, item in pairs(items) do
        if not best or item.count > best.count then best = item end
    end
    return best and LocalLink(best.link) or "-"
end

local charOf = {} -- session -> character name, in the All characters view

local function MergeItems(into, items)
    for id, item in pairs(items) do
        local m = into[id] or { count = 0, link = item.link, quality = item.quality }
        m.count = m.count + item.count
        into[id] = m
    end
end

-- The chosen character key, "all", or the current character if the saved
-- choice has no data.
local function Scope()
    local scope = ReelDB.settings.statsScope
    if scope == "all" or ReelDB.chars[scope] then return scope end
    return ns.CharKey()
end

-- A zone entry is made on a character's first cast.
local function HasCatches(d)
    return next(d.zones) ~= nil
end

-- Dropdown choices: All characters, the current one, then the rest by name.
local function ScopeOptions()
    local me = ns.CharKey()
    local others = {}
    for key, d in pairs(ReelDB.chars) do
        if key ~= me and HasCatches(d) then others[#others + 1] = key end
    end
    table.sort(others)
    local list = { { value = "all", text = L["All characters"] }, { value = me, text = me } }
    for _, key in ipairs(others) do
        list[#list + 1] = { value = key, text = key }
    end
    return list
end

-- The data the tabs show: one character's, or every character's merged.
local function View()
    wipe(charOf)
    local scope = Scope()
    if scope ~= "all" then return ns.InitData(ReelDB.chars[scope]) end
    local v = { zones = {}, fish = {}, sessions = {}, records = {} }
    for key, d in pairs(ReelDB.chars) do
        ns.InitData(d) -- an older character's table may lack a field
        for asCaught, subs in pairs(d.zones) do
            -- One zone whatever language it was caught in: the journal keeps the client's zone
            -- name, so the same zone fished in English and in German is grouped by its English name.
            local zone = ns.EnglishZone(asCaught)
            v.zones[zone] = v.zones[zone] or {}
            for sub, e in pairs(subs) do
                if sub == asCaught then sub = zone else sub = EnglishSub(zone, sub) end -- no subzone: the zone itself
                local m = v.zones[zone][sub] or { casts = 0, catches = 0, items = {} }
                m.casts = m.casts + e.casts
                m.catches = m.catches + e.catches
                MergeItems(m.items, e.items)
                v.zones[zone][sub] = m
            end
        end
        for id, f in pairs(d.fish) do
            local m = v.fish[id]
            if not m then
                m = { count = 0, link = f.link, quality = f.quality }
                v.fish[id] = m
            end
            m.count = m.count + f.count
            if f.first and (not m.first or f.first < m.first) then
                m.first, m.firstZone = f.first, f.firstZone
            end
            if f.last and (not m.last or f.last > m.last) then m.last = f.last end
        end
        for _, session in ipairs(d.sessions) do
            v.sessions[#v.sessions + 1] = session
            charOf[session] = key
        end
        local stack = d.records.stack
        if stack and (not v.records.stack or stack.qty > v.records.stack.qty) then
            v.records.stack = stack
        end
    end
    table.sort(v.sessions, function(a, b) return a.start < b.start end)
    return v
end

-- Zone the session caught the most in, plus the character in All characters.
local function SessionZone(session)
    local best, most = "-", 0
    for zone, count in pairs(session.zones or {}) do
        if count > most then best, most = zone, count end
    end
    if best ~= "-" then best = ZoneText(best) end
    if charOf[session] then best = best .. "  " .. GREY .. charOf[session] .. "|r" end
    return best
end

-- "Elwynn Forest +5": where to go for it (for your faction, where that's a
-- capital), and how many other zones it's a real catch in.
local function FoundIn(fish)
    local best, others = fish.best, 0
    if type(best) == "table" then best = best[UnitFactionGroup("player")] end
    if not best then return L["Location unknown"] end
    for _, zone in ipairs(fish.zones) do
        if zone ~= best then others = others + 1 end
    end
    return others > 0 and string.format("%s +%d", best, others) or best
end

local GetItemIconCompat = C_Item and C_Item.GetItemIconByID or GetItemIcon
local QUESTION = "Interface\\Icons\\INV_Misc_QuestionMark"

local function IdOf(link)
    return link and tonumber(tostring(link):match("item:(%d+)"))
end

local function IconOf(id)
    return id and GetItemIconCompat(id) or QUESTION
end

-- "8x Raw Rockscale Cod" lines under an open zone or session: icon, count, name.
local function ItemRows(rows, items, indent)
    for _, item in ipairs(ns.SortedItems(items)) do
        rows[#rows + 1] = { kind = "full", icon = IconOf(IdOf(item.link)), text = "|cffefe3cc" .. item.count .. "x|r " .. LocalLink(item.link), indent = indent, link = item.link }
    end
end

-- one and many are format strings with the count's %d ("%d kind", "%d kinds").
local function Plural(n, one, many)
    return string.format(n == 1 and one or many, n)
end

-- Table ----------------------------------------------------------------------------------------
-- columns: list of { title, width (nil: takes what's left), align, sort = key, kind }. kind:
--   nil       text
--   "toggle"  the + / - box of a row that opens
--   "icon"    an item icon (cell: the icon)
--   "bar"     a count with its bar (cell: { count, share 0-1 })
--   "item"    an icon then a name (cell: { icon, text })
-- Rows given to SetRows: { cells = { ... }, link, onClick, indent, toggle = true/false (open),
--   open, sel, grey, heading } or { kind = "full", icon, text, indent, link } (one line across the
--   whole width, so no name is cut) or { kind = "detail", text } (under a chosen row).

local ROW_H, HEAD_H, GAP = 21, 20, 8
local TABLE_W = ns.WINDOW_MAIN_WIDTH - 28 - 22 -- the window's width, the margins and the scrollbar

local function CreateTable(parent, columns, onSort)
    local t = {}
    local fixed, flex = 0, nil
    for _, col in ipairs(columns) do
        if col.width then fixed = fixed + col.width else flex = col end
    end
    if flex then flex.width = TABLE_W - fixed - GAP * (#columns - 1) end
    local x = 0
    for _, col in ipairs(columns) do
        col.x = x
        x = x + col.width + GAP
    end
    t.width = TABLE_W

    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT")
    header:SetSize(TABLE_W, HEAD_H)
    local headers = {}
    for i, col in ipairs(columns) do
        local b = CreateFrame("Button", nil, header)
        b:SetPoint("TOPLEFT", col.x, 0)
        b:SetSize(col.width, HEAD_H)
        local fs = W.Text(b, 9.5, C.dim)
        fs:SetPoint("LEFT", 0, 0)
        fs:SetPoint("RIGHT", 0, 0)
        fs:SetJustifyH(col.align or "LEFT")
        fs:SetText((col.title or ""):upper())
        if col.sort then
            b:SetScript("OnClick", function() onSort(col.sort) end)
            local hl = b:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetColorTexture(W.Hex(C.amber, 0.08))
        end
        b.text = fs
        headers[i] = b
    end
    local line = W.Solid(header, "ARTWORK", C.amber, 0.18)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
    line:SetHeight(1)

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -1)
    scroll:SetPoint("BOTTOMRIGHT", -22, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(TABLE_W, 1)
    scroll:SetScrollChild(child)
    t.child = child

    local pool = {}
    local function Row(i)
        if pool[i] then return pool[i] end
        local row = CreateFrame("Button", nil, child)
        row:SetSize(TABLE_W, ROW_H)
        row.bg = W.Solid(row, "BACKGROUND", C.amber, 0)
        row.bg:SetAllPoints()
        row.mark = W.Solid(row, "BORDER", C.amber, 1)
        row.mark:SetPoint("TOPLEFT"); row.mark:SetPoint("BOTTOMLEFT"); row.mark:SetWidth(3)
        row.rule = W.Solid(row, "BORDER", C.rule, 0.075)
        row.rule:SetPoint("BOTTOMLEFT"); row.rule:SetPoint("BOTTOMRIGHT"); row.rule:SetHeight(1)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(W.Hex(C.amber, 0.06))
        row.cells, row.icons, row.tracks, row.fills = {}, {}, {}, {}
        for c, col in ipairs(columns) do
            if col.kind == "toggle" then
                row.toggle = W.ToggleBox(row)
            elseif col.kind == "icon" or col.kind == "item" then
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
                row.icons[c] = icon
            end
            if col.kind == "bar" then
                row.tracks[c] = W.Solid(row, "ARTWORK", C.track, 1)
                row.fills[c] = W.Solid(row, "ARTWORK", C.amber, 1, 1)
                W.Gradient(row.fills[c], "HORIZONTAL", C.barFrom, 1, C.amber, 1)
            end
            if col.kind ~= "toggle" and col.kind ~= "icon" then
                row.cells[c] = W.Text(row, 11, C.ink)
            end
        end
        row.full = W.Text(row, 11, "ffffff")
        row.fullIcon = row:CreateTexture(nil, "ARTWORK")
        row.fullIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row:SetScript("OnEnter", function(self)
            if self.data and self.data.link then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.data.link)
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if self.data and self.data.onClick then self.data.onClick() end
        end)
        pool[i] = row
        return row
    end

    local function Fill(row, data)
        local kind = data.kind
        local indent = (data.indent or 0) * 16
        row:SetHeight((kind == "full" or kind == "detail") and 20 or data.heading and 24 or ROW_H)
        -- backgrounds: an open row amber-tinted, the chosen one with its amber mark
        row.bg:SetColorTexture(W.Hex(C.amber, (data.sel and 0.14) or (data.open and (data.indent or 0) == 0 and 0.1) or (data.open and 0.06) or ((kind == "full" or kind == "detail") and 0.035) or 0))
        row.mark:SetShown((data.sel or kind == "detail") and true or false)
        row.rule:SetShown(not data.sel)
        row.full:SetShown(kind == "full" or kind == "detail")
        row.fullIcon:SetShown(kind == "full")
        if row.toggle then row.toggle:SetShown(data.toggle ~= nil) end
        for c, col in ipairs(columns) do
            if row.cells[c] then row.cells[c]:SetShown(kind == nil) end
            if row.icons[c] then row.icons[c]:SetShown(false) end
            if row.tracks[c] then row.tracks[c]:SetShown(false); row.fills[c]:SetShown(false) end
        end
        if kind == "full" then
            -- across the whole width from the name column, so nothing is cut
            local x = columns[2].x + 18 + indent
            row.fullIcon:SetTexture(data.icon)
            row.fullIcon:SetSize(16, 16)
            row.fullIcon:ClearAllPoints(); row.fullIcon:SetPoint("LEFT", row, "LEFT", x, 0)
            row.full:ClearAllPoints(); row.full:SetPoint("LEFT", row, "LEFT", x + 22, 0)
            row.full:SetWidth(TABLE_W - x - 22)
            row.full:SetText(data.text)
            return
        elseif kind == "detail" then
            row.full:ClearAllPoints(); row.full:SetPoint("LEFT", row, "LEFT", columns[2].x, 0)
            row.full:SetWidth(TABLE_W - columns[2].x)
            row.full:SetText(data.text)
            return
        end
        for c, col in ipairs(columns) do
            local cell = data.cells[c]
            local fs = row.cells[c]
            local x = col.x
            if col.kind == "toggle" then
                if data.toggle ~= nil then
                    row.toggle:Set(data.toggle)
                    row.toggle:ClearAllPoints(); row.toggle:SetPoint("LEFT", row, "LEFT", x + indent, 0)
                end
            elseif col.kind == "icon" then
                local icon = row.icons[c]
                if cell then
                    icon:SetTexture(cell)
                    icon:SetSize(19, 19)
                    icon:ClearAllPoints(); icon:SetPoint("LEFT", row, "LEFT", x + 2, 0)
                    icon:SetDesaturated(data.grey and true or false)
                    icon:SetVertexColor(data.grey and 0.5 or 1, data.grey and 0.5 or 1, data.grey and 0.5 or 1)
                    icon:Show()
                end
            elseif col.kind == "bar" then
                local count, share = cell and cell[1] or "", cell and cell[2] or 0
                fs:ClearAllPoints(); fs:SetPoint("RIGHT", row, "LEFT", x + col.width, 0)
                fs:SetWidth(30); fs:SetJustifyH("RIGHT")
                fs:SetFont(W.FRIZ, 11, ""); fs:SetTextColor(W.Hex(data.grey and C.grey or C.ink))
                fs:SetText(count)
                local track, fill = row.tracks[c], row.fills[c]
                local w = col.width - 30 - 8
                track:ClearAllPoints(); track:SetPoint("LEFT", row, "LEFT", x, 0); track:SetSize(w, 4); track:SetShown(cell ~= nil)
                fill:ClearAllPoints(); fill:SetPoint("LEFT", row, "LEFT", x, 0)
                fill:SetSize(math.max(1, w * math.min(1, share)), 4)
                fill:SetShown(cell ~= nil and share > 0)
            elseif col.kind == "item" then
                local icon = row.icons[c]
                local text = ""
                if type(cell) == "table" then
                    icon:SetTexture(cell[1])
                    icon:SetSize(16, 16)
                    icon:ClearAllPoints(); icon:SetPoint("LEFT", row, "LEFT", x, 0)
                    icon:SetDesaturated(false); icon:SetVertexColor(1, 1, 1)
                    icon:Show()
                    text = cell[2]
                    x = x + 22
                else
                    text = cell or ""
                end
                fs:ClearAllPoints(); fs:SetPoint("LEFT", row, "LEFT", x, 0)
                fs:SetWidth(col.x + col.width - x); fs:SetJustifyH("LEFT")
                fs:SetText(text)
            else
                local pad = c == 2 and indent or 0
                fs:ClearAllPoints(); fs:SetPoint("LEFT", row, "LEFT", x + pad, 0)
                fs:SetWidth(col.width - pad)
                fs:SetJustifyH(col.align or "LEFT")
                if data.heading and c == 2 then fs:SetFont(W.FRIZ, 11.5, "") else fs:SetFont(W.FRIZ, 11, "") end
                local colour = data.grey and C.grey or (data.heading and C.ink2) or ((data.indent or 0) > 0 and data.dimSub and C.ink2) or C.ink
                fs:SetTextColor(W.Hex(colour))
                fs:SetText(cell ~= nil and tostring(cell) or "")
            end
        end
    end

    function t.SetRows(rows)
        if #rows == 0 then rows = { { cells = { nil, "|cff8a7a63" .. L["Nothing caught yet."] .. "|r" } } } end
        local y = 0
        for i, data in ipairs(rows) do
            local row = Row(i)
            row.data = data
            Fill(row, data)
            row:ClearAllPoints(); row:SetPoint("TOPLEFT", 0, -y)
            y = y + row:GetHeight()
            row:Show()
        end
        for i = #rows + 1, #pool do pool[i]:Hide() end
        child:SetHeight(math.max(1, y))
        t.rows = pool
    end

    -- Marks the sorted column's header with v (high to low) or ^.
    function t.SetSortMark(key, descending)
        for i, col in ipairs(columns) do
            local mark = col.sort == key and (descending and " v" or " ^") or ""
            headers[i].text:SetText((col.title or ""):upper() .. mark)
        end
    end

    return t
end

local function Refresh()
    if not panel or not panel:IsVisible() or not current then return end
    local view = View()
    if current.Rows then
        current.table.SetRows(current.Rows(view))
        if current.sortKey then current.table.SetSortMark(current.sortKey, current.descending) end
    else
        current.Draw(view)
    end
    banner.title:SetText(current.name)
    banner.sub:SetText(current.Summary and current.Summary(view) or "")
end

-- Tabs -----------------------------------------------------------------------------------------

local fishSelected -- the fish (item ID) whose First/Last line is open

local fishTab = {
    key = "fish",
    name = L["Fish"],
    banner = "banner-fish",
    medal = "medal-fish",
    sortKey = "count",
    descending = true,
    columns = {
        { width = 22, kind = "icon" },
        { title = L["Fish"], sort = "name" },
        { title = L["Caught"], width = 150, align = "RIGHT", sort = "count", kind = "bar" },
        { title = L["Zone"], width = 160 },
        { title = L["Value"], width = 76, align = "RIGHT", sort = "value" },
    },
}

function fishTab.OnSort(key)
    if fishTab.sortKey == key then
        fishTab.descending = not fishTab.descending
    else
        fishTab.sortKey, fishTab.descending = key, key ~= "name"
    end
    Refresh()
end

function fishTab.Summary(view)
    local total, kinds = 0, 0
    for _, f in pairs(view.fish) do total, kinds = total + f.count, kinds + 1 end
    return string.format(L["%d caught, %s"], total, Plural(kinds, L["%d kind"], L["%d kinds"]))
end

function fishTab.Rows(view)
    local key, descending = fishTab.sortKey, fishTab.descending
    local idOf = {} -- fish entry -> item ID (kept out of the saved tables)
    local function Value(f)
        if key == "name" then return ItemName(f.link) end
        if key == "value" then return (Price(idOf[f], f.quality) or 0) * f.count end
        return f[key] or 0
    end
    local list, most = {}, 0
    for id, f in pairs(view.fish) do
        idOf[f] = id
        list[#list + 1] = f
        most = math.max(most, f.count)
    end
    table.sort(list, function(a, b)
        local x, y = Value(a), Value(b)
        if x == y then return ItemName(a.link) < ItemName(b.link) end
        if descending then return x > y end
        return x < y
    end)
    local rows = {}
    for _, f in ipairs(list) do
        local id = idOf[f]
        local open = fishSelected == id
        rows[#rows + 1] = {
            cells = { IconOf(id), LocalLink(f.link), { f.count, most > 0 and f.count / most or 0 }, ZoneText(f.firstZone) or "-", ValueCell(id, f.count, f.quality) },
            link = f.link,
            sel = open,
            onClick = function() fishSelected = not open and id or nil; Refresh() end,
        }
        if open then
            rows[#rows + 1] = { kind = "detail", text = L["First"] .. "  |cffefe3cc" .. ShortDate(f.first) .. "|r          " .. L["Last"] .. "  |cffefe3cc" .. ShortDate(f.last) .. "|r          " .. (ZoneText(f.firstZone) or "") }
        end
    end

    -- Known fish not caught yet, by name, after everything caught.
    if ReelDB.settings.statsUncaught then
        local missing = {}
        for id, fish in pairs(ns.FISH) do
            if not view.fish[id] then missing[#missing + 1] = { id = id, fish = fish } end
        end
        table.sort(missing, function(a, b) return a.fish.name < b.fish.name end)
        if #missing > 0 then
            rows[#rows + 1] = { cells = { nil, L["Not caught yet"] .. "  |cff8a7a63" .. #missing .. "|r" }, heading = true }
        end
        for _, m in ipairs(missing) do
            rows[#rows + 1] = {
                cells = { IconOf(m.id), m.fish.name, { 0, 0 }, FoundIn(m.fish), "" },
                link = "item:" .. m.id,
                grey = true,
            }
        end
    end
    return rows
end

local zonesOpen = {} -- zone, or zone .. "\t" .. sub -> true
local zonesTab = {
    key = "zones",
    name = L["Zones"],
    banner = "banner-zones",
    medal = "medal-zones",
    columns = {
        { width = 14, kind = "toggle" },
        { title = L["Zone"] },
        { title = L["Casts"], width = 56, align = "RIGHT" },
        { title = L["Catches"], width = 60, align = "RIGHT" },
        { title = L["Top catch"], width = 210, kind = "item" },
    },
}

local function Toggle(open, key)
    return function()
        open[key] = not open[key] or nil
        Refresh()
    end
end

-- The top catch as icon and name, or a dash.
local function TopCell(items)
    local link = Top(items)
    if link == "-" then return "|cff8a7a63-|r" end
    return { IconOf(IdOf(link)), link }
end

local function ZoneList(view)
    local zones = {}
    for name, subs in pairs(view.zones) do
        local z = { name = name, casts = 0, catches = 0, items = {}, subs = {} }
        for sub, entry in pairs(subs) do
            z.casts = z.casts + entry.casts
            z.catches = z.catches + entry.catches
            for id, item in pairs(entry.items) do
                local merged = z.items[id] or { count = 0, link = item.link }
                merged.count = merged.count + item.count
                z.items[id] = merged
            end
            z.subs[#z.subs + 1] = { name = sub, entry = entry }
        end
        table.sort(z.subs, function(a, b) return a.entry.catches > b.entry.catches end)
        zones[#zones + 1] = z
    end
    table.sort(zones, function(a, b) return a.catches > b.catches end)
    return zones
end

function zonesTab.Summary(view)
    local zones, casts, catches = 0, 0, 0
    for _, z in ipairs(ZoneList(view)) do zones, casts, catches = zones + 1, casts + z.casts, catches + z.catches end
    return Plural(zones, L["%d zone"], L["%d zones"]) .. ", " .. Plural(casts, L["%d cast"], L["%d casts"]) .. ", " .. Plural(catches, L["%d catch"], L["%d catches"])
end

function zonesTab.Rows(view)
    local rows = {}
    for _, z in ipairs(ZoneList(view)) do
        local open = zonesOpen[z.name] and true or false
        rows[#rows + 1] = {
            cells = { nil, ZoneText(z.name), z.casts, z.catches, TopCell(z.items) },
            toggle = open, open = open,
            onClick = Toggle(zonesOpen, z.name),
        }
        if open then
            for _, sub in ipairs(z.subs) do
                local key = z.name .. "\t" .. sub.name
                local e = sub.entry
                local subOpen = zonesOpen[key] and true or false
                rows[#rows + 1] = {
                    cells = { nil, sub.name == z.name and ZoneText(z.name) or SubText(z.name, sub.name), e.casts, e.catches, TopCell(e.items) },
                    indent = 1, dimSub = true, toggle = subOpen, open = subOpen,
                    onClick = Toggle(zonesOpen, key),
                }
                if subOpen then ItemRows(rows, e.items, 2) end
            end
        end
    end
    return rows
end

local sessionsOpen = {} -- session table -> true
local sessionsTab = {
    key = "sessions",
    name = L["Sessions"],
    banner = "banner-sessions",
    medal = "medal-sessions",
    columns = {
        { width = 14, kind = "toggle" },
        { title = L["Started"], width = 98 },
        { title = L["Length"], width = 52, align = "RIGHT" },
        { title = L["Zone"] },
        { title = L["Fish (sessions column)"], width = 34, align = "RIGHT" },
        { title = L["Bonus"], width = 40, align = "RIGHT" },
        { title = L["Per hr"], width = 42, align = "RIGHT" },
        { title = L["Each"], width = 40, align = "RIGHT" },
        { title = L["Value/hr"], width = 62, align = "RIGHT" },
    },
}

-- Catches per hour, time per catch and vendor value per hour, or dashes.
local function PaceCells(s)
    local seconds, perHour, each = ns.SessionPace(s)
    if not seconds then return "-", "-", "-" end
    local value, complete = ItemsValue(s.items)
    local valueCell = complete and Money(value * 3600 / seconds) or GREY .. "...|r"
    return math.floor(perHour + 0.5), ns.FormatTime(each), valueCell
end

-- Newest first, grouped by the day each session started.
local function SessionDays(view)
    local days = {}
    local list = view.sessions
    for i = #list, 1, -1 do
        local s = list[i]
        if s.casts > 0 or s == ns.session then
            local key = date("%Y-%m-%d", s.start)
            local day = days[#days]
            if not day or day.key ~= key then
                day = { key = key, start = s.start, fish = 0, bonus = 0, sessions = {} }
                days[#days + 1] = day
            end
            day.fish = day.fish + s.fish
            day.bonus = day.bonus + (s.bonus or 0)
            day.sessions[#day.sessions + 1] = s
        end
    end
    return days
end

function sessionsTab.Summary(view)
    local days, sessions = SessionDays(view), 0
    for _, day in ipairs(days) do sessions = sessions + #day.sessions end
    return string.format(L["%s in %s"], Plural(sessions, L["%d session"], L["%d sessions"]), Plural(#days, L["%d day"], L["%d days"]))
end

-- "Mon, Nov 17" in the client's language and date order ("Di., 17. Nov.").
local function DayHeading(t)
    local d = date("*t", t)
    return string.format(L["%s, %s %d"], L[DAY_KEYS[d.wday]], ShortMonth(d.month), d.day)
end

function sessionsTab.Rows(view)
    local rows = {}
    for _, day in ipairs(SessionDays(view)) do
        rows[#rows + 1] = {
            cells = { nil, DayHeading(day.start), "", "", day.fish, day.bonus },
            heading = true,
        }
        for _, s in ipairs(day.sessions) do
            local started = ClockTime(s.start)
            if s == ns.session then started = started .. "  |cff40ff40" .. L["now"] .. "|r" end
            local length = s.first and s.last and s.last > s.first and ns.FormatTime(s.last - s.first) or "-"
            local perHour, each, value = PaceCells(s)
            local open = sessionsOpen[s] and true or false
            rows[#rows + 1] = {
                cells = { nil, started, length, SessionZone(s), s.fish, s.bonus or 0, perHour, each, value },
                toggle = open, open = open,
                onClick = Toggle(sessionsOpen, s),
            }
            -- an open session's catches use the whole width, so no name is cut
            if open then ItemRows(rows, s.items, 1) end
        end
    end
    return rows
end

-- Records: the rare finds in tackle trays, the derby fish, the feats and the records -----------

local recordsTab = {
    key = "records",
    name = L["Records"],
    banner = "banner-records",
    medal = "hal",
}

local SLOT, SLOT_GAP = 32, 4
local recordsPick -- the item ID whose line shows under the trays

local function Card(parent, title)
    local f = CreateFrame("Frame", nil, parent)
    local bg = W.Solid(f, "BACKGROUND", C.card)
    bg:SetAllPoints()
    W.Outline(f, "BORDER", "000000", 1, 0)
    W.Outline(f, "BORDER", C.amber, 0.14, 1, 1)
    f.title = W.Text(f, 9.5, C.dim)
    f.title:SetPoint("TOPLEFT", 10, -9)
    f.title:SetText(title:upper())
    return f
end

-- The Records tab's frames, made once per panel.
local function BuildRecords(frame)
    local r = { trays = {}, slots = {} }
    local SIDE = 236
    local left = CreateFrame("Frame", nil, frame)
    left:SetPoint("TOPLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", -(SIDE + 18), 0)
    r.left = left
    local trayW = TABLE_W + 22 - SIDE - 18

    -- the trays: Treasures, Pools and wreckage, Stranglethorn Extravaganza, then Rare fish
    local sections = {}
    for _, section in ipairs(ns.NOTABLE) do sections[#sections + 1] = section end
    local rare = { group = "Rare fish", items = {} }
    for _, fish in ipairs(ns.RARE_FISH) do
        rare.items[#rare.items + 1] = { id = fish.id, name = ns.FISH[fish.id] and ns.FISH[fish.id].name or string.format(L["item %s"], fish.id), note = fish.note }
    end
    sections[#sections + 1] = rare
    local y = -2
    for t, section in ipairs(sections) do
        local tray = { section = section }
        tray.name = W.Text(left, 11.5, C.ink)
        tray.name:SetPoint("TOPLEFT", 0, y)
        tray.name:SetText(L[section.group]) -- FishData's groups are listed in Locale.lua
        tray.count = W.Text(left, 9.5, C.dim)
        tray.count:SetPoint("TOPRIGHT", left, "TOPLEFT", trayW, y - 1)
        tray.count:SetJustifyH("RIGHT")
        y = y - 17
        local perRow = math.floor((trayW - 8 + SLOT_GAP) / (SLOT + SLOT_GAP))
        local lines = math.ceil(#section.items / perRow)
        local box = CreateFrame("Frame", nil, left)
        box:SetPoint("TOPLEFT", 0, y)
        box:SetSize(math.min(#section.items, perRow) * (SLOT + SLOT_GAP) - SLOT_GAP + 8, lines * (SLOT + SLOT_GAP) - SLOT_GAP + 8)
        local bg = W.Solid(box, "BACKGROUND", C.pitch)
        bg:SetAllPoints()
        W.Outline(box, "BORDER", "000000", 1, 0)
        W.Outline(box, "BORDER", C.amber, 0.12, 1, 1)
        tray.slots = {}
        for i, item in ipairs(section.items) do
            local col, line = (i - 1) % perRow, math.floor((i - 1) / perRow)
            local s = CreateFrame("Button", nil, box)
            s:SetSize(SLOT, SLOT)
            s:SetPoint("TOPLEFT", 4 + col * (SLOT + SLOT_GAP), -4 - line * (SLOT + SLOT_GAP))
            local sbg = W.Solid(s, "BACKGROUND", C.slot)
            sbg:SetAllPoints()
            s.icon = s:CreateTexture(nil, "ARTWORK")
            s.icon:SetAllPoints()
            s.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            s.ring = W.Outline(s, "OVERLAY", C.amber2, 1, 0)
            s.count = W.Text(s, 11, "ffffff", "OVERLAY")
            s.count:SetFont(W.FRIZ, 11, "OUTLINE")
            s.count:SetPoint("BOTTOMRIGHT", -2, 2)
            s.item = item
            s:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:" .. item.id)
                GameTooltip:Show()
            end)
            s:SetScript("OnLeave", function() GameTooltip:Hide() end)
            s:SetScript("OnClick", function() recordsPick = item.id; Refresh() end)
            tray.slots[i] = s
            r.slots[#r.slots + 1] = s
        end
        y = y - box:GetHeight() - 12
        r.trays[t] = tray
    end

    -- the chosen find: icon, name, how many and where
    local pick = CreateFrame("Frame", nil, left)
    pick:SetPoint("TOPLEFT", 0, y + 2)
    pick:SetSize(trayW, 44)
    local pbg = W.Solid(pick, "BACKGROUND", C.amber, 0.06)
    pbg:SetAllPoints()
    W.Outline(pick, "BORDER", C.amber, 0.25, 0)
    pick.icon = pick:CreateTexture(nil, "ARTWORK")
    pick.icon:SetSize(32, 32)
    pick.icon:SetPoint("LEFT", 8, 0)
    pick.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    pick.name = W.Text(pick, 11, "ffffff")
    pick.name:SetPoint("TOPLEFT", pick.icon, "TOPRIGHT", 9, -2)
    pick.name:SetWidth(trayW - 60)
    pick.meta = W.Text(pick, 10, C.ink2)
    pick.meta:SetPoint("BOTTOMLEFT", pick.icon, "BOTTOMRIGHT", 9, 2)
    pick.meta:SetWidth(trayW - 60)
    r.pick = pick

    -- the side column: Derby, Feats, Records
    local side = CreateFrame("Frame", nil, frame)
    side:SetPoint("TOPRIGHT", 0, 0)
    side:SetSize(SIDE, 1)
    r.side = side
    local derby = Card(side, L["Derby"])
    derby:SetPoint("TOPLEFT"); derby:SetSize(SIDE, 56)
    derby.icon = derby:CreateTexture(nil, "ARTWORK")
    derby.icon:SetSize(30, 30)
    derby.icon:SetPoint("TOPLEFT", 10, -22)
    derby.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    derby.name = W.Text(derby, 11, "ffffff")
    derby.name:SetPoint("LEFT", derby.icon, "RIGHT", 9, 0)
    derby.big = W.Text(derby, 24, C.amber2)
    derby.big:SetPoint("RIGHT", derby, "RIGHT", -12, -8)
    derby.big:SetJustifyH("RIGHT")
    -- a longer name in another language stops short of the count instead of running under it
    derby.name:SetPoint("RIGHT", derby.big, "LEFT", -8, 0)
    derby.name:SetJustifyH("LEFT")
    derby.name:SetWordWrap(false)
    r.derby = derby

    local feats = Card(side, L["Feats"])
    feats:SetPoint("TOPLEFT", derby, "BOTTOMLEFT", 0, -8)
    feats:SetSize(SIDE, 24 + 3 * 40)
    r.feats = {}
    for i = 1, 3 do
        local f = {}
        local top = -22 - (i - 1) * 40
        if i > 1 then
            local rule = W.Solid(feats, "BORDER", C.rule, 0.075)
            rule:SetPoint("TOPLEFT", 10, top + 4); rule:SetPoint("TOPRIGHT", -10, top + 4); rule:SetHeight(1)
        end
        f.name = W.Text(feats, 12, C.ink)
        f.name:SetPoint("TOPLEFT", 10, top)
        f.value = W.Text(feats, 10.5, C.ink)
        f.value:SetPoint("TOPRIGHT", -10, top)
        f.value:SetJustifyH("RIGHT")
        f.need = W.Text(feats, 10, C.ink2)
        f.need:SetPoint("TOPLEFT", 10, top - 15)
        f.need:SetWidth(SIDE - 20)
        f.track = W.Solid(feats, "ARTWORK", C.track, 1)
        f.track:SetPoint("TOPLEFT", 10, top - 30); f.track:SetSize(SIDE - 20, 4)
        f.fill = W.Solid(feats, "ARTWORK", C.amber, 1, 1)
        f.fill:SetPoint("TOPLEFT", 10, top - 30); f.fill:SetHeight(4)
        W.Gradient(f.fill, "HORIZONTAL", C.barFrom, 1, C.amber, 1)
        r.feats[i] = f
    end

    local records = Card(side, L["Records"])
    records:SetPoint("TOPLEFT", feats, "BOTTOMLEFT", 0, -8)
    -- each record: its label, then the value across the card's full width under it, then when
    -- and where; the totals are short enough to sit beside their labels
    local LAYOUT = { "stacked", "stacked", "stacked", "inline", "inline", "under" }
    local HEIGHT = { stacked = 34, inline = 16, under = 24 }
    local height = 0
    for _, kind in ipairs(LAYOUT) do height = height + HEIGHT[kind] end
    records:SetSize(SIDE, 24 + height)
    r.records = {}
    local top = -22
    for i, kind in ipairs(LAYOUT) do
        local line = {}
        line.label = W.Text(records, 10, C.dim)
        line.label:SetPoint("TOPLEFT", 10, top)
        line.value = W.Text(records, 10.5, C.ink)
        if kind == "inline" then
            line.label:SetWidth(84)
            line.value:SetPoint("TOPLEFT", 96, top)
            line.value:SetWidth(SIDE - 106)
        else
            line.label:SetWidth(SIDE - 20)
            line.value:SetPoint("TOPLEFT", 10, top - 12)
            line.value:SetWidth(SIDE - 20)
        end
        line.when = W.Text(records, 9, C.dim)
        line.when:SetPoint("TOPLEFT", 10, top - 24)
        line.when:SetWidth(SIDE - 20)
        line.when:SetShown(kind == "stacked")
        r.records[i] = line
        top = top - HEIGHT[kind]
    end
    return r
end

function recordsTab.Draw(view)
    local r = recordsTab.ui
    -- the trays
    local firstCaught, firstAny
    for _, tray in ipairs(r.trays) do
        local have = 0
        for _, s in ipairs(tray.slots) do
            local f = view.fish[s.item.id]
            s.icon:SetTexture(IconOf(s.item.id))
            s.icon:SetDesaturated(not f)
            s.icon:SetVertexColor(f and 1 or 0.5, f and 1 or 0.5, f and 1 or 0.5)
            s.count:SetText(f and f.count or "")
            if f then have = have + 1; firstCaught = firstCaught or s.item.id end
            firstAny = firstAny or s.item.id
            for _, line in ipairs(s.ring) do line:SetShown(recordsPick == s.item.id) end
        end
        tray.count:SetText(string.format(L["%d of %d"], have, #tray.slots))
    end
    -- the chosen find (the first one caught until one is clicked)
    local id = recordsPick or firstCaught or firstAny
    if not recordsPick then
        for _, s in ipairs(r.slots) do for _, line in ipairs(s.ring) do line:SetShown(s.item.id == id) end end
    end
    local item
    for _, s in ipairs(r.slots) do if s.item.id == id then item = s.item end end
    if item then
        local f = view.fish[id]
        r.pick.icon:SetTexture(IconOf(id))
        r.pick.icon:SetDesaturated(not f)
        r.pick.name:SetText(f and LocalLink(f.link) or ("|cff8f8577" .. LocalName(id, item.name) .. "|r"))
        r.pick.meta:SetText(f and ("|cffffd27a" .. f.count .. "|r  ·  " .. L[item.note] .. (f.firstZone and ("  ·  " .. ZoneText(f.firstZone)) or "")) or (L["Not caught yet"] .. "  ·  " .. L[item.note]))
    end

    -- the derby fish and how many of it
    local tasty = view.fish[19807]
    r.derby.icon:SetTexture(IconOf(19807))
    r.derby.name:SetText(tasty and LocalLink(tasty.link) or LocalName(19807, "Speckled Tastyfish"))
    r.derby.big:SetText(tasty and tasty.count or 0)

    -- feats worked out from the journal
    local zonesFished, bestSession = 0, 0
    for _, subs in pairs(view.zones) do
        for _, entry in pairs(subs) do
            if entry.catches > 0 then zonesFished = zonesFished + 1; break end
        end
    end
    for _, s in ipairs(view.sessions) do
        if (s.catches or 0) > bestSession then bestSession = s.catches end
    end
    local complete = {} -- zones where every fish in FishData has been caught there
    -- The journal keeps zones in the client's language, FishData in English.
    local caughtIn = {}
    for zone, subs in pairs(view.zones) do
        local english = ns.EnglishZone(zone)
        caughtIn[english] = caughtIn[english] or {}
        for _, entry in pairs(subs) do
            for fid in pairs(entry.items) do caughtIn[english][fid] = true end
        end
    end
    for zone, want in pairs(ns.ZoneFish()) do
        local caught = caughtIn[zone] or {}
        local missing = 0
        for fid in pairs(want) do if not caught[fid] then missing = missing + 1 end end
        if missing == 0 then complete[#complete + 1] = ns.LocalZone(zone) end
    end
    table.sort(complete)
    local function Feat(f, name, need, have, target, done)
        f.name:SetText(name)
        f.need:SetText(need)
        if done then
            f.value:SetText("|cff4fd13a" .. L["Done"] .. "|r")
        elseif target then
            f.value:SetText(have .. "/" .. target)
        else
            f.value:SetText("|cff8a7a63" .. L["Not yet"] .. "|r")
        end
        f.track:SetShown(target ~= nil)
        f.fill:SetShown(target ~= nil and have > 0)
        if target then f.fill:SetWidth(math.max(1, (f.track:GetWidth()) * math.min(1, have / target))) end
    end
    Feat(r.feats[1], L["Well travelled"], L["Fish in ten zones"], math.min(zonesFished, 10), 10, zonesFished >= 10)
    Feat(r.feats[2], L["Long evening"], L["100 catches in one session"], math.min(bestSession, 100), 100, bestSession >= 100)
    Feat(r.feats[3], L["Completionist"], #complete > 0 and string.format(L["Every fish in %s"], table.concat(complete, ", ")) or L["Catch every fish listed for a zone"], nil, nil, #complete > 0)

    -- the records
    local casts, catches = 0, 0
    for _, subs in pairs(view.zones) do
        for _, entry in pairs(subs) do
            casts = casts + entry.casts
            catches = catches + entry.catches
        end
    end
    local lines = {}
    local best
    for _, s in ipairs(view.sessions) do
        if s.fish > 0 and (not best or s.fish > best.fish) then best = s end
    end
    lines[1] = { L["Best session"], best and string.format(L["%s fish"], best.fish) or "-", best and When(best.start, SessionZone(best)) }
    local stack = view.records.stack
    lines[2] = { L["Biggest stack"], stack and (stack.qty .. "x " .. LocalLink(stack.link)) or "-", stack and When(stack.time, stack.zone) }
    local rarest
    for _, f in pairs(view.fish) do
        local q, rq = f.quality or 0, rarest and (rarest.quality or 0)
        if not rarest or q > rq or (q == rq and f.count < rarest.count) then rarest = f end
    end
    lines[3] = { L["Rarest catch"], rarest and LocalLink(rarest.link) or "-", rarest and When(rarest.first, rarest.firstZone) }
    lines[4] = { L["Total casts"], casts }
    lines[5] = { L["Total catches"], string.format(L["%d (%s of casts)"], catches, Rate(catches, casts)) }
    local scope = Scope()
    local earned, spent, held = ns.DerbyCoins(scope == "all" and ReelDB.chars or { ReelDB.chars[scope] })
    lines[6] = { L["Derby coins"], string.format(L["%d earned, %d spent, %d held"], earned, spent, held) }
    for i, line in ipairs(r.records) do
        line.label:SetText(lines[i][1])
        -- item names without the link's brackets, so they fit the card
        line.value:SetText((tostring(lines[i][2]):gsub("|h%[(.-)%]|h", "|h%1|h")))
        line.when:SetText(lines[i][3] or "")
    end
end

local TABS = { fishTab, zonesTab, sessionsTab, recordsTab }

local function Select(tab)
    current = tab
    ReelDB.settings.statsTab = tab.key
    for _, t in ipairs(TABS) do
        t.frame:SetShown(t == tab)
        t.button:SetChosen(t == tab)
    end
    newSession:SetShown(tab == sessionsTab)
    uncaught:SetShown(tab == fishTab)
    banner.paint:SetTexture(W.TEX .. tab.banner)
    banner.medal:SetTexture(W.TEX .. tab.medal)
    Refresh()
end

-- Page -----------------------------------------------------------------------------------------

local BANNER_H, TABS_H, TOOLS_H, FOOT_H = 78, 27, 28, 34
local picker

ns.RegisterPage({
    name = "Stats",
    order = 10,
    place = "journal",
    build = function(p)
        panel = p

        -- the painting with the tab's title and a line from the journal
        banner = CreateFrame("Frame", nil, panel)
        banner:SetPoint("TOPLEFT")
        banner:SetPoint("TOPRIGHT")
        banner:SetHeight(BANNER_H)
        banner.paint = banner:CreateTexture(nil, "BACKGROUND")
        banner.paint:SetAllPoints()
        banner.paint:SetTexCoord(0, 1, 0, 110 / 128)
        -- every tab's medal in one spot, so the title doesn't move between tabs (Events too)
        banner.medal = banner:CreateTexture(nil, "ARTWORK")
        banner.medal:SetSize(ns.MEDAL_SIZE, ns.MEDAL_SIZE)
        banner.medal:SetPoint("BOTTOMLEFT", ns.MEDAL_X, ns.MEDAL_Y)
        banner.title = W.Text(banner, 22, "ffffff")
        banner.title:SetPoint("BOTTOMLEFT", ns.BANNER_TITLE_X, ns.BANNER_TITLE_Y)
        banner.sub = W.Text(banner, 10.5, C.ink2)
        banner.sub:SetPoint("TOPLEFT", banner.title, "BOTTOMLEFT", 0, -4)

        -- the four tabs
        local strip = CreateFrame("Frame", nil, panel)
        strip:SetPoint("TOPLEFT", banner, "BOTTOMLEFT")
        strip:SetPoint("TOPRIGHT", banner, "BOTTOMRIGHT")
        strip:SetHeight(TABS_H)
        local stripLine = W.Solid(strip, "BORDER", C.amber, 0.28)
        stripLine:SetPoint("BOTTOMLEFT"); stripLine:SetPoint("BOTTOMRIGHT"); stripLine:SetHeight(1)
        local x = 14
        for _, tab in ipairs(TABS) do
            tab.button = W.OakTab(strip, tab.name, 11.5, 22, function() Select(tab) end)
            tab.button:SetPoint("BOTTOMLEFT", x, 1)
            x = x + tab.button:GetWidth() + 3
        end

        -- the foot: Export
        local foot = CreateFrame("Frame", nil, panel)
        foot:SetPoint("BOTTOMLEFT")
        foot:SetPoint("BOTTOMRIGHT")
        foot:SetHeight(FOOT_H)
        local footBg = W.Solid(foot, "BACKGROUND", C.foot)
        footBg:SetAllPoints()
        local footLine = W.Solid(foot, "BORDER", C.amber, 0.22)
        footLine:SetPoint("TOPLEFT"); footLine:SetPoint("TOPRIGHT"); footLine:SetHeight(1)
        local export = W.OakButton(foot, L["Export"], function() ns.ShowExport() end)
        export:SetPoint("LEFT", 14, 0)
        panel.export = export
        local hint = W.Text(foot, 10.5, C.dim)
        hint:SetPoint("RIGHT", -14, 0)
        hint:SetJustifyH("RIGHT")
        hint:SetText(L["Paste it on |cffcdb894halsudsworth.com|r"])

        -- each tab's table (Records: its trays and cards)
        for _, tab in ipairs(TABS) do
            tab.frame = CreateFrame("Frame", nil, panel)
            local tools = (tab == sessionsTab or tab == fishTab) and TOOLS_H or 0
            tab.frame:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 14, -8 - tools)
            tab.frame:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -14, 8)
            if tab.columns then
                tab.table = CreateTable(tab.frame, tab.columns, function(key) tab.OnSort(key) end)
            else
                tab.ui = BuildRecords(tab.frame)
            end
        end

        newSession = W.OakButton(panel, L["Start new session"], function() ns.StartSession() end)
        newSession:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 14, -7)

        uncaught = W.OakCheck(panel, L["Show fish I haven't caught yet"],
            function() return ReelDB.settings.statsUncaught end,
            function(v) ReelDB.settings.statsUncaught = v; Refresh() end)
        uncaught:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 14, -11)
        uncaught.Refresh()

        -- the character picker, in the window's title bar (made once)
        if not picker then
            local slot = ns.WindowSlot and ns.WindowSlot()
            picker = W.Picker(slot or panel, 150, ScopeOptions, Scope,
                function(v) ReelDB.settings.statsScope = v; Refresh() end)
            picker:SetPoint("RIGHT", 0, 0)
        end
        picker.Refresh()

        local saved = ReelDB.settings.statsTab
        for _, tab in ipairs(TABS) do
            if tab.key == saved then current = tab end
        end
        return function() picker.Refresh(); Select(current or fishTab) end
    end,
})

ns.On("REEL_DATA_CHANGED", Refresh)

-- An item's price or name wasn't loaded when a tab was drawn: draw it again once
-- the client has it (one redraw for a burst of items).
local redrawQueued = false
ns.On("GET_ITEM_INFO_RECEIVED", function()
    if redrawQueued or not (current and panel and panel:IsVisible()) then return end
    redrawQueued = true
    C_Timer.After(0.2, function() redrawQueued = false; Refresh() end)
end)

-- Bar item: "Zone fish 3/7", how many of the fish known for this zone (more
-- than a trace on Wowhead) this character has caught here, with a pip for each
-- at the right end of the bar's foot. With a pole only.
ns.RegisterBarSegment({
    key = "zoneFish",
    label = L["Fish in this zone"],
    name = L["Zone fish"],
    group = "session",
    order = 45,
    icon = "Interface\\Icons\\INV_Misc_Spyglass_01",
    text = function()
        if not ns.PoleEquipped() then return end
        local zone = GetZoneText()
        local caught = {}
        for _, entry in pairs(ns.Data().zones[zone] or {}) do
            for id in pairs(entry.items) do caught[id] = true end
        end
        local have, total = 0, 0
        for id in pairs(ns.ZoneFish()[ns.EnglishZone(zone)] or {}) do
            total = total + 1
            if caught[id] then have = have + 1 end
        end
        if total == 0 then return end
        local t = string.format("%d/%d", have, total)
        local value = have == total and ("|cff4fd13a" .. t .. "|r") or t
        return { value = value, tip = string.format(L["Zone fish %s"], t), pips = { have, total } }
    end,
})
