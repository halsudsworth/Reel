-- Fishing data for WoW Forever. zones: where each fish is a real catch (not
-- just a trace). best: where to send people for it; a capital is never sent to
-- the other faction, so those fish carry one pick per faction. A script writes
-- both; don't edit them by hand.

local _, ns = ...

-- itemID -> { name, best = zone or { Alliance, Horde }, zones = { zone, ... } }
ns.FISH = {
    [6291] = { name = "Raw Brilliant Smallfish", best = "Mulgore", zones = { "Mulgore", "Elwynn Forest", "Dun Morogh", "Tirisfal Glades", "Orgrimmar", "Darnassus", "Stormwind City", "Thunder Bluff", "Ironforge", "Teldrassil", "Durotar", "Undercity", "Loch Modan", "The Barrens", "Silverpine Forest", "Duskwood", "Westfall", "Darkshore" } },
    [6303] = { name = "Raw Slitherskin Mackerel", best = "Durotar", zones = { "Durotar", "Teldrassil", "Westfall", "Darkshore", "Tirisfal Glades", "Silverpine Forest", "The Barrens", "Stormwind City" } },
    [6289] = { name = "Raw Longjaw Mud Snapper", best = { Alliance = "Darnassus", Horde = "Orgrimmar" }, zones = { "Darnassus", "Orgrimmar", "Ironforge", "Thunder Bluff", "Stormwind City", "Loch Modan", "Undercity", "Dun Morogh", "Mulgore", "Elwynn Forest", "Duskwood", "Arathi Basin", "Redridge Mountains", "Tirisfal Glades", "The Barrens", "Ashenvale", "Silverpine Forest", "Stonetalon Mountains", "Hillsbrad Foothills", "Westfall", "Teldrassil", "Durotar", "Darkshore", "Wetlands" } },
    [6317] = { name = "Raw Loch Frenzy", best = "Loch Modan", zones = { "Loch Modan" } },
    [6361] = { name = "Raw Rainbow Fin Albacore", best = "Wetlands", zones = { "Wetlands", "Westfall", "Darkshore", "Ashenvale", "Silverpine Forest", "The Barrens", "Stormwind City" } },
    [6308] = { name = "Raw Bristle Whisker Catfish", best = "Hillsbrad Foothills", zones = { "Hillsbrad Foothills", "Redridge Mountains", "Arathi Basin", "Duskwood", "Ashenvale", "Stonetalon Mountains", "Thousand Needles", "Arathi Highlands", "Desolace", "Ironforge", "Stormwind City", "Thunder Bluff", "Orgrimmar", "Darnassus", "Alterac Mountains", "Undercity", "Loch Modan", "The Barrens", "Silverpine Forest", "Swamp of Sorrows", "Westfall", "Wetlands", "Darkshore", "Dustwallow Marsh", "Stranglethorn Vale" } },
    [21071] = { name = "Raw Sagefish", best = "Silverpine Forest", zones = { "Silverpine Forest", "Stonetalon Mountains", "Ashenvale", "Loch Modan" } },
    [6522] = { name = "Deviate Fish", best = "The Barrens", zones = { "The Barrens" } },
    [6299] = { name = "Sickly Looking Fish", best = { Alliance = "Tirisfal Glades", Horde = "Undercity" }, zones = { "Undercity", "Tirisfal Glades", "Silverpine Forest" } },
    [6458] = { name = "Oil Covered Fish", best = "Stonetalon Mountains", zones = { "Stonetalon Mountains" } },
    [6362] = { name = "Raw Rockscale Cod", best = "Stranglethorn Vale", zones = { "Stranglethorn Vale", "Dustwallow Marsh", "Swamp of Sorrows", "Desolace", "Tanaris", "The Hinterlands", "Azshara", "Feralas", "Arathi Highlands", "Westfall" } },
    [8365] = { name = "Raw Mithril Head Trout", best = "Thousand Needles", zones = { "Thousand Needles", "Arathi Highlands", "Desolace", "Alterac Mountains", "Swamp of Sorrows", "Moonglade", "Un'Goro Crater", "Western Plaguelands", "Felwood", "Dustwallow Marsh", "Feralas", "Stranglethorn Vale", "The Hinterlands", "Eastern Plaguelands", "Azshara" } },
    [21153] = { name = "Raw Greater Sagefish", best = "Alterac Mountains", zones = { "Alterac Mountains", "Stranglethorn Vale" } },
    [4603] = { name = "Raw Spotted Yellowtail", best = "Tanaris", zones = { "Tanaris", "The Hinterlands", "Azshara", "Feralas", "Dustwallow Marsh", "Swamp of Sorrows", "Stranglethorn Vale", "Desolace", "Arathi Highlands" } },
    [13754] = { name = "Raw Glossy Mightfish", best = "Tanaris", zones = { "Tanaris", "The Hinterlands", "Azshara", "Feralas" } },
    [13755] = { name = "Raw Winter Squid", best = "Azshara", zones = { "Azshara", "Tanaris", "The Hinterlands", "Feralas" } },
    [13756] = { name = "Raw Summer Bass", best = "Azshara", zones = { "Azshara", "Tanaris", "The Hinterlands", "Feralas" } },
    [13758] = { name = "Raw Redgill", best = "Felwood", zones = { "Felwood", "Un'Goro Crater", "Western Plaguelands", "Moonglade", "Feralas", "The Hinterlands", "Eastern Plaguelands", "Burning Steppes", "Winterspring", "Silithus", "Alterac Valley", "Azshara", "Deadwind Pass" } },
    [13759] = { name = "Raw Nightfin Snapper", best = "Winterspring", zones = { "Alterac Valley", "Winterspring", "Un'Goro Crater", "Eastern Plaguelands", "Silithus", "Moonglade", "Western Plaguelands", "Felwood", "Feralas", "Burning Steppes", "The Hinterlands", "Deadwind Pass" } },
    [13760] = { name = "Raw Sunscale Salmon", best = "Burning Steppes", zones = { "Burning Steppes", "Eastern Plaguelands", "Winterspring", "Felwood", "Silithus", "Alterac Valley", "Western Plaguelands", "Moonglade", "Un'Goro Crater", "Feralas", "The Hinterlands", "Deadwind Pass" } },
    [13888] = { name = "Darkclaw Lobster", best = "Azshara", zones = { "Azshara" } },
    [13889] = { name = "Raw Whitescale Salmon", best = "Deadwind Pass", zones = { "Deadwind Pass", "Silithus", "Winterspring", "Alterac Valley", "Eastern Plaguelands", "Burning Steppes", "Feralas" } },
    [13893] = { name = "Large Raw Mightfish", best = "Azshara", zones = { "Azshara" } },
    [13890] = { name = "Raw Plated Armorfish", best = "Silithus", zones = { "Alterac Valley", "Silithus", "Winterspring", "Burning Steppes", "Eastern Plaguelands", "Deadwind Pass" } },
    [6358] = { name = "Oily Blackmouth", best = "Wetlands", zones = { "Wetlands", "Westfall", "Silverpine Forest", "Dustwallow Marsh", "Darkshore", "Stranglethorn Vale", "Felwood", "Moonglade", "Western Plaguelands", "Un'Goro Crater", "Swamp of Sorrows", "The Barrens", "Feralas", "Ashenvale", "Desolace", "Tanaris", "The Hinterlands", "Azshara", "Arathi Highlands", "Eastern Plaguelands", "Stormwind City" } },
    [6359] = { name = "Firefin Snapper", best = "Stonetalon Mountains", zones = { "Stonetalon Mountains", "Wetlands", "Dustwallow Marsh", "Tanaris", "Stranglethorn Vale", "Swamp of Sorrows", "Desolace", "The Hinterlands", "Feralas", "Azshara", "Ashenvale", "Arathi Highlands" } },
    [13422] = { name = "Stonescale Eel", best = "Azshara", zones = { "Azshara", "Tanaris", "Feralas", "The Hinterlands", "Stranglethorn Vale" } },
    [13757] = { name = "Lightning Eel", best = "Burning Steppes", zones = { "Burning Steppes", "Alterac Valley", "Silithus", "Eastern Plaguelands", "Winterspring", "Deadwind Pass", "Western Plaguelands", "Felwood", "Moonglade", "Un'Goro Crater", "Feralas" } },
    [19975] = { name = "Zulian Mudskunk", zones = {} }, -- Zul'Gurub only: load five into a Mudskunk Lure and fish at Pagle's Point. Open-world rows for it are left out.
    [6643] = { name = "Bloated Brilliant Smallfish", best = "Dun Morogh", zones = {} },
    [6645] = { name = "Bloated Mud Snapper", best = "Silverpine Forest", zones = {} },
    [6647] = { name = "Bloated Bristle Whisker Catfish", best = "Hillsbrad Foothills", zones = { "Hillsbrad Foothills" } },
    [8366] = { name = "Bloated Mithril Head Trout", best = "Arathi Highlands", zones = {} },
    [13881] = { name = "Bloated Redgill", best = "Durotar", zones = {} },
    [13891] = { name = "Bloated Whitescale Salmon", best = "Winterspring", zones = {} },
    [1467] = { name = "Spotted Sunfish", best = "Redridge Mountains", zones = {} },
    [6717] = { name = "Gaffer Jack", best = "Silithus", zones = {} },
    [16967] = { name = "Feralas Ahi", best = "Feralas", zones = {} },
    [16968] = { name = "Sar'theris Striker", best = "Desolace", zones = {} },
    [16969] = { name = "Savage Coast Blue Sailfin", best = "Stranglethorn Vale", zones = {} },
    [16970] = { name = "Misty Reed Mahi Mahi", best = "Swamp of Sorrows", zones = {} },
    [19803] = { name = "Brownell's Blue Striped Racer", best = "Stranglethorn Vale", zones = {} },
    [19805] = { name = "Keefer's Angelfish", best = "Stranglethorn Vale", zones = {} },
    [19806] = { name = "Dezian Queenfish", best = "Stranglethorn Vale", zones = {} },
    [19807] = { name = "Speckled Tastyfish", best = "Stranglethorn Vale", zones = {} },
    [19808] = { name = "Rockhide Strongfish", best = "Stranglethorn Vale", zones = {} },
    [251524] = { name = "Whimsyfin", best = "Redridge Mountains", zones = {} }, -- Icy Veins; catch rate unknown, so the bar doesn't count it
}

