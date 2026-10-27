-- Reel core: saved data, events, fishing detection, and fishing mode.
--
-- Features plug in from their own files:
--   ns.RegisterDefaults({ key = value })   settings with default values
--   ns.RegisterCVars(function(settings, targets) ... end)
--       add CVar overrides to apply while fishing (targets[cvar] = value)
--   ns.RegisterPage({ name, order, build })  a sidebar page (see Window.lua)
--   ns.RegisterBarSegment({ key, label, order, text })  a fishing bar item (see Bar.lua)
--   ns.On(event, fn)                        game events or Reel events:
--       REEL_READY         saved data is loaded
--       REEL_CAST          the player cast Fishing
--       REEL_FISHING_BEGIN first cast of a fishing session
--       REEL_FISHING_END   restoreDelay seconds after the last bobber is gone
--       REEL_DATA_CHANGED  catch data changed

local _, ns = ...

local FISHING_SPELL_ID = 7620 -- base Fishing spell; ranks share the localized name

local GetCVarValue = C_CVar and C_CVar.GetCVar or GetCVar
local SetCVarValue = C_CVar and C_CVar.SetCVar or SetCVar

function ns.Print(msg)
    print("|cff33ccffReel:|r " .. msg)
end

local function SpellName(id)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(id)
    end
    return (GetSpellInfo(id))
end
ns.SpellName = SpellName

-- 452 -> "7:32", 4380 -> "1h 13m", 529133 -> "6d 2h"
function ns.FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    if seconds >= 86400 then
        return string.format("%dd %dh", math.floor(seconds / 86400), math.floor(seconds % 86400 / 3600))
    elseif seconds >= 3600 then
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor(seconds % 3600 / 60))
    end
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Settings ------------------------------------------------------------------

ns.defaults = {}

function ns.RegisterDefaults(defaults)
    for key, value in pairs(defaults) do
        ns.defaults[key] = value
    end
end

-- Events --------------------------------------------------------------------

local handlers = {}
local eventFrame = CreateFrame("Frame")

function ns.On(event, fn)
    if not handlers[event] then
        handlers[event] = {}
        if not event:find("^REEL_") then
            eventFrame:RegisterEvent(event)
        end
    end
    table.insert(handlers[event], fn)
end

