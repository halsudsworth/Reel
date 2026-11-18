-- Map pins: fishing trainers, pole and lure vendors, Nat Pagle and the Extravaganza NPCs
-- (MapData.lua) on the world map and the minimap. Only your faction's NPCs and those who
-- serve both. NPCs standing on the same spot share one pin; its tooltip lists them all.
--
-- World map: a map canvas data provider, so the pins follow the map's own zoom and map changes.
-- Minimap: the pin's distance from you in yards (from the zone map's size), scaled by the
-- minimap's zoom, turned with the minimap when it rotates.

local _, ns = ...
local L = ns.L

ns.RegisterDefaults({
    mapPinsWorld = true,   -- pins on the world map
    mapPinsMinimap = true, -- pins on the minimap
})

local ICONS = {
    trainer = "Interface\\Icons\\Trade_Fishing",
    vendor = "Interface\\Icons\\INV_Fishingpole_02",
    quest = "Interface\\GossipFrame\\AvailableQuestIcon",
    event = "Interface\\Icons\\INV_Misc_Fish_02",
}
local ROLE_TEXT = {
    trainer = L["Fishing trainer"],
    vendor = L["Fishing supplies"],
    quest = L["Quest"],
    event = L["Stranglethorn Fishing Extravaganza"],
}

-- Pin groups by map ID: { x, y, npcs = {...} }, built once the zone names are known.
local byMap

local function MapIDs()
    local ids = {}
    for id, english in pairs(ns.CALENDAR_DATA and ns.CALENDAR_DATA.maps or {}) do
        if type(english) == "string" then ids[english] = id end
    end
    return ids
end

