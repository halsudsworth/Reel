-- The Journal (the window's Journal tab; Direction A in site/art/ui/mockup/index.html): one of
-- Hal's paintings with the tab's title, five tabs, and an Export button at the foot.
--   Fish      every item ever caught, with its icon, a count bar, where it was first caught and
--             what the catch is worth (click a header to sort; click a fish for its first and
--             last catch), then the known fish not caught yet (FishData.lua)
--   Zones     zones, click to open sub-zones, click again for their catches
--   Sessions  sessions grouped by day, with catches per hour, time per catch and value per
--             hour; click one for its catches, listed across the whole width
--   Collection  categories on the left: Summary (heaviest trophy, the derby count, recent finds,
--               a bar per collection), the trophy wall, and the Treasures, Bloated fish, Pools and
--               wreckage and Stranglethorn Extravaganza trays with where to look for each
--   Feats       categories on the left: Summary (four records, the last feats done, a bar per
--               category), then each category's feats, each done (with the day) or how far along;
--               click a feat to open what it takes
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
    collectionCategory = "summary", -- the category chosen on the Collection tab
    featsCategory = "summary",      -- and on the Feats tab
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
-- A white item's link drawn in the table's cream, so it sits with the other text; green, blue
-- and purple keep their colour.
local function Cream(link)
    return (link:gsub("^|cffffffff", "|cffefe3cc"):gsub("^|cnIQ1:", "|cffefe3cc"))
end
-- An item's link as this client has it (a saved link keeps the language it was caught in).
local function LocalLink(link)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    if not id then return link end
    local _, current = GetItemInfoCompat(id)
    if current then return Cream(current) end
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(id) end
    return Cream(link)
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
    if names[sub] then return names[sub] end
    -- caught under another client language
    local foreign = ns.AREA_FOREIGN and ns.AREA_FOREIGN[zone]
    return foreign and foreign[sub] or sub
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

-- One zone whatever language it was caught in: the journal keeps the client's zone and subzone
-- names, so the same water fished in English and in German is grouped by its English names.
local function AddZones(into, zones)
    for asCaught, subs in pairs(zones) do
        local zone = ns.EnglishZone(asCaught)
        into[zone] = into[zone] or {}
        for sub, e in pairs(subs) do
            if sub == asCaught then sub = zone else sub = EnglishSub(zone, sub) end -- no subzone: the zone itself
            local m = into[zone][sub] or { casts = 0, catches = 0, items = {} }
            m.casts = m.casts + e.casts
            m.catches = m.catches + e.catches
            MergeItems(m.items, e.items)
            into[zone][sub] = m
        end
    end
end

-- The data the tabs show: one character's, or every character's merged.
local function View()
    wipe(charOf)
    local scope = Scope()
    if scope ~= "all" then
        -- the character's own table, with its zones grouped by language (a copy: the saved table stays as it is)
        local d = ns.InitData(ReelDB.chars[scope])
        local v = setmetatable({ zones = {} }, { __index = d })
        AddZones(v.zones, d.zones)
        return v
    end
    local v = { zones = {}, fish = {}, sessions = {}, records = {} }
    for key, d in pairs(ReelDB.chars) do
        ns.InitData(d) -- an older character's table may lack a field
        AddZones(v.zones, d.zones)
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
    banner.count:SetText(current.Count and current.Count(view) or "")
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
        { width = 22, kind = "toggle" }, -- as wide as Fish's icon column, so every table's first heading lines up
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
        { width = 22, kind = "toggle" }, -- as wide as Fish's icon column, so every table's first heading lines up
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

-- Collection and Feats -------------------------------------------------------------------------
-- Both laid out like Blizzard's achievement window (mockups G and H in
-- site/art/ui/mockup/records-concepts.html): a list of categories on the left, each with its count
-- and a slim bar, and the chosen category on the right, which scrolls when it runs long. Each tab
-- keeps its chosen category in ReelDB.settings (collectionCategory, featsCategory).

local collectionTab = {
    key = "collection",
    name = L["Collection"],
    banner = "banner-records",
    medal = "hal",
    setting = "collectionCategory",
    navWidth = 206, -- wide enough for "Stranglethorn Extravaganza" on two lines
}
local featsTab = {
    key = "feats",
    name = L["Feats"],
    banner = "banner-feats",
    medal = "medal-feats",
    setting = "featsCategory",
    navWidth = 206, -- the same as Collection, so the column doesn't shift between the two
}

local AMBER = "|cffffd27a"
local DOT = " · "
local FRAME_W = ns.WINDOW_MAIN_WIDTH - 28 -- a tab's frame: the panel less its margins
local NAV_GAP, BAR_W = 18, 22             -- list to pane (a rule halfway); the pane's scrollbar
local TASTYFISH = 19807

-- "Nov 13 · Hillsbrad Foothills", or the date alone.
local function DateZone(t, zone)
    return ShortDate(t) .. (zone and (DOT .. ZoneText(zone)) or "")
end

-- A link's text without its brackets, in the item's colour, so it fits a narrow line.
local function Bare(link)
    return (LocalLink(link):gsub("|h%[(.-)%]|h", "|h%1|h"))
end

-- An item's English name from FishData (fish, other catches, tray items), and its name in this
-- client's language once the client has it.
local trayItem = {}
for _, section in ipairs(ns.NOTABLE) do
    for _, item in ipairs(section.items) do trayItem[item.id] = item end
end
local function NameOf(id)
    local e = ns.FISH[id] or ns.CATCHES[id] or trayItem[id]
    return LocalName(id, e and e.name or ("item:" .. id))
end

local function ShowLines(lines, shown)
    for _, line in ipairs(lines) do line:SetShown(shown) end
end

-- An item's tooltip, with where to look and the tray's note under it for a tray item.
local function ItemTip(self)
    local item = self.item
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink("item:" .. item.id)
    if item.where then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(string.format(L["Where to look: %s"], L[item.where]), 1, 0.82, 0)
        GameTooltip:AddLine(L[item.note], 1, 1, 1, true)
    end
    GameTooltip:Show()
end
local function HideTip() GameTooltip:Hide() end

