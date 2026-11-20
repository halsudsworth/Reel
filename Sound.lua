-- Sound page: splash booster and grouped muting (site/art/ui/mockup/sound-groups.png).
-- While fishing, sound effects (and optionally master volume) go up, and the groups the player
-- picked go quiet: each group is a set of sound files (SoundData.lua) muted with MuteSoundFile,
-- plus the game's own setting for it where there is one (music volume, ambience volume, voices...).
-- The fishing sounds are in no group, so the splash always comes through.

local _, ns = ...
local L = ns.L
local W = ns.W

-- The groups, in the page's order. cvars: settings turned to 0 with the group, on top of its files.
local GROUPS = {
    { key = "music", label = L["Music"], what = L["Zone and city music"], cvars = { "Sound_MusicVolume" } },
    { key = "footsteps", label = L["Footsteps"], what = L["Yours, other players', mounts', and wading through water"] },
    { key = "players", label = L["Other players"], what = L["Spells, hearthstones and portals, level-ups, mounting up, toys and fireworks"] },
    { key = "voices", label = L["Voices"], what = L["NPC and character voices, emotes, \"I can't do that yet\""],
      cvars = { "Sound_EnableDialog", "Sound_EnableEmoteSounds", "Sound_EnableErrorSpeech" } },
    { key = "creatures", label = L["Creatures"], what = L["Murlocs, gulls, frogs, pets, anything that growls nearby"],
      cvars = { "Sound_EnablePetSounds" } },
    { key = "place", label = L["The place"], what = L["Bells, ship horns, creaking docks, wind, rain and waterfalls"],
      cvars = { "Sound_AmbienceVolume" } },
    { key = "interface", label = L["Interface"], what = L["Coins, bags, loot, clicks, armor rustle"],
      cvars = { "Sound_EnableArmorFoleySoundForOthers", "Sound_EnableArmorFoleySoundForSelf" } },
}

-- The levels across the top: each sets the groups below. Changing a group makes it Custom.
local LEVELS = {
    { key = "everything", label = L["Everything"], what = L["R.E.E.L. leaves your sound alone"], groups = {} },
    { key = "world", label = L["The world"], what = L["Music and voices off, the place and its creatures on"],
      groups = { music = true, footsteps = true, players = true, voices = true, interface = true } },
    { key = "bobber", label = L["Bobber only"], what = L["Every group muted; the splash and your alerts"],
      groups = { music = true, footsteps = true, players = true, voices = true, creatures = true, place = true, interface = true } },
    { key = "custom", label = L["Custom"], what = L["Your own picks below"] },
}

ns.RegisterDefaults({
    boost = true,      -- splash booster on/off
    bgSound = false,   -- keep sound playing when the game is in the background
    setMaster = false, -- also force master volume while fishing
    master = 70,       -- percent
    sfx = 100,         -- percent
    soundLevel = "world",
    letAlerts = true,  -- whispers, invites and the like come through on any level
    quietReverb = false,
})
for _, g in ipairs(GROUPS) do
    ns.RegisterDefaults({ ["mute_" .. g.key] = LEVELS[2].groups[g.key] or false })
end

local function Volume(percent)
    return string.format("%.2f", percent / 100)
end

-- Is this group (or "alerts") muted while fishing, by the player's settings?
local function Wants(s, key)
    if key == "alerts" then return not s.letAlerts and s.soundLevel ~= "everything" end
    return s.soundLevel ~= "everything" and s["mute_" .. key] and true or false
end

ns.RegisterCVars(function(s, targets)
    -- Sound while tabbed out stands on its own.
    if s.bgSound then
        targets.Sound_EnableSoundWhenGameIsInBG = "1"
    end
    for _, g in ipairs(GROUPS) do
        if g.cvars and Wants(s, g.key) then
            for _, cvar in ipairs(g.cvars) do targets[cvar] = "0" end
        end
    end
    if s.quietReverb then targets.Sound_EnableReverb = "0" end
    if not s.boost then return end
    targets.Sound_EnableSFX = "1"
    targets.Sound_SFXVolume = Volume(s.sfx)
    if s.setMaster then
        targets.Sound_EnableAllSound = "1"
        targets.Sound_MasterVolume = Volume(s.master)
    end
end)

