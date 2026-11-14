-- Guild hello: finds guild members who also run R.E.E.L.
--
-- A moment after login, a hidden addon message ("HELLO", version) goes to the
-- guild. Each copy that hears it answers the sender by addon whisper ("HI",
-- version). Forever doesn't echo your own guild messages back, and an addon
-- whisper to "First Last" arrives (LAUNCH.md, 2026-11-08).
--
-- Everyone heard from is kept in ReelDB.guildSeen[name] = { v = version, t = time }.
-- A chat line after login lists who answered; /reel guild lists everyone seen.

local _, ns = ...

local PREFIX = "REEL"
local HELLO_DELAY = 10  -- seconds after login, so the guild roster has loaded
local REPORT_DELAY = 8  -- seconds after the hello to list who answered
local REPLY_GAP = 30    -- answer each sender at most once in this many seconds

local GetMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local version = GetMeta and GetMeta("Reel", "Version") or "?"

local registered = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
    and C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local function Send(kind, channel, target)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    C_ChatInfo.SendAddonMessage(PREFIX, kind .. "\t" .. version, channel, target)
end

local answered = {}  -- names that answered this login's hello
local repliedAt = {} -- sender -> GetTime() of our last answer

local function Record(name, v)
    ReelDB.guildSeen = ReelDB.guildSeen or {}
    ReelDB.guildSeen[name] = { v = v, t = ns.Now() }
end

ns.On("CHAT_MSG_ADDON", function(prefix, text, channel, sender)
    if prefix ~= PREFIX or not ReelDB or not sender then return end
    sender = sender:gsub("%-.*$", "") -- drop a realm suffix, if one ever comes
    if sender == ns.CharKey() then return end
    local kind, v = strsplit("\t", text or "")
    if kind == "HELLO" and channel == "GUILD" then
        Record(sender, v)
        local now = GetTime()
        if not repliedAt[sender] or now - repliedAt[sender] > REPLY_GAP then
            repliedAt[sender] = now
            Send("HI", "WHISPER", sender)
        end
    elseif kind == "HI" then
        Record(sender, v)
        answered[#answered + 1] = sender
    end
end)

local function Names(list)
    table.sort(list)
    return table.concat(list, ", ")
end

local said = false
ns.On("PLAYER_ENTERING_WORLD", function()
    if said or not registered then return end
    said = true
    C_Timer.After(HELLO_DELAY, function()
        if not IsInGuild() then return end
        Send("HELLO", "GUILD")
        C_Timer.After(REPORT_DELAY, function()
            if #answered > 0 then ns.Print("R.E.E.L. in guild: " .. Names(answered)) end
        end)
    end)
end)

-- /reel guild
function ns.PrintGuild()
    local seen = ReelDB.guildSeen or {}
    local list = {}
    for name, entry in pairs(seen) do
        list[#list + 1] = string.format("%s (%s, %s ago)", name, entry.v or "?", ns.FormatTime(ns.Now() - (entry.t or 0)))
    end
    if #list == 0 then
        ns.Print("No guild members with R.E.E.L. heard from yet.")
    else
        ns.Print("Guild members with R.E.E.L.: " .. Names(list))
    end
end
