-- Stats page: the fishing journal, in four tabs.
--   Fish      every item ever caught (click a header to sort), then the
--             known fish not caught yet (from FishData.lua)
--   Zones     zones, click to open sub-zones, click again for their catches
--   Sessions  sessions grouped by day, click one for its catches
--   Records   best session, biggest stack, rarest catch, totals, rare fish
-- A dropdown picks a character with catch data, or all of them together.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    statsTab = "fish",
    statsScope = "char", -- "all", or a character key; anything else means the current one
    statsUncaught = true,
})

local ROW_HEIGHT = 18
local INDENT = 14
local GREY = "|cff888888"

local panel, current, newSession, uncaught

local function ShortDate(t)
    if not t then return "-" end
    return date("%b ", t) .. tonumber(date("%d", t))
end

local function When(t, zone)
    if not t then return "-" end
    return zone and (ShortDate(t) .. "   " .. zone) or ShortDate(t)
end

local function ClockTime(t)
    return (date("%I:%M %p", t):gsub("^0", ""))
end

local function ItemName(link)
    return link and link:match("%[(.-)%]") or ""
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
    return best and best.link or "-"
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
    local list = { { value = "all", text = "All characters" }, { value = me, text = me } }
    for _, key in ipairs(others) do
        list[#list + 1] = { value = key, text = key }
    end
    return list
end

-- The data the tabs show: one character's, or every character's merged.
local function View()
    wipe(charOf)
    local scope = Scope()
    if scope ~= "all" then return ReelDB.chars[scope] end
    local v = { zones = {}, fish = {}, sessions = {}, records = {} }
    for key, d in pairs(ReelDB.chars) do
        for zone, subs in pairs(d.zones) do
            v.zones[zone] = v.zones[zone] or {}
            for sub, e in pairs(subs) do
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
    if charOf[session] then best = best .. "  " .. GREY .. charOf[session] .. "|r" end
    return best
end

-- "Elwynn Forest +5": the zone with the biggest share of catches, and how
-- many other zones have more than a trace.
local function FoundIn(fish)
    local best, most, others = nil, -1, 0
    for zone, percent in pairs(fish.zones) do
        if percent > most then best, most = zone, percent end
    end
    if not best then return "Location unknown" end
    for zone, percent in pairs(fish.zones) do
        if zone ~= best and percent >= 0.1 then others = others + 1 end
    end
    return others > 0 and string.format("%s +%d", best, others) or best
end

local function ItemRows(rows, items, indent)
    for _, item in ipairs(ns.SortedItems(items)) do
        rows[#rows + 1] = { cells = { item.count .. "x " .. item.link }, indent = indent, link = item.link }
    end
end

-- Table ----------------------------------------------------------------------
-- columns: list of { title, width, align, sort = key }. Rows given to SetRows:
-- { cells = { ... }, indent = n, heading = bool, link = itemLink, onClick = fn }

local function CreateTable(parent, columns, onSort)
    local t = {}
    local width = 0
    for _, col in ipairs(columns) do
        col.x = width
        width = width + col.width
    end

    local header = CreateFrame("Frame", nil, parent)
    header:SetPoint("TOPLEFT")
    header:SetSize(width, ROW_HEIGHT)
    local headers = {}
    for i, col in ipairs(columns) do
        local b = CreateFrame("Button", nil, header)
        b:SetPoint("TOPLEFT", col.x, 0)
        b:SetSize(col.width, ROW_HEIGHT)
        local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        fs:SetPoint("LEFT", 4, 0)
        fs:SetPoint("RIGHT", -4, 0)
        fs:SetJustifyH(col.align or "LEFT")
        fs:SetText(col.title)
        if col.sort then
            b:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            b:SetScript("OnClick", function() onSort(col.sort) end)
        end
        b.text = fs
        headers[i] = b
    end
    local line = header:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
    line:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
    line:SetHeight(1)

    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    scroll:SetPoint("BOTTOMRIGHT", -24, 0)
    local child = CreateFrame("Frame", nil, scroll)
    child:SetSize(width, 1)
    scroll:SetScrollChild(child)

    local pool = {}
    local function Row(i)
        if pool[i] then return pool[i] end
        local row = CreateFrame("Button", nil, child)
        row:SetSize(width, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        row.cells = {}
        for c, col in ipairs(columns) do
            local fs = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetJustifyH(col.align or "LEFT")
            fs:SetWordWrap(false)
            row.cells[c] = fs
        end
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

    function t.SetRows(rows)
        if #rows == 0 then rows = { { cells = { GREY .. "Nothing caught yet.|r" } } } end
        for i, data in ipairs(rows) do
            local row = Row(i)
            row.data = data
            local indent = (data.indent or 0) * INDENT
            for c, col in ipairs(columns) do
                local fs = row.cells[c]
                local pad = c == 1 and indent or 0
                fs:ClearAllPoints()
                fs:SetPoint("LEFT", row, "LEFT", col.x + 4 + pad, 0)
                fs:SetWidth(col.width - 8 - pad)
                fs:SetFontObject(data.heading and "GameFontNormalSmall" or "GameFontHighlightSmall")
                fs:SetText(data.cells[c] ~= nil and tostring(data.cells[c]) or "")
            end
            row:Show()
        end
        for i = #rows + 1, #pool do pool[i]:Hide() end
        child:SetHeight(#rows * ROW_HEIGHT)
    end

    -- Marks the sorted column's header with v (high to low) or ^.
    function t.SetSortMark(key, descending)
        for i, col in ipairs(columns) do
            local mark = col.sort == key and (descending and " v" or " ^") or ""
            headers[i].text:SetText(col.title .. mark)
        end
    end

    return t
end

local function Refresh()
    if not panel or not panel:IsVisible() or not current then return end
    current.table.SetRows(current.Rows(View()))
    if current.sortKey then current.table.SetSortMark(current.sortKey, current.descending) end
end

-- Tabs -----------------------------------------------------------------------

local fishTab = {
    key = "fish",
    name = "Fish",
    sortKey = "count",
    descending = true,
    columns = {
        { title = "Fish", width = 220, sort = "name" },
        { title = "Caught", width = 60, align = "RIGHT", sort = "count" },
        { title = "First caught", width = 154, sort = "first" },
        { title = "Last caught", width = 66, sort = "last" },
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

function fishTab.Rows(view)
    local key, descending = fishTab.sortKey, fishTab.descending
    local function Value(f)
        if key == "name" then return ItemName(f.link) end
        return f[key] or 0
    end
    local list = {}
    for _, f in pairs(view.fish) do list[#list + 1] = f end
    table.sort(list, function(a, b)
        local x, y = Value(a), Value(b)
        if x == y then return ItemName(a.link) < ItemName(b.link) end
        if descending then return x > y end
        return x < y
    end)
    local rows = {}
    for _, f in ipairs(list) do
        rows[#rows + 1] = {
            cells = { f.link, f.count, When(f.first, f.firstZone), ShortDate(f.last) },
            link = f.link,
        }
    end

    -- Known fish not caught yet, by name, after everything caught.
    if ReelDB.settings.statsUncaught then
        local missing = {}
        for id, fish in pairs(ns.FISH) do
            if not view.fish[id] then missing[#missing + 1] = { id = id, fish = fish } end
        end
        table.sort(missing, function(a, b) return a.fish.name < b.fish.name end)
        for _, m in ipairs(missing) do
            rows[#rows + 1] = {
                cells = { GREY .. m.fish.name .. "|r", GREY .. "-|r", GREY .. FoundIn(m.fish) .. "|r", "" },
                link = "item:" .. m.id,
            }
        end
    end
    return rows
end

local zonesOpen = {} -- zone, or zone .. "\t" .. sub -> true
local zonesTab = {
    key = "zones",
    name = "Zones",
    columns = {
        { title = "Zone", width = 230 },
        { title = "Casts", width = 60, align = "RIGHT" },
        { title = "Catches", width = 60, align = "RIGHT" },
        { title = "Top catch", width = 150 },
    },
}

local function Toggle(open, key)
    return function()
        open[key] = not open[key] or nil
        Refresh()
    end
end

function zonesTab.Rows(view)
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

    local rows = {}
    for _, z in ipairs(zones) do
        rows[#rows + 1] = {
            cells = { Arrow(zonesOpen[z.name]) .. z.name, z.casts, z.catches, Top(z.items) },
            onClick = Toggle(zonesOpen, z.name),
        }
        if zonesOpen[z.name] then
            for _, sub in ipairs(z.subs) do
                local key = z.name .. "\t" .. sub.name
                local e = sub.entry
                rows[#rows + 1] = {
                    cells = { Arrow(zonesOpen[key]) .. sub.name, e.casts, e.catches, Top(e.items) },
                    indent = 1,
                    onClick = Toggle(zonesOpen, key),
                }
                if zonesOpen[key] then ItemRows(rows, e.items, 2) end
            end
        end
    end
    return rows
end

local sessionsOpen = {} -- session table -> true
local sessionsTab = {
    key = "sessions",
    name = "Sessions",
    columns = {
        { title = "Started", width = 120 },
        { title = "Length", width = 70, align = "RIGHT" },
        { title = "Zone", width = 190 },
        { title = "Fish", width = 60, align = "RIGHT" },
        { title = "Bonus", width = 60, align = "RIGHT" },
    },
}

function sessionsTab.Rows(view)
    -- Newest first, grouped by the day each session started.
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

    local rows = {}
    for _, day in ipairs(days) do
        rows[#rows + 1] = {
            cells = { date("%A, %b ", day.start) .. tonumber(date("%d", day.start)), "", "", day.fish, day.bonus },
            heading = true,
        }
        for _, s in ipairs(day.sessions) do
            local started = ClockTime(s.start)
            if s == ns.session then started = started .. "  |cff40ff40now|r" end
            local length = s.first and s.last and s.last > s.first and ns.FormatTime(s.last - s.first) or "-"
            rows[#rows + 1] = {
                cells = { Arrow(sessionsOpen[s]) .. started, length, SessionZone(s), s.fish, s.bonus or 0 },
                indent = 1,
                onClick = Toggle(sessionsOpen, s),
            }
            if sessionsOpen[s] then ItemRows(rows, s.items, 2) end
        end
    end
    return rows
end

local recordsTab = {
    key = "records",
    name = "Records",
    columns = {
        { title = "Record", width = 140 },
        { title = "", width = 210 },
        { title = "When", width = 150 },
    },
}

function recordsTab.Rows(view)
    local casts, catches = 0, 0
    for _, subs in pairs(view.zones) do
        for _, entry in pairs(subs) do
            casts = casts + entry.casts
            catches = catches + entry.catches
        end
    end
    if casts == 0 and catches == 0 then return {} end

    local rows = {}
    local best
    for _, s in ipairs(view.sessions) do
        if s.fish > 0 and (not best or s.fish > best.fish) then best = s end
    end
    if best then
        rows[#rows + 1] = { cells = { "Best session", best.fish .. " fish", When(best.start, SessionZone(best)) } }
    end

    local stack = view.records.stack
    if stack then
        rows[#rows + 1] = {
            cells = { "Biggest stack", stack.qty .. "x " .. stack.link, When(stack.time, stack.zone) },
            link = stack.link,
        }
    end

    local rarest
    for _, f in pairs(view.fish) do
        local q, rq = f.quality or 0, rarest and (rarest.quality or 0)
        if not rarest or q > rq or (q == rq and f.count < rarest.count) then rarest = f end
    end
    if rarest then
        rows[#rows + 1] = {
            cells = { "Rarest catch", rarest.link, When(rarest.first, rarest.firstZone) },
            link = rarest.link,
        }
    end

    rows[#rows + 1] = { cells = { "Total casts", casts } }
    rows[#rows + 1] = { cells = { "Total catches", string.format("%d (%s of casts)", catches, Rate(catches, casts)) } }

    rows[#rows + 1] = { cells = { " " } }
    rows[#rows + 1] = { cells = { "Rare fish" }, heading = true }
    for _, rare in ipairs(ns.RARE_FISH) do
        local f = view.fish[rare.id]
        local name = ns.FISH[rare.id] and ns.FISH[rare.id].name or ("item " .. rare.id)
        if f then
            rows[#rows + 1] = {
                cells = { f.link, "Caught " .. f.count, When(f.first, f.firstZone) },
                link = f.link,
                indent = 1,
            }
        else
            rows[#rows + 1] = {
                cells = { GREY .. name .. "|r", GREY .. "Not caught yet|r", GREY .. rare.note .. "|r" },
                link = "item:" .. rare.id,
                indent = 1,
            }
        end
    end
    return rows
end

local TABS = { fishTab, zonesTab, sessionsTab, recordsTab }

local function Select(tab)
    current = tab
    ReelDB.settings.statsTab = tab.key
    for _, t in ipairs(TABS) do
        t.frame:SetShown(t == tab)
        if t == tab then t.button:LockHighlight() else t.button:UnlockHighlight() end
    end
    newSession:SetShown(tab == sessionsTab)
    uncaught:SetShown(tab == fishTab)
    Refresh()
end

-- Page -----------------------------------------------------------------------

ns.RegisterPage({
    name = "Stats",
    order = 10,
    build = function(p)
        panel = p
        for i, tab in ipairs(TABS) do
            tab.button = W.Button(panel, tab.name, 80, function() Select(tab) end)
            tab.button:SetPoint("TOPLEFT", (i - 1) * 84, 0)
            tab.frame = CreateFrame("Frame", nil, panel)
            tab.frame:SetPoint("TOPLEFT", 0, -30)
            tab.frame:SetPoint("BOTTOMRIGHT", 0, (tab == sessionsTab or tab == fishTab) and 30 or 0)
            tab.table = CreateTable(tab.frame, tab.columns, function(key) tab.OnSort(key) end)
        end

        newSession = W.Button(panel, "Start new session", 130, function() ns.StartSession() end)
        newSession:SetPoint("BOTTOMLEFT")

        uncaught = W.Checkbox(panel, "Show fish I haven't caught yet",
            function() return ReelDB.settings.statsUncaught end,
            function(v) ReelDB.settings.statsUncaught = v; Refresh() end)
        uncaught:SetPoint("BOTTOMLEFT", 0, 2)
        uncaught.Refresh()

        local scope = W.Dropdown(panel, "", 130, ScopeOptions, Scope,
            function(v) ReelDB.settings.statsScope = v; Refresh() end)
        scope:SetPoint("TOPRIGHT", -24, 0)
        scope.Refresh()

        local saved = ReelDB.settings.statsTab
        for _, tab in ipairs(TABS) do
            if tab.key == saved then current = tab end
        end
        return function() Select(current or fishTab) end
    end,
})

ns.On("REEL_DATA_CHANGED", Refresh)

-- Bar item: "Zone fish 3/7", how many of the fish known for this zone (more
-- than a trace on Wowhead) this character has caught here. With a pole only.
ns.RegisterBarSegment({
    key = "zoneFish",
    label = "Fish caught in this zone",
    order = 45,
    text = function()
        if not ns.PoleEquipped() then return end
        local zone = GetZoneText()
        local caught = {}
        for _, entry in pairs(ns.Data().zones[zone] or {}) do
            for id in pairs(entry.items) do caught[id] = true end
        end
        local have, total = 0, 0
        for id, fish in pairs(ns.FISH) do
            if (fish.zones[zone] or 0) >= 0.1 then
                total = total + 1
                if caught[id] then have = have + 1 end
            end
        end
        if total == 0 then return end
        local t = string.format("Zone fish %d/%d", have, total)
        if have == total then t = "|cff40ff40" .. t .. "|r" end
        return t
    end,
})
