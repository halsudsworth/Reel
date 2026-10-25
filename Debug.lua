-- /reel debug: records what the client reports about fishing skill, lure,
-- and buffs into ReelDB.debug, so it can be read from the SavedVariables
-- file after a /reload (the game has no copy-paste out of chat).

local _, ns = ...

local function Pack(...)
    return { n = select("#", ...), ... }
end

local function Try(fn, ...)
    if type(fn) ~= "function" then return "missing" end
    local result = Pack(pcall(fn, ...))
    if not result[1] then return "error: " .. tostring(result[2]) end
    table.remove(result, 1)
    result.n = result.n - 1
    return result
end

function ns.Debug()
    local d = { time = date("%Y-%m-%d %H:%M:%S"), build = Pack(GetBuildInfo()) }

    d.GetProfessions = Try(GetProfessions)
    local fishing = type(d.GetProfessions) == "table" and d.GetProfessions[4]
    if fishing then
        d.GetProfessionInfo = Try(GetProfessionInfo, fishing)
    end
    d.GetNumSkillLines = Try(GetNumSkillLines)
    if C_TradeSkillUI then
        d.ProfessionInfoBySkillLine356 = Try(C_TradeSkillUI.GetProfessionInfoBySkillLineID, 356)
    else
        d.ProfessionInfoBySkillLine356 = "no C_TradeSkillUI"
    end
    d.GetWeaponEnchantInfo = Try(GetWeaponEnchantInfo)
    d.FishingSkill = Pack(ns.FishingSkill())

    d.buffs = {}
    for _, aura in ipairs(ns.PlayerBuffs()) do -- the out-of-combat cache; auras are secret in combat
        local desc = C_Spell and C_Spell.GetSpellDescription and C_Spell.GetSpellDescription(aura.spellId)
        d.buffs[#d.buffs + 1] = { name = aura.name, spellId = aura.spellId, description = desc, points = aura.points }
    end

    -- Equipped items whose tooltip mentions fishing (hats, poles, etc.).
    d.gear = {}
    if C_TooltipInfo and C_TooltipInfo.GetInventoryItem then
        for slot = 1, 19 do
            local info = C_TooltipInfo.GetInventoryItem("player", slot)
            if info and info.lines then
                for _, line in ipairs(info.lines) do
                    local t = line.leftText
                    if t and t:lower():find("fishing") then
                        d.gear[#d.gear + 1] = { slot = slot, item = GetInventoryItemLink("player", slot), line = t }
                    end
                end
            end
        end
    else
        d.gear = "no C_TooltipInfo"
    end

    -- Character name calls, to find the one that includes the last name.
    d.names = {
        UnitName = Try(UnitName, "player"),
        UnitFullName = Try(UnitFullName, "player"),
        GetUnitName = Try(GetUnitName, "player", true),
        UnitPVPName = Try(UnitPVPName, "player"),
    }
    if C_PlayerInfo and C_PlayerInfo.GetName and PlayerLocation and PlayerLocation.CreateFromUnit then
        d.names.C_PlayerInfo_GetName = Try(C_PlayerInfo.GetName, PlayerLocation:CreateFromUnit("player"))
    else
        d.names.C_PlayerInfo_GetName = "missing"
    end
    if C_TooltipInfo and C_TooltipInfo.GetUnit then
        local info = C_TooltipInfo.GetUnit("player")
        d.names.tooltip = {}
        for _, line in ipairs(info and info.lines or {}) do
            d.names.tooltip[#d.names.tooltip + 1] = line.leftText
        end
    end

    -- Which sound and targeting settings this client has (nil = doesn't exist).
    local GetCVarValue = C_CVar and C_CVar.GetCVar or GetCVar
    d.cvars = {}
    for _, cvar in ipairs({
        "Sound_MasterVolume", "Sound_SFXVolume", "Sound_MusicVolume", "Sound_AmbienceVolume",
        "Sound_DialogVolume", "Sound_EnableAllSound", "Sound_EnableSFX", "Sound_EnableMusic",
        "Sound_EnableAmbience", "Sound_EnableDialog", "Sound_EnableEmoteSounds",
        "Sound_EnablePetSounds", "Sound_EnableErrorSpeech", "Sound_EnableSoundWhenGameIsInBG",
        "Sound_EnableReverb", "Sound_EnablePositionalLowPassFilter", "Sound_EnableDSPEffects",
        "Sound_EnableArmorFoleySoundForSelf", "Sound_EnableArmorFoleySoundForOthers",
        "Sound_ListenerAtCharacter", "Sound_NumChannels",
        "SoftTargetInteract", "SoftTargetIconInteract", "SoftTargetIconGameObject",
        -- Immersion page
        "UnitNameOwn", "UnitNameFriendlyPlayerName", "nameplateShowAll", "nameplateShowFriendlyPlayers",
        "autoLootDefault", "enableFloatingCombatText",
        "graphicsQuality", "graphicsLiquidDetail", "graphicsPBRLiquidDetail", "graphicsViewDistance",
        "graphicsEnvironmentDetail", "graphicsGroundClutter", "graphicsShadowQuality",
        "graphicsParticleDensity", "graphicsSSAO", "graphicsDepthEffects",
    }) do
        d.cvars[cvar] = GetCVarValue(cvar) or "MISSING"
    end
    d.IsGraphicsSettingValueSupported = IsGraphicsSettingValueSupported ~= nil
    d.SaveView = SaveView ~= nil
    d.TooltipDataProcessor = TooltipDataProcessor ~= nil
    d.MuteSoundFile = MuteSoundFile ~= nil
    d.UnmuteSoundFile = UnmuteSoundFile ~= nil

    ReelDB.debug = d
    ns.Print("Debug info saved. Type /reload so it's written to disk.")
end

-- /reel debug sound: logs in to voice chat, then runs the mic test on
-- every input device in turn, DEVICE_SECONDS each, counting the sound-level
-- events (VOICE_CHAT_AUDIO_CAPTURE_ENERGY) each one delivers. Blizzard's own
-- meter (Blizzard_SettingsDefinitions_Shared/Audio.lua) is driven by the same
-- call and event, so a device with no events here gives the game no audio.
-- Casts and loot are logged on the same timeline. Results go to
-- ReelDB.debugSound; the original device is put back at the end.

local DEVICE_SECONDS = 6
local MAX_ENERGY_SAMPLES = 20 -- per device
local SOUND_EVENTS = {
    "VOICE_CHAT_LOGIN", "VOICE_CHAT_ERROR", "VOICE_CHAT_CONNECTION_SUCCESS",
    "VOICE_CHAT_AUDIO_CAPTURE_STARTED", "VOICE_CHAT_AUDIO_CAPTURE_STOPPED",
    "UNIT_SPELLCAST_CHANNEL_START", "UNIT_SPELLCAST_CHANNEL_STOP", "LOOT_OPENED",
}

local soundFrame
local recording

local function Round(v)
    return type(v) == "number" and math.floor(v * 1000 + 0.5) / 1000 or v
end

local function VoiceState()
    local vc = C_VoiceChat
    if not vc then return "no C_VoiceChat" end
    local GetCVarValue = C_CVar and C_CVar.GetCVar or GetCVar
    local cvars = {}
    for _, cvar in ipairs({ "EnableVoiceChat", "VoiceInputDevice", "VoiceOutputDevice",
        "VoiceChatMasterVolumeScale", "VoiceVADSensitivity", "VoiceChatMode", "VoiceInputVolume" }) do
        cvars[cvar] = GetCVarValue(cvar) or "MISSING"
    end
    return {
        IsEnabled = Try(vc.IsEnabled),
        IsLoggedIn = Try(vc.IsLoggedIn),
        IsVoiceChatConnected = Try(vc.IsVoiceChatConnected),
        ConnectionStatusCode = Try(vc.GetCurrentVoiceChatConnectionStatusCode),
        ActiveVoiceProviderID = Try(vc.GetActiveVoiceProviderID),
        CanPlayerUseVoiceChat = Try(vc.CanPlayerUseVoiceChat),
        IsMuted = Try(vc.IsMuted),
        GetInputVolume = Try(vc.GetInputVolume),
        GetMasterVolumeScale = Try(vc.GetMasterVolumeScale),
        GetVADSensitivity = Try(vc.GetVADSensitivity),
        cvars = cvars,
    }
end

local function StopSound(reason)
    if not recording then return end
    local d = recording
    recording = nil
    soundFrame:UnregisterAllEvents()
    Try(C_VoiceChat and C_VoiceChat.EndLocalCapture)
    if d.originalDevice and C_VoiceChat and C_VoiceChat.SetInputDevice then
        d.restoreDevice = Try(C_VoiceChat.SetInputDevice, d.originalDevice)
    end
    d.stopped = reason
    d.stateAfter = VoiceState()
    ns.Print("Sound test done. Type /reload so it's written to disk.")
end

function ns.DebugSound()
    if recording then
        StopSound("stopped early")
        return
    end
    if not (C_VoiceChat and C_VoiceChat.BeginLocalCapture and C_VoiceChat.GetAvailableInputDevices) then
        ns.Print("This client has no C_VoiceChat capture.")
        return
    end
    local d = { time = date("%Y-%m-%d %H:%M:%S"), log = {}, devices = {} }
    d.stateBefore = VoiceState()
    d.originalDevice = C_VoiceChat.GetInputDevice and C_VoiceChat.GetInputDevice()
        or (C_CVar and C_CVar.GetCVar or GetCVar)("VoiceInputDevice")

    local devices = C_VoiceChat.GetAvailableInputDevices() or {}
    local current -- the device entry being tested
    local start = GetTime()

    soundFrame = soundFrame or CreateFrame("Frame")
    for _, event in ipairs(SOUND_EVENTS) do pcall(soundFrame.RegisterEvent, soundFrame, event) end
    pcall(soundFrame.RegisterEvent, soundFrame, "VOICE_CHAT_AUDIO_CAPTURE_ENERGY")
    soundFrame:SetScript("OnEvent", function(_, event, ...)
        if event == "VOICE_CHAT_AUDIO_CAPTURE_ENERGY" then
            if not current then return end
            local isSpeaking, energy = ...
            current.energyEvents = current.energyEvents + 1
            if energy and energy > current.maxEnergy then current.maxEnergy = energy end
            if isSpeaking then current.speakingEvents = current.speakingEvents + 1 end
            if current.energyEvents <= MAX_ENERGY_SAMPLES then
                current.samples[#current.samples + 1] = { Round(GetTime() - start), isSpeaking, Round(energy) }
            end
            return
        end
        if event:find("^UNIT_SPELLCAST") and ... ~= "player" then return end
        local entry = { Round(GetTime() - start), event }
        for i = 1, select("#", ...) do entry[#entry + 1] = Round((select(i, ...))) end
        d.log[#d.log + 1] = entry
    end)

    local index = 0
    local function NextDevice()
        if recording ~= d then return end
        Try(C_VoiceChat.EndLocalCapture)
        index = index + 1
        local device = devices[index]
        if not device then
            StopSound("all devices tested")
            return
        end
        current = {
            name = device.displayName, deviceID = device.deviceID,
            energyEvents = 0, speakingEvents = 0, maxEnergy = 0, samples = {},
            at = Round(GetTime() - start),
        }
        current.SetInputDevice = Try(C_VoiceChat.SetInputDevice, device.deviceID)
        current.SetInputVolume = Try(C_VoiceChat.SetInputVolume, 100)
        current.BeginLocalCapture = Try(C_VoiceChat.BeginLocalCapture, true)
        d.devices[index] = current
        ns.Print(string.format("Testing input %d/%d: %s", index, #devices, device.displayName))
        C_Timer.After(DEVICE_SECONDS, NextDevice)
    end

    d.Login = Try(C_VoiceChat.Login)
    recording = d
    ReelDB.debugSound = d
    ns.Print(string.format("Sound test: %d input devices, %ds each. Talk and fish the whole time.", #devices, DEVICE_SECONDS))
    C_Timer.After(3, NextDevice) -- give the login a moment
end