local function Groups()
    if byMap then return byMap end
    byMap = {}
    local ids = MapIDs()
    local faction = UnitFactionGroup and UnitFactionGroup("player")
    local mine = faction == "Alliance" and "A" or faction == "Horde" and "H" or nil
    for _, npc in ipairs(ns.FISHING_NPCS or {}) do
        local map = ids[npc.zone]
        if map and (npc.faction == "both" or npc.faction == mine) then
            local list = byMap[map] or {}
            byMap[map] = list
            local group
            for _, g in ipairs(list) do
                if math.abs(g.x - npc.x) <= 0.6 and math.abs(g.y - npc.y) <= 0.6 then group = g; break end
            end
            if not group then
                group = { x = npc.x / 100, y = npc.y / 100, npcs = {} }
                list[#list + 1] = group
            end
            group.npcs[#group.npcs + 1] = npc
        end
    end
    -- the pin's icon is its first NPC's: a trainer first, then a vendor
    local rank = { trainer = 1, vendor = 2, quest = 3, event = 4 }
    for _, list in pairs(byMap) do
        for _, g in ipairs(list) do
            table.sort(g.npcs, function(a, b) return (rank[a.role] or 9) < (rank[b.role] or 9) end)
            g.icon = ICONS[g.npcs[1].role] or ICONS.trainer
        end
    end
    return byMap
end

local function ShowTip(pin)
    local g = pin.group
    if not g then return end
    GameTooltip:SetOwner(pin, "ANCHOR_RIGHT")
    for i, npc in ipairs(g.npcs) do
        if i > 1 then GameTooltip:AddLine(" ") end
        GameTooltip:AddLine(npc.name, 1, 0.82, 0)
        GameTooltip:AddLine(ROLE_TEXT[npc.role] or "", 0.8, 0.8, 0.8)
        if npc.teaches then GameTooltip:AddLine(string.format(L["Teaches: %s"], npc.teaches), 1, 1, 1, true) end
        if npc.sells then GameTooltip:AddLine(string.format(L["Sells: %s"], npc.sells), 1, 1, 1, true) end
        if npc.note then GameTooltip:AddLine(npc.note, 1, 1, 1, true) end
    end
    GameTooltip:Show()
end

local function NewPin(parent)
    local pin = CreateFrame("Frame", nil, parent)
    pin.reelPin = true
    pin:EnableMouse(true)
    pin.tex = pin:CreateTexture(nil, "OVERLAY")
    pin.tex:SetAllPoints()
    pin:SetScript("OnEnter", ShowTip)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    pin:Hide()
    return pin
end

local function SetGroup(pin, g)
    pin.group = g
    pin.tex:SetTexture(g.icon)
    -- item and spell icons lose their baked-in border; the quest mark is used whole
    if g.icon == ICONS.quest then pin.tex:SetTexCoord(0, 1, 0, 1) else pin.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92) end
end

-- World map -------------------------------------------------------------------

local WORLD_SIZE = 16
local worldPins = {}
local provider

-- Above the map's own layers: the map hands out frame levels to its pins, and its terrain and
-- overlays sit well above the canvas's own level, so a fixed offset can land under the map.
local function TopLevel(map, canvas)
    local top = canvas:GetFrameLevel()
    for _, child in ipairs({ canvas:GetChildren() }) do
        if not child.reelPin and child:GetFrameLevel() > top then top = child:GetFrameLevel() end
    end
    local manager = map.GetPinFrameLevelsManager and map:GetPinFrameLevelsManager()
    if manager and manager.GetValidFrameLevel then
        local ok, level = pcall(manager.GetValidFrameLevel, manager, "PIN_FRAME_LEVEL_AREA_POI")
        if ok and type(level) == "number" and level > top then top = level end
    end
    return math.min(top + 10, 9000)
end

local function SetupWorldMap()
    if provider or not (WorldMapFrame and WorldMapFrame.AddDataProvider and MapCanvasDataProviderMixin) then return end
    provider = CreateFromMixins(MapCanvasDataProviderMixin)

    function provider:RemoveAllData()
        for _, pin in ipairs(worldPins) do pin:Hide(); pin.group = nil end
    end

    function provider:RefreshAllData()
        self:RemoveAllData()
        if not ReelDB.settings.mapPinsWorld then return end
        local map = self:GetMap()
        local list = Groups()[map:GetMapID()]
        if not list then return end
        local canvas = map:GetCanvas()
        local w, h = canvas:GetWidth(), canvas:GetHeight()
        for i, g in ipairs(list) do
            local pin = worldPins[i] or NewPin(canvas)
            worldPins[i] = pin
            pin:SetParent(canvas)
            pin:SetFrameLevel(TopLevel(map, canvas))
            SetGroup(pin, g)
            pin:ClearAllPoints()
            pin:SetPoint("CENTER", canvas, "TOPLEFT", g.x * w, -g.y * h)
            pin:Show()
        end
        self:OnCanvasScaleChanged()
    end

    -- Clicking to another zone: the map tells each provider its map changed, and the base
    -- provider doesn't redraw on its own.
    function provider:OnMapChanged() self:RefreshAllData() end
    function provider:OnShow() self:RefreshAllData() end

    -- Pins keep their size on screen as the map zooms.
    function provider:OnCanvasScaleChanged()
        local scale = self:GetMap():GetCanvasScale() or 1
        if scale <= 0 then scale = 1 end
        for _, pin in ipairs(worldPins) do pin:SetSize(WORLD_SIZE / scale, WORLD_SIZE / scale) end
    end

    WorldMapFrame:AddDataProvider(provider)
end

-- /reel debug pins: what the world map pins are doing, with the map open.
function ns.DebugPins()
    local map = WorldMapFrame and WorldMapFrame:GetMapID()
    local added = provider and WorldMapFrame.dataProviders and WorldMapFrame.dataProviders[provider]
    local list = map and Groups()[map]
    ns.Print(string.format("pins: provider %s, added %s, map %s, groups here %d, pins made %d, setting %s",
        tostring(provider ~= nil), tostring(added), tostring(map), list and #list or 0, #worldPins,
        tostring(ReelDB.settings.mapPinsWorld)))
    if provider and provider:GetMap() then
        local ok, err = pcall(provider.RefreshAllData, provider)
        if not ok then ns.Print("refresh error: " .. tostring(err)) end
    end
    local canvas = WorldMapFrame and WorldMapFrame.GetCanvas and WorldMapFrame:GetCanvas()
    if canvas then
        ns.Print(string.format("canvas %.0fx%.0f level %d scale %s", canvas:GetWidth(), canvas:GetHeight(),
            canvas:GetFrameLevel(), tostring(WorldMapFrame:GetCanvasScale())))
    end
    for i, pin in ipairs(worldPins) do
        local x, y = pin:GetCenter()
        ns.Print(string.format("pin %d: shown %s visible %s size %.1f at %s,%s level %d tex %s", i,
            tostring(pin:IsShown()), tostring(pin:IsVisible()), pin:GetWidth(), tostring(x and math.floor(x)),
            tostring(y and math.floor(y)), pin:GetFrameLevel(), tostring(pin.tex:GetTexture())))
    end
end

local function RefreshWorldMap()
    if provider and provider:GetMap() and WorldMapFrame:IsShown() then provider:RefreshAllData() end
end

-- Minimap ---------------------------------------------------------------------

-- The minimap's diameter in yards at each zoom level (the client's own scale, the same one
-- HereBeDragons-Pins uses).
local MINIMAP_YARDS = {
    indoor = { [0] = 300, 240, 180, 120, 80, 50 },
    outdoor = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 },
}
local MINI_SIZE = 10
local miniPins = {}   -- one per group, in order of `miniGroups`
local miniGroups = {} -- { map, group } for the maps near the player
local mapYards = {}   -- map ID -> width, height in yards

