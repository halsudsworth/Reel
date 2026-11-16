-- Hal's calendar data: his annual events and what the daily and weekly challenges pick from.
-- Written by tools/gen_calendar.py from site/data/hal_events.json, site/server/lib/data.json
-- and calendar.php's launch tables. Don't edit by hand; run the script again.
--
-- Zones are map IDs (C_Map). maps holds their English names only to build challenge names
-- the way halsudsworth.com writes them. Subzones (sub, notSub) are the site's English names:
-- the site data has no IDs for them.

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
        { id = "tongas-survey", name = "Tonga's survey", art = "tongas-survey", scoring = "quest", rule = { kind = "weekend", month = 11, n = 4 }, note = "Tonga Runetotem wants to know what's bubbling up under the new oases. Hal wants to know if the fish taste funny. One fish from each of the three waters settles both.", needs = { { label = "The Forgotten Pools", zone = { 1413 }, sub = { "The Forgotten Pools" }, n = 1 }, { label = "Lushwater Oasis", zone = { 1413 }, sub = { "Lushwater Oasis" }, n = 1 }, { label = "The Stagnant Oasis", zone = { 1413 }, sub = { "The Stagnant Oasis" }, n = 1 } } },
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
        { id = "something-in-the-water", name = "Something in the water", art = "something-in-the-water", scoring = "quest", rule = { kind = "week", month = 9, n = 4 }, note = "Ten fish from Valorwind Lake, where the Violet Tragan grows, and ten from anywhere else in the Hinterlands to compare them with.", needs = { { label = "Valorwind Lake", zone = { 1425 }, sub = { "Valorwind Lake" }, n = 10 }, { label = "The rest of the Hinterlands", zone = { 1425 }, notSub = { "Valorwind Lake" }, n = 10 } } },
        { id = "four-corners", name = "Four corners", art = "four-corners", scoring = "variety", rule = { kind = "weekend", month = 10, n = 2 }, note = "A fish from each corner of Kalimdor and a fish from each corner of the Eastern Kingdoms, every one a different kind. Two runs, two badges: do one or both.", parts = { { label = "Kalimdor", zone = { 1439, 1452, 1446, 1444 } }, { label = "Eastern Kingdoms", zone = { 1421, 1423, 1434, 1435 } } } },
        { id = "hallows-feud", name = "Hallow's feud", art = "hallows-feud", scoring = "faction", rule = { kind = "weekend", month = 10, n = -1 }, note = "Alliance against Horde for Darrowmere Lake: Alliance fish count for Weldon Barov, Horde fish for Alexi. The side with more fish from the lake holds it for a year.", zone = { 1422 }, sub = { "Darrowmere Lake", "Caer Darrow" } },
    },
}
