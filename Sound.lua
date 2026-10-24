-- Sound page: splash booster. While fishing, music and ambience go off,
-- sound effects (and optionally master volume) go up, and chosen noises
-- (voices, emotes, pets...) are muted so the splash stands out.

local _, ns = ...
local W = ns.W

ns.RegisterDefaults({
    boost = true,      -- splash booster on/off
    bgSound = false,   -- keep sound playing when the game is in the background
    setMaster = false, -- also force master volume while fishing
    master = 70,       -- percent
    sfx = 100,         -- percent
})

-- "Quiet while fishing": setting key, label, CVar turned off, default.
-- All of these CVars were confirmed on the client with /reel debug.
local QUIET = {
    { key = "quietDialog", label = "NPC and character voices", cvar = "Sound_EnableDialog", default = true },
    { key = "quietEmotes", label = "Emote sounds", cvar = "Sound_EnableEmoteSounds", default = true },
    { key = "quietPets", label = "Pet sounds", cvar = "Sound_EnablePetSounds", default = true },
    { key = "quietErrors", label = "Error speech (\"I can't do that yet\")", cvar = "Sound_EnableErrorSpeech", default = true },
    { key = "quietArmorOthers", label = "Other players' armor rustle", cvar = "Sound_EnableArmorFoleySoundForOthers", default = true },
    { key = "quietArmorSelf", label = "My own armor rustle", cvar = "Sound_EnableArmorFoleySoundForSelf", default = false },
    { key = "quietReverb", label = "Reverb", cvar = "Sound_EnableReverb", default = false },
}

for _, q in ipairs(QUIET) do
    ns.RegisterDefaults({ [q.key] = q.default })
end

local function Volume(percent)
    return string.format("%.2f", percent / 100)
end

ns.RegisterCVars(function(s, targets)
    if not s.boost then return end
    targets.Sound_EnableSFX = "1"
    targets.Sound_SFXVolume = Volume(s.sfx)
    targets.Sound_MusicVolume = "0"
    targets.Sound_AmbienceVolume = "0"
    if s.bgSound then
        targets.Sound_EnableSoundWhenGameIsInBG = "1"
    end
    if s.setMaster then
        targets.Sound_EnableAllSound = "1"
        targets.Sound_MasterVolume = Volume(s.master)
    end
    for _, q in ipairs(QUIET) do
        if s[q.key] then targets[q.cvar] = "0" end
    end
end)

ns.RegisterPage({
    name = "Sound",
    order = 20,
    build = function(panel)
        local s = ReelDB.settings
        local boost, bgSound, setMaster, master, sfx

        local quiet = {}

        local function Refresh()
            for _, c in ipairs({ boost, bgSound, setMaster, master, sfx }) do c.Refresh() end
            bgSound:SetActive(s.boost)
            setMaster:SetActive(s.boost)
            master:SetActive(s.boost and s.setMaster)
            sfx:SetActive(s.boost)
            for _, cb in ipairs(quiet) do
                cb.Refresh()
                cb:SetActive(s.boost)
            end
        end

        local function Changed()
            ns.ApplySettings()
            Refresh()
        end

        boost = W.Checkbox(panel, "Splash booster",
            function() return s.boost end,
            function(v) s.boost = v; Changed() end)
        boost:SetPoint("TOPLEFT")

        local note = W.Note(panel, "While fishing: music and ambience off, sound effects up.", ns.CONTENT_WIDTH - 30)
        note:SetPoint("TOPLEFT", boost, "BOTTOMLEFT", 26, 0)

        bgSound = W.Checkbox(panel, "Play sound when tabbed out",
            function() return s.bgSound end,
            function(v) s.bgSound = v; Changed() end)
        bgSound:SetPoint("TOPLEFT", boost, "BOTTOMLEFT", 0, -24)

        setMaster = W.Checkbox(panel, "Set master volume",
            function() return s.setMaster end,
            function(v) s.setMaster = v; Changed() end)
        setMaster:SetPoint("TOPLEFT", bgSound, "BOTTOMLEFT", 0, -4)

        master = W.Slider(panel, "Master", 0, 100, 5, "%",
            function() return s.master end,
            function(v) s.master = v; Changed() end)
        master:SetPoint("TOPLEFT", setMaster, "BOTTOMLEFT", 80, -14)

        sfx = W.Slider(panel, "Effects", 0, 100, 5, "%",
            function() return s.sfx end,
            function(v) s.sfx = v; Changed() end)
        sfx:SetPoint("TOPLEFT", master, "BOTTOMLEFT", 0, -22)

        local header = W.Label(panel, "Quiet while fishing", "GameFontNormal")
        header:SetPoint("TOPLEFT", setMaster, "BOTTOMLEFT", 0, -82)
        local anchor = header
        for i, q in ipairs(QUIET) do
            local cb = W.Checkbox(panel, q.label,
                function() return s[q.key] end,
                function(v) s[q.key] = v; Changed() end)
            cb:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, i == 1 and -4 or -1)
            anchor = cb
            quiet[#quiet + 1] = cb
        end

        return Refresh
    end,
})
