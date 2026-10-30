-- Stranglethorn Fishing Extravaganza: a Speckled Tastyfish counter on the bar,
-- shown only while the contest runs (Sundays 2-4 PM server time). It turns
-- green once you have enough to turn in.
--
-- Contest details are from Icy Veins' Forever fishing guide: catch 40
-- Speckled Tastyfish and bring them to Riggle Bassbait in Booty Bay.
--
-- /reel derby shows the counter outside contest hours, for testing.

local _, ns = ...

local FISH = 19807 -- Speckled Tastyfish (by ID, so non-English clients count too)
local GOAL = 40
local COIN = 274026 -- Extravagant Extravaganza Coin, the Forever derby prize
local SUNDAY, START_HOUR, END_HOUR = 1, 14, 16

local GetItemCountCompat = C_Item and C_Item.GetItemCount or GetItemCount

local testMode = false

-- Uses the calendar's clock, which is server (realm) time.
local function ContestRunning()
    if testMode then return true end
    local now = C_DateAndTime and C_DateAndTime.GetCurrentCalendarTime and C_DateAndTime.GetCurrentCalendarTime()
    if not now then return false end
    return now.weekday == SUNDAY and now.hour >= START_HOUR and now.hour < END_HOUR
end

function ns.ToggleDerbyTest()
    testMode = not testMode
    ns.Print("Derby counter test mode " .. (testMode and "on" or "off") .. ".")
    ns.UpdateBar()
end

-- Lifetime derby coins, per character: every rise in the coin count is
-- "earned", every fall is "spent". The count the last time we looked is kept
-- so a relog doesn't count the coins you already had. Bank included, so
-- moving coins to the bank isn't "spent". Only runs from bag events, never
-- at login, where an empty bag cache would read as spending everything.
local function TrackCoins()
    local data = ns.Data()
    if not data then return end
    local count = GetItemCountCompat(COIN, true)
    local derby = data.derby
    if not derby then
        derby = { earned = 0, spent = 0, seen = count }
        data.derby = derby
    end
    if count > derby.seen then
        derby.earned = derby.earned + (count - derby.seen)
    elseif count < derby.seen then
        derby.spent = derby.spent + (derby.seen - count)
    end
    if count ~= derby.seen then
        derby.seen = count
        ns.Fire("REEL_DATA_CHANGED")
    end
end

ns.On("BAG_UPDATE_DELAYED", TrackCoins)

-- Master Anglers: Riggle yells each winner to the whole zone ("We have a winner! Shame is
-- one of our Master Anglers this week!", seen in a Forever beta video). Every one heard is
-- kept with the time, so the site can list each Sunday's winners from anyone's journal. Forever
-- has no realms; the yell only reaches the hearer's own Ruleset, and the site files it under the
-- journal's Ruleset. The same name twice within a few hours is one win.
local WINNER = "^We have a winner! (.-) is one of our Master Anglers this week!"

ns.On("CHAT_MSG_MONSTER_YELL", function(text, sender)
    if sender ~= "Riggle Bassbait" or type(text) ~= "string" then return end
    local name = text:match(WINNER)
    local data = ns.Data()
    if not name or not data then return end
    data.wins = data.wins or {}
    local now = time()
    for _, w in ipairs(data.wins) do
        if w[2] == name and now - w[1] < 6 * 3600 then return end
    end
    table.insert(data.wins, { now, name })
    ns.Fire("REEL_DATA_CHANGED")
end)

-- Combined across characters when the Records tab shows all of them.
function ns.DerbyCoins(chars)
    local earned, spent, held = 0, 0, 0
    for _, d in pairs(chars) do
        if d.derby then
            earned, spent, held = earned + d.derby.earned, spent + d.derby.spent, held + d.derby.seen
        end
    end
    return earned, spent, held
end

ns.RegisterBarSegment({
    key = "derby",
    label = "Tastyfish (Sunday derby only)",
    order = 5,
    text = function()
        if not ContestRunning() then return end
        local count = GetItemCountCompat(FISH)
        if count >= GOAL then
            return string.format("|cff40ff40Tastyfish %d/%d - turn in to Riggle Bassbait|r", count, GOAL), true
        end
        return string.format("Tastyfish %d/%d", count, GOAL), true
    end,
})