-- Cooking recipes that use a fish: fishID -> list of
-- { spell, name, cooking = skill, from = { { npc, zone }, ... } or how = text }
ns.FISH_RECIPES = {
    [6291] = {
        { spell = 7751, name = "Brilliant Smallfish", cooking = 1, from = { { "Tharynn Bouden", "Elwynn Forest" }, { "Khara Deepwater", "Loch Modan" }, { "Sewa Mistrunner", "Thunder Bluff" }, { "Martine Tramblay", "Tirisfal Glades" }, { "Nyoma", "Teldrassil" }, { "Lizbeth Cromwell", "Undercity" }, { "Catherine Leland", "Stormwind City" }, { "Harn Longcast", "Mulgore" }, { "Gretta Ganter", "Dun Morogh" }, { "Nyalah Brightfire", "Zephras Isle" } } },
    },
    [6303] = {
        { spell = 7752, name = "Slitherskin Mackerel", cooking = 1, from = { { "Martine Tramblay", "Tirisfal Glades" }, { "Kriggon Talsone", "Westfall" }, { "Tansy Puddlefizz", "Ironforge" }, { "Zansoa", "Durotar" }, { "Nessa Shadowsong", "Teldrassil" }, { "Nyalah Brightfire", "Zephras Isle" } } },
    },
    [6289] = {
        { spell = 7753, name = "Longjaw Mud Snapper", cooking = 50, from = { { "Tharynn Bouden", "Elwynn Forest" }, { "Khara Deepwater", "Loch Modan" }, { "Naal Mistrunner", "Thunder Bluff" }, { "Nyoma", "Teldrassil" }, { "Lizbeth Cromwell", "Undercity" }, { "Tansy Puddlefizz", "Ironforge" }, { "Killian Sanatha", "Silverpine Forest" }, { "Harn Longcast", "Mulgore" }, { "Nyalah Brightfire", "Zephras Isle" } } },
    },
    [6317] = {
        { spell = 7754, name = "Loch Frenzy Delight", cooking = 50, from = { { "Khara Deepwater", "Loch Modan" } } },
    },
    [6361] = {
        { spell = 7827, name = "Rainbow Fin Albacore", cooking = 50, from = { { "Stuart Fleming", "Wetlands" }, { "Shankys", "Orgrimmar" }, { "Kilxx", "The Barrens" }, { "Kriggon Talsone", "Westfall" }, { "Heldan Galesong", "Darkshore" }, { "Ronald Burch", "Undercity" }, { "Catherine Leland", "Stormwind City" }, { "Killian Sanatha", "Silverpine Forest" }, { "Zansoa", "Durotar" }, { "Nessa Shadowsong", "Teldrassil" }, { "Gritta Chumwater", "Riverglades" } } },
    },
    [6308] = {
        { spell = 7755, name = "Bristle Whisker Catfish", cooking = 100, from = { { "Lindea Rabonne", "Hillsbrad Foothills" }, { "Derak Nightfall", "Hillsbrad Foothills" }, { "Naal Mistrunner", "Thunder Bluff" }, { "Sewa Mistrunner", "Thunder Bluff" }, { "Kilxx", "The Barrens" }, { "Ronald Burch", "Undercity" }, { "Catherine Leland", "Stormwind City" }, { "Gritta Chumwater", "Riverglades" } } },
    },
    [21071] = {
        { spell = 25704, name = "Smoked Sagefish", cooking = 80, from = { { "Micha Yance", "Hillsbrad Foothills" }, { "Derak Nightfall", "Hillsbrad Foothills" }, { "Kelsey Yance", "Stranglethorn Vale" }, { "Naal Mistrunner", "Thunder Bluff" }, { "Gloria Femmel", "Redridge Mountains" }, { "Xen'to", "Orgrimmar" }, { "Fyldan", "Darnassus" }, { "Nyoma", "Teldrassil" }, { "Ronald Burch", "Undercity" }, { "Emrul Riknussun", "Ironforge" }, { "Erika Tate", "Stormwind City" }, { "Tarban Hearthgrain", "The Barrens" }, { "Wulan", "Desolace" }, { "Otho Moji'ko", "The Hinterlands" }, { "Carrie Hearthfire", "Eastern Plaguelands" }, { "Reagent Bot", "Westfall" }, { "Aza'bek", "The Barrens" }, { "Zerril Softbreeze", "Zephras Isle" }, { "Derek Odds", "Alterac Mountains" }, { "Repair Bot", "Wetlands" }, { "Kalsey Sanden", "Redridge Mountains" }, { "Fimbo Greasemitz", "Riverglades" }, { "Paige", "Alterac Mountains" }, { "Qujo", "The Hinterlands" }, { "Miranda Turner", "Riverglades" } } },
    },
    [6522] = {
        { spell = 8238, name = "Savory Deviate Delight", cooking = 85, how = "Drops very rarely from mobs" },
    },
    [6362] = {
        { spell = 7828, name = "Rockscale Cod", cooking = 175, from = { { "Lindea Rabonne", "Hillsbrad Foothills" }, { "Kelsey Yance", "Stranglethorn Vale" }, { "Stuart Fleming", "Wetlands" }, { "Shankys", "Orgrimmar" }, { "Heldan Galesong", "Darkshore" }, { "Lizbeth Cromwell", "Undercity" }, { "Tansy Puddlefizz", "Ironforge" }, { "Wulan", "Desolace" }, { "Wik'Tar", "Ashenvale" } } },
        { spell = 1225762, name = "Specklefin Feast", cooking = 280, how = "Carrie's Cookbook (source unknown)" },
    },
    [8365] = {
        { spell = 20916, name = "Mithril Headed Trout", cooking = 175, from = { { "Lindea Rabonne", "Hillsbrad Foothills" }, { "Kelsey Yance", "Stranglethorn Vale" }, { "Stuart Fleming", "Wetlands" }, { "Shankys", "Orgrimmar" }, { "Heldan Galesong", "Darkshore" }, { "Lizbeth Cromwell", "Undercity" }, { "Tansy Puddlefizz", "Ironforge" }, { "Wulan", "Desolace" }, { "Wik'Tar", "Ashenvale" } } },
    },
    [21153] = {
        { spell = 25954, name = "Sagefish Delight", cooking = 175, from = { { "Micha Yance", "Hillsbrad Foothills" }, { "Derak Nightfall", "Hillsbrad Foothills" }, { "Kelsey Yance", "Stranglethorn Vale" }, { "Naal Mistrunner", "Thunder Bluff" }, { "Gloria Femmel", "Redridge Mountains" }, { "Xen'to", "Orgrimmar" }, { "Fyldan", "Darnassus" }, { "Nyoma", "Teldrassil" }, { "Ronald Burch", "Undercity" }, { "Emrul Riknussun", "Ironforge" }, { "Erika Tate", "Stormwind City" }, { "Tarban Hearthgrain", "The Barrens" }, { "Wulan", "Desolace" }, { "Otho Moji'ko", "The Hinterlands" }, { "Carrie Hearthfire", "Eastern Plaguelands" }, { "Reagent Bot", "Westfall" }, { "Aza'bek", "The Barrens" }, { "Zerril Softbreeze", "Zephras Isle" }, { "Derek Odds", "Alterac Mountains" }, { "Repair Bot", "Wetlands" }, { "Kalsey Sanden", "Redridge Mountains" }, { "Fimbo Greasemitz", "Riverglades" }, { "Paige", "Alterac Mountains" }, { "Qujo", "The Hinterlands" }, { "Miranda Turner", "Riverglades" } } },
    },
    [4603] = {
        { spell = 18238, name = "Spotted Yellowtail", cooking = 225, from = { { "Gikkix", "Tanaris" } } },
        { spell = 1225762, name = "Specklefin Feast", cooking = 280, how = "Carrie's Cookbook (source unknown)" },
    },
    [13754] = {
        { spell = 18239, name = "Cooked Glossy Mightfish", cooking = 225, from = { { "Kelsey Yance", "Stranglethorn Vale" } } },
    },
    [13758] = {
        { spell = 18241, name = "Filet of Redgill", cooking = 225, from = { { "Kelsey Yance", "Stranglethorn Vale" } } },
        { spell = 470370, name = "Smoked Redgill", cooking = 300, from = { { "Chief Expeditionary Requisitioner Enkles", "Silithus" }, { "Apothecary Quinard", "Silithus" } } },
    },
    [13890] = {
        { spell = 1319313, name = "Plated Armorfish", cooking = 225, how = "Source unknown" },
    },
    [13755] = {
        { spell = 18240, name = "Grilled Squid", cooking = 240, from = { { "Gikkix", "Tanaris" } } },
    },
    [13756] = {
        { spell = 18242, name = "Hot Smoked Bass", cooking = 240, from = { { "Kelsey Yance", "Stranglethorn Vale" } } },
    },
    [13759] = {
        { spell = 18243, name = "Nightfin Soup", cooking = 250, from = { { "Gikkix", "Tanaris" } } },
    },
    [13760] = {
        { spell = 18244, name = "Poached Sunscale Salmon", cooking = 250, from = { { "Gikkix", "Tanaris" } } },
    },
    [13888] = {
        { spell = 18245, name = "Lobster Stew", cooking = 275, from = { { "Vivianna", "Feralas" }, { "Sheendra Tallgrass", "Feralas" } } },
        { spell = 470359, name = "Darkclaw Bisque", cooking = 300, from = { { "Chief Expeditionary Requisitioner Enkles", "Silithus" }, { "Apothecary Quinard", "Silithus" } } },
        { spell = 1225763, name = "Grand Lobster Banquet", cooking = 280, how = "Carrie's Cookbook (source unknown)" },
    },
    [13893] = {
        { spell = 18246, name = "Mightfish Steak", cooking = 275, from = { { "Vivianna", "Feralas" }, { "Sheendra Tallgrass", "Feralas" } } },
    },
    [13889] = {
        { spell = 18247, name = "Baked Salmon", cooking = 275, from = { { "Vivianna", "Feralas" }, { "Sheendra Tallgrass", "Feralas" } } },
    },
    [251524] = {
        { spell = 1252566, name = "Savory Whimsyfin Delight", cooking = 85, how = "Drops very rarely from mobs in Redridge Mountains" },
    },
}

