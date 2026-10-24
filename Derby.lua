-- Stranglethorn Fishing Extravaganza: a Speckled Tastyfish counter on the bar,
-- shown only while the contest runs (Sundays 2-4 PM server time). It turns
-- green once you have enough to turn in.
--
-- Contest details are from Icy Veins' Forever fishing guide: catch 40
-- Speckled Tastyfish and bring them to Riggle Bassbait in Booty Bay.
--
-- /reel derby shows the counter outside contest hours, for testing.

local _, ns = ...

local FISH = "Speckled Tastyfish"
local GOAL = 40
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
