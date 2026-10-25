-- Fishing NPCs for the map pins (not drawn yet; see ROADMAP). Coordinates
-- are Wowhead Forever's first pin for each NPC (rounded to 0.2), read on
-- 2026-10-24. "full set" vendors sell both poles and all four lures.
-- Faction: "A", "H" or "both". "teaches" is from Wowhead Forever's trainer pages (2026-10-25):
-- every fishing trainer teaches Apprentice, Journeyman and the Fish Bowl, nothing else.

local _, ns = ...

ns.FISHING_NPCS = {
    -- Trainers
    { id = 1651,   name = "Lee Brown",            zone = "Elwynn Forest",        x = 47.4, y = 62.2, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 5493,   name = "Arnold Leland",        zone = "Stormwind City",       x = 45.4, y = 57.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 1700,   name = "Paxton Ganter",        zone = "Dun Morogh",           x = 35.4, y = 40.2, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 5161,   name = "Grimnur Stonebrand",   zone = "Ironforge",            x = 48.2, y = 6.6,  role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 1683,   name = "Warg Deepwater",       zone = "Loch Modan",           x = 40.4, y = 39.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 3179,   name = "Harold Riggs",         zone = "Wetlands",             x = 8.0,  y = 58.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 1680,   name = "Matthew Hooper",       zone = "Redridge Mountains",   x = 21.2, y = 50.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 7946,   name = "Brannock",             zone = "Feralas",              x = 32.2, y = 41.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 3607,   name = "Androl Oakhand",       zone = "Teldrassil",           x = 55.8, y = 93.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 4156,   name = "Astaia",               zone = "Darnassus",            x = 47.4, y = 56.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 2367,   name = "Donald Rabonne",       zone = "Hillsbrad Foothills",  x = 50.4, y = 61.0, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A" },
    { id = 255877, name = "Hunter Moore",         zone = "Hillsbrad Foothills",  x = 54.0, y = 80.2, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "A", forever = true },
    { id = 5941,   name = "Lau'Tiki",             zone = "Durotar",              x = 53.2, y = 81.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 3332,   name = "Lumak",                zone = "Orgrimmar",            x = 69.4, y = 28.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 5938,   name = "Uthan Stillwater",     zone = "Mulgore",              x = 44.2, y = 63.8, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 3028,   name = "Kah Mistrunner",       zone = "Thunder Bluff",        x = 55.8, y = 47.6, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 12032,  name = "Lui'Mala",             zone = "Desolace",             x = 22.6, y = 72.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 12961,  name = "Kil'Hiwana",           zone = "Ashenvale",            x = 10.8, y = 33.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 14740,  name = "Katoom the Angler",    zone = "The Hinterlands",      x = 80.2, y = 81.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H", sells = "full set" },
    { id = 5690,   name = "Clyde Kellen",         zone = "Tirisfal Glades",      x = 67.2, y = 51.0, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 4573,   name = "Armand Cromwell",      zone = "Undercity",            x = 80.4, y = 31.2, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "H" },
    { id = 2834,   name = "Myizz Luckycatch",     zone = "Stranglethorn Vale",   x = 27.4, y = 77.0, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "both" },
    { id = 260558, name = "Krix",                 zone = "Riverglades",          x = 79.2, y = 54.8, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "both", forever = true },
    { id = 257008, name = "Baelann Swiftcurrent", zone = "Zephras Isle",         x = 63.2, y = 75.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "both", forever = true, sells = "full set" },
    { id = 251992, name = "Fenn Fairweather",     zone = "Zephras Isle",         x = 45.0, y = 48.4, role = "trainer", teaches = "Apprentice, Journeyman, Fish Bowl", faction = "both", forever = true, sells = "pole" },

    -- Vendors (poles and lures)
    { id = 2626,   name = "Old Man Heming",       zone = "Stranglethorn Vale",   x = 27.4, y = 77.0, role = "vendor", faction = "both", sells = "full set, Expert Fishing book" },
    { id = 5494,   name = "Catherine Leland",     zone = "Stormwind City",       x = 45.4, y = 57.6, role = "vendor", faction = "A", sells = "full set" },
    { id = 5162,   name = "Tansy Puddlefizz",     zone = "Ironforge",            x = 47.8, y = 6.4,  role = "vendor", faction = "A", sells = "full set" },
    { id = 4222,   name = "Voloren",              zone = "Darnassus",            x = 46.4, y = 56.0, role = "vendor", faction = "A", sells = "full set" },
    { id = 66,     name = "Tharynn Bouden",       zone = "Elwynn Forest",        x = 41.8, y = 67.0, role = "vendor", faction = "A", sells = "pole, Shiny Bauble" },
    { id = 8508,   name = "Gretta Ganter",        zone = "Dun Morogh",           x = 31.4, y = 44.6, role = "vendor", faction = "A", sells = "full set" },
    { id = 10118,  name = "Nessa Shadowsong",     zone = "Teldrassil",           x = 56.2, y = 92.4, role = "vendor", faction = "A", sells = "full set" },
    { id = 1684,   name = "Khara Deepwater",      zone = "Loch Modan",           x = 39.4, y = 39.2, role = "vendor", faction = "A", sells = "full set" },
    { id = 3178,   name = "Stuart Fleming",       zone = "Wetlands",             x = 8.0,  y = 58.2, role = "vendor", faction = "A", sells = "full set" },
    { id = 1678,   name = "Vernon Hale",          zone = "Redridge Mountains",   x = 22.2, y = 47.6, role = "vendor", faction = "A", sells = "full set" },
    { id = 2383,   name = "Lindea Rabonne",       zone = "Hillsbrad Foothills",  x = 50.0, y = 62.6, role = "vendor", faction = "A", sells = "full set" },
    { id = 2381,   name = "Micha Yance",          zone = "Hillsbrad Foothills",  x = 49.0, y = 55.0, role = "vendor", faction = "A", sells = "Nightcrawlers, Bright Baubles" },
    { id = 7947,   name = "Vivianna",             zone = "Feralas",              x = 31.2, y = 43.4, role = "vendor", faction = "A", sells = "pole, Nightcrawlers, Bright Baubles" },
    { id = 3333,   name = "Shankys",              zone = "Orgrimmar",            x = 69.4, y = 29.0, role = "vendor", faction = "H", sells = "full set" },
    { id = 4574,   name = "Lizbeth Cromwell",     zone = "Undercity",            x = 81.0, y = 29.2, role = "vendor", faction = "H", sells = "full set" },
    { id = 3029,   name = "Sewa Mistrunner",      zone = "Thunder Bluff",        x = 55.2, y = 48.0, role = "vendor", faction = "H", sells = "full set" },
    { id = 5942,   name = "Zansoa",               zone = "Durotar",              x = 56.0, y = 73.4, role = "vendor", faction = "H", sells = "full set" },
    { id = 5940,   name = "Harn Longcast",        zone = "Mulgore",              x = 46.6, y = 59.2, role = "vendor", faction = "H", sells = "full set" },
    { id = 3081,   name = "Wunna Darkmane",       zone = "Mulgore",              x = 45.4, y = 61.8, role = "vendor", faction = "H", sells = "pole, Shiny Bauble" },
    { id = 3550,   name = "Martine Tramblay",     zone = "Tirisfal Glades",      x = 65.8, y = 59.4, role = "vendor", faction = "H", sells = "full set" },
    { id = 12962,  name = "Wik'Tar",              zone = "Ashenvale",            x = 11.8, y = 34.0, role = "vendor", faction = "H", sells = "full set" },
    { id = 3497,   name = "Kilxx",                zone = "The Barrens",          x = 62.8, y = 38.2, role = "vendor", faction = "both", sells = "full set" },
    { id = 260487, name = "Gritta Chumwater",     zone = "Riverglades",          x = 78.4, y = 55.0, role = "vendor", faction = "both", forever = true, sells = "full set, Fresh Chum" },
    { id = 254360, name = "Belandiel Farflight",  zone = "Zephras Isle",         x = 44.8, y = 45.0, role = "vendor", faction = "both", forever = true, sells = "pole, Shiny Bauble, Nightcrawlers" },

    -- Quest and event
    { id = 12919,  name = "Nat Pagle",            zone = "Dustwallow Marsh",     x = 58.4, y = 60.0, role = "quest",  faction = "both", note = "Artisan Fishing" },
    { id = 15077,  name = "Riggle Bassbait",      zone = "Stranglethorn Vale",   x = 27.4, y = 76.8, role = "event",  faction = "both", note = "Extravaganza turn-in" },
    { id = 15078,  name = "Jang",                 zone = "Stranglethorn Vale",   x = 27.4, y = 76.8, role = "event",  faction = "both", note = "Extravaganza prizes" },
    { id = 15079,  name = "Fishbot 5000",         zone = "Stranglethorn Vale",   x = 27.4, y = 76.8, role = "event",  faction = "both", note = "Extravaganza" },
}