-- Rare and special fish for the Records tab, in this order.
-- Notable catches for the Records tab, grouped. Everything here arrives through the loot
-- window, so the journal's per-item first-catch record is enough to light
-- one up. Old Ironjaw and Old Crafty aren't on Forever.
ns.NOTABLE = {
    { group = "Treasures", items = {
        { id = 8350,  name = "The 1 Ring",                        note = "Open water, anywhere" },
        { id = 6307,  name = "Message in a Bottle",               note = "Open water, low-level zones" },
        { id = 6643,  name = "Bloated Brilliant Smallfish",        note = "Has a gem inside" },
        { id = 6645,  name = "Bloated Mud Snapper",                note = "Has a gem inside" },
        { id = 6647,  name = "Bloated Bristle Whisker Catfish",    note = "Has a gem inside" },
        { id = 8366,  name = "Bloated Mithril Head Trout",         note = "Has a gem inside" },
        { id = 13881, name = "Bloated Redgill",                    note = "Has a gem inside" },
        { id = 13891, name = "Bloated Whitescale Salmon",          note = "Has a gem inside" },
        { id = 21243, name = "Bloated Mightfish",                  note = "Azshara" },
    } },
    { group = "Pools and wreckage", items = {
        { id = 20708, name = "Tightly Sealed Trunk",   note = "Floating Debris pools" },
        { id = 21113, name = "Watertight Trunk",       note = "Schooner Wreckage pools" },
        { id = 21150, name = "Iron Bound Trunk",       note = "Waterlogged Wreckage pools" },
        { id = 21228, name = "Mithril Bound Trunk",    note = "Bloodsail Wreckage pools" },
        { id = 6351,  name = "Dented Crate",           note = "Near Venture Co. camps" },
        { id = 6352,  name = "Waterlogged Crate",      note = "Near Venture Co. camps" },
        { id = 6357,  name = "Sealed Crate",           note = "Near Venture Co. camps" },
        { id = 13874, name = "Heavy Crate",            note = "Near Venture Co. camps" },
    } },
    { group = "Stranglethorn Extravaganza", items = {
        { id = 19807, name = "Speckled Tastyfish",              note = "Sundays 2-4 PM, Booty Bay coast" },
        { id = 19805, name = "Keefer's Angelfish",              note = "About 1 in 200 during the contest" },
        { id = 19803, name = "Brownell's Blue Striped Racer",   note = "About 1 in 200 during the contest" },
        { id = 19806, name = "Dezian Queenfish",                note = "About 1 in 200 during the contest" },
        { id = 19808, name = "Rockhide Strongfish",             note = "A fished mace" },
    } },
    { group = "New in Forever", items = {
        { id = 251524, name = "Whimsyfin",              note = "Redridge rivers, near the murlocs. The Alliance-side Deviate Fish" },
        { id = 285094, name = "Ravaged Fishing Pole",   note = "Source still unknown" },
    } },
}