-- The trophy fish by kind, lightest first, worked out from FishData's "26 Pound Catfish" names.
-- The kinds' names are in Locale.lua.
local TROPHY_KINDS = { "Catfish", "Mud Snapper", "Lobster", "Salmon", "Redgill", "Yellowtail", "Mightfish" }
local trophyKinds -- list of { kind, list = { { id, pounds, name }, ... } }
local function TrophyKinds()
    if trophyKinds then return trophyKinds end
    local byKind = {}
    for id, item in pairs(ns.CATCHES) do
        if item.kind == "trophy" then
            local pounds, kind = item.name:match("^(%d+) Pound (.+)$")
            if pounds then
                byKind[kind] = byKind[kind] or {}
                table.insert(byKind[kind], { id = id, pounds = tonumber(pounds), name = item.name })
            end
        end
    end
    trophyKinds = {}
    local known = {}
    for _, kind in ipairs(TROPHY_KINDS) do
        known[kind] = true
        if byKind[kind] then trophyKinds[#trophyKinds + 1] = { kind = kind, list = byKind[kind] } end
    end
    -- a kind FishData gains later still gets a row, after these
    local extra = {}
    for kind in pairs(byKind) do if not known[kind] then extra[#extra + 1] = kind end end
    table.sort(extra)
    for _, kind in ipairs(extra) do trophyKinds[#trophyKinds + 1] = { kind = kind, list = byKind[kind] } end
    for _, k in ipairs(trophyKinds) do table.sort(k.list, function(a, b) return a.pounds < b.pounds end) end
    return trophyKinds
end

-- The wall as it stands: each kind's catches and its heaviest caught, the heaviest of all, and the
-- one Hal points at next: the lightest still missing in the kind with the most caught.
local function Wall(view)
    local wall = { have = 0, total = 0, kinds = {} }
    local nearest
    for _, k in ipairs(TrophyKinds()) do
        local row = { kind = k.kind, list = k.list, have = 0 }
        for _, t in ipairs(k.list) do
            if view.fish[t.id] then
                row.have = row.have + 1
                row.top = t -- lightest first, so the last one caught is the heaviest
            elseif not row.missing then
                row.missing = t
            end
        end
        wall.have, wall.total = wall.have + row.have, wall.total + #k.list
        if row.top and (not wall.top or row.top.pounds > wall.top.pounds) then wall.top = row.top end
        if row.missing and (not nearest or row.have > nearest.have) then nearest = row end
        wall.kinds[#wall.kinds + 1] = row
    end
    wall.next = nearest and nearest.missing
    return wall
end

function collectionTab.Summary(view)
    local wall = Wall(view)
    if not wall.next then return L["Every trophy is on the wall."] end
    return string.format(L["The %s is still out there."], LocalName(wall.next.id, wall.next.name))
end

-- A weight on the ladder: brass when caught, ringed when it's the kind's heaviest.
local TAG_W, TAG_H, TAG_GAP = 34, 20, 4
local function Tag(parent)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(TAG_W, TAG_H)
    b.off = W.Solid(b, "BACKGROUND", C.rule, 0.03)
    b.off:SetAllPoints()
    b.offEdge = W.Outline(b, "BORDER", C.rule, 0.1, 0)
    b.on = W.Solid(b, "BACKGROUND", "a8783a", 1, 1)
    b.on:SetAllPoints()
    W.Gradient(b.on, "VERTICAL", "a8783a", 1, "dcb46c", 1)
    b.onEdge = W.Outline(b, "BORDER", "000000", 1, 0)
    b.ring = W.Outline(b, "OVERLAY", C.amber2, 1, -1)
    b.text = W.Text(b, 9.5, "6b5f50")
    b.text:SetPoint("CENTER", 0, 0)
    b:SetScript("OnEnter", ItemTip)
    b:SetScript("OnLeave", HideTip)
    return b
end

local function SetTag(b, t, caught, top)
    b.text:SetText(string.format(L["%d lb"], t.pounds))
    b.item = { id = t.id }
    b.off:SetShown(not caught); ShowLines(b.offEdge, not caught)
    b.on:SetShown(caught); ShowLines(b.onEdge, caught)
    ShowLines(b.ring, top)
    b.text:SetTextColor(W.Hex(caught and "2b1a0a" or "6b5f50"))
    b.text:SetShadowColor(0, 0, 0, caught and 0 or 1)
    b.caught, b.top = caught, top
end

-- Drawing ----------------------------------------------------------------------------------------
-- A pane is drawn again on every refresh, from pooled pieces: Get(kind) hands out a spare one (or
-- makes one), Reset() puts back everything handed out since the last Reset. Whoever takes a piece
-- sets everything about it that can differ between uses.

local MAKERS = {
    text = function(p) return W.Text(p, 11, C.ink) end,
    solid = function(p) return p:CreateTexture(nil, "BORDER") end,
    fade = function(p) return p:CreateTexture(nil, "BACKGROUND") end,
    icon = function(p) return p:CreateTexture(nil, "ARTWORK") end,
    tag = Tag,
    button = function(p)
        local b = CreateFrame("Button", nil, p)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(W.Hex(C.amber, 0.05))
        return b
    end,
}

local function Canvas(parent)
    local c = { used = {}, free = {} }
    function c.Reset()
        for kind, list in pairs(c.used) do
            local free = c.free[kind] or {}
            c.free[kind] = free
            for i = #list, 1, -1 do
                list[i]:Hide()
                free[#free + 1] = list[i]
                list[i] = nil
            end
        end
    end
    function c.Get(kind)
        local free = c.free[kind]
        local piece = free and table.remove(free) or MAKERS[kind](parent)
        piece:ClearAllPoints()
        piece:Show()
        c.used[kind] = c.used[kind] or {}
        table.insert(c.used[kind], piece)
        return piece
    end
    return c
end

-- Text with its top left at x, y; width cuts it (or wraps it, with wrap). Returns the font string.
local function Txt(c, text, size, hex, x, y, width, justify, wrap, flags)
    local fs = c.Get("text")
    fs:SetFont(W.FRIZ, size, flags or "")
    fs:SetTextColor(W.Hex(hex))
    fs:SetJustifyH(justify or "LEFT")
    fs:SetWordWrap(wrap and true or false)
    fs:SetWidth(width or 0)
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function Rect(c, layer, sub, hex, a, x, y, w, h)
    local t = c.Get("solid")
    t:SetDrawLayer(layer, sub)
    t:SetColorTexture(W.Hex(hex, a))
    t:SetPoint("TOPLEFT", x, y)
    t:SetSize(w, h)
    return t
end

-- A left-to-right gradient.
local function Fade(c, layer, sub, hex1, a1, hex2, a2, x, y, w, h)
    local t = c.Get("fade")
    t:SetDrawLayer(layer, sub)
    W.Gradient(t, "HORIZONTAL", hex1, a1, hex2, a2)
    t:SetPoint("TOPLEFT", x, y)
    t:SetSize(w, h)
    return t
end

-- A one-pixel line around a box.
local function Edge(c, layer, hex, a, x, y, w, h)
    Rect(c, layer, 0, hex, a, x, y, w, 1)
    Rect(c, layer, 0, hex, a, x, y - h + 1, w, 1)
    Rect(c, layer, 0, hex, a, x, y, 1, h)
    Rect(c, layer, 0, hex, a, x + w - 1, y, 1, h)
end

-- An icon, greyed and darkened to dim when it isn't lit.
local function Icon(c, tex, x, y, size, lit, dim)
    local t = c.Get("icon")
    t:SetTexture(tex)
    t:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    t:SetDesaturated(not lit)
    local v = lit and 1 or (dim or 0.45)
    t:SetVertexColor(v, v, v)
    t:SetPoint("TOPLEFT", x, y)
    t:SetSize(size, size)
    return t
end

local function Tick(c, x, y, size)
    local t = c.Get("icon")
    t:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    t:SetTexCoord(0, 1, 0, 1)
    t:SetDesaturated(false)
    t:SetVertexColor(1, 1, 1)
    t:SetPoint("TOPLEFT", x, y)
    t:SetSize(size, size)
    return t
end

-- A slim progress bar: a dark track and an amber fill for the share done.
local function Bar(c, x, y, w, share, h)
    h = h or 4
    Rect(c, "ARTWORK", 0, C.track, 1, x, y, w, h)
    if share > 0 then Fade(c, "ARTWORK", 1, C.barFrom, 1, C.amber2, 1, x, y, math.max(1, w * math.min(1, share)), h) end
end

-- A small triangle: down when shut, up when open (the window picker's caret).
local function Caret(c, x, y, up, hex)
    for i, w in ipairs({ 7, 5, 3, 1 }) do
        Rect(c, "ARTWORK", 0, hex, 1, x + (7 - w) / 2, y - (up and (4 - i) or (i - 1)), w, 1)
    end
end

-- A clickable area; its scripts and fields are cleared each time it's handed out.
local function Hit(c, x, y, w, h)
    local b = c.Get("button")
    for _, script in ipairs({ "OnClick", "OnEnter", "OnLeave" }) do b:SetScript(script, nil) end
    b.item, b.feat, b.right, b.icon, b.count = nil, nil, nil, nil, nil
    b:SetPoint("TOPLEFT", x, y)
    b:SetSize(w, h)
    return b
end

-- "267 Raw Longjaw Mud Snapper" on one line with the number large: before and after in the line's
-- size on the number's baseline, the last part cut to the width.
local function Figure(c, x, y, before, num, after, width, numSize, size, hex)
    -- the parts are spaced by position, so their own edge spaces go
    before = before and before:match("^%s*(.-)%s*$")
    after = after and after:match("^%s*(.-)%s*$")
    local parts = {}
    if before and before ~= "" then parts[#parts + 1] = { before, size, hex } end
    parts[#parts + 1] = { tostring(num), numSize, C.amber2 }
    if after and after ~= "" then parts[#parts + 1] = { after, size, hex } end
    local cx = x
    for i, p in ipairs(parts) do
        local fs = Txt(c, p[1], p[2], p[3], 0, 0)
        fs:ClearAllPoints()
        -- a smaller font's baseline sits a little higher in its line than a big one's
        local lift = p[2] < numSize and math.floor((numSize - p[2]) * 0.2 + 0.5) or 0
        fs:SetPoint("BOTTOMLEFT", fs:GetParent(), "TOPLEFT", cx, y - numSize - 3 + lift)
        if i == #parts then fs:SetWidth(math.max(1, x + width - cx)) end
        cx = cx + math.ceil(fs:GetStringWidth()) + 4
    end
end

-- A lit row (a done feat, a recent find): amber fading to the right, an amber outline and a 3px
-- amber edge. Otherwise dark with a faint outline, a little stronger when open.
local function Ground(c, x, y, w, h, lit, open)
    Rect(c, "BACKGROUND", 0, "0e0a07", 1, x, y, w, h)
    if lit then
        Fade(c, "BACKGROUND", 1, C.amber, 0.14, C.amber, 0.03, x, y, w, h)
        Edge(c, "BORDER", C.amber, 0.45, x, y, w, h)
        Rect(c, "BORDER", 1, C.amber, 1, x, y, 3, h)
    else
        Edge(c, "BORDER", C.rule, open and 0.16 or 0.06, x, y, w, h)
    end
end

-- A lit icon's amber ring.
local function Ring(c, x, y, size)
    Edge(c, "BORDER", C.amber, 1, x - 1, y + 1, size + 2, size + 2)
end

-- A section's title (amber) with a line on the right; returns where what follows starts.
local function Head(c, y, text, right, width, size)
    size = size or 15
    Txt(c, text, size, C.amber2, 0, y, width - 150)
    if right then Txt(c, right, 10.5, C.ink2, 150, y - (size - 11), width - 150, "RIGHT") end
    return y - size - 11
end

-- Progress bars, one per category: name, bar, "n of m". cols: 1 or 2.
local function Progress(c, rows, y, width, labelW, cols)
    local gap = 28
    local colW = cols == 2 and math.floor((width - gap) / 2) or width
    for i, r in ipairs(rows) do
        local col = cols == 2 and (i - 1) % 2 or 0
        local x = col * (colW + gap)
        local yy = y - math.floor((i - 1) / cols) * 24
        Txt(c, r.name, 11, C.ink, x, yy - 4, labelW)
        Bar(c, x + labelW + 8, yy - 8, colW - labelW - 8 - 56, r.total > 0 and r.have / r.total or 0)
        Txt(c, string.format(L["%d of %d"], r.have, r.total), 10.5, C.ink2, x + colW - 50, yy - 4, 50, "RIGHT")
    end
    return y - math.ceil(#rows / cols) * 24
end

-- The category list: one button per category with its name, "n of m" and a slim bar; the chosen one
-- lit with an amber edge. Clicking one keeps it in the tab's setting and draws it.
local function BuildNav(tab, frame, cats)
    local navW = tab.navWidth
    local nav = { width = navW, keys = {} }
    local y = 0
    for i, cat in ipairs(cats) do
        local b = CreateFrame("Button", nil, frame)
        b.navKey = cat.key
        b.lit = W.Solid(b, "BACKGROUND", C.amber, 1)
        b.lit:SetAllPoints()
        W.Gradient(b.lit, "HORIZONTAL", C.amber, 0.18, C.amber, 0.03)
        b.edge = W.Solid(b, "BORDER", C.amber, 1)
        b.edge:SetPoint("TOPLEFT"); b.edge:SetPoint("BOTTOMLEFT"); b.edge:SetWidth(3)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(W.Hex(C.amber, 0.06))
        b.name = W.Text(b, 13, C.ink2)
        b.name:SetPoint("TOPLEFT", 10, -8)
        b.name:SetWidth(navW - 20 - 46)
        b.name:SetWordWrap(true)
        b.name:SetText(cat.name)
        b.count = W.Text(b, 10, C.dim)
        b.count:SetPoint("TOPRIGHT", -10, -10)
        b.count:SetJustifyH("RIGHT")
        b.track = W.Solid(b, "ARTWORK", C.track)
        b.track:SetPoint("BOTTOMLEFT", 10, 8)
        b.track:SetSize(navW - 20, 3)
        b.fill = W.Solid(b, "ARTWORK", C.amber, 1, 1)
        b.fill:SetPoint("BOTTOMLEFT", 10, 8)
        b.fill:SetHeight(3)
        local h = math.max(16, math.ceil(b.name:GetStringHeight())) + 26
        b:SetSize(navW, h)
        b:SetPoint("TOPLEFT", 0, -y)
        b:SetScript("OnClick", function()
            ReelDB.settings[tab.setting] = cat.key
            if tab.scroll then tab.scroll:SetVerticalScroll(0) end
            Refresh()
        end)
        y = y + h + 3 + (i == 1 and 8 or 0) -- Summary stands a little apart
        nav[i], nav.keys[cat.key] = b, b
    end
    local rule = W.Solid(frame, "BORDER", C.rule, 0.075)
    rule:SetPoint("TOPLEFT", navW + NAV_GAP / 2, 0)
    rule:SetPoint("BOTTOMLEFT", navW + NAV_GAP / 2, 0)
    rule:SetWidth(1)
    return nav
end

-- The tab's chosen category: the saved one if the list has it, else Summary.
local function Chosen(tab, nav)
    local key = ReelDB.settings[tab.setting]
    if not nav.keys[key] then key = "summary" end
    return key
end

-- counts[key] = { have, total }
local function SetNav(nav, chosen, counts)
    for _, b in ipairs(nav) do
        local on = b.navKey == chosen
        local n = counts[b.navKey] or { 0, 0 }
        b.lit:SetShown(on)
        b.edge:SetShown(on)
        b.name:SetTextColor(W.Hex(on and C.amber2 or C.ink2))
        b.count:SetTextColor(W.Hex(on and C.ink2 or C.dim))
        b.count:SetText(string.format(L["%d of %d"], n[1], n[2]))
        local share = n[2] > 0 and n[1] / n[2] or 0
        b.fill:SetShown(share > 0)
        b.fill:SetWidth(math.max(1, (nav.width - 20) * share))
        W.Gradient(b.fill, "HORIZONTAL", on and C.barFrom or "8a5c22", 1, on and C.amber2 or "c99040", 1)
    end
end

-- The right side: a scrolling pane beside the list. Returns its child and its width.
local function BuildPane(tab, frame)
    local x = tab.navWidth + NAV_GAP
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", x, 0)
    scroll:SetPoint("BOTTOMRIGHT", -BAR_W, 0)
    -- the scrollbar only when there's more than fits (the client's scroll template reads this)
    scroll.scrollBarHideable = true
    local width = FRAME_W - x - BAR_W
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, 1)
    scroll:SetScrollChild(child)
    tab.scroll = scroll
    return child, width
end

local function BuildSplit(tab, frame, cats)
    local u = { nav = BuildNav(tab, frame, cats) }
    u.child, u.width = BuildPane(tab, frame)
    u.canvas = Canvas(u.child)
    return u
end

-- Collection -------------------------------------------------------------------------------------

-- The derby block: Speckled Tastyfish, when the contest runs, and how many caught, shown big.
local function Derby(c, view, x, y, w)
    Txt(c, L["Derby"]:upper(), 9.5, C.dim, x, y, w)
    local tasty = view.fish[TASTYFISH]
    Icon(c, IconOf(TASTYFISH), x, y - 17, 38, true)
    Txt(c, NameOf(TASTYFISH), 12, "ffffff", x + 48, y - 21, w - 48 - 76)
    Txt(c, L["Sundays 2-4 PM"], 10, C.ink2, x + 48, y - 38, w - 48 - 76)
    Txt(c, tostring(tasty and tasty.count or 0), 34, C.amber2, x + w - 76, y - 16, 76, "RIGHT")
    return y - 60
end

-- "19 Pound Catfish" with the weight large; a name that doesn't start with it, whole.
local function TrophyName(c, id, x, y, width, numSize)
    local name = NameOf(id)
    local num, rest = name:match("^(%d+)%s*(.*)$")
    if num then
        Figure(c, x, y, nil, num, rest, width, numSize, 12, "ffffff")
    else
        Txt(c, name, 12.5, "ffffff", x, y - numSize + 12, width)
    end
end

local function DrawCollectionSummary(u, view, wall, rows)
    local c, pw = u.canvas, u.width
    local half = math.floor((pw - 29) / 2)
    -- the heaviest trophy and the derby, side by side
    Txt(c, L["Heaviest trophy"]:upper(), 9.5, C.dim, 0, 0, half)
    if wall.top then
        local f = view.fish[wall.top.id]
        Icon(c, IconOf(wall.top.id), 0, -17, 38, true)
        TrophyName(c, wall.top.id, 48, -14, half - 48, 24)
        Txt(c, DateZone(f.first, f.firstZone), 10, C.ink2, 48, -42, half - 48)
    else
        Txt(c, L["Not on the wall yet"], 11, "6f6354", 0, -26, half)
    end
    Rect(c, "BORDER", 0, C.rule, 0.075, half + 14, 0, 1, 58)
    Derby(c, view, half + 29, 0, pw - half - 29)

    -- the last four finds added to a collection or the wall
    local y = Head(c, -68, L["Recently added"], nil, pw)
    local finds = {}
    for _, section in ipairs(ns.NOTABLE) do
        for _, item in ipairs(section.items) do
            local f = view.fish[item.id]
            if f and f.first then finds[#finds + 1] = { id = item.id, when = f.first, sub = L[section.group] .. DOT .. L[item.where] } end
        end
    end
    for _, k in ipairs(wall.kinds) do
        for _, t in ipairs(k.list) do
            local f = view.fish[t.id]
            if f and f.first then finds[#finds + 1] = { id = t.id, when = f.first, sub = L["Trophy fish"] .. (f.firstZone and (DOT .. ZoneText(f.firstZone)) or "") } end
        end
    end
    table.sort(finds, function(a, b) return a.when > b.when end)
    if #finds == 0 then
        Txt(c, L["Nothing caught yet."], 11, C.dim, 0, y - 2, pw)
        y = y - 22
    end
    for i = 1, math.min(4, #finds) do
        local find = finds[i]
        Ground(c, 0, y, pw, 36, true)
        Icon(c, IconOf(find.id), 7, y - 5, 26, true)
        Ring(c, 7, y - 5, 26)
        Txt(c, NameOf(find.id), 12.5, C.amber2, 42, y - 4, pw - 42 - 70)
        Txt(c, find.sub, 10, C.ink2, 42, y - 20, pw - 42 - 70)
        Txt(c, ShortDate(find.when), 11, C.ink, pw - 64, y - 12, 54, "RIGHT")
        y = y - 40
    end

    -- one bar per collection, one column so "Stranglethorn Extravaganza" fits
    y = Head(c, y - 8, L["Progress"], string.format(L["%d of %d"], rows.have, rows.total), pw)
    return Progress(c, rows, y, pw, 180, 1)
end

-- The wall: one roomy row per kind, its weights on the right.
local KIND_H = 58
local function DrawTrophies(u, view, wall)
    local c, pw = u.canvas, u.width
    local right = string.format(L["%d of %d"], wall.have, wall.total)
    if wall.top then
        right = right .. DOT .. string.format(L["heaviest %s"], "|cffffffff" .. ItemName(view.fish[wall.top.id].link) .. "|r")
    end
    local y = Head(c, 0, L["Trophy fish"], right, pw, 18)
    for i, row in ipairs(wall.kinds) do
        if i > 1 then Rect(c, "BORDER", 0, C.rule, 0.075, 0, y, pw, 1) end
        local shown = row.top or row.list[#row.list]
        Icon(c, IconOf(shown.id), 0, y - 14, 30, row.top ~= nil, 0.45)
        Txt(c, L[row.kind], 13, row.top and C.ink or "93887a", 40, y - 12, 142)
        if row.top then
            local f = view.fish[row.top.id]
            Txt(c, string.format(L["%d lb"], row.top.pounds) .. DOT .. DateZone(f.first, f.firstZone), 10, C.ink2, 40, y - 30, 144)
        else
            Txt(c, L["Not on the wall yet"], 10, "6f6354", 40, y - 30, 144)
        end
        Txt(c, string.format(L["%d of %d"], row.have, #row.list), 10, C.dim, 186, y - 23, 38)
        local n = #row.list
        -- the weights fill the room right of the "0 of 7" (which ends at 224); narrower tags when a
        -- long row (Lobster's seven) wouldn't fit at this window size
        local step = math.min(TAG_W + TAG_GAP, math.floor((pw - 228 + TAG_GAP) / n))
        for j, t in ipairs(row.list) do
            local tag = c.Get("tag")
            tag:SetWidth(step - TAG_GAP)
            tag:SetPoint("TOPLEFT", pw - (n - j + 1) * step + TAG_GAP, y - 19)
            SetTag(tag, t, view.fish[t.id] ~= nil, row.top == t)
        end
        y = y - KIND_H
    end
    return y
end

-- A tray: four squares a row, each with the item's name, where to look and when it first came up.
local SQ = 52
local function DrawTray(u, view, section, got)
    local c, pw = u.canvas, u.width
    local y = Head(c, 0, L[section.group], string.format(L["%d of %d"], got, #section.items), pw, 18) - 4
    local cols = 4
    local colW = math.floor(pw / cols)
    local rowH = 0
    for i, item in ipairs(section.items) do
        local col = (i - 1) % cols
        if col == 0 and i > 1 then y, rowH = y - rowH - 16, 0 end
        local x = col * colW
        local f = view.fish[item.id]
        local sx = x + math.floor((colW - SQ) / 2)
        Rect(c, "BACKGROUND", 0, C.slot, 1, sx, y, SQ, SQ)
        local icon = Icon(c, IconOf(item.id), sx, y, SQ, f ~= nil, 0.42)
        Edge(c, "BORDER", f and C.amber or "000000", 1, sx - 1, y + 1, SQ + 2, SQ + 2)
        local count = Txt(c, f and f.count or "", 13, "ffffff", sx, y - SQ + 17, SQ - 4, "RIGHT", false, "OUTLINE")
        local ty = y - SQ - 7
        local name = Txt(c, NameOf(item.id), 11.5, f and "ffffff" or C.grey, x + 3, ty, colW - 6, "CENTER", true)
        ty = ty - math.ceil(name:GetStringHeight()) - 2
        local where = Txt(c, L[item.where], 10, f and C.ink2 or "6f6354", x + 3, ty, colW - 6, "CENTER", true)
        ty = ty - math.ceil(where:GetStringHeight()) - 4
        local first = f and (f.first and string.format(L["First %s"], ShortDate(f.first)) or "") or L["Not yet"]
        Txt(c, first, 10, f and C.amber2 or "5f5547", x + 3, ty, colW - 6, "CENTER")
        local h = y - ty + 12
        rowH = math.max(rowH, h)
        local hit = Hit(c, x, y, colW, h)
        hit.item, hit.icon, hit.count = item, icon, count
        hit:SetScript("OnEnter", ItemTip)
        hit:SetScript("OnLeave", HideTip)
    end
    y = y - rowH
    -- the Extravaganza's derby count under its tray
    for _, item in ipairs(section.items) do
        if item.id == TASTYFISH then
            Rect(c, "BORDER", 0, C.rule, 0.075, 0, y - 12, pw, 1)
            y = Derby(c, view, 0, y - 26, pw)
            break
        end
    end
    return y
end

local function CollectionCats()
    local cats = { { key = "summary", name = L["Summary"] }, { key = "trophy", name = L["Trophy fish"] } }
    for _, section in ipairs(ns.NOTABLE) do
        cats[#cats + 1] = { key = section.group, name = L[section.group] } -- FishData's groups are in Locale.lua
    end
    return cats
end

function collectionTab.Build(frame)
    return BuildSplit(collectionTab, frame, CollectionCats())
end

function collectionTab.Draw(view)
    local u = collectionTab.ui
    local wall = Wall(view)
    local counts = { trophy = { wall.have, wall.total } }
    local rows = { { name = L["Trophy fish"], have = wall.have, total = wall.total } }
    rows.have, rows.total = wall.have, wall.total
    for _, section in ipairs(ns.NOTABLE) do
        local got = 0
        for _, item in ipairs(section.items) do
            if view.fish[item.id] then got = got + 1 end
        end
        counts[section.group] = { got, #section.items }
        rows[#rows + 1] = { name = L[section.group], have = got, total = #section.items }
        rows.have, rows.total = rows.have + got, rows.total + #section.items
    end
    counts.summary = { rows.have, rows.total }
    collectionTab.have, collectionTab.total = rows.have, rows.total

    local chosen = Chosen(collectionTab, u.nav)
    SetNav(u.nav, chosen, counts)
    u.canvas.Reset()
    local y = 0
    if chosen == "summary" then
        y = DrawCollectionSummary(u, view, wall, rows)
    elseif chosen == "trophy" then
        y = DrawTrophies(u, view, wall)
    else
        for _, section in ipairs(ns.NOTABLE) do
            if section.group == chosen then y = DrawTray(u, view, section, counts[chosen][1]) end
        end
    end
    u.child:SetHeight(math.max(1, -y + 4))
end

-- "10 of 46" by the title: trophies and tray items found.
function collectionTab.Count()
    return string.format(L["%d of %d"], collectionTab.have or 0, collectionTab.total or 0)
end

-- Feats ----------------------------------------------------------------------------------------
-- Worked out from the journal: the zones, fish and sessions tables for what's done, and the catch
-- log (one row per item per catch, oldest first) for when. A date shows only when every catch it
-- depends on is in the log; a journal older than the log shows Done without one.

local CAPITALS = { "Stormwind City", "Ironforge", "Darnassus", "Orgrimmar", "Thunder Bluff", "Undercity" }
local CONTINENTS = { "Kalimdor", "Eastern Kingdoms", "Zephras Isle" }
local CONTINENT_MAPS = { Kalimdor = 1414, ["Eastern Kingdoms"] = 1415 } -- world map IDs, for their names
local WRECKAGE = { 20708, 21113, 21150, 21228 } -- a trunk from each of the four wreckage pools
local NAT_PAGLE = { 16967, 16968, 16969, 16970 }
local MESSAGE = 6307
local CLEAN_GOAL, MORNING_GOAL, THOUSAND = 150, 50, 1000

local FEAT_CATS = {
    { key = "summary", name = L["Summary"] },
    { key = "places", name = L["Places"] },
    { key = "sitting", name = L["Sitting there"] },
    { key = "collecting", name = L["Collecting"] },
    { key = "volume", name = L["Volume"] },
    { key = "extravaganza", name = L["Extravaganza"] },
}

local function ICON(name) return "Interface\\Icons\\" .. name end

-- Item IDs from FishData: CATCHES whose name matches, or a tray's items (whose name matches).
local function CatchesNamed(pattern)
    local out = {}
    for id, item in pairs(ns.CATCHES) do
        if item.name:find(pattern) then out[#out + 1] = id end
    end
    table.sort(out) -- the rums by ID: Light, Dark, Black Label
    return out
end
local function TrayItems(group, pattern)
    local out = {}
    for _, section in ipairs(ns.NOTABLE) do
        if section.group == group then
            for _, item in ipairs(section.items) do
                if not pattern or item.name:find(pattern) then out[#out + 1] = item.id end
            end
        end
    end
    return out
end
local RUMS = CatchesNamed("^Rumsey Rum")
local BIG_ONE = CatchesNamed("^32 Pound Catfish$")
local BLOATED = TrayItems("Bloated fish")
local CONTEST = TrayItems("Stranglethorn Extravaganza")

-- A continent's name in this client's language.
local function ContinentName(name)
    local id = CONTINENT_MAPS[name]
    if id and C_Map and C_Map.GetMapInfo then
        local ok, info = pcall(C_Map.GetMapInfo, id)
        if ok and info and info.name and info.name ~= "" then return info.name end
    end
    return ns.LocalZone(name)
end

-- The characters the view covers: key -> saved data.
local function ViewChars()
    local scope = Scope()
    if scope ~= "all" then return { [scope] = ReelDB.chars[scope] } end
    return ReelDB.chars
end

-- Calls fn(time, clean, zone) for each catch in a character's log: rows with the same time are one
-- catch (one loot window can hold more than one item); clean when every item in it is a fish.
local function EachCatch(rows, fn)
    local t, clean, zone
    for _, r in ipairs(rows) do
        if r[1] ~= t then
            if t then fn(t, clean, zone) end
            t, clean, zone = r[1], true, r[2]
        end
        if not ns.FISH[r[6]] then clean = false end
    end
    if t then fn(t, clean, zone) end
end

-- One pass over the view's catch log, kept until the log grows or the character changes:
--   zoneFirst[zone]          first catch in a zone (English names)
--   zoneFish[zone][fishID]   first catch of a fish there
--   tastyDays[day]           first Speckled Tastyfish on a server day
--   clean, cleanAt, cleanBest  the longest run of catches with nothing but fish; when one reached
--                            150; when the longest ended
--   morning, morningAt, morningBest  most catches in one morning, 5:00 to 6:59 server time; when one
--                            reached 50; when the best one's last catch was
--   night, nightZone         first catch between 12:00 and 12:59 AM server time, and where
--   thousandAt               when a fish first reached 1,000 (if all of that fish is in the log)
-- Runs and mornings are per character, the best of them.
local logCache = {}
local function LogFacts()
    local chars, rows = ViewChars(), 0
    for _, d in pairs(chars) do rows = rows + #d.catches end
    local key = Scope() .. "|" .. rows
    if logCache.key == key then return logCache.facts end

    local offset = ns.Calendar.ServerOffset(ns.Now()) * 60 -- server time from the log's UTC times
    local facts = { zoneFirst = {}, zoneFish = {}, tastyDays = {}, clean = 0, morning = 0 }
    local english = {}
    -- the fish there are 1,000 of: their rows, to find when the 1,000th came in
    local total, big = {}, {}
    for _, d in pairs(chars) do
        for id, f in pairs(d.fish) do total[id] = (total[id] or 0) + f.count end
    end
    for id, n in pairs(total) do
        if ns.FISH[id] and n >= THOUSAND then big[id] = { n = 0 } end
    end
    for _, d in pairs(chars) do
        local rowsOf = d.catches
        for _, r in ipairs(rowsOf) do
            local t, id, zone = r[1], r[6], r[2] or "Unknown"
            local z = english[zone]
            if not z then z = ns.EnglishZone(zone); english[zone] = z end
            if not facts.zoneFirst[z] or t < facts.zoneFirst[z] then facts.zoneFirst[z] = t end
            if ns.FISH[id] then
                local zf = facts.zoneFish[z] or {}
                facts.zoneFish[z] = zf
                if not zf[id] or t < zf[id] then zf[id] = t end
            end
            if id == TASTYFISH then
                local day = math.floor((t + offset) / 86400)
                if not facts.tastyDays[day] or t < facts.tastyDays[day] then facts.tastyDays[day] = t end
            end
            local b = big[id]
            if b then
                b.n = b.n + (r[7] or 1)
                b[#b + 1] = { t, r[7] or 1 }
            end
        end
        local run, day, count = 0, nil, 0
        EachCatch(rowsOf, function(t, clean, zone)
            run = clean and run + 1 or 0
            if run > facts.clean then facts.clean, facts.cleanBest = run, t end
            if run == CLEAN_GOAL and (not facts.cleanAt or t < facts.cleanAt) then facts.cleanAt = t end
            local s = t + offset
            local hour = math.floor(s % 86400 / 3600)
            if hour == 0 and (not facts.night or t < facts.night) then facts.night, facts.nightZone = t, zone end
            if hour == 5 or hour == 6 then
                local d2 = math.floor(s / 86400)
                if d2 ~= day then day, count = d2, 0 end
                count = count + 1
                if count > facts.morning then facts.morning, facts.morningBest = count, t end
                if count == MORNING_GOAL and (not facts.morningAt or t < facts.morningAt) then facts.morningAt = t end
            end
        end)
    end
    for id, b in pairs(big) do
        if b.n == total[id] then -- every one of them is in the log
            table.sort(b, function(x, y) return x[1] < y[1] end)
            local n = 0
            for _, row in ipairs(b) do
                n = n + row[2]
                if n >= THOUSAND then
                    if not facts.thousandAt or row[1] < facts.thousandAt then facts.thousandAt = row[1] end
                    break
                end
            end
        end
    end
    logCache.key, logCache.facts = key, facts
    return facts
end

-- The kth earliest of a set's times, when every member of the set (all of them) has one.
local function KthTime(times, k, all)
    local list = {}
    for _, t in pairs(times) do list[#list + 1] = t end
    if #list < all or #list < k then return nil end
    table.sort(list)
    return list[k]
end

-- The time of the nth catch between from and to in a character's log (in one zone, if given).
local function NthCatch(rows, from, to, n, zone)
    local lo, hi = 1, #rows + 1 -- the log is oldest first: halve to the first row at or after from
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if rows[mid][1] < from then lo = mid + 1 else hi = mid end
    end
    local count, last = 0, nil
    for i = lo, #rows do
        local r = rows[i]
        if r[1] > to then return nil end
        if r[1] ~= last and (not zone or ns.EnglishZone(r[2]) == zone) then
            count, last = count + 1, r[1]
            if count == n then return r[1] end
        end
    end
end

-- A session's character's catch log.
local function SessionRows(s)
    local d = ReelDB.chars[charOf[s] or Scope()]
    return d and d.catches or {}
end

-- How many of a list of items have been caught, and when the last of them first was (once all are).
local function ItemsCaught(view, ids)
    local have, last = 0, 0
    for _, id in ipairs(ids) do
        local f = view.fish[id]
        if f then
            have = have + 1
            if f.first and last then last = math.max(last, f.first) else last = nil end
        end
    end
    if have < #ids or last == 0 then last = nil end
    return have, last
end

-- A list of items as ticks with their icons, for an opened feat.
local function ItemTicks(view, ids, cols)
    local items = {}
    for _, id in ipairs(ids) do
        items[#items + 1] = { text = NameOf(id), got = view.fish[id] ~= nil, icon = IconOf(id) }
    end
    return { kind = "ticks", items = items, cols = cols }
end

-- One feat: done with a goal when have reaches it; when is the time it was done, if known. key
-- names it for its open state; crit is what an opened row shows (blocks for DrawCriteria).
local function Feat(f)
    if f.done == nil then f.done = f.have ~= nil and f.goal ~= nil and f.have >= f.goal end
    if f.have and f.goal then f.have = math.min(f.have, f.goal) end
    if not f.done then f.when = nil end
    return f
end

-- Every feat for the view, in five groups.
local function Feats(view)
    local facts = LogFacts()

    -- zones with a catch, in English
    local fished, fishedCount, fishedNames = {}, 0, {}
    local caughtIn = {}
    for zone, subs in pairs(view.zones) do
        local z = ns.EnglishZone(zone)
        caughtIn[z] = caughtIn[z] or {}
        for _, entry in pairs(subs) do
            if entry.catches > 0 and not fished[z] then
                fished[z] = true
                fishedCount = fishedCount + 1
                fishedNames[#fishedNames + 1] = ns.LocalZone(z)
            end
            for fid in pairs(entry.items) do caughtIn[z][fid] = true end
        end
    end
    table.sort(fishedNames)
    local zoneTimes = {}
    for z in pairs(fished) do zoneTimes[z] = facts.zoneFirst[z] end
    local fishedChips = { kind = "chips", label = L["Zones fished"], items = fishedNames }

    -- continents and capitals: first when the earliest of their zones was, if all have a time
    local continentFirst, continents, continentTicks = {}, 0, {}
    for _, name in ipairs(CONTINENTS) do
        local first, any, complete = nil, false, true
        for z in pairs(fished) do
            if ns.CONTINENT and ns.CONTINENT[z] == name then
                any = true
                local t = facts.zoneFirst[z]
                if t then first = first and math.min(first, t) or t else complete = false end
            end
        end
        if any then
            continents = continents + 1
            continentFirst[name] = complete and first or false
        end
        continentTicks[#continentTicks + 1] = { text = ContinentName(name), got = any }
    end
    local capitalFirst, capitals, capitalTicks = {}, 0, {}
    for _, z in ipairs(CAPITALS) do
        if fished[z] then
            capitals = capitals + 1
            capitalFirst[z] = facts.zoneFirst[z] or false
        end
        capitalTicks[#capitalTicks + 1] = { text = ns.LocalZone(z), got = fished[z] == true }
    end
    local function Known(times)
        local out = {}
        for k, t in pairs(times) do if t then out[k] = t end end
        return out
    end

    -- zones where every fish listed for them has been caught there, and when the last one was;
    -- the rest that are started, nearest done first
    local complete, completeTimes, near = {}, {}, {}
    for zone, want in pairs(ns.ZoneFish()) do
        local caught = caughtIn[zone] or {}
        local missing, total, last = {}, 0, 0
        for fid in pairs(want) do
            total = total + 1
            if not caught[fid] then missing[#missing + 1] = fid end
            local t = facts.zoneFish[zone] and facts.zoneFish[zone][fid]
            if t and last then last = math.max(last, t) else last = nil end
        end
        if #missing == 0 then
            complete[#complete + 1] = ns.LocalZone(zone)
            if last then completeTimes[zone] = last end
        elseif #missing < total then
            near[#near + 1] = { zone = ns.LocalZone(zone), have = total - #missing, total = total, ids = missing }
        end
    end
    table.sort(complete)
    table.sort(near, function(a, b)
        local x, y = a.have / a.total, b.have / b.total
        if x ~= y then return x > y end
        if #a.ids ~= #b.ids then return #a.ids < #b.ids end
        return a.zone < b.zone
    end)
    for i = #near, 4, -1 do near[i] = nil end -- the three nearest
    for _, n in ipairs(near) do
        local names = {}
        for _, fid in ipairs(n.ids) do names[#names + 1] = NameOf(fid) end
        table.sort(names)
        n.missing = table.concat(names, ", ")
    end
    local finishedChips = { kind = "chips", label = L["Zones finished"], items = complete }

    -- sessions: the most catches in one, and the most sessions in one zone
    local best, bestSession, perZone, settled = 0, nil, {}, 0
    local eveningAt, nightAt, settledAt
    for _, s in ipairs(view.sessions) do
        local n = s.catches or 0
        if n > best then best, bestSession = n, s end
        if n >= 100 and eveningAt == nil then eveningAt = NthCatch(SessionRows(s), s.start, s.last or s.start, 100) or false end
        if n >= 500 and nightAt == nil then nightAt = NthCatch(SessionRows(s), s.start, s.last or s.start, 500) or false end
        local seen = {}
        for zone, count in pairs(s.zones or {}) do
            local z = ns.EnglishZone(zone)
            if count > 0 and not seen[z] then
                seen[z] = true
                perZone[z] = (perZone[z] or 0) + 1
                if perZone[z] > settled then settled = perZone[z] end
                if perZone[z] == 10 and settledAt == nil then settledAt = NthCatch(SessionRows(s), s.start, s.last or s.start, 1, z) or false end
            end
        end
    end
    local bestLine = { kind = "lines", rows = { { L["Best session"], bestSession
        and (string.format(L["%d catches"], best) .. DOT .. ShortDate(bestSession.start) .. DOT .. SessionZone(bestSession)) or L["Not yet"] } } }
    -- the zones with the most sessions, for Settled in
    local settledRows = {}
    for z, n in pairs(perZone) do settledRows[#settledRows + 1] = { text = ns.LocalZone(z), have = math.min(n, 10), goal = 10, n = n } end
    table.sort(settledRows, function(a, b) if a.n ~= b.n then return a.n > b.n end return a.text < b.text end)
    for i = #settledRows, 5, -1 do settledRows[i] = nil end
    local settledNeed = L["Ten sessions in one zone"]
    if settled < 10 and settledRows[1] then settledNeed = settledNeed .. DOT .. string.format(L["closest: %s"], settledRows[1].text) end

    -- casts and the zone with the most, the most of one fish, the Extravaganza Sundays
    local casts, castsIn = 0, {}
    for zone, subs in pairs(view.zones) do
        local z = ns.EnglishZone(zone)
        for _, entry in pairs(subs) do
            casts = casts + entry.casts
            castsIn[z] = (castsIn[z] or 0) + entry.casts
        end
    end
    local castZone
    for z, n in pairs(castsIn) do
        if not castZone or n > castsIn[castZone] or (n == castsIn[castZone] and z < castZone) then castZone = z end
    end
    local most, mostId = 0, nil
    for id, f in pairs(view.fish) do
        if ns.FISH[id] and f.count > most then most, mostId = f.count, id end
    end
    -- the Sundays with a Speckled Tastyfish: server days of the sessions that caught one (the
    -- contest is 2 to 4 PM, so a session's start is on its day)
    local offset = ns.Calendar.ServerOffset(ns.Now()) * 60
    local sundays, sundayCount, sundayDates = {}, 0, {}
    for _, s in ipairs(view.sessions) do
        local day = math.floor((s.start + offset) / 86400)
        if s.items and s.items[TASTYFISH] and not sundays[day] then
            sundays[day] = true
            sundayCount = sundayCount + 1
            sundayDates[#sundayDates + 1] = ShortDate(s.start) -- sessions are oldest first
        end
    end

    -- trophies: one of every kind, and when the last kind got its first; each kind's heaviest
    local kinds, kindsHave, kindsAt, kindsDated, kindTicks = TrophyKinds(), 0, 0, true, {}
    for _, k in ipairs(kinds) do
        local first, top
        for _, t in ipairs(k.list) do
            local f = view.fish[t.id]
            if f then top = t end
            if f and f.first then first = first and math.min(first, f.first) or f.first end
        end
        if top then
            kindsHave = kindsHave + 1
            if first then kindsAt = math.max(kindsAt, first) else kindsDated = false end
        end
        local shown = top or k.list[#k.list]
        kindTicks[#kindTicks + 1] = { text = L[k.kind], got = top ~= nil, icon = IconOf(shown.id), value = top and string.format(L["%d lb"], top.pounds) }
    end
    if not kindsDated or kindsAt == 0 then kindsAt = nil end

    -- the first of any of a list of items
    local function FirstOf(ids)
        local first, any = nil, false
        for _, id in ipairs(ids) do
            local f = view.fish[id]
            if f then
                any = true
                if f.first and (not first or f.first < first) then first = f.first end
            end
        end
        return any, first
    end
    local bloated, bloatedAt = FirstOf(BLOATED)
    local bigOne, bigOneAt = FirstOf(BIG_ONE)
    local mail, mailAt = FirstOf({ MESSAGE })
    local bloatedGot = {}
    for _, id in ipairs(BLOATED) do
        if view.fish[id] then bloatedGot[#bloatedGot + 1] = id end
    end
    local bloatedCrit = #bloatedGot > 0 and ItemTicks(view, bloatedGot, 2) or { kind = "lines", rows = { { L["Bloated fish"], L["Not yet"] } } }

    local wreckHave, wreckAt = ItemsCaught(view, WRECKAGE)
    local rumHave, rumAt = ItemsCaught(view, RUMS)
    local natHave, natAt = ItemsCaught(view, NAT_PAGLE)
    local contestHave, contestAt = ItemsCaught(view, CONTEST)

    local nightLine = facts.night and (ShortDate(facts.night) .. DOT .. ClockTime(facts.night) .. (facts.nightZone and (DOT .. ZoneText(facts.nightZone)) or "")) or L["Not yet"]
    local function CountDate(n, t) return string.format(L["%d catches"], n) .. (t and (DOT .. ShortDate(t)) or "") end

    return {
        { key = "places", name = L["Places"], feats = {
            Feat({ key = "travelled", icon = ICON("INV_Misc_Spyglass_01"), name = L["Well travelled"], need = L["Fish in ten zones"],
                have = fishedCount, goal = 10, when = KthTime(zoneTimes, 10, fishedCount), crit = { fishedChips } }),
            Feat({ key = "completionist", icon = ICON("Trade_Fishing"), name = L["Completionist"], need = L["Every fish in one zone"],
                when = KthTime(completeTimes, 1, #complete), done = #complete > 0, crit = { finishedChips } }),
            Feat({ key = "settled", icon = ICON("INV_FishingChair"), name = L["Settled in"], need = settledNeed,
                have = settled, goal = 10, when = settledAt, crit = { #settledRows > 0 and { kind = "bars", rows = settledRows } or { kind = "lines", rows = { { L["Sessions"], L["Not yet"] } } } } }),
            Feat({ key = "bothsides", icon = ICON("INV_Misc_Fish_25"), name = L["Both sides of the sea"], need = L["A fish in Kalimdor, the Eastern Kingdoms and Zephras Isle"],
                have = continents, goal = 3, when = KthTime(Known(continentFirst), 3, continents), crit = { { kind = "ticks", items = continentTicks, cols = 3 } } }),
            Feat({ key = "capitals", icon = ICON("INV_Jewelry_Ring_03"), name = L["Six capitals"], need = L["A fish in every capital city"],
                have = capitals, goal = 6, when = KthTime(Known(capitalFirst), 6, capitals), crit = { { kind = "ticks", items = capitalTicks, cols = 3 } } }),
            Feat({ key = "thorough", icon = ICON("INV_Misc_Fish_24"), name = L["Thorough"], need = L["Every fish in five zones"],
                have = #complete, goal = 5, when = KthTime(completeTimes, 5, #complete), crit = { finishedChips, #near > 0 and { kind = "near", rows = near } or nil } }),
            Feat({ key = "longway", icon = ICON("INV_Misc_Fish_14"), name = L["Long way round"], need = L["Fish in twenty-five zones"],
                have = fishedCount, goal = 25, when = KthTime(zoneTimes, 25, fishedCount), crit = { fishedChips } }),
        } },
        { key = "sitting", name = L["Sitting there"], feats = {
            Feat({ key = "evening", icon = ICON("INV_Misc_PocketWatch_01"), name = L["Long evening"], need = L["100 catches in one session"],
                have = best, goal = 100, when = eveningAt, crit = { bestLine } }),
            Feat({ key = "clean", icon = ICON("INV_Fishingpole_02"), name = L["Clean line"], need = L["150 catches in a row, no junk"],
                have = facts.clean, goal = CLEAN_GOAL, when = facts.cleanAt,
                crit = { { kind = "lines", rows = { { L["Longest run"], CountDate(facts.clean, facts.cleanBest) } } } } }),
            Feat({ key = "allnight", icon = ICON("Spell_Nature_Starfall"), name = L["Up all night"], need = L["500 catches in one session"],
                have = best, goal = 500, when = nightAt, crit = { bestLine } }),
            Feat({ key = "breakfast", icon = ICON("INV_Misc_Food_47"), name = L["Before breakfast"], need = L["50 catches between 5 and 7 AM server time, one morning"],
                have = facts.morning, goal = MORNING_GOAL, when = facts.morningAt,
                crit = { { kind = "lines", rows = { { L["Best morning"], CountDate(facts.morning, facts.morningBest) } } } } }),
            Feat({ key = "nightshift", icon = ICON("Spell_Shadow_Twilight"), name = L["Night shift"], need = L["A catch between 12:00 and 12:59 AM server time"],
                when = facts.night, done = facts.night ~= nil, crit = { { kind = "lines", rows = { { L["First"], nightLine } } } } }),
        } },
        { key = "collecting", name = L["Collecting"], feats = {
            Feat({ key = "wreckage", icon = ICON("INV_Box_01"), name = L["Every wreckage pool"], need = L["A trunk from each of the four wreckage pools"],
                have = wreckHave, goal = #WRECKAGE, when = wreckAt, crit = { ItemTicks(view, WRECKAGE, 2) } }),
            Feat({ key = "oneofeach", icon = ICON("INV_Misc_Fish_30"), name = L["One of each"], need = L["A trophy fish of every kind"],
                have = kindsHave, goal = #kinds, when = kindsAt, crit = { { kind = "ticks", items = kindTicks, cols = 2 } } }),
            Feat({ key = "rums", icon = IconOf(RUMS[1]), name = L["Three rums"], need = L["Light, Dark and Black Label"],
                have = rumHave, goal = #RUMS, when = rumAt, crit = { ItemTicks(view, RUMS, 1) } }),
            Feat({ key = "natpagle", icon = ICON("INV_Misc_Fish_10"), name = L["Nat Pagle's list"], need = L["All four of Nat Pagle's fish"],
                have = natHave, goal = #NAT_PAGLE, when = natAt, crit = { ItemTicks(view, NAT_PAGLE, 2) } }),
            Feat({ key = "bigone", icon = ICON("INV_Misc_Fish_31"), name = L["The big one"], need = L["A 32 Pound Catfish"],
                when = bigOneAt, done = bigOne, crit = { ItemTicks(view, BIG_ONE, 2) } }),
            Feat({ key = "inside", icon = ICON("INV_Misc_Gem_Variety_02"), name = L["Something inside"], need = L["Catch a bloated fish"],
                when = bloatedAt, done = bloated, crit = { bloatedCrit } }),
            Feat({ key = "mail", icon = IconOf(MESSAGE), name = L["Mail from the sea"], need = L["A Message in a Bottle"],
                when = mailAt, done = mail, crit = { ItemTicks(view, { MESSAGE }, 2) } }),
        } },
        { key = "volume", name = L["Volume"], feats = {
            Feat({ key = "thousand", icon = mostId and IconOf(mostId) or ICON("Trade_Fishing"), name = L["A thousand of one"], need = L["1,000 of a single fish"],
                have = most, goal = THOUSAND, when = facts.thousandAt,
                crit = { { kind = "lines", rows = { { L["Most of one fish"], mostId and (most .. " " .. NameOf(mostId)) or L["Not yet"] } } } } }),
            Feat({ key = "casts", icon = ICON("INV_Fishingpole_01"), name = L["5,000 casts"], need = L["Cast five thousand times"],
                have = casts, goal = 5000,
                crit = { { kind = "lines", rows = { { L["Casts"], tostring(casts) }, castZone and { L["Zone"], ns.LocalZone(castZone) .. DOT .. castsIn[castZone] } or nil } } } }),
        } },
        { key = "extravaganza", name = L["Extravaganza"], feats = {
            Feat({ key = "regular", icon = IconOf(TASTYFISH), name = L["The Regular"], need = L["A Speckled Tastyfish on five Sundays"],
                have = sundayCount, goal = 5, when = KthTime(facts.tastyDays, 5, sundayCount), crit = { { kind = "chips", label = L["Sundays"], items = sundayDates } } }),
            Feat({ key = "contest", icon = IconOf(19805), name = L["Full card"], need = L["All five Extravaganza catches"],
                have = contestHave, goal = #CONTEST, when = contestAt, crit = { ItemTicks(view, CONTEST, 2) } }),
        } },
    }
end

-- The four records on the Summary: best session, most of one fish, heaviest trophy, rarest catch.
-- Each: key, then a number shown large with the text before and after it, or a text alone; sub.
local function Records(view)
    local out = {}
    local best
    for _, s in ipairs(view.sessions) do
        if s.fish > 0 and (not best or s.fish > best.fish) then best = s end
    end
    local before, after = L["%s fish"]:match("^(.-)%%s(.*)$")
    out[1] = { key = L["Best session"], num = best and best.fish, before = before, after = after, sub = best and (ShortDate(best.start) .. DOT .. SessionZone(best)) }
    local most
    for id, f in pairs(view.fish) do
        if ns.FISH[id] and (not most or f.count > most.count) then most = f end
    end
    out[2] = { key = L["Most of one fish"], num = most and most.count, after = most and Bare(most.link), sub = most and DateZone(most.first, most.firstZone) }
    local top = Wall(view).top
    local heavy = top and view.fish[top.id]
    out[3] = { key = L["Heaviest trophy"], trophy = top and top.id, sub = heavy and DateZone(heavy.first, heavy.firstZone) }
    local rarest
    for _, f in pairs(view.fish) do
        local q, rq = f.quality or 0, rarest and (rarest.quality or 0)
        if not rarest or q > rq or (q == rq and f.count < rarest.count) then rarest = f end
    end
    out[4] = { key = L["Rarest catch"], text = rarest and Bare(rarest.link), sub = rarest and DateZone(rarest.first, rarest.firstZone) }
    return out
end

local RECORD_SHARES = { 0.9, 1.45, 1, 1 }
local function DrawRecords(c, view, y, pw)
    local sum, x = 0, 0
    for _, share in ipairs(RECORD_SHARES) do sum = sum + share end
    for i, rec in ipairs(Records(view)) do
        local w = math.floor(pw * RECORD_SHARES[i] / sum)
        local pad = i > 1 and 10 or 0
        local inner = w - pad - 6
        if i > 1 then Rect(c, "BORDER", 0, C.rule, 0.075, x, y, 1, 46) end
        Txt(c, rec.key:upper(), 9, C.dim, x + pad, y, inner)
        if rec.num then
            Figure(c, x + pad, y - 12, rec.before, rec.num, rec.after, inner, 17, 11, C.ink)
        elseif rec.trophy then
            TrophyName(c, rec.trophy, x + pad, y - 12, inner, 17)
        else
            Txt(c, rec.text or "-", 12, C.ink, x + pad, y - 17, inner)
        end
        Txt(c, rec.sub or "", 9.5, C.ink2, x + pad, y - 35, inner)
        x = x + w
    end
    return y - 50
end

-- An opened feat's criteria, one kind of block each, from x0 to right; each returns where it ends.
local BLOCKS = {}

-- Labelled chips with a tick, wrapping onto more lines.
function BLOCKS.chips(c, b, y, x0, right)
    local x = x0
    if b.label then
        local fs = Txt(c, b.label:upper(), 9.5, C.dim, x, y - 5)
        x = x + math.ceil(fs:GetStringWidth()) + 10
    end
    if #b.items == 0 then
        Txt(c, L["Not yet"], 11, "6f6354", x, y - 4)
        return y - 20
    end
    for _, text in ipairs(b.items) do
        local fs = Txt(c, text, 11, C.ink, 0, 0)
        local w = math.min(right - x0, math.ceil(fs:GetStringWidth()) + 28)
        if x + w > right and x > x0 then x, y = x0, y - 24 end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", x + 20, y - 4)
        fs:SetWidth(w - 26)
        Rect(c, "BACKGROUND", 2, C.amber, 0.08, x, y, w, 19)
        Edge(c, "BORDER", C.amber, 0.25, x, y, w, 19)
        Tick(c, x + 3, y - 1, 16)
        x = x + w + 6
    end
    return y - 20
end

-- A grid of ticked or empty boxes, each with an optional icon and a value on the right.
function BLOCKS.ticks(c, b, y, x0, right)
    local cols = b.cols or 3
    local colW = math.floor((right - x0) / cols)
    for i, item in ipairs(b.items) do
        local x = x0 + ((i - 1) % cols) * colW
        local yy = y - math.floor((i - 1) / cols) * 28
        Rect(c, "BACKGROUND", 2, C.pitch, item.got and 1 or 0, x, yy - 7, 14, 14)
        Edge(c, "BORDER", item.got and C.amber or C.rule, item.got and 0.5 or 0.18, x, yy - 7, 14, 14)
        if item.got then Tick(c, x - 2, yy - 5, 18) end
        local tx = x + 22
        if item.icon then
            Icon(c, item.icon, tx, yy - 3, 22, item.got, 0.45)
            tx = tx + 29
        end
        local vw = item.value and 44 or 0
        Txt(c, item.text, 11.5, item.got and C.ink or C.grey, tx, yy - 8, colW - (tx - x) - vw - 8)
        if item.value then Txt(c, item.value, 11, C.amber2, x + colW - 8 - vw, yy - 8, vw, "RIGHT") end
    end
    return y - math.ceil(#b.items / cols) * 28
end

-- Zones and how far along each is toward a goal, the first in amber.
function BLOCKS.bars(c, b, y, x0, right)
    for i, r in ipairs(b.rows) do
        Txt(c, r.text, 11, i == 1 and C.amber2 or C.ink, x0, y - 4, 150)
        Bar(c, x0 + 160, y - 8, right - x0 - 160 - 66, r.have / r.goal)
        Txt(c, string.format(L["%d of %d"], r.have, r.goal), 10.5, C.ink2, right - 56, y - 4, 56, "RIGHT")
        y = y - 20
    end
    return y
end

-- The nearest unfinished zones: how many of their fish, and the ones still missing.
function BLOCKS.near(c, b, y, x0, right)
    for _, r in ipairs(b.rows) do
        Txt(c, r.zone, 11, C.ink, x0, y - 4, right - x0 - 110)
        Txt(c, string.format(L["%d of %d fish"], r.have, r.total), 10.5, C.ink2, right - 110, y - 4, 110, "RIGHT")
        Txt(c, r.missing, 10, C.dim, x0 + 10, y - 19, right - x0 - 10)
        y = y - 34
    end
    return y
end

-- Label and value lines: the best so far, and where and when.
function BLOCKS.lines(c, b, y, x0, right)
    for _, r in ipairs(b.rows) do
        Txt(c, r[1]:upper(), 9.5, C.dim, x0, y - 5, 120)
        Txt(c, r[2], 11, C.ink, x0 + 128, y - 4, right - x0 - 128)
        y = y - 20
    end
    return y
end

local CRIT_X = 45 -- under the feat's name
local function DrawCriteria(c, crit, y, pw)
    local right = pw - 12
    Rect(c, "BORDER", 0, C.rule, 0.075, CRIT_X, y, right - CRIT_X, 1)
    y = y - 8
    for i = 1, table.maxn(crit) do
        local block = crit[i]
        if block then y = BLOCKS[block.kind](c, block, y, CRIT_X, right) - 6 end
    end
    return y - 2
end

local featsOpen = {} -- feat key -> true while its row is open (until the Journal is closed)

-- A feat's row: icon, name, what it takes, and on the right the day it was done or how far along it
-- is; click to open its criteria under it.
local FEAT_H = 38
local function DrawFeat(c, feat, y, pw)
    local top = y
    local open = featsOpen[feat.key] == true
    local rightW = feat.done and 86 or feat.goal and 152 or 86
    Icon(c, feat.icon, 7, y - 5, 28, feat.done, open and 0.8 or 0.6)
    if feat.done then Ring(c, 7, y - 5, 28) end
    Txt(c, feat.name, 13, feat.done and C.amber2 or open and C.ink or "b3a690", 45, y - 5, pw - 45 - rightW - 8)
    Txt(c, feat.need, 10.5, feat.done and C.ink2 or C.dim, 45, y - 21, pw - 45 - rightW - 8)
    Caret(c, pw - 17, y - 17, open, open and C.amber or "6f6354")
    local right
    if feat.done then
        right = Txt(c, feat.when and ShortDate(feat.when) or L["Done"], 11, C.ink, pw - 86, y - 13, 60, "RIGHT")
    elseif feat.goal then
        right = Txt(c, "|cffefe3cc" .. feat.have .. "|r / " .. feat.goal, 11, C.ink2, pw - 80, y - 13, 54, "RIGHT")
        Bar(c, pw - 152, y - 17, 64, feat.have / feat.goal)
    else
        right = Txt(c, L["Not yet"], 10.5, "6f6354", pw - 86, y - 13, 60, "RIGHT")
    end
    local hit = Hit(c, 0, y, pw, FEAT_H)
    hit.feat, hit.right = feat, right
    hit:SetScript("OnClick", function()
        featsOpen[feat.key] = not open or nil
        Refresh()
    end)
    y = y - FEAT_H
    if open then y = DrawCriteria(c, feat.crit, y, pw) end
    Ground(c, 0, top, pw, top - y, feat.done, open)
    return y
end

-- A done feat on the Summary: lit, with its category and day.
local function DrawRecent(c, feat, y, pw)
    Ground(c, 0, y, pw, FEAT_H, true)
    Icon(c, feat.icon, 7, y - 5, 28, true)
    Ring(c, 7, y - 5, 28)
    Txt(c, feat.name, 13, C.amber2, 45, y - 5, pw - 45 - 160)
    Txt(c, feat.need, 10.5, C.ink2, 45, y - 21, pw - 45 - 160)
    Txt(c, feat.group, 10.5, C.dim, pw - 156, y - 13, 92, "RIGHT")
    Txt(c, ShortDate(feat.when), 11, C.ink, pw - 60, y - 13, 50, "RIGHT")
    return y - FEAT_H - 4
end

local function DrawFeatSummary(c, view, groups, pw)
    local y = Head(c, 0, L["Records"], nil, pw)
    y = DrawRecords(c, view, y, pw)

    -- the last four feats done, with their days
    y = Head(c, y - 10, L["Recently done"], nil, pw)
    local recent = {}
    for _, g in ipairs(groups) do
        for _, feat in ipairs(g.feats) do
            if feat.done and feat.when then
                feat.group = g.name
                recent[#recent + 1] = feat
            end
        end
    end
    table.sort(recent, function(a, b) return a.when > b.when end)
    if #recent == 0 then
        Txt(c, L["No feats done yet."], 11, C.dim, 0, y - 2, pw)
        y = y - 22
    end
    for i = 1, math.min(4, #recent) do y = DrawRecent(c, recent[i], y, pw) end

    -- a bar per category
    local rows, done, total = {}, 0, 0
    for _, g in ipairs(groups) do
        rows[#rows + 1] = { name = g.name, have = g.done, total = #g.feats }
        done, total = done + g.done, total + #g.feats
    end
    y = Head(c, y - 10, L["Progress"], string.format(L["%d of %d done"], done, total), pw)
    return Progress(c, rows, y, pw, 118, 2)
end

function featsTab.Build(frame)
    return BuildSplit(featsTab, frame, FEAT_CATS)
end

function featsTab.Draw(view)
    local u = featsTab.ui
    local groups = Feats(view)
    featsTab.last = groups
    local counts, done, total = {}, 0, 0
    for _, g in ipairs(groups) do
        g.done = 0
        for _, feat in ipairs(g.feats) do
            if feat.done then g.done = g.done + 1 end
        end
        counts[g.key] = { g.done, #g.feats }
        done, total = done + g.done, total + #g.feats
    end
    counts.summary = { done, total }
    local chosen = Chosen(featsTab, u.nav)
    SetNav(u.nav, chosen, counts)

    local c, pw = u.canvas, u.width
    c.Reset()
    local y = 0
    if chosen == "summary" then
        y = DrawFeatSummary(c, view, groups, pw)
    else
        for _, g in ipairs(groups) do
            if g.key == chosen then
                y = Head(c, 0, g.name, string.format(L["%d of %d done"], g.done, #g.feats), pw, 18)
                for _, feat in ipairs(g.feats) do y = DrawFeat(c, feat, y, pw) - 4 end
            end
        end
    end
    u.child:SetHeight(math.max(1, -y + 4))
end

-- "8 of 23 done" by the title.
function featsTab.Count()
    local done, total = 0, 0
    for _, group in ipairs(featsTab.last or {}) do
        for _, feat in ipairs(group.feats) do
            total = total + 1
            if feat.done then done = done + 1 end
        end
    end
    return string.format(L["%d of %d done"], done, total)
end

-- Hal's line: the feat nearest done, and how many it's short.
function featsTab.Summary()
    local near, open
    for _, group in ipairs(featsTab.last or {}) do
        for _, feat in ipairs(group.feats) do
            if not feat.done then
                open = open or feat
                if feat.goal and (not near or feat.have / feat.goal > near.have / near.goal) then near = feat end
            end
        end
    end
    if near then return string.format(L["%s is %d short."], near.name, near.goal - near.have) end
    if open then return string.format(L["%s is still to do."], open.name) end
    return L["Every feat is done."]
end

local TABS = { fishTab, zonesTab, sessionsTab, collectionTab, featsTab }

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

local BANNER_H, TABS_H, FOOT_H = 78, 27, 34
local picker

ns.RegisterPage({
    name = "Stats",
    order = 10,
    place = "journal",
    build = function(p)
        panel = p
        -- opened feats stay open until the Journal is closed
        panel:HookScript("OnHide", function() wipe(featsOpen) end)

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
        -- Feats: "4 of 23 done" by the title
        banner.count = W.Text(banner, 12, C.amber2)
        banner.count:SetPoint("BOTTOMLEFT", banner.title, "BOTTOMRIGHT", 10, 2)

        -- the tabs
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

        -- each tab's table (Collection and Feats: their own frames)
        for _, tab in ipairs(TABS) do
            tab.frame = CreateFrame("Frame", nil, panel)
            tab.frame:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 14, -8)
            tab.frame:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", -14, 8)
            if tab.columns then
                tab.table = CreateTable(tab.frame, tab.columns, function(key) tab.OnSort(key) end)
            else
                tab.ui = tab.Build(tab.frame)
            end
        end

        -- a tab's own control sits at the right end of the tab strip, so no tab's table starts lower
        newSession = W.OakButton(strip, L["Start new session"], function() ns.StartSession() end, 20)
        newSession:SetPoint("BOTTOMRIGHT", -14, 3)

        uncaught = W.OakCheck(strip, L["Show fish I haven't caught yet"],
            function() return ReelDB.settings.statsUncaught end,
            function(v) ReelDB.settings.statsUncaught = v; Refresh() end)
        uncaught:SetPoint("BOTTOMRIGHT", -14, 5)
        uncaught.Refresh()

        -- the character picker, in the window's title bar (made once)
        if not picker then
            local slot = ns.WindowSlot and ns.WindowSlot()
            picker = W.Picker(slot or panel, 150, ScopeOptions, Scope,
                function(v) ReelDB.settings.statsScope = v; Refresh() end)
            picker:SetPoint("RIGHT", 0, 0)
        end
        picker.Refresh()

        -- Records became Collection and Feats
        if ReelDB.settings.statsTab == "records" then ReelDB.settings.statsTab = "collection" end
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