-- File mutes ------------------------------------------------------------------------------------
-- Groups muted right now, kept in ReelDB.soundMuted too: if the game is closed mid-session or
-- crashes, the next load unmutes them, whether or not the game kept the mutes.

local muted = {}

local function Each(key, fn)
    local list = ns.SOUND_FILES and ns.SOUND_FILES[key]
    if not (list and fn) then return end
    local id = 0
    for gap in list:gmatch("[^,]+") do
        id = id + tonumber(gap, 36)
        fn(id)
    end
end

local function SetMuted(key, on)
    if (muted[key] or false) == on then return end
    Each(key, on and MuteSoundFile or UnmuteSoundFile)
    muted[key] = on or nil
    local copy = {}
    for k in pairs(muted) do copy[k] = true end
    ReelDB.soundMuted = next(copy) and copy or nil
end

-- Mutes what the settings want while fishing, unmutes the rest.
local function Sync()
    local s, fishing = ReelDB.settings, ns.IsFishing()
    SetMuted("alerts", fishing and Wants(s, "alerts"))
    for _, g in ipairs(GROUPS) do
        SetMuted(g.key, fishing and Wants(s, g.key))
    end
end

ns.On("REEL_READY", function()
    for key in pairs(ReelDB.soundMuted or {}) do
        Each(key, UnmuteSoundFile)
    end
    ReelDB.soundMuted = nil
    -- settings from before grouped muting (1.7.0)
    for _, old in ipairs({ "quietDialog", "quietEmotes", "quietPets", "quietErrors", "quietArmorOthers", "quietArmorSelf" }) do
        ReelDB.settings[old] = nil
    end
end)
ns.On("REEL_FISHING_BEGIN", Sync)
ns.On("REEL_FISHING_END", Sync)

-- Page ------------------------------------------------------------------------------------------

-- A level's box: its name, and a line on what it does under it.
local function LevelBox(parent, level, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 52)
    local bg = W.Solid(b, "BACKGROUND", W.C.rule, 0.03)
    bg:SetAllPoints()
    local edge = W.Outline(b, "BORDER", "4a3c28", 1, 0)
    local name = W.Label(b, level.label, "GameFontHighlight")
    name:SetPoint("TOPLEFT", 8, -7)
    name:SetWidth(width - 14)
    local what = W.Label(b, level.what, "GameFontDisableSmall")
    what:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    what:SetWidth(width - 14)
    what:SetWordWrap(true)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(W.Hex(W.C.amber, 0.06))
    b:SetScript("OnClick", onClick)
    function b.SetOn(_, on)
        for _, t in ipairs(edge) do t:SetColorTexture(W.Hex(on and "ffd100" or "4a3c28")) end
        bg:SetColorTexture(W.Hex(on and "ffd100" or W.C.rule, on and 0.08 or 0.03))
        name:SetTextColor(W.Hex(on and "ffd100" or W.C.ink))
    end
    function b.Fit() b:SetHeight(math.max(52, 7 + name:GetStringHeight() + 3 + what:GetStringHeight() + 8)) end
    return b
end

