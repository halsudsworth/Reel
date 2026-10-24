-- Fishing data for WoW Forever, read from Wowhead's Forever database
-- (wowhead.com/forever) on 2026-10-19. Zone numbers are Wowhead's share of
-- catches in that zone, in percent; 0.05 means a trace amount (<0.1%).

local _, ns = ...

-- itemID -> { name, zones = { zone -> percent } }
ns.FISH = {
    [6291] = { name = "Raw Brilliant Smallfish", zones = { ["Elwynn Forest"] = 58.9, ["Mulgore"] = 59.8, ["Stormwind City"] = 17.1, ["Dun Morogh"] = 59.9, ["Orgrimmar"] = 16.9, ["The Barrens"] = 5.1, ["Thunder Bluff"] = 17.0, ["Tirisfal Glades"] = 45.4, ["Teldrassil"] = 25.5, ["Durotar"] = 22.2, ["Darkshore"] = 2.8, ["Darnassus"] = 17.0, ["Undercity"] = 11.7, ["Loch Modan"] = 8.7, ["Westfall"] = 1.2, ["Silverpine Forest"] = 1.3, ["Duskwood"] = 20.4, ["Tanaris"] = 0.05, ["Azshara"] = 0.05, ["Ashenvale"] = 0.05, ["Moonglade"] = 0.05 } },
    [6303] = { name = "Raw Slitherskin Mackerel", zones = { ["Darkshore"] = 13.1, ["The Barrens"] = 5.5, ["Durotar"] = 59.7, ["Teldrassil"] = 56.2, ["Westfall"] = 13.9, ["Silverpine Forest"] = 12.4, ["Tirisfal Glades"] = 1.3, ["Dustwallow Marsh"] = 0.05 } },
    [6289] = { name = "Raw Longjaw Mud Snapper", zones = { ["Stormwind City"] = 59.9, ["Orgrimmar"] = 59.8, ["The Barrens"] = 17.9, ["Thunder Bluff"] = 60.0, ["Elwynn Forest"] = 37.1, ["Stonetalon Mountains"] = 27.3, ["Ashenvale"] = 21.3, ["Redridge Mountains"] = 35.2, ["Darkshore"] = 9.9, ["Mulgore"] = 38.2, ["Darnassus"] = 59.9, ["Dun Morogh"] = 38.1, ["Undercity"] = 41.7, ["Hillsbrad Foothills"] = 7.4, ["Loch Modan"] = 30.0, ["Tirisfal Glades"] = 29.0, ["Durotar"] = 15.5, ["Teldrassil"] = 16.2, ["Westfall"] = 4.3, ["Silverpine Forest"] = 5.2, ["Duskwood"] = 30.3, ["Wetlands"] = 1.0, ["Azshara"] = 0.05, ["Arathi Basin"] = 43.9 } },
    [6317] = { name = "Raw Loch Frenzy", zones = { ["Loch Modan"] = 21.7 } },
    [6361] = { name = "Raw Rainbow Fin Albacore", zones = { ["Wetlands"] = 48.8, ["Darkshore"] = 19.1, ["The Barrens"] = 8.0, ["Ashenvale"] = 19.3, ["Hillsbrad Foothills"] = 12.3, ["Westfall"] = 20.3, ["Silverpine Forest"] = 18.7, ["Dustwallow Marsh"] = 0.05 } },
    [6308] = { name = "Raw Bristle Whisker Catfish", zones = { ["Ashenvale"] = 39.2, ["Stonetalon Mountains"] = 48.9, ["Stormwind City"] = 21.9, ["Redridge Mountains"] = 63.9, ["Dustwallow Marsh"] = 12.9, ["Orgrimmar"] = 22.3, ["The Barrens"] = 6.4, ["Hillsbrad Foothills"] = 13.4, ["Desolace"] = 14.4, ["Thunder Bluff"] = 21.9, ["Stranglethorn Vale"] = 1.5, ["Arathi Highlands"] = 25.6, ["Darkshore"] = 3.5, ["Darnassus"] = 22.0, ["Alterac Mountains"] = 12.4, ["Undercity"] = 15.0, ["Loch Modan"] = 11.6, ["Wetlands"] = 1.7, ["Duskwood"] = 47.2, ["Thousand Needles"] = 35.0, ["Swamp of Sorrows"] = 4.0, ["Westfall"] = 1.7, ["Silverpine Forest"] = 1.9, ["Arathi Basin"] = 55.8, ["Azshara"] = 0.05, ["Durotar"] = 0.6, ["Tirisfal Glades"] = 0.8 } },
    [21071] = { name = "Raw Sagefish", zones = { ["Hillsbrad Foothills"] = 25.0, ["Loch Modan"] = 21.4, ["Ashenvale"] = 5.6, ["Stonetalon Mountains"] = 6.8, ["Silverpine Forest"] = 5.4 } },
    [6522] = { name = "Deviate Fish", zones = { ["The Barrens"] = 26.6, ["Azshara"] = 0.05, ["Ashenvale"] = 0.05, ["Moonglade"] = 0.05, ["Orgrimmar"] = 0.05, ["Undercity"] = 9.1, ["Dustwallow Marsh"] = 0.05, ["Western Plaguelands"] = 0.05, ["Thousand Needles"] = 0.4, ["Tanaris"] = 0.1, ["Silithus"] = 0.6, ["Blasted Lands"] = 12.1, ["Thunder Bluff"] = 0.05, ["Silverpine Forest"] = 0.05 } },
    [6299] = { name = "Sickly Looking Fish", zones = { ["Undercity"] = 15.2, ["Tirisfal Glades"] = 14.8, ["Silverpine Forest"] = 0.9, ["Ashenvale"] = 0.2, ["Darkshore"] = 0.05, ["Stonetalon Mountains"] = 0.05, ["Darnassus"] = 0.1 } },
    [6458] = { name = "Oil Covered Fish", zones = { ["Stonetalon Mountains"] = 0.2, ["The Barrens"] = 0.05 } },
    [6362] = { name = "Raw Rockscale Cod", zones = { ["Stranglethorn Vale"] = 18.4, ["Dustwallow Marsh"] = 27.1, ["Tanaris"] = 7.0, ["Azshara"] = 2.3, ["Desolace"] = 17.5, ["Swamp of Sorrows"] = 49.0, ["Feralas"] = 2.2, ["The Hinterlands"] = 5.3, ["Arathi Highlands"] = 8.8, ["The Barrens"] = 0.05, ["Tirisfal Glades"] = 4.8 } },
    [8365] = { name = "Raw Mithril Head Trout", zones = { ["Dustwallow Marsh"] = 23.6, ["Feralas"] = 6.3, ["Moonglade"] = 10.0, ["Desolace"] = 26.5, ["Western Plaguelands"] = 10.1, ["Stranglethorn Vale"] = 2.8, ["Arathi Highlands"] = 46.2, ["Azshara"] = 0.8, ["The Hinterlands"] = 4.7, ["Alterac Mountains"] = 23.4, ["Felwood"] = 9.9, ["Thousand Needles"] = 62.8, ["Swamp of Sorrows"] = 7.5, ["Un'Goro Crater"] = 10.2, ["Tirisfal Glades"] = 1.2, ["Eastern Plaguelands"] = 0.5, ["Ashenvale"] = 0.2, ["Hillsbrad Foothills"] = 0.05, ["Mulgore"] = 0.05 } },
    [21153] = { name = "Raw Greater Sagefish", zones = { ["Stranglethorn Vale"] = 5.2, ["Alterac Mountains"] = 50.0 } },
    [4603] = { name = "Raw Spotted Yellowtail", zones = { ["Azshara"] = 11.1, ["Tanaris"] = 27.4, ["Feralas"] = 9.0, ["Stranglethorn Vale"] = 7.3, ["The Hinterlands"] = 21.5, ["Dustwallow Marsh"] = 10.0, ["Desolace"] = 6.4, ["Swamp of Sorrows"] = 17.5, ["Arathi Highlands"] = 3.2, ["Eastern Plaguelands"] = 3.1, ["The Barrens"] = 0.05 } },
    [13754] = { name = "Raw Glossy Mightfish", zones = { ["Azshara"] = 2.4, ["Tanaris"] = 6.5, ["Feralas"] = 2.2, ["The Hinterlands"] = 5.6, ["Stranglethorn Vale"] = 0.2 } },
    [13755] = { name = "Raw Winter Squid", zones = { ["Azshara"] = 13.6, ["Tanaris"] = 5.3, ["Feralas"] = 1.7, ["The Hinterlands"] = 2.9, ["Stranglethorn Vale"] = 0.1 } },
    [13756] = { name = "Raw Summer Bass", zones = { ["Azshara"] = 1.1, ["Tanaris"] = 1.6, ["The Hinterlands"] = 2.0, ["Feralas"] = 0.5, ["Eastern Plaguelands"] = 20.3, ["Stranglethorn Vale"] = 0.05 } },
    [13758] = { name = "Raw Redgill", zones = { ["Feralas"] = 31.8, ["Moonglade"] = 50.2, ["Western Plaguelands"] = 50.3, ["Azshara"] = 4.1, ["The Hinterlands"] = 24.2, ["Felwood"] = 50.6, ["Un'Goro Crater"] = 49.5, ["Winterspring"] = 5.0, ["Eastern Plaguelands"] = 6.9, ["Alterac Valley"] = 5.0, ["Deadwind Pass"] = 4.8, ["Desolace"] = 1.0, ["Ashenvale"] = 0.8, ["Stranglethorn Vale"] = 0.05, ["Silithus"] = 4.1, ["Swamp of Sorrows"] = 0.1, ["Duskwood"] = 0.7, ["Tanaris"] = 0.05, ["Burning Steppes"] = 2.2, ["Alterac Mountains"] = 0.05 } },
    [13759] = { name = "Raw Nightfin Snapper", zones = { ["Feralas"] = 12.1, ["Moonglade"] = 21.8, ["Western Plaguelands"] = 20.0, ["The Hinterlands"] = 10.0, ["Azshara"] = 1.4, ["Winterspring"] = 19.8, ["Alterac Valley"] = 15.9, ["Eastern Plaguelands"] = 19.0, ["Felwood"] = 18.7, ["Deadwind Pass"] = 19.0, ["Un'Goro Crater"] = 21.6, ["Stranglethorn Vale"] = 0.2, ["Desolace"] = 0.3, ["Ashenvale"] = 0.2, ["Duskwood"] = 2.2, ["Silithus"] = 6.1, ["Burning Steppes"] = 5.1, ["Swamp of Sorrows"] = 0.05, ["Dustwallow Marsh"] = 0.05, ["Stormwind City"] = 0.05, ["Orgrimmar"] = 0.05, ["Tirisfal Glades"] = 0.05, ["Westfall"] = 0.05 } },
    [13760] = { name = "Raw Sunscale Salmon", zones = { ["Feralas"] = 5.7, ["Western Plaguelands"] = 7.7, ["Moonglade"] = 6.2, ["Azshara"] = 0.8, ["The Hinterlands"] = 3.2, ["Winterspring"] = 10.6, ["Alterac Valley"] = 14.0, ["Eastern Plaguelands"] = 10.9, ["Deadwind Pass"] = 10.7, ["Felwood"] = 8.8, ["Un'Goro Crater"] = 6.3, ["Stranglethorn Vale"] = 0.1, ["Silithus"] = 21.9, ["Desolace"] = 0.3, ["Ashenvale"] = 0.2, ["Duskwood"] = 2.1, ["Burning Steppes"] = 7.9, ["Tanaris"] = 0.05, ["Swamp of Sorrows"] = 0.05, ["Dustwallow Marsh"] = 0.05, ["Stormwind City"] = 0.05, ["Orgrimmar"] = 0.05, ["Blasted Lands"] = 3.0, ["Elwynn Forest"] = 0.05, ["Alterac Mountains"] = 0.05, ["Westfall"] = 0.05 } },
    [13888] = { name = "Darkclaw Lobster", zones = { ["Azshara"] = 26.1, ["Eastern Plaguelands"] = 45.2 } },
    [13889] = { name = "Raw Whitescale Salmon", zones = { ["Winterspring"] = 39.4, ["Alterac Valley"] = 39.4, ["Eastern Plaguelands"] = 37.4, ["Deadwind Pass"] = 40.1, ["Feralas"] = 0.7, ["Stranglethorn Vale"] = 0.4, ["Silithus"] = 37.3, ["Duskwood"] = 5.2, ["Burning Steppes"] = 15.2, ["Stormwind City"] = 0.05, ["Dustwallow Marsh"] = 0.05, ["Orgrimmar"] = 0.05, ["Western Plaguelands"] = 0.05, ["Felwood"] = 0.05, ["Elwynn Forest"] = 0.05, ["Westfall"] = 0.05, ["Tirisfal Glades"] = 0.05, ["Undercity"] = 0.05, ["Blasted Lands"] = 3.0 } },
    [13893] = { name = "Large Raw Mightfish", zones = { ["Azshara"] = 5.4, ["Eastern Plaguelands"] = 8.2 } },
    [13890] = { name = "Raw Plated Armorfish", zones = { ["Winterspring"] = 17.4, ["Alterac Valley"] = 15.1, ["Eastern Plaguelands"] = 16.2, ["Deadwind Pass"] = 16.6, ["Feralas"] = 0.3, ["Stranglethorn Vale"] = 0.2, ["Silithus"] = 11.1, ["Duskwood"] = 2.1, ["Burning Steppes"] = 2.8, ["Western Plaguelands"] = 0.05, ["Dustwallow Marsh"] = 0.05, ["Felwood"] = 0.05 } },
    [6358] = { name = "Oily Blackmouth", zones = { ["Stranglethorn Vale"] = 15.7, ["The Barrens"] = 18.3, ["Feralas"] = 9.3, ["Wetlands"] = 24.4, ["Tanaris"] = 7.7, ["Darkshore"] = 16.3, ["Moonglade"] = 10.0, ["Western Plaguelands"] = 10.0, ["Azshara"] = 1.7, ["Dustwallow Marsh"] = 9.9, ["Hillsbrad Foothills"] = 16.1, ["Westfall"] = 41.1, ["Silverpine Forest"] = 36.4, ["Desolace"] = 11.0, ["The Hinterlands"] = 4.8, ["Ashenvale"] = 7.8, ["Swamp of Sorrows"] = 10.3, ["Felwood"] = 9.6, ["Un'Goro Crater"] = 10.0, ["Arathi Highlands"] = 5.3, ["Eastern Plaguelands"] = 0.5 } },
    [6359] = { name = "Firefin Snapper", zones = { ["Stranglethorn Vale"] = 17.8, ["Tanaris"] = 14.3, ["Azshara"] = 3.3, ["Feralas"] = 5.3, ["Wetlands"] = 17.0, ["Dustwallow Marsh"] = 10.9, ["Desolace"] = 14.8, ["Hillsbrad Foothills"] = 11.9, ["The Hinterlands"] = 5.3, ["Stonetalon Mountains"] = 8.7, ["Swamp of Sorrows"] = 10.4, ["Ashenvale"] = 3.2, ["The Barrens"] = 0.6, ["Arathi Highlands"] = 6.4 } },
    [13422] = { name = "Stonescale Eel", zones = { ["Azshara"] = 11.8, ["Tanaris"] = 13.6, ["Feralas"] = 5.0, ["Stranglethorn Vale"] = 4.9, ["The Hinterlands"] = 5.1, ["Eastern Plaguelands"] = 11.3 } },
    [13757] = { name = "Lightning Eel", zones = { ["Feralas"] = 0.9, ["Alterac Valley"] = 9.5, ["Winterspring"] = 6.8, ["Eastern Plaguelands"] = 7.6, ["Western Plaguelands"] = 0.9, ["Deadwind Pass"] = 7.8, ["Moonglade"] = 0.7, ["Azshara"] = 0.05, ["The Hinterlands"] = 0.4, ["Stranglethorn Vale"] = 0.05, ["Felwood"] = 1.4, ["Un'Goro Crater"] = 0.9, ["Silithus"] = 13.3, ["Duskwood"] = 1.2, ["Ashenvale"] = 0.05, ["Burning Steppes"] = 9.0, ["Desolace"] = 0.05, ["Orgrimmar"] = 0.05, ["Dustwallow Marsh"] = 0.05, ["Stormwind City"] = 0.05, ["Undercity"] = 1.5, ["Elwynn Forest"] = 0.05, ["Westfall"] = 0.05, ["Tirisfal Glades"] = 0.05 } },
    [19975] = { name = "Zulian Mudskunk", zones = { ["Stranglethorn Vale"] = 0.6, ["Duskwood"] = 4.5, ["Westfall"] = 0.2, ["Dustwallow Marsh"] = 0.05, ["Stormwind City"] = 0.05, ["Silithus"] = 3.6, ["Elwynn Forest"] = 0.05, ["Orgrimmar"] = 0.05, ["Blasted Lands"] = 30.3, ["Tanaris"] = 0.05, ["Eastern Plaguelands"] = 0.05, ["Tirisfal Glades"] = 0.05, ["The Barrens"] = 0.05, ["Undercity"] = 0.05, ["Hillsbrad Foothills"] = 0.05, ["Winterspring"] = 0.05 } },
    [6643] = { name = "Bloated Brilliant Smallfish", zones = { ["Elwynn Forest"] = 0.1, ["Mulgore"] = 0.1, ["Dun Morogh"] = 0.05, ["Durotar"] = 0.05, ["Teldrassil"] = 0.05, ["Tirisfal Glades"] = 0.05, ["Duskwood"] = 0.1 } },
    [6645] = { name = "Bloated Mud Snapper", zones = { ["Stormwind City"] = 0.05, ["Orgrimmar"] = 0.05, ["The Barrens"] = 0.05, ["Thunder Bluff"] = 0.05, ["Darkshore"] = 0.05, ["Undercity"] = 0.05, ["Darnassus"] = 0.05, ["Loch Modan"] = 0.05, ["Silverpine Forest"] = 0.05, ["Westfall"] = 0.05 } },
    [6647] = { name = "Bloated Bristle Whisker Catfish", zones = { ["Ashenvale"] = 0.05, ["Redridge Mountains"] = 0.05, ["Stonetalon Mountains"] = 0.05, ["Hillsbrad Foothills"] = 0.05, ["Duskwood"] = 0.05 } },
    [8366] = { name = "Bloated Mithril Head Trout", zones = { ["Dustwallow Marsh"] = 0.05, ["Desolace"] = 0.05, ["Arathi Highlands"] = 0.05, ["Stranglethorn Vale"] = 0.05, ["Alterac Mountains"] = 0.05, ["Swamp of Sorrows"] = 0.05, ["Thousand Needles"] = 0.05 } },
    [13881] = { name = "Bloated Redgill", zones = { ["Feralas"] = 0.05, ["Moonglade"] = 0.05, ["Western Plaguelands"] = 0.05, ["Azshara"] = 0.05, ["The Hinterlands"] = 0.05, ["Felwood"] = 0.05, ["Un'Goro Crater"] = 0.05, ["Eastern Plaguelands"] = 0.05 } },
    [13891] = { name = "Bloated Whitescale Salmon", zones = { ["Winterspring"] = 0.05, ["Alterac Valley"] = 0.05, ["Eastern Plaguelands"] = 0.05, ["Feralas"] = 0.05, ["Deadwind Pass"] = 0.05, ["Stranglethorn Vale"] = 0.05 } },
    [1467] = { name = "Spotted Sunfish", zones = { ["Redridge Mountains"] = 7.1 } },
    [6717] = { name = "Gaffer Jack", zones = { ["Darkshore"] = 4.0 } },
    [16967] = { name = "Feralas Ahi", zones = { ["Feralas"] = 0.3 } },
    [16968] = { name = "Sar'theris Striker", zones = { ["Desolace"] = 2.2 } },
    [16969] = { name = "Savage Coast Blue Sailfin", zones = { ["Stranglethorn Vale"] = 0.3 } },
    [16970] = { name = "Misty Reed Mahi Mahi", zones = { ["Swamp of Sorrows"] = 6.7 } },
    [19803] = { name = "Brownell's Blue Striped Racer", zones = { ["Stranglethorn Vale"] = 0.05 } },
    [19805] = { name = "Keefer's Angelfish", zones = { ["Stranglethorn Vale"] = 0.05 } },
    [19806] = { name = "Dezian Queenfish", zones = { ["Stranglethorn Vale"] = 0.05 } },
    [19807] = { name = "Speckled Tastyfish", zones = { ["Stranglethorn Vale"] = 6.8 } },
    [19808] = { name = "Rockhide Strongfish", zones = { ["Stranglethorn Vale"] = 0.05 } },
    [251524] = { name = "Whimsyfin", zones = { ["Redridge Mountains"] = 0 } }, -- Icy Veins; catch rate unknown, so the bar doesn't count it
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