local function MapYards(map)
    local size = mapYards[map]
    if size then return size[1], size[2] end
    local w, h
    if C_Map.GetMapWorldSize then w, h = C_Map.GetMapWorldSize(map) end
    if not (w and w > 0) and C_Map.GetWorldPosFromMapPos and CreateVector2D then
        -- the map's corners in world space; the distance between them is the size whatever
        -- way round the world axes are
        local _, a = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(0, 0))
        local _, b = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(1, 0))
        local _, c = C_Map.GetWorldPosFromMapPos(map, CreateVector2D(0, 1))
        if a and b and c then
            local ax, ay = a.x, a.y
            local bx, by = b.x, b.y
            local cx, cy = c.x, c.y
            w = math.sqrt((bx - ax) ^ 2 + (by - ay) ^ 2)
            h = math.sqrt((cx - ax) ^ 2 + (cy - ay) ^ 2)
        end
    end
    if not (w and w > 0 and h and h > 0) then return end
    mapYards[map] = { w, h }
    return w, h
end

local function PlayerPos(map)
    local ok, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
    if ok and pos then
        local x, y = pos.x, pos.y
        if x and y and (x ~= 0 or y ~= 0) then return x, y end
    end
end

-- The maps the player has a position on (their zone and its neighbours), after each zone change.
local function FindMiniGroups()
    wipe(miniGroups)
    if not (C_Map and C_Map.GetPlayerMapPosition) then return end
    for map, list in pairs(Groups()) do
        if PlayerPos(map) and MapYards(map) then
            for _, g in ipairs(list) do miniGroups[#miniGroups + 1] = { map = map, group = g } end
        end
    end
    for i, entry in ipairs(miniGroups) do
        local pin = miniPins[i] or NewPin(Minimap)
        miniPins[i] = pin
        pin:SetSize(MINI_SIZE, MINI_SIZE)
        pin:SetFrameLevel(Minimap:GetFrameLevel() + 5)
        SetGroup(pin, entry.group)
    end
    for i = #miniGroups + 1, #miniPins do miniPins[i]:Hide() end
end

local function UpdateMinimap()
    if not ReelDB.settings.mapPinsMinimap or not Minimap:IsVisible() then
        for _, pin in ipairs(miniPins) do pin:Hide() end
        return
    end
    local indoors = IsIndoors and IsIndoors()
    local zoom = Minimap:GetZoom() or 0
    local yards = (indoors and MINIMAP_YARDS.indoor or MINIMAP_YARDS.outdoor)[zoom] or MINIMAP_YARDS.outdoor[0]
    local half = Minimap:GetWidth() / 2
    local perYard = half / (yards / 2)
    local rotate = GetCVar("rotateMinimap") == "1"
    local facing = rotate and GetPlayerFacing and GetPlayerFacing() or 0
    local cosF, sinF = math.cos(facing), math.sin(facing)
    local square = GetMinimapShape and GetMinimapShape() == "SQUARE"
    local here = {}
    for i, entry in ipairs(miniGroups) do
        local pin = miniPins[i]
        local px, py
        if here[entry.map] == nil then
            px, py = PlayerPos(entry.map)
            here[entry.map] = px and { px, py } or false
        elseif here[entry.map] then
            px, py = here[entry.map][1], here[entry.map][2]
        end
        local w, h = MapYards(entry.map)
        if px and w then
            -- yards east and north of the player, then minimap pixels
            local sx = (entry.group.x - px) * w * perYard
            local sy = -(entry.group.y - py) * h * perYard
            if rotate then
                sx, sy = sx * cosF + sy * sinF, -sx * sinF + sy * cosF
            end
            local inside = square and (math.abs(sx) <= half and math.abs(sy) <= half)
                or (not square and sx * sx + sy * sy <= half * half)
            if inside then
                pin:ClearAllPoints()
                pin:SetPoint("CENTER", Minimap, "CENTER", sx, sy)
                pin:Show()
            else
                pin:Hide()
            end
        else
            pin:Hide()
        end
    end
end

local ticker
local function StartMinimap()
    FindMiniGroups()
    if not ticker then ticker = C_Timer.NewTicker(0.05, UpdateMinimap) end
end

-- Setup -------------------------------------------------------------------------

function ns.RefreshMapPins()
    RefreshWorldMap()
    UpdateMinimap()
end

ns.On("PLAYER_ENTERING_WORLD", function()
    byMap = nil -- faction and zone names are known now
    SetupWorldMap()
    RefreshWorldMap()
    StartMinimap()
end)
ns.On("ZONE_CHANGED_NEW_AREA", FindMiniGroups)
ns.On("ADDON_LOADED", function(name)
    if name == "Blizzard_WorldMap" then SetupWorldMap() end
end)