-- zone -> set of fish IDs that are a real catch there (traces are left out so
-- "every fish in a zone" is something a person can finish).
local zoneFish
function ns.ZoneFish()
    if not zoneFish then
        zoneFish = {}
        for id, fish in pairs(ns.FISH) do
            for _, zone in ipairs(fish.zones) do
                zoneFish[zone] = zoneFish[zone] or {}
                zoneFish[zone][id] = true
            end
        end
    end
    return zoneFish
end

ns.RARE_FISH = {
    { id = 19805, note = "Booty Bay rare fish quest" },  -- Keefer's Angelfish
    { id = 19803, note = "Booty Bay rare fish quest" },  -- Brownell's Blue Striped Racer
    { id = 19806, note = "Booty Bay rare fish quest" },  -- Dezian Queenfish
    { id = 19808, note = "A fished mace" },              -- Rockhide Strongfish
    { id = 16967, note = "Nat Pagle quest" },            -- Feralas Ahi
    { id = 16968, note = "Nat Pagle quest" },            -- Sar'theris Striker
    { id = 16969, note = "Nat Pagle quest" },            -- Savage Coast Blue Sailfin
    { id = 16970, note = "Nat Pagle quest" },            -- Misty Reed Mahi Mahi
    { id = 251524, note = "New in Forever" },            -- Whimsyfin
}

