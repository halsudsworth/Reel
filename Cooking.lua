-- Cooking hints: fish tooltips (in bags, loot, links, and the Stats page) list
-- the cooking recipes that use the fish, and for each one you don't know,
-- where to get it. Recipe data is in FishData.lua.

local _, ns = ...
local L = ns.L

ns.RegisterDefaults({
    cookingTips = true,
})

local GREEN, GREY, GOLD = "|cff40ff40", "|cff888888", "|cffffd100"

local function Known(spell)
    return (IsPlayerSpell and IsPlayerSpell(spell)) or (IsSpellKnown and IsSpellKnown(spell)) or false
end

-- Recipe vendors who sell to one faction only, from the faction on each NPC's
-- Wowhead Forever tooltip (2026-11-05). Anyone not listed sells to both: the
-- goblin towns, and the NPCs whose tooltip names no faction or a faction new
-- to Forever (Powderfuse, Brotherhood of the Horse, Azeroth
-- Commerce Authority).
local VENDOR_FACTION = {
    ["Catherine Leland"] = "Alliance", ["Chief Expeditionary Requisitioner Enkles"] = "Alliance",
    ["Emrul Riknussun"] = "Alliance", ["Erika Tate"] = "Alliance", ["Fyldan"] = "Alliance",
    ["Gloria Femmel"] = "Alliance", ["Gretta Ganter"] = "Alliance", ["Heldan Galesong"] = "Alliance",
    ["Khara Deepwater"] = "Alliance", ["Kriggon Talsone"] = "Alliance", ["Lindea Rabonne"] = "Alliance",
    ["Micha Yance"] = "Alliance", ["Nessa Shadowsong"] = "Alliance", ["Nyoma"] = "Alliance",
    ["Stuart Fleming"] = "Alliance", ["Tansy Puddlefizz"] = "Alliance", ["Tharynn Bouden"] = "Alliance",
    ["Vivianna"] = "Alliance",
    -- Kirin Tor of Dalaran, an Alliance city in this era.
    ["Derek Odds"] = "Alliance", ["Paige"] = "Alliance",
    ["Apothecary Quinard"] = "Horde", ["Aza'bek"] = "Horde", ["Derak Nightfall"] = "Horde",
    ["Harn Longcast"] = "Horde", ["Killian Sanatha"] = "Horde", ["Lizbeth Cromwell"] = "Horde",
    ["Martine Tramblay"] = "Horde", ["Naal Mistrunner"] = "Horde", ["Ronald Burch"] = "Horde",
    ["Sewa Mistrunner"] = "Horde", ["Shankys"] = "Horde", ["Sheendra Tallgrass"] = "Horde",
    ["Tarban Hearthgrain"] = "Horde", ["Wik'Tar"] = "Horde", ["Wulan"] = "Horde",
    ["Xen'to"] = "Horde", ["Zansoa"] = "Horde",
}

-- NPC IDs of the recipe vendors (MapData.lua and site/data/recipe_vendors.json, from Wowhead
-- Forever), to show each by the client's own name for it. Reagent Bot and Repair Bot are bots
-- players put down and have no fixed ID; they stay as written.
local VENDOR_IDS = {
    ["Apothecary Quinard"] = 17070, ["Aza'bek"] = 248198, ["Carrie Hearthfire"] = 240604,
    ["Catherine Leland"] = 5494, ["Chief Expeditionary Requisitioner Enkles"] = 17068,
    ["Derak Nightfall"] = 2397, ["Derek Odds"] = 252083, ["Emrul Riknussun"] = 5160,
    ["Erika Tate"] = 5483, ["Fimbo Greasemitz"] = 259962, ["Fyldan"] = 4223, ["Gikkix"] = 8137,
    ["Gloria Femmel"] = 3085, ["Gretta Ganter"] = 8508, ["Gritta Chumwater"] = 260487,
    ["Harn Longcast"] = 5940, ["Heldan Galesong"] = 4307, ["Kalsey Sanden"] = 256731,
    ["Kelsey Yance"] = 2664, ["Khara Deepwater"] = 1684, ["Killian Sanatha"] = 5748,
    ["Kilxx"] = 3497, ["Kriggon Talsone"] = 4305, ["Lindea Rabonne"] = 2383,
    ["Lizbeth Cromwell"] = 4574, ["Martine Tramblay"] = 3550, ["Micha Yance"] = 2381,
    ["Miranda Turner"] = 272646, ["Naal Mistrunner"] = 3027, ["Nessa Shadowsong"] = 10118,
    ["Nyalah Brightfire"] = 257006, ["Nyoma"] = 4265, ["Otho Moji'ko"] = 14738, ["Paige"] = 267000,
    ["Qujo"] = 270780, ["Ronald Burch"] = 4553, ["Sewa Mistrunner"] = 3029, ["Shankys"] = 3333,
    ["Sheendra Tallgrass"] = 8145, ["Stuart Fleming"] = 3178, ["Tansy Puddlefizz"] = 5162,
    ["Tarban Hearthgrain"] = 8307, ["Tharynn Bouden"] = 66, ["Vivianna"] = 7947,
    ["Wik'Tar"] = 12962, ["Wulan"] = 12033, ["Xen'to"] = 3400, ["Zansoa"] = 5942,
    ["Zerril Softbreeze"] = 251905,
}

