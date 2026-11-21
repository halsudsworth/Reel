-- Guild hello: finds guild members who also run R.E.E.L.
--
-- A moment after login, a hidden addon message ("HELLO", version) goes to the
-- guild. Each copy that hears it answers the sender by addon whisper ("HI",
-- version). Forever doesn't echo your own guild messages back, and an addon
-- whisper to "First Last" arrives (LAUNCH.md, 2026-11-08).
--
-- Everyone heard from is kept in ReelDB.guildSeen[name] = { v = version, t = time }.
-- A chat line after login lists who answered; /reel guild lists everyone seen.
--
-- Fishers channel (behind the scenes; for now only a check): can copies that share no guild find
-- each other? A moment later R.E.E.L. joins a custom channel, hidden from every chat window, and
-- says HELLO there. Copies that hear it answer by addon whisper ("HIC"). Tested alone in game
-- 2026-11-21 (tools/channeltest): the channel joins and echoes back, about 10 messages go at once
-- before the throttle drops the rest, and addon messages by say and yell are refused. Whether
-- other players hear the channel, and across factions, is what this checks.
-- Kept in ReelDB.channelSeen[name] = { v, f = faction, t, how = "CHANNEL" or "WHISPER" } and
-- ReelDB.channelStatus. Nothing is shown to the player.
-- Every message carries version and faction after the kind; older copies ignore the extra field.

local _, ns = ...
local L = ns.L

local PREFIX = "REEL"
local HELLO_DELAY = 10  -- seconds after login, so the guild roster has loaded
local REPORT_DELAY = 8  -- seconds after the hello to list who answered
local REPLY_GAP = 30    -- answer each sender at most once in this many seconds
local REPLY_JITTER = 5  -- answers wait a random 0-5 seconds, so a guild's copies don't all send at once
local RETRY_DELAY, RETRIES = 3, 2
-- SendAddonMessage results worth another try: AddonMessageThrottle, ChannelThrottle,
-- GeneralError (the same three BigWigs retries).
local RETRY_CODES = { [3] = true, [8] = true, [9] = true }

local CHANNEL = "ReelFishers"
local CHANNEL_DELAY = 12 -- seconds after the guild hello
local SEEN_KEEP = 500
-- Every copy on the realm hears every channel hello, so answers thin out as more copies are heard:
-- each answers with chance ANSWERS / (copies heard this session), about ANSWERS answers per hello.
local ANSWERS = 10

local GetMeta = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local version = GetMeta and GetMeta("Reel", "Version") or "?"
local faction = UnitFactionGroup("player")

local registered = C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix
    and C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

local function Send(kind, channel, target, tries)
    if not (C_ChatInfo and C_ChatInfo.SendAddonMessage) then return end
    local text = kind .. "\t" .. version .. "\t" .. (faction or "?")
    local result = C_ChatInfo.SendAddonMessage(PREFIX, text, channel, target)
    tries = tries or 0
    if RETRY_CODES[result] and tries < RETRIES then
        C_Timer.After(RETRY_DELAY, function() Send(kind, channel, target, tries + 1) end)
    end
    return result
end

local answered = {}  -- names that answered this login's hello
local repliedAt = {} -- sender -> GetTime() of our last answer

local function Record(name, v)
    ReelDB.guildSeen = ReelDB.guildSeen or {}
    ReelDB.guildSeen[name] = { v = v, t = ns.Now() }
end

local heardNames, heard = {}, 0 -- different copies heard on the channel this session

local function RecordChannel(name, v, f, how)
    ReelDB.channelSeen = ReelDB.channelSeen or {}
    local seen = ReelDB.channelSeen
    if not seen[name] then
        local n, oldest, oldestT = 0, nil, math.huge
        for k, e in pairs(seen) do
            n = n + 1
            if (e.t or 0) < oldestT then oldest, oldestT = k, e.t or 0 end
        end
        if n >= SEEN_KEEP and oldest then seen[oldest] = nil end
    end
    local old = seen[name]
    -- once heard on the channel itself, keep saying so: that's the question
    seen[name] = { v = v, f = f, t = ns.Now(), how = (old and old.how == "CHANNEL") and "CHANNEL" or how }
end

local function ChannelId()
    local id = GetChannelName(CHANNEL)
    return id and id > 0 and id or nil
end

local function Answer(sender, kind)
    local now = GetTime()
    if repliedAt[sender] and now - repliedAt[sender] <= REPLY_GAP then return end
    repliedAt[sender] = now
    C_Timer.After(math.random() * REPLY_JITTER, function() Send(kind, "WHISPER", sender) end)
end

ns.On("CHAT_MSG_ADDON", function(prefix, text, channel, sender)
    if prefix ~= PREFIX or not ReelDB or not sender then return end
    sender = sender:gsub("%-.*$", "") -- drop a realm suffix, if one ever comes
    if sender == ns.CharKey() then return end
    local kind, v, f = strsplit("\t", text or "")
    if kind == "HELLO" and channel == "GUILD" then
        Record(sender, v)
        Answer(sender, "HI")
    elseif kind == "HELLO" and channel == "CHANNEL" then
        if not heardNames[sender] then heardNames[sender] = true; heard = heard + 1 end
        RecordChannel(sender, v, f, "CHANNEL")
        if math.random() * heard < ANSWERS then Answer(sender, "HIC") end
    elseif kind == "HI" then
        Record(sender, v)
        answered[#answered + 1] = sender
    elseif kind == "HIC" then
        RecordChannel(sender, v, f, "WHISPER")
    end
end)

local function Names(list)
    table.sort(list)
    return table.concat(list, ", ")
end

local function JoinChannel()
    local status = { t = ns.Now(), faction = faction }
    ReelDB.channelStatus = status
    if not ChannelId() then JoinChannelByName(CHANNEL) end
    C_Timer.After(2, function()
        local id = ChannelId()
        status.id = id
        if not id then return end
        for i = 1, NUM_CHAT_WINDOWS or 10 do
            local cf = _G["ChatFrame" .. i]
            if cf and ChatFrame_RemoveChannel then ChatFrame_RemoveChannel(cf, CHANNEL) end
        end
        status.hello = Send("HELLO", "CHANNEL", tostring(id))
    end)
end

local said = false
ns.On("PLAYER_ENTERING_WORLD", function()
    if said or not registered then return end
    said = true
    C_Timer.After(HELLO_DELAY, function()
        if not IsInGuild() then return end
        Send("HELLO", "GUILD")
        C_Timer.After(REPORT_DELAY, function()
            if #answered > 0 then ns.Print(string.format(L["R.E.E.L. in guild: %s"], Names(answered))) end
        end)
    end)
    C_Timer.After(HELLO_DELAY + CHANNEL_DELAY, JoinChannel)
end)

-- /reel guild
function ns.PrintGuild()
    local seen = ReelDB.guildSeen or {}
    local list = {}
    for name, entry in pairs(seen) do
        list[#list + 1] = string.format(L["%s (%s, %s ago)"], name, entry.v or "?", ns.FormatTime(ns.Now() - (entry.t or 0)))
    end
    if #list == 0 then
        ns.Print(L["No guild members with R.E.E.L. heard from yet."])
    else
        ns.Print(string.format(L["Guild members with R.E.E.L.: %s"], Names(list)))
    end
end