-- Each handler runs on its own, so one erroring feature doesn't stop the
-- others (and a broken REEL_READY handler can't leave later ones unrun).
function ns.Fire(event, ...)
    local list = handlers[event]
    if not list then return end
    for _, fn in ipairs(list) do
        local ok, err = pcall(fn, ...)
        if not ok then geterrorhandler()(err) end
    end
end

-- Runs fn now, or after combat if secure frames can't be touched right now.
local pendingOutOfCombat = {}
function ns.WhenOutOfCombat(fn)
    if InCombatLockdown() then
        pendingOutOfCombat[#pendingOutOfCombat + 1] = fn
    else
        fn()
    end
end

eventFrame:SetScript("OnEvent", function(_, event, ...) ns.Fire(event, ...) end)

-- Fishing mode --------------------------------------------------------------
-- While fishing, features override CVars and the player's own values are put
-- back restoreDelay seconds after the last bobber is gone.

ns.RegisterDefaults({ restoreDelay = 20 })

local providers = {}
local missingWarned = {}
local lastFishing = 0     -- when the last Fishing channel ended (or started)
local channeling = false  -- a Fishing bobber is out right now
local fishing = false     -- between REEL_FISHING_BEGIN and REEL_FISHING_END

function ns.Channeling() return channeling end
function ns.IsFishing() return fishing end

function ns.RegisterCVars(fn)
    providers[#providers + 1] = fn
end

local function Targets()
    local targets = {}
    for _, fn in ipairs(providers) do
        fn(ReelDB.settings, targets)
    end
    return targets
end

local function Wanted()
    return next(Targets()) ~= nil
end

-- Saved originals are kept per character: some CVars (auto-loot) are
-- per-character, so another character logging in must not restore them.
local function SavedKey()
    return ns.CharKey and ns.CharKey() or "?"
end

function ns.Restore()
    local all = ReelDB.savedCVars
    local saved = all and all[SavedKey()]
    if not saved then return end
    for cvar, value in pairs(saved) do
        SetCVarValue(cvar, value)
    end
    all[SavedKey()] = nil
    if next(all) == nil then ReelDB.savedCVars = nil end
end

-- Saves each CVar's original value the first time it is changed, so settings
-- can be adjusted mid-session and restore still returns the player's values.
-- Stored in SavedVariables so a /reload or crash mid-session still restores.
local function Apply()
    ReelDB.savedCVars = ReelDB.savedCVars or {}
    local saved = ReelDB.savedCVars[SavedKey()] or {}
    local targets = Targets()
    for cvar, value in pairs(targets) do
        if saved[cvar] == nil then
            saved[cvar] = GetCVarValue(cvar)
        end
        if saved[cvar] == nil then
            if not missingWarned[cvar] then
                missingWarned[cvar] = true
                ns.Print("This client has no " .. cvar .. " setting, so that option does nothing.")
            end
        else
            SetCVarValue(cvar, value)
        end
    end
    for cvar, original in pairs(saved) do
        if targets[cvar] == nil then
            SetCVarValue(cvar, original)
            saved[cvar] = nil
        end
    end
    ReelDB.savedCVars[SavedKey()] = saved
end

-- Called by pages after any setting changes.
function ns.ApplySettings()
    if not (ReelDB.savedCVars and ReelDB.savedCVars[SavedKey()]) then return end
    if Wanted() then
        Apply()
    else
        ns.Restore()
    end
end

-- True while a bobber is out, and until restoreDelay seconds after it's gone.
function ns.RecentlyFishing()
    return channeling or (lastFishing > 0 and GetTime() - lastFishing < ReelDB.settings.restoreDelay)
end

-- Player buffs ---------------------------------------------------------------

-- Auras are secret to addons in combat, so buffs are read out of combat and
-- the last list is kept until combat ends.
local buffs = {}

function ns.PlayerBuffs()
    if InCombatLockdown() then
        -- Drop buffs that ran out since combat started.
        local now, live = GetTime(), {}
        for _, aura in ipairs(buffs) do
            if not aura.expirationTime or aura.expirationTime == 0 or aura.expirationTime > now then
                live[#live + 1] = aura
            end
        end
        return live
    end
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataByIndex) then return buffs end
    buffs = {}
    for i = 1, 40 do
        local aura = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not aura then break end
        buffs[#buffs + 1] = aura
    end
    return buffs
end

local function EndFishing()
    ns.Restore()
    if fishing then
        fishing = false
        ns.Fire("REEL_FISHING_END")
    end
end

-- Checks again every second after the delay, so a delay changed mid-wait
-- (or a timer landing a hair early) can't leave fishing mode on for good.
local function ScheduleEnd()
    C_Timer.After(ReelDB.settings.restoreDelay, function()
        if ns.RecentlyFishing() then
            if not channeling then C_Timer.After(1, function() if not ns.RecentlyFishing() then EndFishing() end end) end
        else
            EndFishing()
        end
    end)
end

-- Fishing detection ---------------------------------------------------------

local fishingName

ns.On("UNIT_SPELLCAST_CHANNEL_START", function(unit, _, spellID)
    if unit ~= "player" or not fishingName or SpellName(spellID) ~= fishingName then
        return
    end
    channeling = true
    lastFishing = GetTime()
    if not fishing then
        fishing = true
        ns.Fire("REEL_FISHING_BEGIN")
    end
    if Wanted() then Apply() end
    ns.Fire("REEL_CAST")
end)

-- The bobber is gone (caught, missed, or cancelled): start the end delay.
ns.On("UNIT_SPELLCAST_CHANNEL_STOP", function(unit)
    if unit ~= "player" or not channeling then return end
    channeling = false
    lastFishing = GetTime()
    ScheduleEnd()
end)

-- Logging out mid-session: put everything back now rather than on the next
-- login (which might be another character).
ns.On("PLAYER_LOGOUT", function()
    if fishing then EndFishing() end
end)

ns.On("PLAYER_REGEN_ENABLED", function()
    local list = pendingOutOfCombat
    pendingOutOfCombat = {}
    for _, fn in ipairs(list) do -- one failure must not skip the rest
        local ok, err = pcall(fn)
        if not ok then geterrorhandler()(err) end
    end
end)

-- Startup -------------------------------------------------------------------

ns.On("PLAYER_LOGIN", function()
    ReelDB = ReelDB or {}
    ReelDB.settings = ReelDB.settings or {}
    for key, value in pairs(ns.defaults) do
        if ReelDB.settings[key] == nil then
            ReelDB.settings[key] = value
        end
    end
    ReelDB.boost = nil -- replaced by settings.boost in 0.2.0
    ReelDB.biteLog, ReelDB.biteLogOn = nil, nil -- bite recorder removed in 0.9.0
    ReelDB.settings.softInteract = nil -- bobber marker removed in 0.9.0
    ReelDB.settings.lureWarnSeconds = nil -- fixed at 30s in 0.9.0
    for key in pairs(ReelDB.settings) do -- pop-up alerts removed in 0.8.0
        if key:find("^alert") or key == "lureWarn" or key == "campAlert" then
            ReelDB.settings[key] = nil
        end
    end
    if ReelDB.savedSound then -- renamed to savedCVars in 0.3.0
        ReelDB.savedCVars = ReelDB.savedCVars or ReelDB.savedSound
        ReelDB.savedSound = nil
    end
    -- savedCVars became per character in 1.0.0; an old flat { cvar = value }
    -- table left by a crash mid-session belongs to whoever logs in next.
    if ReelDB.savedCVars then
        for _, value in pairs(ReelDB.savedCVars) do
            if type(value) ~= "table" then
                ReelDB.savedCVars = { [SavedKey()] = ReelDB.savedCVars }
                break
            end
        end
    end
    ns.Restore()

    fishingName = SpellName(FISHING_SPELL_ID)
    ns.fishingName = fishingName
    if not fishingName then
        ns.Print("Couldn't look up the Fishing spell (ID " .. FISHING_SPELL_ID .. "). Casts won't be detected.")
    end
    ns.Fire("REEL_READY")
end)

-- /reel where: the zone and subzone a catch here would be logged under, and the map
-- position when the client gives one. For checking event spots in game.
function ns.PrintWhere()
    local zone = GetZoneText() or "?"
    local sub = GetSubZoneText()
    if not sub or sub == "" then sub = "(none, logged as " .. zone .. ")" end
    local pos = ""
    if C_Map and C_Map.GetBestMapForUnit then
        local ok, map = pcall(C_Map.GetBestMapForUnit, "player")
        local okp, p = false, nil
        if ok and map then okp, p = pcall(C_Map.GetPlayerMapPosition, map, "player") end
        if okp and p and p.x then pos = string.format("  %.1f, %.1f", p.x * 100, p.y * 100) end
    end
    ns.Print("Zone: " .. zone .. "  Subzone: " .. sub .. pos)
end

-- Slash command -------------------------------------------------------------

SLASH_REEL1 = "/reel"
SlashCmdList.REEL = function(msg)
    msg = strtrim(msg or ""):lower()
    if msg == "reset" then
        ns.ConfirmReset()
    elseif msg == "debug" then
        ns.Debug()
    elseif msg == "debug sound" then
        ns.DebugSound()
    elseif msg == "derby" then
        ns.ToggleDerbyTest()
    elseif msg == "where" then
        ns.PrintWhere()
    elseif not ns.ExitCleanView() then
        ns.ToggleWindow()
    end
end