ns.RegisterPage({
    name = "Sound",
    order = 20,
    build = function(panel)
        local s = ReelDB.settings
        local boost, bgSound, setMaster, master, sfx, alerts, reverb
        local levelBoxes, groupBoxes = {}, {}

        local function Refresh()
            for _, c in ipairs({ boost, bgSound, setMaster, master, sfx, alerts, reverb }) do c.Refresh() end
            setMaster:SetActive(s.boost)
            master:SetActive(s.boost and s.setMaster)
            sfx:SetActive(s.boost)
            for _, b in ipairs(levelBoxes) do b:SetOn(b.key == s.soundLevel) end
            for _, cb in ipairs(groupBoxes) do cb.Refresh() end
        end

        local function Changed()
            ns.ApplySettings()
            Sync()
            Refresh()
        end

        boost = W.Checkbox(panel, L["Splash booster"],
            function() return s.boost end,
            function(v) s.boost = v; Changed() end)
        boost:SetPoint("TOPLEFT")

        local note = W.Note(panel, L["While fishing: sound effects up."], ns.CONTENT_WIDTH - 30)
        note:SetPoint("TOPLEFT", boost, "BOTTOMLEFT", 26, 0)

        bgSound = W.Checkbox(panel, L["Play sound when tabbed out"],
            function() return s.bgSound end,
            function(v) s.bgSound = v; Changed() end)
        bgSound:SetPoint("TOPLEFT", boost, "BOTTOMLEFT", 0, -24)

        setMaster = W.Checkbox(panel, L["Set master volume"],
            function() return s.setMaster end,
            function(v) s.setMaster = v; Changed() end)
        setMaster:SetPoint("TOPLEFT", bgSound, "BOTTOMLEFT", 0, -4)

        master = W.Slider(panel, L["Master"], 0, 100, 5, "%",
            function() return s.master end,
            function(v) s.master = v; Changed() end)

        sfx = W.Slider(panel, L["Effects"], 0, 100, 5, "%",
            function() return s.sfx end,
            function(v) s.sfx = v; Changed() end)
        sfx:SetPoint("TOPLEFT", master, "BOTTOMLEFT", 0, -22)
        master:SetPoint("TOPLEFT", setMaster, "BOTTOMLEFT", W.Room(80, master, sfx), -14)

        -- While fishing, hear: the four levels side by side.
        local hear = W.Label(panel, L["While fishing, hear"], "GameFontNormal")
        hear:SetPoint("TOPLEFT", setMaster, "BOTTOMLEFT", 0, -82)
        local gap = 6
        local boxW = math.floor((ns.CONTENT_WIDTH - gap * (#LEVELS - 1)) / #LEVELS)
        local tallest = 52
        for i, level in ipairs(LEVELS) do
            local b = LevelBox(panel, level, boxW, function()
                s.soundLevel = level.key
                if level.groups then
                    for _, g in ipairs(GROUPS) do s["mute_" .. g.key] = level.groups[g.key] or false end
                end
                Changed()
            end)
            b.key = level.key
            b:SetPoint("TOPLEFT", hear, "BOTTOMLEFT", (i - 1) * (boxW + gap), -6)
            b.Fit()
            tallest = math.max(tallest, b:GetHeight())
            levelBoxes[i] = b
        end
        for _, b in ipairs(levelBoxes) do b:SetHeight(tallest) end

        -- Muted while fishing: a row per group, its checkbox, name and what's in it.
        local mutedHead = W.Label(panel, L["Muted while fishing"], "GameFontNormal")
        mutedHead:SetPoint("TOPLEFT", levelBoxes[1], "BOTTOMLEFT", 0, -14)
        local anchor, nameW = mutedHead, 0
        local rows = {}
        for i, g in ipairs(GROUPS) do
            local cb = W.Checkbox(panel, g.label,
                function() return s["mute_" .. g.key] end,
                function(v) s["mute_" .. g.key] = v; s.soundLevel = "custom"; Changed() end)
            cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -4 or -2)
            nameW = math.max(nameW, cb.label:GetStringWidth())
            anchor = cb
            groupBoxes[i] = cb
            rows[i] = cb
        end
        for i, g in ipairs(GROUPS) do
            local what = W.Note(panel, g.what, ns.CONTENT_WIDTH - nameW - 40)
            what:SetPoint("LEFT", rows[i], "RIGHT", nameW + 12, 0)
        end

        reverb = W.Checkbox(panel, L["Reverb"],
            function() return s.quietReverb end,
            function(v) s.quietReverb = v; Changed() end)
        reverb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

        alerts = W.Checkbox(panel, L["Let alerts through on any level"],
            function() return s.letAlerts end,
            function(v) s.letAlerts = v; Changed() end)
        alerts:SetPoint("TOPLEFT", reverb, "BOTTOMLEFT", 0, -12)
        local alertsWhat = W.Note(panel, L["Whispers, guild and party invites, ready checks, raid warnings"], ns.CONTENT_WIDTH - 30)
        alertsWhat:SetPoint("TOPLEFT", alerts, "BOTTOMLEFT", 26, 0)

        local splash = W.Note(panel, L["Other anglers' splashes are the same sound as yours, so they stay."], ns.CONTENT_WIDTH - 4)
        splash:SetPoint("TOPLEFT", alerts, "BOTTOMLEFT", 0, -20)

        return Refresh
    end,
})
