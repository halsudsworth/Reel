-- Cooking hints: fish tooltips (in bags, loot, links, and the Stats page) list
-- the cooking recipes that use the fish, and for each one you don't know,
-- where to get it. Recipe data is in FishData.lua.

local _, ns = ...

ns.RegisterDefaults({
    cookingTips = true,
})

local GREEN, GREY, GOLD = "|cff40ff40", "|cff888888", "|cffffd100"

local function Known(spell)
    return (IsPlayerSpell and IsPlayerSpell(spell)) or (IsSpellKnown and IsSpellKnown(spell)) or false
end

-- "Kelsey Yance, Stranglethorn Vale (+8 more)", preferring a vendor in the
-- zone you're in.
local function Where(recipe)
    if not recipe.from then return recipe.how end
    local zone = GetZoneText()
    local pick = recipe.from[1]
    for _, vendor in ipairs(recipe.from) do
        if vendor[2] == zone then pick = vendor break end
    end
    if not pick then return "Vendor" end
    local text = pick[1] .. ", " .. pick[2]
    if #recipe.from > 1 then text = text .. string.format(" (+%d more)", #recipe.from - 1) end
    return text
end

local function AddLines(tooltip, id)
    if not ReelDB or not ReelDB.settings.cookingTips then return end
    local recipes = id and ns.FISH_RECIPES[id]
    if not recipes then return end
    tooltip:AddLine(" ")
    for _, recipe in ipairs(recipes) do
        if Known(recipe.spell) then
            tooltip:AddLine(GOLD .. "Cooking:|r " .. recipe.name .. " " .. GREEN .. "(known)|r")
        else
            tooltip:AddLine(GOLD .. "Cooking:|r " .. recipe.name .. GREY .. " (skill " .. recipe.cooking .. ")|r")
            tooltip:AddLine("   Recipe: " .. Where(recipe), 1, 1, 1)
        end
    end
    tooltip:Show()
end

local function ItemID(link)
    return link and tonumber(link:match("item:(%d+)"))
end

ns.On("REEL_READY", function()
    if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
        TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
            if tooltip == GameTooltip or tooltip == ItemRefTooltip then
                AddLines(tooltip, data and data.id)
            end
        end)
    else
        for _, tooltip in ipairs({ GameTooltip, ItemRefTooltip }) do
            tooltip:HookScript("OnTooltipSetItem", function(self)
                local _, link = self:GetItem()
                AddLines(self, ItemID(link))
            end)
        end
    end
end)