-- A vendor's name in the client's language: the game names an NPC on a unit tooltip once the
-- client has seen it, so the English name stands in until then.
local ENGLISH = GetLocale():find("^en") ~= nil
local npcNames = {}
local function VendorName(english)
    if ENGLISH then return english end
    local id = VENDOR_IDS[english]
    if not id then return english end
    if npcNames[id] then return npcNames[id] end
    if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
        local ok, info = pcall(C_TooltipInfo.GetHyperlink, "unit:Creature-0-0-0-0-" .. id .. "-0000000000")
        local name = ok and info and info.lines and info.lines[1] and info.lines[1].leftText
        if name and name ~= "" then npcNames[id] = name; return name end
    end
    return english
end

-- Continent of each zone, from Forever's own map tree (C_Map.GetMapInfo
-- parents, read on launch night). Zephras Isle hangs off the world map on
-- its own.
local CONTINENT = {}
for continent, zones in pairs({
    Kalimdor = { "Durotar", "Mulgore", "The Barrens", "Teldrassil", "Darkshore", "Ashenvale",
        "Thousand Needles", "Stonetalon Mountains", "Desolace", "Feralas", "Dustwallow Marsh",
        "Tanaris", "Azshara", "Felwood", "Un'Goro Crater", "Moonglade", "Silithus", "Winterspring",
        "Orgrimmar", "Thunder Bluff", "Darnassus", "Mount Hyjal", "Shen'dralas" },
    ["Eastern Kingdoms"] = { "Alterac Mountains", "Arathi Highlands", "Badlands", "Blasted Lands",
        "Tirisfal Glades", "Silverpine Forest", "Western Plaguelands", "Eastern Plaguelands",
        "Hillsbrad Foothills", "The Hinterlands", "Dun Morogh", "Searing Gorge", "Burning Steppes",
        "Elwynn Forest", "Deadwind Pass", "Duskwood", "Loch Modan", "Redridge Mountains",
        "Stranglethorn Vale", "Swamp of Sorrows", "Westfall", "Wetlands", "Stormwind City",
        "Ironforge", "Undercity", "Riverglades" },
    ["Zephras Isle"] = { "Zephras Isle" },
}) do
    for _, zone in ipairs(zones) do CONTINENT[zone] = continent end
end

-- "Naal Mistrunner, Thunder Bluff (+3 more)": the closest vendor who sells to
-- your faction. A vendor in the zone you're in first, then one on your
-- continent, then anywhere. Vendors of the other faction are left out.
local function Where(recipe)
    if not recipe.from then return L[recipe.how] end
    local faction = UnitFactionGroup("player")
    local zone = ns.EnglishZone(GetZoneText()) -- the vendor list is in English
    local continent = CONTINENT[zone]
    local pick, pickRank, count = nil, nil, 0
    for _, vendor in ipairs(recipe.from) do
        local sells = VENDOR_FACTION[vendor[1]]
        if not sells or sells == faction then
            count = count + 1
            local rank = (vendor[2] == zone and 1) or (continent and CONTINENT[vendor[2]] == continent and 2) or 3
            if not pick or rank < pickRank then pick, pickRank = vendor, rank end
        end
    end
    if not pick then return L["Vendor"] end
    local text = VendorName(pick[1]) .. ", " .. ns.LocalZone(pick[2])
    if count > 1 then text = text .. string.format(L[" (+%d more)"], count - 1) end
    return text
end

-- A recipe's name in the client's language: the recipe spell's own name.
local function RecipeName(recipe)
    if ENGLISH then return recipe.name end
    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(recipe.spell)
        or GetSpellInfo and GetSpellInfo(recipe.spell)
    return name or recipe.name
end

local function AddLines(tooltip, id)
    if not ReelDB or not ReelDB.settings.cookingTips then return end
    local recipes = id and ns.FISH_RECIPES[id]
    if not recipes then return end
    tooltip:AddLine(" ")
    for _, recipe in ipairs(recipes) do
        if Known(recipe.spell) then
            tooltip:AddLine(GOLD .. L["Cooking:"] .. "|r " .. RecipeName(recipe) .. " " .. GREEN .. L["(known)"] .. "|r")
        else
            tooltip:AddLine(GOLD .. L["Cooking:"] .. "|r " .. RecipeName(recipe) .. GREY .. string.format(L[" (skill %s)"], recipe.cooking) .. "|r")
            tooltip:AddLine("   " .. string.format(L["Recipe: %s"], Where(recipe)), 1, 1, 1)
        end
    end
    tooltip:Show()
end

local function ItemID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

ns.On("REEL_READY", function()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                AddLines(tooltip, data and data.id)
            end
        end)
    else
        for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
            tooltip:HookScript("OnTooltipSetItem", function(self)
                local _, link = self:GetItem()
                AddLines(self, ItemID(link))
            end)
        end
    end
end)
