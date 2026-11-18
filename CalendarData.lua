-- Hal's calendar data: his annual events and what the daily and weekly challenges pick from.
-- Written by tools/gen_calendar.py from site/data/hal_events.json, site/server/lib/data.json
-- and calendar.php's launch tables. Don't edit by hand; run the script again.
--
-- Zones are map IDs (C_Map). maps holds their English names only to build challenge names
-- the way halsudsworth.com writes them. Subzones (sub, notSub) are area IDs (C_Map.GetAreaInfo
-- names them in the client's language); site/data/areas.json lists them.

local _, ns = ...

ns.CALENDAR_DATA = {
    calStart = "2026-11-01",

    -- map ID -> English zone name; mapAlias: a second ID of the same zone -> the one used here
    maps = {
        [1411] = "Durotar",
        [1412] = "Mulgore",
        [1413] = "The Barrens",
        [1416] = "Alterac Mountains",
        [1417] = "Arathi Highlands",
        [1420] = "Tirisfal Glades",
        [1421] = "Silverpine Forest",
        [1422] = "Western Plaguelands",
        [1423] = "Eastern Plaguelands",
        [1424] = "Hillsbrad Foothills",
        [1425] = "The Hinterlands",
        [1426] = "Dun Morogh",
        [1428] = "Burning Steppes",
        [1429] = "Elwynn Forest",
        [1430] = "Deadwind Pass",
        [1431] = "Duskwood",
        [1432] = "Loch Modan",
        [1433] = "Redridge Mountains",
        [1434] = "Stranglethorn Vale",
        [1435] = "Swamp of Sorrows",
        [1436] = "Westfall",
        [1437] = "Wetlands",
        [1438] = "Teldrassil",
        [1439] = "Darkshore",
        [1440] = "Ashenvale",
        [1441] = "Thousand Needles",
        [1442] = "Stonetalon Mountains",
        [1443] = "Desolace",
        [1444] = "Feralas",
        [1445] = "Dustwallow Marsh",
        [1446] = "Tanaris",
        [1447] = "Azshara",
        [1448] = "Felwood",
        [1449] = "Un'Goro Crater",
        [1450] = "Moonglade",
        [1451] = "Silithus",
        [1452] = "Winterspring",
        [1453] = "Stormwind City",
        [1454] = "Orgrimmar",
        [1455] = "Ironforge",
        [1456] = "Thunder Bluff",
        [1457] = "Darnassus",
        [1458] = "Undercity",
        [2521] = "Zephras Isle",
        [2548] = "Riverglades",
    },
    mapAlias = { [2665] = 2521 },

    -- item ID -> English name, for the challenge names
    fishNames = {
        [4603] = "Raw Spotted Yellowtail",
        [6289] = "Raw Longjaw Mud Snapper",
        [6291] = "Raw Brilliant Smallfish",
        [6299] = "Sickly Looking Fish",
        [6303] = "Raw Slitherskin Mackerel",
        [6308] = "Raw Bristle Whisker Catfish",
        [6317] = "Raw Loch Frenzy",
        [6358] = "Oily Blackmouth",
        [6359] = "Firefin Snapper",
        [6361] = "Raw Rainbow Fin Albacore",
        [6362] = "Raw Rockscale Cod",
        [6522] = "Deviate Fish",
        [8365] = "Raw Mithril Head Trout",
        [13422] = "Stonescale Eel",
        [13754] = "Raw Glossy Mightfish",
        [13758] = "Raw Redgill",
        [13759] = "Raw Nightfin Snapper",
        [13760] = "Raw Sunscale Salmon",
        [13889] = "Raw Whitescale Salmon",
        [13890] = "Raw Plated Armorfish",
        [21071] = "Raw Sagefish",
        [21153] = "Raw Greater Sagefish",
    },

    -- calendar.php pairs(): { zone, fish } for best-30 and race challenges, in the site's order
    pairs = {
        { 1416, 6308 }, -- Alterac Mountains, Raw Bristle Whisker Catfish
        { 1416, 8365 }, -- Alterac Mountains, Raw Mithril Head Trout
        { 1416, 21153 }, -- Alterac Mountains, Raw Greater Sagefish
        { 1417, 6308 }, -- Arathi Highlands, Raw Bristle Whisker Catfish
        { 1417, 8365 }, -- Arathi Highlands, Raw Mithril Head Trout
        { 1440, 6289 }, -- Ashenvale, Raw Longjaw Mud Snapper
        { 1440, 6308 }, -- Ashenvale, Raw Bristle Whisker Catfish
        { 1440, 6361 }, -- Ashenvale, Raw Rainbow Fin Albacore
        { 1447, 4603 }, -- Azshara, Raw Spotted Yellowtail
        { 1428, 13889 }, -- Burning Steppes, Raw Whitescale Salmon
        { 1439, 6303 }, -- Darkshore, Raw Slitherskin Mackerel
        { 1439, 6361 }, -- Darkshore, Raw Rainbow Fin Albacore
        { 1457, 6289 }, -- Darnassus, Raw Longjaw Mud Snapper
        { 1457, 6291 }, -- Darnassus, Raw Brilliant Smallfish
        { 1457, 6308 }, -- Darnassus, Raw Bristle Whisker Catfish
        { 1430, 13889 }, -- Deadwind Pass, Raw Whitescale Salmon
        { 1443, 6308 }, -- Desolace, Raw Bristle Whisker Catfish
        { 1443, 8365 }, -- Desolace, Raw Mithril Head Trout
        { 1426, 6289 }, -- Dun Morogh, Raw Longjaw Mud Snapper
        { 1426, 6291 }, -- Dun Morogh, Raw Brilliant Smallfish
        { 1411, 6303 }, -- Durotar, Raw Slitherskin Mackerel
        { 1431, 6289 }, -- Duskwood, Raw Longjaw Mud Snapper
        { 1431, 6308 }, -- Duskwood, Raw Bristle Whisker Catfish
        { 1445, 4603 }, -- Dustwallow Marsh, Raw Spotted Yellowtail
        { 1445, 6362 }, -- Dustwallow Marsh, Raw Rockscale Cod
        { 1423, 13889 }, -- Eastern Plaguelands, Raw Whitescale Salmon
        { 1429, 6289 }, -- Elwynn Forest, Raw Longjaw Mud Snapper
        { 1429, 6291 }, -- Elwynn Forest, Raw Brilliant Smallfish
        { 1448, 13758 }, -- Felwood, Raw Redgill
        { 1444, 4603 }, -- Feralas, Raw Spotted Yellowtail
        { 1444, 13758 }, -- Feralas, Raw Redgill
        { 1424, 6289 }, -- Hillsbrad Foothills, Raw Longjaw Mud Snapper
        { 1424, 6308 }, -- Hillsbrad Foothills, Raw Bristle Whisker Catfish
        { 1455, 6289 }, -- Ironforge, Raw Longjaw Mud Snapper
        { 1455, 6291 }, -- Ironforge, Raw Brilliant Smallfish
        { 1455, 6308 }, -- Ironforge, Raw Bristle Whisker Catfish
        { 1432, 6289 }, -- Loch Modan, Raw Longjaw Mud Snapper
        { 1432, 6317 }, -- Loch Modan, Raw Loch Frenzy
        { 1450, 13758 }, -- Moonglade, Raw Redgill
        { 1412, 6289 }, -- Mulgore, Raw Longjaw Mud Snapper
        { 1412, 6291 }, -- Mulgore, Raw Brilliant Smallfish
        { 1454, 6289 }, -- Orgrimmar, Raw Longjaw Mud Snapper
        { 1454, 6291 }, -- Orgrimmar, Raw Brilliant Smallfish
        { 1454, 6308 }, -- Orgrimmar, Raw Bristle Whisker Catfish
        { 1433, 6289 }, -- Redridge Mountains, Raw Longjaw Mud Snapper
        { 1433, 6308 }, -- Redridge Mountains, Raw Bristle Whisker Catfish
        { 1451, 13889 }, -- Silithus, Raw Whitescale Salmon
        { 1421, 6289 }, -- Silverpine Forest, Raw Longjaw Mud Snapper
        { 1442, 6289 }, -- Stonetalon Mountains, Raw Longjaw Mud Snapper
        { 1442, 6308 }, -- Stonetalon Mountains, Raw Bristle Whisker Catfish
        { 1442, 6359 }, -- Stonetalon Mountains, Firefin Snapper
        { 1453, 6289 }, -- Stormwind City, Raw Longjaw Mud Snapper
        { 1453, 6291 }, -- Stormwind City, Raw Brilliant Smallfish
        { 1453, 6308 }, -- Stormwind City, Raw Bristle Whisker Catfish
        { 1434, 6362 }, -- Stranglethorn Vale, Raw Rockscale Cod
        { 1435, 4603 }, -- Swamp of Sorrows, Raw Spotted Yellowtail
        { 1435, 6362 }, -- Swamp of Sorrows, Raw Rockscale Cod
        { 1446, 4603 }, -- Tanaris, Raw Spotted Yellowtail
        { 1438, 6291 }, -- Teldrassil, Raw Brilliant Smallfish
        { 1438, 6303 }, -- Teldrassil, Raw Slitherskin Mackerel
        { 1413, 6289 }, -- The Barrens, Raw Longjaw Mud Snapper
        { 1413, 6522 }, -- The Barrens, Deviate Fish
        { 1425, 4603 }, -- The Hinterlands, Raw Spotted Yellowtail
        { 1425, 13758 }, -- The Hinterlands, Raw Redgill
        { 1441, 6308 }, -- Thousand Needles, Raw Bristle Whisker Catfish
        { 1441, 8365 }, -- Thousand Needles, Raw Mithril Head Trout
        { 1456, 6289 }, -- Thunder Bluff, Raw Longjaw Mud Snapper
        { 1456, 6291 }, -- Thunder Bluff, Raw Brilliant Smallfish
        { 1456, 6308 }, -- Thunder Bluff, Raw Bristle Whisker Catfish
        { 1420, 6289 }, -- Tirisfal Glades, Raw Longjaw Mud Snapper
        { 1420, 6291 }, -- Tirisfal Glades, Raw Brilliant Smallfish
        { 1449, 13758 }, -- Un'Goro Crater, Raw Redgill
        { 1458, 6289 }, -- Undercity, Raw Longjaw Mud Snapper
        { 1458, 6299 }, -- Undercity, Sickly Looking Fish
        { 1458, 6308 }, -- Undercity, Raw Bristle Whisker Catfish
        { 1422, 13758 }, -- Western Plaguelands, Raw Redgill
        { 1436, 6303 }, -- Westfall, Raw Slitherskin Mackerel
        { 1436, 6358 }, -- Westfall, Oily Blackmouth
        { 1436, 6361 }, -- Westfall, Raw Rainbow Fin Albacore
        { 1437, 6358 }, -- Wetlands, Oily Blackmouth
        { 1437, 6361 }, -- Wetlands, Raw Rainbow Fin Albacore
        { 1452, 13889 }, -- Winterspring, Raw Whitescale Salmon
    },
    -- calendar.php wide_fish(): the fish for "most" challenges, in the site's order
    wide = { 4603, 6289, 6291, 6303, 6308, 6358, 6359, 6361, 6362, 8365, 13422, 13754, 13758, 13759, 13760, 13889, 13890, 21071 },

    -- calendar.php LAUNCH_DAYS and LAUNCH_WEEKS: the hand-picked first challenges
    launchDays = {
        ["2026-11-02"] = { name = "Most Raw Brilliant Smallfish", scoring = "most", fish = { 6291 } },
        ["2026-11-03"] = { name = "Best 30 minutes: Raw Brilliant Smallfish in a starting zone", scoring = "best30", fish = { 6291 }, zone = { 1429, 1426, 1438, 1411, 1412, 1420 } },
        ["2026-11-04"] = { name = "Race to 20 Raw Brilliant Smallfish, any starting zone", scoring = "race", fish = { 6291 }, zone = { 1429, 1426, 1438, 1411, 1412, 1420 }, target = 20 },
        ["2026-11-05"] = { name = "Most Raw Longjaw Mud Snapper", scoring = "most", fish = { 6289 } },
        ["2026-11-06"] = { name = "Best 30 minutes: Raw Slitherskin Mackerel in Durotar or Teldrassil", scoring = "best30", fish = { 6303 }, zone = { 1411, 1438 } },
        ["2026-11-07"] = { name = "Race to 20 Raw Longjaw Mud Snapper, any capital city", scoring = "race", fish = { 6289 }, zone = { 1453, 1455, 1457, 1454, 1456, 1458 }, target = 20 },
        ["2026-11-08"] = { name = "Most Raw Slitherskin Mackerel", scoring = "most", fish = { 6303 } },
        ["2026-11-09"] = { name = "Best 30 minutes: Raw Rainbow Fin Albacore", scoring = "best30", fish = { 6361 }, zone = { 1436, 1439, 1421, 1413 } },
        ["2026-11-10"] = { name = "Race to 20 Oily Blackmouth", scoring = "race", fish = { 6358 }, zone = { 1437, 1436, 1421, 1439 }, target = 20 },
        ["2026-11-11"] = { name = "Most Raw Rainbow Fin Albacore", scoring = "most", fish = { 6361 } },
        ["2026-11-12"] = { name = "Best 30 minutes: Raw Sagefish", scoring = "best30", fish = { 21071 }, zone = { 1421, 1442, 1440, 1432 } },
        ["2026-11-13"] = { name = "Race to 20 Deviate Fish, The Barrens", scoring = "race", fish = { 6522 }, zone = { 1413 }, target = 20 },
        ["2026-11-14"] = { name = "Most Oily Blackmouth", scoring = "most", fish = { 6358 } },
        ["2026-11-15"] = { name = "Best 30 minutes: Raw Bristle Whisker Catfish", scoring = "best30", fish = { 6308 }, zone = { 1424, 1433, 1431, 1440 } },
        ["2026-11-16"] = { name = "Race to 20 Raw Sagefish", scoring = "race", fish = { 21071 }, zone = { 1421, 1442, 1440, 1432 }, target = 20 },
        ["2026-11-17"] = { name = "Most Raw Bristle Whisker Catfish", scoring = "most", fish = { 6308 } },
        ["2026-11-18"] = { name = "Best 30 minutes: Raw Loch Frenzy in Loch Modan", scoring = "best30", fish = { 6317 }, zone = { 1432 } },
        ["2026-11-19"] = { name = "Race to 20 Raw Bristle Whisker Catfish", scoring = "race", fish = { 6308 }, zone = { 1424, 1442, 1441, 1417 }, target = 20 },
        ["2026-11-20"] = { name = "Most Raw Sagefish", scoring = "most", fish = { 21071 } },
        ["2026-11-21"] = { name = "Best 30 minutes: Firefin Snapper", scoring = "best30", fish = { 6359 }, zone = { 1442, 1437, 1445 } },
        ["2026-11-22"] = { name = "Race to 20 Raw Rainbow Fin Albacore", scoring = "race", fish = { 6361 }, zone = { 1437, 1436, 1439 }, target = 20 },
        ["2026-11-23"] = { name = "Most Raw Mithril Head Trout", scoring = "most", fish = { 8365 } },
        ["2026-11-24"] = { name = "Best 30 minutes: Raw Mithril Head Trout in Thousand Needles or Arathi Highlands", scoring = "best30", fish = { 8365 }, zone = { 1441, 1417 } },
        ["2026-11-25"] = { name = "Race to 20 Raw Bristle Whisker Catfish", scoring = "race", fish = { 6308 }, zone = { 1433, 1431, 1440 }, target = 20 },
        ["2026-11-26"] = { name = "Most Firefin Snapper", scoring = "most", fish = { 6359 } },
        ["2026-11-27"] = { name = "Best 30 minutes: Oily Blackmouth", scoring = "best30", fish = { 6358 }, zone = { 1437, 1436, 1445 } },
        ["2026-11-28"] = { name = "Race to 20 Raw Mithril Head Trout", scoring = "race", fish = { 8365 }, zone = { 1417, 1441, 1443 }, target = 20 },
        ["2026-11-29"] = { name = "Most Raw Rockscale Cod", scoring = "most", fish = { 6362 } },
    },
    launchWeeks = {
        ["2026-11-02"] = { name = "Race to 60 Raw Brilliant Smallfish, any starting zone", scoring = "race", fish = { 6291 }, zone = { 1429, 1426, 1438, 1411, 1412, 1420 }, target = 60 },
        ["2026-11-09"] = { name = "Most Raw Longjaw Mud Snapper", scoring = "most", fish = { 6289 } },
        ["2026-11-16"] = { name = "Best 30 minutes: Raw Slitherskin Mackerel in Durotar or Teldrassil", scoring = "best30", fish = { 6303 }, zone = { 1411, 1438 } },
        ["2026-11-23"] = { name = "Race to 60 Raw Rainbow Fin Albacore", scoring = "race", fish = { 6361 }, zone = { 1436, 1439, 1421, 1413 }, target = 60 },
    },

    -- Hal's series. rule: month (the whole month), week n (the n-th Monday-to-Sunday week
    -- starting in the month), weekend n (the n-th Friday to Sunday, -1 = the last), saturday n.
    -- years[y] sets one year apart: its own dates, note, founding badge.
    series = {
        { id = "first-cast-tour", name = "First cast tour", art = "first-cast-tour", scoring = "quest", rule = { kind = "weekend", month = 11, n = 2 }, note = "One fish in a starting zone and one in a capital city, any order, over the weekend.", needs = { { label = "A starting zone", zone = { 1429, 1426, 1438, 1411, 1412, 1420, 2521 }, n = 1 }, { label = "A capital city", zone = { 1453, 1455, 1457, 1454, 1456, 1458 }, n = 1 } }, years = { [2026] = { start = "2026-11-04", ["end"] = "2026-12-03", note = "Forever's first month: one fish in a starting zone and one in a capital city, any order, any day from launch to December 3.", founding = true } } },
        { id = "tongas-survey", name = "Tonga's survey", art = "tongas-survey", scoring = "quest", rule = { kind = "weekend", month = 11, n = 4 }, note = "Tonga Runetotem wants to know what's bubbling up under the new oases. Hal wants to know if the fish taste funny. One fish from each of the three waters settles both.", needs = { { label = "The Forgotten Pools", zone = { 1413 }, sub = { 386 }, n = 1 }, { label = "Lushwater Oasis", zone = { 1413 }, sub = { 387 }, n = 1 }, { label = "The Stagnant Oasis", zone = { 1413 }, sub = { 388 }, n = 1 } } },
        { id = "loch-frenzy-race", name = "Loch Frenzy race", art = "loch-frenzy-race", scoring = "race", rule = { kind = "week", month = 12, n = 1 }, note = "Twenty Raw Loch Frenzy. They only live in Loch Modan.", target = 20, zone = { 1432 }, fish = { 6317 } },
        { id = "winter-veil-feast", name = "Winter Veil feast", art = "winter-veil-feast", scoring = "quest", rule = { kind = "weekend", month = 12, n = 3 }, note = "Ten each of Smallfish, Mud Snapper and Mackerel, from wherever you like.", needs = { { label = "Raw Brilliant Smallfish", fish = { 6291 }, n = 10 }, { label = "Raw Longjaw Mud Snapper", fish = { 6289 }, n = 10 }, { label = "Raw Slitherskin Mackerel", fish = { 6303 }, n = 10 } } },
        { id = "riverglades-race", name = "Riverglades race", art = "riverglades-race", scoring = "set", rule = { kind = "week", month = 1, n = 2 }, note = "Ten fish of any kind from at least four spots in the Riverglades. Fastest wins.", needs = { { zone = { 2548 }, n = 10 }, { zone = { 2548 }, n = 4, distinct = "sub" } } },
        { id = "squid-run", name = "The squid run", art = "squid-run", scoring = "community", rule = { kind = "month", month = 1 }, note = "Everyone's Raw Winter Squid in January count toward one tally.", target = 2500, fish = { 13755 } },
        { id = "trainers-cup-winter", name = "Winter Trainers' Cup", art = "trainers-cup", scoring = "cup", rule = { kind = "weekend", month = 2, n = 2 }, note = "Every fish caught in a capital counts for that city. The city with the best angler wins.", zone = { 1453, 1455, 1457, 1454, 1456, 1458 } },
        { id = "trainers-cup-spring", name = "Spring Trainers' Cup", art = "trainers-cup", scoring = "cup", rule = { kind = "weekend", month = 5, n = 2 }, note = "Every fish caught in a capital counts for that city. The city with the best angler wins.", zone = { 1453, 1455, 1457, 1454, 1456, 1458 } },
        { id = "trainers-cup-summer", name = "Summer Trainers' Cup", art = "trainers-cup", scoring = "cup", rule = { kind = "weekend", month = 8, n = 1 }, note = "Every fish caught in a capital counts for that city. The city with the best angler wins.", zone = { 1453, 1455, 1457, 1454, 1456, 1458 } },
        { id = "trainers-cup-fall", name = "Fall Trainers' Cup", art = "trainers-cup", scoring = "cup", rule = { kind = "weekend", month = 11, n = 3 }, note = "Every fish caught in a capital counts for that city. The city with the best angler wins.", zone = { 1453, 1455, 1457, 1454, 1456, 1458 } },
        { id = "swallowed-ring", name = "The swallowed ring", art = "swallowed-ring", scoring = "community", rule = { kind = "weekend", month = 2, n = 3 }, note = "Every bloated fish anyone catches this weekend, from anywhere, goes on one pile for Hal to open.", target = 50, fish = { 6643, 6645, 6647, 8366, 13881, 13891, 21243 } },
        { id = "westfall-coast", name = "Westfall coast", art = "westfall-coast", scoring = "best30", rule = { kind = "weekend", month = 3, n = 2 }, note = "Your best thirty minutes on the Westfall coast.", zone = { 1436 } },
        { id = "da-big-catch", name = "Da Big Catch", art = "da-big-catch", scoring = "most", rule = { kind = "saturday", month = 3, n = 4 }, note = "Most fish from Durotar in one Saturday.", zone = { 1411 } },
        { id = "spring-salvage", name = "Spring salvage", art = "spring-salvage", scoring = "most", rule = { kind = "week", month = 4, n = 2 }, note = "Most bottles, crates and trunks fished up in a week, from anywhere.", fish = { 8350, 6307, 6351, 6352, 6357, 13874, 20708, 21113, 21150, 21228 } },
        { id = "apothecarys-order", name = "The apothecary's order", art = "apothecarys-order", scoring = "race", rule = { kind = "weekend", month = 4, n = 4 }, note = "Fifteen Sickly Looking Fish from Tirisfal Glades, Silverpine Forest or the Undercity canals.", target = 15, zone = { 1420, 1458, 1421 }, fish = { 6299 } },
        { id = "man-vs-machine", name = "Man vs. machine", art = "man-vs-machine", scoring = "most", rule = { kind = "week", month = 5, n = 1 }, note = "Most fish from Dun Morogh or the Barrens in a week.", zone = { 1426, 1413 } },
        { id = "hillsbrad-truce", name = "The Hillsbrad truce", art = "hillsbrad-truce", scoring = "race", rule = { kind = "weekend", month = 5, n = 3 }, note = "Ten Raw Bristle Whisker Catfish from Hillsbrad Foothills. Fastest wins.", target = 10, zone = { 1424 }, fish = { 6308 } },
        { id = "longest-day", name = "Longest day", art = "longest-day", scoring = "quest", rule = { kind = "weekend", month = 6, n = 3 }, note = "One fish between 5 and 9 in the morning and one between 6 and 10 at night, server time, any day of the solstice weekend.", needs = { { label = "A fish at dawn, 5 to 9 AM", n = 1, hours = { from = "05:00", to = "09:00" } }, { label = "A fish at dusk, 6 to 10 PM", n = 1, hours = { from = "18:00", to = "22:00" } } } },
        { id = "summer-bass-month", name = "Summer Bass month", art = "summer-bass-month", scoring = "community", rule = { kind = "month", month = 6 }, note = "Everyone's Raw Summer Bass in June count toward one tally.", target = 2500, fish = { 13756 } },
        { id = "blump-family-reunion", name = "The Blump family reunion", art = "blump-family-reunion", scoring = "best30", rule = { kind = "week", month = 7, n = 2 }, note = "Your best thirty minutes of fishing in Darkshore over the week.", zone = { 1439 } },
        { id = "shedding-season", name = "Shedding season", art = "shedding-season", scoring = "race", rule = { kind = "weekend", month = 7, n = 4 }, note = "Fifteen Rockscale Cod from Desolace. Fastest wins.", target = 15, zone = { 1443 }, fish = { 6362 } },
        { id = "feralas-week", name = "The Feralas cook-off", art = "feralas-week", scoring = "faction", rule = { kind = "week", month = 8, n = 2 }, note = "Alliance against Horde: every fish from Feralas counts for your side.", zone = { 1444 } },
        { id = "extreme-clammin", name = "Extreme Clammin'", art = "extreme-clammin", scoring = "most", rule = { kind = "weekend", month = 8, n = 4 }, note = "Most Big-mouth Clams from Azshara over the weekend.", zone = { 1447 }, fish = { 7973 } },
        { id = "dwarven-economics", name = "Dwarven economics", art = "dwarven-economics", scoring = "community", rule = { kind = "weekend", month = 9, n = 2 }, note = "A thousand Stonescale Eels from Tanaris between everyone, over the weekend.", target = 1000, zone = { 1446 }, fish = { 13422 } },
        { id = "something-in-the-water", name = "Something in the water", art = "something-in-the-water", scoring = "quest", rule = { kind = "week", month = 9, n = 4 }, note = "Ten fish from Valorwind Lake, where the Violet Tragan grows, and ten from anywhere else in the Hinterlands to compare them with.", needs = { { label = "Valorwind Lake", zone = { 1425 }, sub = { 1883 }, n = 10 }, { label = "The rest of the Hinterlands", zone = { 1425 }, notSub = { 1883 }, n = 10 } } },
        { id = "four-corners", name = "Four corners", art = "four-corners", scoring = "variety", rule = { kind = "weekend", month = 10, n = 2 }, note = "A fish from each corner of Kalimdor and a fish from each corner of the Eastern Kingdoms, every one a different kind. Two runs, two badges: do one or both.", parts = { { label = "Kalimdor", zone = { 1439, 1452, 1446, 1444 } }, { label = "Eastern Kingdoms", zone = { 1421, 1423, 1434, 1435 } } } },
        { id = "hallows-feud", name = "Hallow's feud", art = "hallows-feud", scoring = "faction", rule = { kind = "weekend", month = 10, n = -1 }, note = "Alliance against Horde for Darrowmere Lake: Alliance fish count for Weldon Barov, Horde fish for Alexi. The side with more fish from the lake holds it for a year.", zone = { 1422 }, sub = { 2297, 2298 } },
    },

    -- The series' text in other languages (site/data/i18n/events.<locale>.json, tools/i18n_events.py):
    -- text[locale][series id] = { name, note, years = { [y] = note }, needs = { label... }, parts = { label... } }.
    -- Anything missing stays English.
    text = {
        deDE = {
            ["first-cast-tour"] = { name = "Tour des ersten Wurfs", note = "Ein Fisch in einem Startgebiet und einer in einer Hauptstadt, egal in welcher Reihenfolge, übers Wochenende.", years = { [2026] = "Forevers erster Monat: ein Fisch in einem Startgebiet und einer in einer Hauptstadt, egal in welcher Reihenfolge, an jedem beliebigen Tag vom Start bis zum 3. Dezember." }, needs = { "Ein Startgebiet", "Eine Hauptstadt" } },
            ["tongas-survey"] = { name = "Tongas Erkundung", note = "Tonga Runentotem will wissen, was unter den neuen Oasen hochblubbert. Hal will wissen, ob die Fische komisch schmecken. Ein Fisch aus jedem der drei Gewässer klärt beides.", needs = { "Die Vergessenen Teiche", "Die Blühende Oase", "Die Brackige Oase" } },
            ["loch-frenzy-race"] = { name = "Loch-Frenzy-Wettlauf", note = "Zwanzig Raw Loch Frenzy. Die gibt es nur in Loch Modan." },
            ["winter-veil-feast"] = { name = "Winterhauch-Festmahl", note = "Je zehn Kleinfische, Schlammschnapper und Makrelen, von wo du willst.", needs = { "Roher glänzender Kleinfisch", "Roher Langkiefer-Schlammschnapper", "Rohe Glitschhautmakrele" } },
            ["riverglades-race"] = { name = "Riverglades-Rennen", note = "Zehn Fische beliebiger Art von mindestens vier Stellen in den Riverglades. Wer am schnellsten ist, gewinnt." },
            ["squid-run"] = { name = "Die Kalmarjagd", note = "Alle Rohen Winterkalmare, die im Januar irgendwer fängt, zählen zu einer gemeinsamen Summe." },
            ["trainers-cup-winter"] = { name = "Winterpokal der Angellehrer", note = "Jeder Fisch, der in einer Hauptstadt gefangen wird, zählt für diese Stadt. Die Stadt mit dem besten Angler gewinnt." },
            ["trainers-cup-spring"] = { name = "Frühlingspokal der Angellehrer", note = "Jeder Fisch, der in einer Hauptstadt gefangen wird, zählt für diese Stadt. Die Stadt mit dem besten Angler gewinnt." },
            ["trainers-cup-summer"] = { name = "Sommerpokal der Angellehrer", note = "Jeder Fisch, der in einer Hauptstadt gefangen wird, zählt für diese Stadt. Die Stadt mit dem besten Angler gewinnt." },
            ["trainers-cup-fall"] = { name = "Herbstpokal der Angellehrer", note = "Jeder Fisch, der in einer Hauptstadt gefangen wird, zählt für diese Stadt. Die Stadt mit dem besten Angler gewinnt." },
            ["swallowed-ring"] = { name = "Der verschluckte Ring", note = "Jeder aufgeblähte Fisch, den irgendwer an diesem Wochenende fängt, egal wo, kommt auf einen Haufen, und Hal macht sie auf." },
            ["westfall-coast"] = { name = "Die Küste von Westfall", note = "Deine besten dreißig Minuten an der Küste von Westfall." },
            ["da-big-catch"] = { name = "Da große Fang", note = "Die meisten Fische aus Durotar an einem Samstag." },
            ["spring-salvage"] = { name = "Frühjahrsbergung", note = "Die meisten Flaschen, Kisten und Truhen, die in einer Woche aus dem Wasser kommen, egal wo." },
            ["apothecarys-order"] = { name = "Die Bestellung des Apothekers", note = "Fünfzehn Kränklich aussehende Fische aus Tirisfal, dem Silberwald oder den Kanälen von Unterstadt." },
            ["man-vs-machine"] = { name = "Mensch gegen Maschine", note = "Die meisten Fische aus Dun Morogh oder dem Brachland in einer Woche." },
            ["hillsbrad-truce"] = { name = "Der Waffenstillstand im Hügelland", note = "Zehn Raw Bristle Whisker Catfish aus dem Vorgebirge des Hügellands. Wer am schnellsten ist, gewinnt." },
            ["longest-day"] = { name = "Der längste Tag", note = "Ein Fisch zwischen 5 und 9 Uhr morgens und einer zwischen 18 und 22 Uhr abends, Serverzeit, an einem beliebigen Tag des Sonnenwendwochenendes.", needs = { "Ein Fisch im Morgengrauen, 5 bis 9 Uhr", "Ein Fisch in der Abenddämmerung, 18 bis 22 Uhr" } },
            ["summer-bass-month"] = { name = "Sommerbarsch-Monat", note = "Alle Rohen Sommerbarsche, die im Juni irgendwer fängt, zählen zu einer gemeinsamen Summe." },
            ["blump-family-reunion"] = { name = "Das Familientreffen der Blumps", note = "Deine besten dreißig Minuten Angeln an der Dunkelküste im Lauf der Woche." },
            ["shedding-season"] = { name = "Häutungszeit", note = "Fünfzehn Felsschuppenkabeljaue aus Desolace. Wer am schnellsten ist, gewinnt." },
            ["feralas-week"] = { name = "Das Kochduell von Feralas", note = "Allianz gegen Horde: Jeder Fisch aus Feralas zählt für deine Seite." },
            ["extreme-clammin"] = { name = "Extrem-Muscheln", note = "Die meisten Großmaulmuscheln aus Azshara übers Wochenende." },
            ["dwarven-economics"] = { name = "Zwergische Volkswirtschaft", note = "Tausend Steinschuppenaale aus Tanaris, alle zusammen, übers Wochenende." },
            ["something-in-the-water"] = { name = "Irgendwas im Wasser", note = "Zehn Fische aus dem Valorwindsee, wo der Violette Tragan wächst, und zehn aus dem übrigen Hinterland, damit man sie vergleichen kann.", needs = { "Valorwindsee", "Das übrige Hinterland" } },
            ["four-corners"] = { name = "Vier Ecken", note = "Ein Fisch aus jeder Ecke Kalimdors und einer aus jeder Ecke der Östlichen Königreiche, jeder von einer anderen Art. Zwei Läufe, zwei Abzeichen: mach einen oder beide.", parts = { "Kalimdor", "Östliche Königreiche" } },
            ["hallows-feud"] = { name = "Die Schlotterfehde", note = "Allianz gegen Horde um den Darrowmeresee: Fische der Allianz zählen für Weldon Barov, Fische der Horde für Alexi. Die Seite mit mehr Fischen aus dem See behält ihn ein Jahr lang." },
        },
        esES = {
            ["first-cast-tour"] = { name = "Gira del primer lanzamiento", note = "Un pez en una zona de inicio y otro en una capital, en el orden que quieras, durante el fin de semana.", years = { [2026] = "El primer mes de Forever: un pez en una zona de inicio y otro en una capital, en el orden que quieras, cualquier día desde el lanzamiento hasta el 3 de diciembre." }, needs = { "Una zona de inicio", "Una capital" } },
            ["tongas-survey"] = { name = "El estudio de Tonga", note = "Tonga Tótem Rúnico quiere saber qué burbujea bajo los nuevos oasis. Hal quiere saber si los peces saben raro. Un pez de cada una de las tres aguas resuelve las dos cosas.", needs = { "Las Charcas del Olvido", "Oasis Aguaverde", "El Oasis Estancado" } },
            ["loch-frenzy-race"] = { name = "Carrera del Loch Frenzy", note = "Veinte Raw Loch Frenzy. Solo viven en Loch Modan." },
            ["winter-veil-feast"] = { name = "Banquete del Festival de Invierno", note = "Diez de cada: Smallfish, Mud Snapper y Mackerel, pescados donde quieras.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Carrera de Riverglades", note = "Diez peces de cualquier tipo de al menos cuatro sitios de Riverglades. Gana el más rápido." },
            ["squid-run"] = { name = "La temporada del calamar", note = "Todos los Raw Winter Squid que pesque cualquiera en enero cuentan para un único total." },
            ["trainers-cup-winter"] = { name = "Copa de instructores de invierno", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-spring"] = { name = "Copa de instructores de primavera", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-summer"] = { name = "Copa de instructores de verano", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-fall"] = { name = "Copa de instructores de otoño", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["swallowed-ring"] = { name = "El anillo tragado", note = "Todos los peces hinchados que pesque cualquiera este fin de semana, en cualquier sitio, van a un mismo montón para que Hal los abra." },
            ["westfall-coast"] = { name = "La costa de Poniente", note = "Tus mejores treinta minutos en la costa de los Páramos de Poniente." },
            ["da-big-catch"] = { name = "Da gran pesca", note = "Más peces de Durotar en un sábado." },
            ["spring-salvage"] = { name = "Rescate de primavera", note = "Más botellas, cajas y baúles sacados del agua en una semana, en cualquier sitio." },
            ["apothecarys-order"] = { name = "El encargo del boticario", note = "Quince Sickly Looking Fish de los Claros de Tirisfal, el Bosque de Argénteos o los canales de Entrañas." },
            ["man-vs-machine"] = { name = "Hombre contra máquina", note = "Más peces de Dun Morogh o Los Baldíos en una semana." },
            ["hillsbrad-truce"] = { name = "La tregua de Trabalomas", note = "Diez Raw Bristle Whisker Catfish de las Laderas de Trabalomas. Gana el más rápido." },
            ["longest-day"] = { name = "El día más largo", note = "Un pez entre las 5:00 y las 9:00 de la mañana y otro entre las 18:00 y las 22:00, hora del servidor, cualquier día del fin de semana del solsticio.", needs = { "Un pez al amanecer, de 5:00 a 9:00", "Un pez al anochecer, de 18:00 a 22:00" } },
            ["summer-bass-month"] = { name = "El mes del Summer Bass", note = "Todos los Raw Summer Bass que pesque cualquiera en junio cuentan para un único total." },
            ["blump-family-reunion"] = { name = "La reunión familiar de los Blump", note = "Tus mejores treinta minutos de pesca en Costa Oscura durante la semana." },
            ["shedding-season"] = { name = "Temporada de muda", note = "Quince Rockscale Cod de Desolace. Gana el más rápido." },
            ["feralas-week"] = { name = "El duelo de cocina de Feralas", note = "Alianza contra Horda: cada pez de Feralas cuenta para tu bando." },
            ["extreme-clammin"] = { name = "Almejeo extremo", note = "Más Big-mouth Clams de Azshara durante el fin de semana." },
            ["dwarven-economics"] = { name = "Economía enana", note = "Mil Stonescale Eels de Tanaris entre todos, durante el fin de semana." },
            ["something-in-the-water"] = { name = "Algo en el agua", note = "Diez peces del Lago Ventobravo, donde crece el Violet Tragan, y diez de cualquier otro sitio de las Tierras del Interior para compararlos.", needs = { "Lago Ventobravo", "El resto de las Tierras del Interior" } },
            ["four-corners"] = { name = "Cuatro esquinas", note = "Un pez de cada esquina de Kalimdor y uno de cada esquina de los Reinos del Este, cada uno de una especie distinta. Dos recorridos, dos insignias: haz uno o los dos.", parts = { "Kalimdor", "Reinos del Este" } },
            ["hallows-feud"] = { name = "La rencilla de Halloween", note = "Alianza contra Horda por el Lago Darrowmere: los peces de la Alianza cuentan para Weldon Barov y los de la Horda para Alexi. El bando que saque más peces del lago se lo queda un año." },
        },
        esMX = {
            ["first-cast-tour"] = { name = "Gira del primer lanzamiento", note = "Un pez en una zona de inicio y otro en una capital, en el orden que quieras, durante el fin de semana.", years = { [2026] = "El primer mes de Forever: un pez en una zona de inicio y otro en una capital, en el orden que quieras, cualquier día desde el lanzamiento hasta el 3 de diciembre." }, needs = { "Una zona de inicio", "Una capital" } },
            ["tongas-survey"] = { name = "El estudio de Tonga", note = "Tonga Tótem Rúnico quiere saber qué burbujea bajo los nuevos oasis. Hal quiere saber si los peces saben raro. Un pez de cada una de las tres aguas resuelve las dos cosas.", needs = { "Las Charcas del Olvido", "Oasis Aguaverde", "El Oasis Estancado" } },
            ["loch-frenzy-race"] = { name = "Carrera del Loch Frenzy", note = "Veinte Raw Loch Frenzy. Solo viven en Loch Modan." },
            ["winter-veil-feast"] = { name = "Banquete del Festival de Invierno", note = "Diez de cada: Smallfish, Mud Snapper y Mackerel, pescados donde quieras.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Carrera de Riverglades", note = "Diez peces de cualquier tipo de al menos cuatro lugares de Riverglades. Gana el más rápido." },
            ["squid-run"] = { name = "La temporada del calamar", note = "Todos los Raw Winter Squid que pesque cualquiera en enero cuentan para un único total." },
            ["trainers-cup-winter"] = { name = "Copa de instructores de invierno", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-spring"] = { name = "Copa de instructores de primavera", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-summer"] = { name = "Copa de instructores de verano", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["trainers-cup-fall"] = { name = "Copa de instructores de otoño", note = "Cada pez pescado en una capital cuenta para esa ciudad. Gana la ciudad con el mejor pescador." },
            ["swallowed-ring"] = { name = "El anillo tragado", note = "Todos los peces hinchados que pesque cualquiera este fin de semana, en cualquier lugar, van a un mismo montón para que Hal los abra." },
            ["westfall-coast"] = { name = "La costa de Poniente", note = "Tus mejores treinta minutos en la costa de los Páramos de Poniente." },
            ["da-big-catch"] = { name = "Da gran pesca", note = "Más peces de Durotar en un sábado." },
            ["spring-salvage"] = { name = "Rescate de primavera", note = "Más botellas, cajas y baúles sacados del agua en una semana, en cualquier lugar." },
            ["apothecarys-order"] = { name = "El encargo del boticario", note = "Quince Sickly Looking Fish de los Claros de Tirisfal, el Bosque de Argénteos o los canales de Entrañas." },
            ["man-vs-machine"] = { name = "Hombre contra máquina", note = "Más peces de Dun Morogh o Los Baldíos en una semana." },
            ["hillsbrad-truce"] = { name = "La tregua de Trabalomas", note = "Diez Raw Bristle Whisker Catfish de las Laderas de Trabalomas. Gana el más rápido." },
            ["longest-day"] = { name = "El día más largo", note = "Un pez entre las 5 y las 9 a. m. y otro entre las 6 y las 10 p. m., hora del servidor, cualquier día del fin de semana del solsticio.", needs = { "Un pez al amanecer, de 5 a 9 a. m.", "Un pez al anochecer, de 6 a 10 p. m." } },
            ["summer-bass-month"] = { name = "El mes del Summer Bass", note = "Todos los Raw Summer Bass que pesque cualquiera en junio cuentan para un único total." },
            ["blump-family-reunion"] = { name = "La reunión familiar de los Blump", note = "Tus mejores treinta minutos de pesca en Costa Oscura durante la semana." },
            ["shedding-season"] = { name = "Temporada de muda", note = "Quince Rockscale Cod de Desolace. Gana el más rápido." },
            ["feralas-week"] = { name = "El duelo de cocina de Feralas", note = "Alianza contra Horda: cada pez de Feralas cuenta para tu bando." },
            ["extreme-clammin"] = { name = "Almejeo extremo", note = "Más Big-mouth Clams de Azshara durante el fin de semana." },
            ["dwarven-economics"] = { name = "Economía enana", note = "Mil Stonescale Eels de Tanaris entre todos, durante el fin de semana." },
            ["something-in-the-water"] = { name = "Algo en el agua", note = "Diez peces del Lago Ventobravo, donde crece el Violet Tragan, y diez de cualquier otro lugar de las Tierras del Interior para compararlos.", needs = { "Lago Ventobravo", "El resto de las Tierras del Interior" } },
            ["four-corners"] = { name = "Cuatro esquinas", note = "Un pez de cada esquina de Kalimdor y uno de cada esquina de los Reinos del Este, cada uno de una especie distinta. Dos recorridos, dos insignias: haz uno o los dos.", parts = { "Kalimdor", "Reinos del Este" } },
            ["hallows-feud"] = { name = "La rencilla de Halloween", note = "Alianza contra Horda por el Lago Darrowmere: los peces de la Alianza cuentan para Weldon Barov y los de la Horda para Alexi. El bando que saque más peces del lago se lo queda un año." },
        },
        frFR = {
            ["first-cast-tour"] = { name = "Tournée du premier lancer", note = "Un poisson dans une zone de départ et un dans une capitale, dans l'ordre que vous voulez, pendant le week-end.", years = { [2026] = "Le premier mois de Forever : un poisson dans une zone de départ et un dans une capitale, dans l'ordre que vous voulez, n'importe quel jour entre le lancement et le 3 décembre." }, needs = { "Une zone de départ", "Une capitale" } },
            ["tongas-survey"] = { name = "L'enquête de Tonga", note = "Tonga Totem-Runique veut savoir ce qui bouillonne sous les nouvelles oasis. Hal veut savoir si les poissons ont un drôle de goût. Un poisson de chacun des trois points d'eau règle les deux questions.", needs = { "Les Bassins oubliés", "Oasis luxuriante", "L'oasis stagnante" } },
            ["loch-frenzy-race"] = { name = "Course aux Loch Frenzy", note = "Vingt Raw Loch Frenzy. On n'en trouve qu'au Loch Modan." },
            ["winter-veil-feast"] = { name = "Le festin du Voile d'hiver", note = "Dix de chaque : Smallfish, Mud Snapper et Mackerel, pêchés où vous voulez.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Course des Riverglades", note = "Dix poissons de n'importe quelle sorte, pris à au moins quatre endroits des Riverglades. Le plus rapide gagne." },
            ["squid-run"] = { name = "La saison du calmar", note = "Tous les Raw Winter Squid pêchés en janvier, par qui que ce soit, comptent pour un seul total." },
            ["trainers-cup-winter"] = { name = "Coupe des maîtres : hiver", note = "Chaque poisson pêché dans une capitale compte pour cette ville. La ville qui a le meilleur pêcheur gagne." },
            ["trainers-cup-spring"] = { name = "Coupe des maîtres : printemps", note = "Chaque poisson pêché dans une capitale compte pour cette ville. La ville qui a le meilleur pêcheur gagne." },
            ["trainers-cup-summer"] = { name = "Coupe des maîtres : été", note = "Chaque poisson pêché dans une capitale compte pour cette ville. La ville qui a le meilleur pêcheur gagne." },
            ["trainers-cup-fall"] = { name = "Coupe des maîtres : automne", note = "Chaque poisson pêché dans une capitale compte pour cette ville. La ville qui a le meilleur pêcheur gagne." },
            ["swallowed-ring"] = { name = "La bague avalée", note = "Chaque poisson gonflé pêché ce week-end, par n'importe qui et n'importe où, va sur un seul tas que Hal ouvrira." },
            ["westfall-coast"] = { name = "La côte de la Marche de l'Ouest", note = "Vos trente meilleures minutes sur la côte de la Marche de l'Ouest." },
            ["da-big-catch"] = { name = "Da grosse prise", note = "Le plus de poissons de Durotar en un samedi." },
            ["spring-salvage"] = { name = "Repêchage de printemps", note = "Le plus de bouteilles, caisses et malles repêchées en une semaine, n'importe où." },
            ["apothecarys-order"] = { name = "La commande de l'apothicaire", note = "Quinze Sickly Looking Fish des clairières de Tirisfal, de la forêt des Pins-Argentés ou des canaux de Fossoyeuse." },
            ["man-vs-machine"] = { name = "L'homme contre la machine", note = "Le plus de poissons de Dun Morogh ou des Tarides en une semaine." },
            ["hillsbrad-truce"] = { name = "La trêve de Hautebrande", note = "Dix Raw Bristle Whisker Catfish des contreforts de Hautebrande. Le plus rapide gagne." },
            ["longest-day"] = { name = "Le jour le plus long", note = "Un poisson entre 5 h et 9 h du matin et un entre 18 h et 22 h, heure du serveur, n'importe quel jour du week-end du solstice.", needs = { "Un poisson à l'aube, de 5 h à 9 h", "Un poisson au crépuscule, de 18 h à 22 h" } },
            ["summer-bass-month"] = { name = "Le mois du Summer Bass", note = "Tous les Raw Summer Bass pêchés en juin, par qui que ce soit, comptent pour un seul total." },
            ["blump-family-reunion"] = { name = "La réunion de famille des Blump", note = "Vos trente meilleures minutes de pêche à Sombrivage au cours de la semaine." },
            ["shedding-season"] = { name = "La saison de la mue", note = "Quinze Rockscale Cod de Désolace. Le plus rapide gagne." },
            ["feralas-week"] = { name = "Le duel culinaire de Feralas", note = "L'Alliance contre la Horde : chaque poisson de Feralas compte pour votre camp." },
            ["extreme-clammin"] = { name = "Palourdes de l'extrême", note = "Le plus de Big-mouth Clams d'Azshara pendant le week-end." },
            ["dwarven-economics"] = { name = "Économie naine", note = "Mille Stonescale Eels de Tanaris, tous ensemble, pendant le week-end." },
            ["something-in-the-water"] = { name = "Quelque chose dans l'eau", note = "Dix poissons du lac Vent-vaillant, où pousse le Violet Tragan, et dix d'ailleurs dans les Hinterlands, pour comparer.", needs = { "Lac Vent-vaillant", "Le reste des Hinterlands" } },
            ["four-corners"] = { name = "Les quatre coins", note = "Un poisson de chaque coin de Kalimdor et un de chaque coin des Royaumes de l'Est, chacun d'une espèce différente. Deux parcours, deux badges : faites-en un ou les deux.", parts = { "Kalimdor", "Royaumes de l'Est" } },
            ["hallows-feud"] = { name = "La querelle de la Sanssaint", note = "L'Alliance contre la Horde pour le lac Darrowmere : les poissons de l'Alliance comptent pour Weldon Barov, ceux de la Horde pour Alexi. Le camp qui sort le plus de poissons du lac le garde pendant un an." },
        },
        itIT = {
            ["first-cast-tour"] = { name = "Il giro del primo lancio", note = "Un pesce in una zona iniziale e uno in una capitale, in qualsiasi ordine, nel fine settimana.", years = { [2026] = "Il primo mese di Forever: un pesce in una zona iniziale e uno in una capitale, in qualsiasi ordine, in qualsiasi giorno dal lancio al 3 dicembre." }, needs = { "Una zona iniziale", "Una capitale" } },
            ["tongas-survey"] = { name = "L'indagine di Tonga", note = "Tonga Totem Runico vuole sapere cosa ribolle sotto le nuove oasi. Hal vuole sapere se i pesci hanno un sapore strano. Un pesce da ciascuna delle tre acque risponde a tutti e due.", needs = { "The Forgotten Pools", "Lushwater Oasis", "The Stagnant Oasis" } },
            ["loch-frenzy-race"] = { name = "Gara di Loch Modan", note = "Venti Raw Loch Frenzy. Vivono solo a Loch Modan." },
            ["winter-veil-feast"] = { name = "Banchetto di Grande Inverno", note = "Dieci ciascuno di Brilliant Smallfish, Mud Snapper e Mackerel, da dove vuoi.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Gara delle Riverglades", note = "Dieci pesci qualsiasi da almeno quattro punti delle Riverglades. Vince il più veloce." },
            ["squid-run"] = { name = "La corsa ai calamari", note = "Tutti i Raw Winter Squid pescati da chiunque a gennaio finiscono in un unico conteggio." },
            ["trainers-cup-winter"] = { name = "Coppa degli Istruttori d'Inverno", note = "Ogni pesce preso in una capitale conta per quella città. Vince la città con il pescatore migliore." },
            ["trainers-cup-spring"] = { name = "Coppa degli Istruttori di Primavera", note = "Ogni pesce preso in una capitale conta per quella città. Vince la città con il pescatore migliore." },
            ["trainers-cup-summer"] = { name = "Coppa degli Istruttori d'Estate", note = "Ogni pesce preso in una capitale conta per quella città. Vince la città con il pescatore migliore." },
            ["trainers-cup-fall"] = { name = "Coppa degli Istruttori d'Autunno", note = "Ogni pesce preso in una capitale conta per quella città. Vince la città con il pescatore migliore." },
            ["swallowed-ring"] = { name = "L'anello inghiottito", note = "Ogni pesce gonfio che chiunque peschi questo fine settimana, da qualsiasi posto, finisce in un'unica pila che Hal aprirà." },
            ["westfall-coast"] = { name = "La costa delle Marche", note = "La tua mezz'ora migliore sulla costa delle Marche Occidentali." },
            ["da-big-catch"] = { name = "La Grossa Pescata", note = "Più pesci da Durotar in un solo sabato." },
            ["spring-salvage"] = { name = "Recupero di primavera", note = "Più bottiglie, casse e bauli ripescati in una settimana, da qualsiasi posto." },
            ["apothecarys-order"] = { name = "L'ordine dello speziale", note = "Quindici Sickly Looking Fish dalle Radure di Tirisfal, dalla Foresta di Pinargento o dai canali di Sepulcra." },
            ["man-vs-machine"] = { name = "Uomo contro macchina", note = "Più pesci da Dun Morogh o dalle Savane in una settimana." },
            ["hillsbrad-truce"] = { name = "La tregua di Hillsbrad", note = "Dieci Raw Bristle Whisker Catfish dalle Colline di Hillsbrad. Vince il più veloce." },
            ["longest-day"] = { name = "Il giorno più lungo", note = "Un pesce tra le 5 e le 9 del mattino e uno tra le 18 e le 22, ora del server, in qualsiasi giorno del fine settimana del solstizio.", needs = { "Un pesce all'alba, dalle 5 alle 9", "Un pesce al tramonto, dalle 18 alle 22" } },
            ["summer-bass-month"] = { name = "Il mese dei Summer Bass", note = "Tutti i Raw Summer Bass pescati da chiunque a giugno finiscono in un unico conteggio." },
            ["blump-family-reunion"] = { name = "La rimpatriata dei Blump", note = "La tua mezz'ora di pesca migliore a Rivafosca durante la settimana." },
            ["shedding-season"] = { name = "La stagione della muta", note = "Quindici Rockscale Cod da Desolanda. Vince il più veloce." },
            ["feralas-week"] = { name = "La sfida ai fornelli di Feralas", note = "Alleanza contro Orda: ogni pesce di Feralas conta per la tua fazione." },
            ["extreme-clammin"] = { name = "Vongole estreme", note = "Più Big-mouth Clam da Azshara nel fine settimana." },
            ["dwarven-economics"] = { name = "Economia nanica", note = "Mille Stonescale Eel da Tanaris tutti insieme, nel fine settimana." },
            ["something-in-the-water"] = { name = "C'è qualcosa nell'acqua", note = "Dieci pesci dal Valorwind Lake, dove cresce la Violet Tragan, e dieci da qualsiasi altro punto degli Entroterre per fare il confronto.", needs = { "Valorwind Lake", "Il resto degli Entroterre" } },
            ["four-corners"] = { name = "Quattro angoli", note = "Un pesce da ogni angolo di Kalimdor e un pesce da ogni angolo dei Regni Orientali, ognuno di specie diversa. Due percorsi, due distintivi: fanne uno o tutti e due.", parts = { "Kalimdor", "Regni Orientali" } },
            ["hallows-feud"] = { name = "La faida dei Barov", note = "Alleanza contro Orda per il Darrowmere Lake: i pesci dell'Alleanza contano per Weldon Barov, quelli dell'Orda per Alexi. La fazione con più pesci del lago lo tiene per un anno." },
        },
        koKR = {
            ["first-cast-tour"] = { name = "첫 낚시 순례", note = "주말 동안 시작 지역에서 한 마리, 수도에서 한 마리. 순서는 상관없습니다.", years = { [2026] = "Forever의 첫 달: 시작 지역에서 한 마리, 수도에서 한 마리. 순서는 상관없고, 출시일부터 12월 3일까지 아무 날이나 됩니다." }, needs = { "시작 지역", "수도" } },
            ["tongas-survey"] = { name = "통가의 조사", note = "통가 룬토템은 새로 생긴 오아시스 밑에서 뭐가 끓어오르는지 알고 싶어 합니다. Hal은 물고기 맛이 이상한지 알고 싶습니다. 세 물가에서 한 마리씩이면 둘 다 해결됩니다.", needs = { "잊혀진 웅덩이", "푸른 오아시스", "죽은 오아시스" } },
            ["loch-frenzy-race"] = { name = "모단 호수 경주", note = "Raw Loch Frenzy 스무 마리. 모단 호수에만 삽니다." },
            ["winter-veil-feast"] = { name = "겨울맞이 축제 만찬", note = "작은 물고기, 진흙 퉁돔, 고등어를 열 마리씩. 어디서 낚든 상관없습니다.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Riverglades 경주", note = "Riverglades에서 적어도 네 곳의 낚시터를 돌며 아무 물고기나 열 마리. 가장 빠른 사람이 이깁니다." },
            ["squid-run"] = { name = "오징어 철", note = "1월에 모두가 낚은 겨울 오징어를 하나로 합산합니다." },
            ["trainers-cup-winter"] = { name = "겨울 수도 대항전", note = "수도에서 낚은 물고기는 모두 그 도시의 점수가 됩니다. 최고의 낚시꾼이 있는 도시가 이깁니다." },
            ["trainers-cup-spring"] = { name = "봄 수도 대항전", note = "수도에서 낚은 물고기는 모두 그 도시의 점수가 됩니다. 최고의 낚시꾼이 있는 도시가 이깁니다." },
            ["trainers-cup-summer"] = { name = "여름 수도 대항전", note = "수도에서 낚은 물고기는 모두 그 도시의 점수가 됩니다. 최고의 낚시꾼이 있는 도시가 이깁니다." },
            ["trainers-cup-fall"] = { name = "가을 수도 대항전", note = "수도에서 낚은 물고기는 모두 그 도시의 점수가 됩니다. 최고의 낚시꾼이 있는 도시가 이깁니다." },
            ["swallowed-ring"] = { name = "삼켜진 반지", note = "이번 주말 누가 어디서 낚았든, 배가 부푼 물고기는 전부 한 무더기에 모아 Hal이 하나씩 갈라 봅니다." },
            ["westfall-coast"] = { name = "서부 몰락지대 해안", note = "서부 몰락지대 해안에서 보낸 당신의 최고의 30분." },
            ["da-big-catch"] = { name = "대물 잔치", note = "토요일 하루, 듀로타에서 가장 많이 낚은 사람이 이깁니다." },
            ["spring-salvage"] = { name = "봄맞이 인양", note = "일주일 동안 어디서든 병, 상자, 궤짝을 가장 많이 건져 올린 사람이 이깁니다." },
            ["apothecarys-order"] = { name = "약제사의 주문", note = "티리스팔 숲, 은빛소나무 숲, 또는 언더시티 수로에서 Sickly Looking Fish 열다섯 마리." },
            ["man-vs-machine"] = { name = "인간 대 기계", note = "일주일 동안 던 모로나 불모의 땅에서 가장 많이 낚은 사람이 이깁니다." },
            ["hillsbrad-truce"] = { name = "힐스브래드 휴전", note = "힐스브래드 구릉지에서 Raw Bristle Whisker Catfish 열 마리. 가장 빠른 사람이 이깁니다." },
            ["longest-day"] = { name = "가장 긴 하루", note = "하지 주말 중 아무 날이나, 서버 시간으로 아침 5시에서 9시 사이에 한 마리, 저녁 6시에서 10시 사이에 한 마리.", needs = { "새벽 물고기, 오전 5~9시", "해 질 녘 물고기, 오후 6~10시" } },
            ["summer-bass-month"] = { name = "여름 농어의 달", note = "6월에 모두가 낚은 여름 농어를 하나로 합산합니다." },
            ["blump-family-reunion"] = { name = "Blump 가족 모임", note = "일주일 중 어둠해안에서 보낸 당신의 최고의 낚시 30분." },
            ["shedding-season"] = { name = "탈피의 계절", note = "잊혀진 땅에서 Rockscale Cod 열다섯 마리. 가장 빠른 사람이 이깁니다." },
            ["feralas-week"] = { name = "페랄라스 요리 대결", note = "얼라이언스 대 호드: 페랄라스에서 낚은 물고기는 모두 자기 진영의 점수가 됩니다." },
            ["extreme-clammin"] = { name = "극한 조개잡이", note = "주말 동안 아즈샤라에서 Big-mouth Clam을 가장 많이 낚은 사람이 이깁니다." },
            ["dwarven-economics"] = { name = "드워프 경제학", note = "주말 동안 모두 함께 타나리스에서 Stonescale Eel 천 마리." },
            ["something-in-the-water"] = { name = "물속의 무언가", note = "Violet Tragan이 자라는 돌개바람 호수에서 열 마리, 그리고 비교할 수 있게 동부 내륙지의 다른 곳에서 열 마리.", needs = { "돌개바람 호수", "동부 내륙지의 나머지 지역" } },
            ["four-corners"] = { name = "네 귀퉁이", note = "칼림도어의 네 귀퉁이에서 한 마리씩, 동부 왕국의 네 귀퉁이에서 한 마리씩, 모두 다른 어종으로. 코스 두 개, 배지 두 개: 하나만 해도, 둘 다 해도 됩니다.", parts = { "칼림도어", "동부 왕국" } },
            ["hallows-feud"] = { name = "할로윈 앙숙전", note = "다로미어 호수를 두고 얼라이언스 대 호드: 얼라이언스의 물고기는 Weldon Barov, 호드의 물고기는 Alexi의 몫입니다. 호수에서 더 많이 낚은 쪽이 1년 동안 호수를 차지합니다." },
        },
        ptBR = {
            ["first-cast-tour"] = { name = "Rota do primeiro arremesso", note = "Um peixe numa zona inicial e um numa capital, em qualquer ordem, no fim de semana.", years = { [2026] = "Primeiro mês de Forever: um peixe numa zona inicial e um numa capital, em qualquer ordem, em qualquer dia do lançamento até 3 de dezembro." }, needs = { "Uma zona inicial", "Uma capital" } },
            ["tongas-survey"] = { name = "A pesquisa de Tonga", note = "Tonga Totem Rúnico quer saber o que está borbulhando debaixo dos novos oásis. O Hal quer saber se os peixes estão com gosto estranho. Um peixe de cada uma das três águas resolve as duas coisas.", needs = { "The Forgotten Pools", "Lushwater Oasis", "The Stagnant Oasis" } },
            ["loch-frenzy-race"] = { name = "Corrida de Loch Modan", note = "Vinte Raw Loch Frenzy. Eles só vivem em Loch Modan." },
            ["winter-veil-feast"] = { name = "Banquete do Véu de Inverno", note = "Dez de cada: Brilliant Smallfish, Mud Snapper e Mackerel, de onde você quiser.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Corrida de Riverglades", note = "Dez peixes de qualquer tipo de pelo menos quatro pontos de Riverglades. Vence o mais rápido." },
            ["squid-run"] = { name = "A temporada da lula", note = "Toda Raw Winter Squid pescada por qualquer um em janeiro entra numa só contagem." },
            ["trainers-cup-winter"] = { name = "Copa dos Instrutores de Inverno", note = "Todo peixe pescado numa capital conta para aquela cidade. Vence a cidade com o melhor pescador." },
            ["trainers-cup-spring"] = { name = "Copa dos Instrutores de Primavera", note = "Todo peixe pescado numa capital conta para aquela cidade. Vence a cidade com o melhor pescador." },
            ["trainers-cup-summer"] = { name = "Copa dos Instrutores de Verão", note = "Todo peixe pescado numa capital conta para aquela cidade. Vence a cidade com o melhor pescador." },
            ["trainers-cup-fall"] = { name = "Copa dos Instrutores de Outono", note = "Todo peixe pescado numa capital conta para aquela cidade. Vence a cidade com o melhor pescador." },
            ["swallowed-ring"] = { name = "O anel engolido", note = "Todo peixe inchado que qualquer um pescar neste fim de semana, de qualquer lugar, vai para uma pilha só para o Hal abrir." },
            ["westfall-coast"] = { name = "Costa do Cerrado Oeste", note = "Sua melhor meia hora na costa do Cerrado Oeste." },
            ["da-big-catch"] = { name = "A Grande Pescaria", note = "Mais peixes de Durotar num só sábado." },
            ["spring-salvage"] = { name = "Resgate de primavera", note = "Mais garrafas, caixotes e baús pescados numa semana, de qualquer lugar." },
            ["apothecarys-order"] = { name = "A encomenda do boticário", note = "Quinze Sickly Looking Fish das Clareiras de Tirisfal, da Floresta de Pinhaprata ou dos canais da Cidade Baixa." },
            ["man-vs-machine"] = { name = "Homem contra máquina", note = "Mais peixes de Dun Morogh ou dos Sertões numa semana." },
            ["hillsbrad-truce"] = { name = "A trégua de Eira dos Montes", note = "Dez Raw Bristle Whisker Catfish do Contraforte de Eira dos Montes. Vence o mais rápido." },
            ["longest-day"] = { name = "O dia mais longo", note = "Um peixe entre 5h e 9h da manhã e um entre 18h e 22h, horário do servidor, em qualquer dia do fim de semana do solstício.", needs = { "Um peixe ao amanhecer, das 5h às 9h", "Um peixe ao entardecer, das 18h às 22h" } },
            ["summer-bass-month"] = { name = "Mês do Summer Bass", note = "Todo Raw Summer Bass pescado por qualquer um em junho entra numa só contagem." },
            ["blump-family-reunion"] = { name = "A reunião dos Blump", note = "Sua melhor meia hora de pesca na Costa Negra durante a semana." },
            ["shedding-season"] = { name = "Época da muda", note = "Quinze Rockscale Cod de Desolação. Vence o mais rápido." },
            ["feralas-week"] = { name = "O duelo de cozinha de Feralas", note = "Aliança contra Horda: todo peixe de Feralas conta para o seu lado." },
            ["extreme-clammin"] = { name = "Mariscada radical", note = "Mais Big-mouth Clams de Azshara no fim de semana." },
            ["dwarven-economics"] = { name = "Economia anã", note = "Mil Stonescale Eels de Tanaris, somando todo mundo, no fim de semana." },
            ["something-in-the-water"] = { name = "Tem algo na água", note = "Dez peixes do Valorwind Lake, onde cresce a Violet Tragan, e dez de qualquer outro lugar das Terras Agrestes para comparar.", needs = { "Valorwind Lake", "O resto das Terras Agrestes" } },
            ["four-corners"] = { name = "Quatro cantos", note = "Um peixe de cada canto de Kalimdor e um peixe de cada canto dos Reinos do Leste, todos de tipos diferentes. Duas corridas, dois emblemas: faça uma ou as duas.", parts = { "Kalimdor", "Reinos do Leste" } },
            ["hallows-feud"] = { name = "A rixa da Noturnália", note = "Aliança contra Horda pelo Darrowmere Lake: peixes da Aliança contam para Weldon Barov, peixes da Horda para Alexi. O lado com mais peixes do lago fica com ele por um ano." },
        },
        ruRU = {
            ["first-cast-tour"] = { name = "Первый заброс", note = "Одна рыба в стартовой зоне и одна в столице, в любом порядке, за выходные.", years = { [2026] = "Первый месяц Forever: одна рыба в стартовой зоне и одна в столице, в любом порядке, в любой день с запуска до 3 декабря." }, needs = { "Стартовая зона", "Столица" } },
            ["tongas-survey"] = { name = "Изыскания Тонги", note = "Тонга Рунный Тотем хочет знать, что пузырится под новыми оазисами. Хэл хочет знать, не странный ли у рыбы вкус. По рыбе из каждого из трёх водоёмов ответят на оба вопроса.", needs = { "The Forgotten Pools", "Lushwater Oasis", "The Stagnant Oasis" } },
            ["loch-frenzy-race"] = { name = "Гонка в Лок Модане", note = "Двадцать штук Raw Loch Frenzy. Водятся только в Лок Модане." },
            ["winter-veil-feast"] = { name = "Пир Зимнего Покрова", note = "По десять штук Brilliant Smallfish, Mud Snapper и Mackerel, откуда угодно.", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Гонка в Riverglades", note = "Десять рыб любого вида минимум из четырёх мест в Riverglades. Побеждает самый быстрый." },
            ["squid-run"] = { name = "Кальмаровый сезон", note = "Все Raw Winter Squid, пойманные кем угодно в январе, идут в общий счёт." },
            ["trainers-cup-winter"] = { name = "Зимний кубок наставников", note = "Каждая рыба, пойманная в столице, засчитывается этому городу. Побеждает город, где лучший рыболов." },
            ["trainers-cup-spring"] = { name = "Весенний кубок наставников", note = "Каждая рыба, пойманная в столице, засчитывается этому городу. Побеждает город, где лучший рыболов." },
            ["trainers-cup-summer"] = { name = "Летний кубок наставников", note = "Каждая рыба, пойманная в столице, засчитывается этому городу. Побеждает город, где лучший рыболов." },
            ["trainers-cup-fall"] = { name = "Осенний кубок наставников", note = "Каждая рыба, пойманная в столице, засчитывается этому городу. Побеждает город, где лучший рыболов." },
            ["swallowed-ring"] = { name = "Проглоченное кольцо", note = "Вся раздутая рыба, пойманная кем угодно и где угодно в эти выходные, идёт в одну кучу, а Хэл её вскроет." },
            ["westfall-coast"] = { name = "Побережье Западного Края", note = "Ваши лучшие полчаса на побережье Западного Края." },
            ["da-big-catch"] = { name = "Большой улов", note = "Больше всех рыбы из Дуротара за одну субботу." },
            ["spring-salvage"] = { name = "Весенний подъём со дна", note = "Больше всех бутылок, ящиков и сундуков, выловленных за неделю, откуда угодно." },
            ["apothecarys-order"] = { name = "Заказ аптекаря", note = "Пятнадцать штук Sickly Looking Fish из Тирисфальских лесов, Серебряного бора или каналов Подгорода." },
            ["man-vs-machine"] = { name = "Человек против машины", note = "Больше всех рыбы из Дун Морога или Степей за неделю." },
            ["hillsbrad-truce"] = { name = "Хилсбрадское перемирие", note = "Десять штук Raw Bristle Whisker Catfish из Предгорий Хилсбрада. Побеждает самый быстрый." },
            ["longest-day"] = { name = "Самый длинный день", note = "Одна рыба с 5 до 9 утра и одна с 18 до 22 вечера по серверному времени, в любой день выходных солнцестояния.", needs = { "Рыба на рассвете, с 5 до 9 утра", "Рыба на закате, с 18 до 22" } },
            ["summer-bass-month"] = { name = "Месяц Summer Bass", note = "Все Raw Summer Bass, пойманные кем угодно в июне, идут в общий счёт." },
            ["blump-family-reunion"] = { name = "Сбор семьи Blump", note = "Ваши лучшие полчаса рыбалки на Темных берегах за неделю." },
            ["shedding-season"] = { name = "Сезон линьки", note = "Пятнадцать штук Rockscale Cod из Пустошей. Побеждает самый быстрый." },
            ["feralas-week"] = { name = "Кулинарная битва Фераласа", note = "Альянс против Орды: каждая рыба из Фераласа засчитывается вашей стороне." },
            ["extreme-clammin"] = { name = "Моллюсковый экстрим", note = "Больше всех Big-mouth Clam из Азшары за выходные." },
            ["dwarven-economics"] = { name = "Дворфийская экономика", note = "Тысяча штук Stonescale Eel из Танариса на всех, за выходные." },
            ["something-in-the-water"] = { name = "Что-то в воде", note = "Десять рыб из Valorwind Lake, где растёт Violet Tragan, и десять из любого другого места Внутренних земель для сравнения.", needs = { "Valorwind Lake", "Остальные Внутренние земли" } },
            ["four-corners"] = { name = "Четыре угла", note = "По рыбе из каждого угла Калимдора и из каждого угла Восточных королевств, и все разных видов. Два забега, два значка: пройдите один или оба.", parts = { "Калимдор", "Восточные королевства" } },
            ["hallows-feud"] = { name = "Вражда Баровых", note = "Альянс против Орды за Darrowmere Lake: рыба Альянса идёт в зачёт Велдону Барову, рыба Орды — Алексею. Сторона, поймавшая в озере больше рыбы, владеет им год." },
        },
        zhCN = {
            ["first-cast-tour"] = { name = "初钓之旅", note = "周末期间，在新手区域钓一条，在主城钓一条，顺序不限。", years = { [2026] = "Forever的第一个月：在新手区域钓一条，在主城钓一条，顺序不限，从开服到12月3日任意一天都行。" }, needs = { "一个新手区域", "一座主城" } },
            ["tongas-survey"] = { name = "通加的调查", note = "通加·符文图腾想知道新绿洲底下冒出来的是什么。Hal想知道鱼吃起来味道怪不怪。三处水域各钓一条，两件事一并解决。", needs = { "遗忘之池", "甜水绿洲", "死水绿洲" } },
            ["loch-frenzy-race"] = { name = "洛克湖狂鱼竞速", note = "二十条生洛克湖狂鱼。它们只生活在洛克莫丹。" },
            ["winter-veil-feast"] = { name = "冬幕节盛宴", note = "小鱼、泥鳅和鲭鱼各十条，在哪里钓都行。", needs = { "Raw Brilliant Smallfish", "生长嘴泥鳅", "生滑皮鲭鱼" } },
            ["riverglades-race"] = { name = "Riverglades竞速", note = "在Riverglades至少四个钓点钓到任意十条鱼。最快者获胜。" },
            ["squid-run"] = { name = "鱿鱼季", note = "一月里所有人钓到的生冬鱿鱼都计入同一个总数。" },
            ["trainers-cup-winter"] = { name = "冬季训练师杯", note = "在主城钓到的每条鱼都计入那座城市。拥有最强钓手的城市获胜。" },
            ["trainers-cup-spring"] = { name = "春季训练师杯", note = "在主城钓到的每条鱼都计入那座城市。拥有最强钓手的城市获胜。" },
            ["trainers-cup-summer"] = { name = "夏季训练师杯", note = "在主城钓到的每条鱼都计入那座城市。拥有最强钓手的城市获胜。" },
            ["trainers-cup-fall"] = { name = "秋季训练师杯", note = "在主城钓到的每条鱼都计入那座城市。拥有最强钓手的城市获胜。" },
            ["swallowed-ring"] = { name = "被吞的戒指", note = "本周末，不管谁在哪里钓到的肚子鼓鼓的鱼，都堆成一堆，由Hal一条条剖开。" },
            ["westfall-coast"] = { name = "西部荒野海岸", note = "你在西部荒野海岸最好的三十分钟。" },
            ["da-big-catch"] = { name = "大大滴丰收", note = "一个星期六之内，在杜隆塔尔钓鱼最多者获胜。" },
            ["spring-salvage"] = { name = "春季打捞", note = "一周之内，在任何地方钓上瓶子、板条箱和箱子最多者获胜。" },
            ["apothecarys-order"] = { name = "药剂师的订单", note = "从提瑞斯法林地、银松森林或幽暗城水道钓十五条Sickly Looking Fish。" },
            ["man-vs-machine"] = { name = "人机大战", note = "一周之内，在丹莫罗或贫瘠之地钓鱼最多者获胜。" },
            ["hillsbrad-truce"] = { name = "希尔斯布莱德停战", note = "在希尔斯布莱德丘陵钓十条生刺须鲶鱼。最快者获胜。" },
            ["longest-day"] = { name = "最长的一天", note = "夏至周末的任意一天，按服务器时间，早上5点到9点之间钓一条，晚上6点到10点之间钓一条。", needs = { "黎明一条，早上5到9点", "黄昏一条，晚上6到10点" } },
            ["summer-bass-month"] = { name = "夏日鲈鱼月", note = "六月里所有人钓到的生夏日鲈鱼都计入同一个总数。" },
            ["blump-family-reunion"] = { name = "Blump家族聚会", note = "这一周里你在黑海岸钓鱼最好的三十分钟。" },
            ["shedding-season"] = { name = "蜕壳季", note = "在凄凉之地钓十五条石鳞鳕鱼。最快者获胜。" },
            ["feralas-week"] = { name = "菲拉斯厨艺对决", note = "联盟对部落：在菲拉斯钓到的每条鱼都算你这一方的。" },
            ["extreme-clammin"] = { name = "极限捞蚌", note = "周末期间，在艾萨拉钓到大嘴蚌最多者获胜。" },
            ["dwarven-economics"] = { name = "矮人经济学", note = "周末期间，大家一起在塔纳利斯钓上一千条石鳞鳗。" },
            ["something-in-the-water"] = { name = "水里有东西", note = "在长着Violet Tragan的瓦罗温湖钓十条，再在辛特兰其他地方钓十条用来对比。", needs = { "瓦罗温湖", "辛特兰其他地方" } },
            ["four-corners"] = { name = "四角之旅", note = "在卡利姆多的四个角落各钓一条，在东部王国的四个角落各钓一条，每条都得是不同的鱼。两条路线，两枚徽章：做一条，或者两条都做。", parts = { "卡利姆多", "东部王国" } },
            ["hallows-feud"] = { name = "万圣节宿怨", note = "联盟与部落争夺达隆米尔湖：联盟的鱼算维尔顿·巴罗夫的，部落的鱼算阿莱克斯的。从湖里钓鱼更多的一方占据这片湖一年。" },
        },
        zhTW = {
            ["first-cast-tour"] = { name = "初釣之旅", note = "週末期間，在新手區域釣一條，在主城釣一條，順序不限。", years = { [2026] = "Forever的第一個月：在新手區域釣一條，在主城釣一條，順序不限，從開服到12月3日任何一天都行。" }, needs = { "一個新手區域", "一座主城" } },
            ["tongas-survey"] = { name = "通加的調查", note = "通加·符文圖騰想知道新綠洲底下冒出來的是什麼。Hal想知道魚吃起來味道怪不怪。三處水域各釣一條，兩件事一併解決。", needs = { "遺忘之池", "甜水綠洲", "死水綠洲" } },
            ["loch-frenzy-race"] = { name = "洛克莫丹競速", note = "二十條Raw Loch Frenzy。牠們只生活在洛克莫丹。" },
            ["winter-veil-feast"] = { name = "冬幕節盛宴", note = "小魚、泥鰍和鯖魚各十條，在哪裡釣都行。", needs = { "Raw Brilliant Smallfish", "Raw Longjaw Mud Snapper", "Raw Slitherskin Mackerel" } },
            ["riverglades-race"] = { name = "Riverglades競速", note = "在Riverglades至少四個釣點釣到任意十條魚。最快者獲勝。" },
            ["squid-run"] = { name = "魷魚季", note = "一月裡所有人釣到的冬季魷魚都計入同一個總數。" },
            ["trainers-cup-winter"] = { name = "冬季訓練師盃", note = "在主城釣到的每條魚都計入那座城市。擁有最強釣手的城市獲勝。" },
            ["trainers-cup-spring"] = { name = "春季訓練師盃", note = "在主城釣到的每條魚都計入那座城市。擁有最強釣手的城市獲勝。" },
            ["trainers-cup-summer"] = { name = "夏季訓練師盃", note = "在主城釣到的每條魚都計入那座城市。擁有最強釣手的城市獲勝。" },
            ["trainers-cup-fall"] = { name = "秋季訓練師盃", note = "在主城釣到的每條魚都計入那座城市。擁有最強釣手的城市獲勝。" },
            ["swallowed-ring"] = { name = "被吞的戒指", note = "本週末，不管誰在哪裡釣到的肚子鼓鼓的魚，都堆成一堆，由Hal一條條剖開。" },
            ["westfall-coast"] = { name = "西部荒野海岸", note = "你在西部荒野海岸最好的三十分鐘。" },
            ["da-big-catch"] = { name = "大大滴豐收", note = "一個星期六之內，在杜洛塔釣魚最多者獲勝。" },
            ["spring-salvage"] = { name = "春季打撈", note = "一週之內，在任何地方釣上瓶子、板條箱和箱子最多者獲勝。" },
            ["apothecarys-order"] = { name = "藥劑師的訂單", note = "從提里斯法林地、銀松森林或幽暗城水道釣十五條Sickly Looking Fish。" },
            ["man-vs-machine"] = { name = "人機大戰", note = "一週之內，在丹莫洛或貧瘠之地釣魚最多者獲勝。" },
            ["hillsbrad-truce"] = { name = "希爾斯布萊德停戰", note = "在希爾斯布萊德丘陵釣十條Raw Bristle Whisker Catfish。最快者獲勝。" },
            ["longest-day"] = { name = "最長的一天", note = "夏至週末的任何一天，依伺服器時間，早上5點到9點之間釣一條，晚上6點到10點之間釣一條。", needs = { "黎明一條，早上5到9點", "黃昏一條，晚上6到10點" } },
            ["summer-bass-month"] = { name = "夏日鱸魚月", note = "六月裡所有人釣到的夏日鱸魚都計入同一個總數。" },
            ["blump-family-reunion"] = { name = "Blump家族聚會", note = "這一週裡你在黑海岸釣魚最好的三十分鐘。" },
            ["shedding-season"] = { name = "蛻殼季", note = "在淒涼之地釣十五條Rockscale Cod。最快者獲勝。" },
            ["feralas-week"] = { name = "菲拉斯廚藝對決", note = "聯盟對部落：在菲拉斯釣到的每條魚都算你這一方的。" },
            ["extreme-clammin"] = { name = "極限撈蚌", note = "週末期間，在艾薩拉釣到Big-mouth Clam最多者獲勝。" },
            ["dwarven-economics"] = { name = "矮人經濟學", note = "週末期間，大家一起在塔納利斯釣上一千條Stonescale Eel。" },
            ["something-in-the-water"] = { name = "水裡有東西", note = "在長著Violet Tragan的瓦羅溫湖釣十條，再在辛特蘭其他地方釣十條用來對比。", needs = { "瓦羅溫湖", "辛特蘭其他地方" } },
            ["four-corners"] = { name = "四角之旅", note = "在卡林多的四個角落各釣一條，在東部王國的四個角落各釣一條，每條都得是不同的魚。兩條路線，兩枚徽章：做一條，或者兩條都做。", parts = { "卡林多", "東部王國" } },
            ["hallows-feud"] = { name = "巴羅夫家的宿怨", note = "聯盟與部落爭奪達隆米爾湖：聯盟的魚算Weldon Barov的，部落的魚算Alexi的。從湖裡釣魚更多的一方佔據這片湖一年。" },
        },
    },
}