-- Everything else that comes up on the line. Not fish: kept out of the zone-fish count,
-- the zone clear and the uncaught list. kind: clam (clams and pearls), crate (crates and chests), trunk (trunks and rum), trophy (trophy fish), material (materials), odd (odd things), gear (only from fishing).
-- Random greens, potions and recipes that also turn up now and then are left out; the site
-- counts them per zone instead.
ns.CATCHES = {
    [7973] = { name = "Big-mouth Clam", kind = "clam" },
    [7971] = { name = "Black Pearl", kind = "clam" },
    [5500] = { name = "Iridescent Pearl", kind = "clam" },
    [5498] = { name = "Small Lustrous Pearl", kind = "clam" },
    [7974] = { name = "Zesty Clam Meat", kind = "clam" },
    [6356] = { name = "Battered Chest", kind = "crate" },
    [6351] = { name = "Dented Crate", kind = "crate" },
    [13874] = { name = "Heavy Crate", kind = "crate" },
    [13875] = { name = "Ironbound Locked Chest", kind = "crate" },
    [13918] = { name = "Reinforced Locked Chest", kind = "crate" },
    [6357] = { name = "Sealed Crate", kind = "crate" },
    [6353] = { name = "Small Chest", kind = "crate" },
    [6354] = { name = "Small Locked Chest", kind = "crate" },
    [6355] = { name = "Sturdy Locked Chest", kind = "crate" },
    [6352] = { name = "Waterlogged Crate", kind = "crate" },
    [21150] = { name = "Iron Bound Trunk", kind = "trunk" },
    [21151] = { name = "Rumsey Rum Black Label", kind = "trunk" },
    [21114] = { name = "Rumsey Rum Dark", kind = "trunk" },
    [20709] = { name = "Rumsey Rum Light", kind = "trunk" },
    [20708] = { name = "Tightly Sealed Trunk", kind = "trunk" },
    [21113] = { name = "Watertight Trunk", kind = "trunk" },
    [6292] = { name = "10 Pound Mud Snapper", kind = "trophy" },
    [13909] = { name = "12 Pound Lobster", kind = "trophy" },
    [6294] = { name = "12 Pound Mud Snapper", kind = "trophy" },
    [6295] = { name = "15 Pound Mud Snapper", kind = "trophy" },
    [13901] = { name = "15 Pound Salmon", kind = "trophy" },
    [6309] = { name = "17 Pound Catfish", kind = "trophy" },
    [13902] = { name = "18 Pound Salmon", kind = "trophy" },
    [6310] = { name = "19 Pound Catfish", kind = "trophy" },
    [6311] = { name = "22 Pound Catfish", kind = "trophy" },
    [13913] = { name = "22 Pound Lobster", kind = "trophy" },
    [13903] = { name = "22 Pound Salmon", kind = "trophy" },
    [13904] = { name = "25 Pound Salmon", kind = "trophy" },
    [6363] = { name = "26 Pound Catfish", kind = "trophy" },
    [13905] = { name = "29 Pound Salmon", kind = "trophy" },
    [6364] = { name = "32 Pound Catfish", kind = "trophy" },
    [13885] = { name = "34 Pound Redgill", kind = "trophy" },
    [13886] = { name = "37 Pound Redgill", kind = "trophy" },
    [13876] = { name = "40 Pound Yellowtail", kind = "trophy" },
    [13882] = { name = "42 Pound Redgill", kind = "trophy" },
    [13883] = { name = "45 Pound Redgill", kind = "trophy" },
    [13884] = { name = "49 Pound Redgill", kind = "trophy" },
    [13887] = { name = "52 Pound Redgill", kind = "trophy" },
    [13907] = { name = "7 Pound Lobster", kind = "trophy" },
    [13908] = { name = "9 Pound Lobster", kind = "trophy" },
    [7070] = { name = "Elemental Water", kind = "material" },
    [7080] = { name = "Essence of Water", kind = "material" },
    [7079] = { name = "Globe of Water", kind = "material" },
    [10505] = { name = "Solid Blasting Powder", kind = "material" },
    [3820] = { name = "Stranglekelp", kind = "material" },
    [6456] = { name = "Acidic Slime", kind = "odd" },
    [6304] = { name = "Damp Diary Page (Day 4)", kind = "odd" },
    [6306] = { name = "Damp Diary Page (Day 512)", kind = "odd" },
    [6307] = { name = "Message in a Bottle", kind = "odd" },
    [6297] = { name = "Old Skull", kind = "odd" },
    [6301] = { name = "Old Teamster's Skull", kind = "odd" },
    [770] = { name = "Pointy Crocolisk Tooth", kind = "odd" },
    [6457] = { name = "Rusted Engineering Parts", kind = "odd" },
    [6360] = { name = "Steelscale Crushfish", kind = "gear" },
    [8350] = { name = "The 1 Ring", kind = "gear" },
}
