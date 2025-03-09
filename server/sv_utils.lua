local webhookUrl = 'YOUR_WEBHOOK_HERE' -- Replace with your actual Discord Webhook URL

function SendCraftingLog(player, bench, items, xpGained, newLevel, canceled)
    local playerName = GetPlayerName(player) or "Unknown"
    local xpMessage = canceled and "No XP gained" or ("XP Gained: " .. xpGained .. " | New Level: " .. newLevel)

    local formattedItems = {}
    for _, item in pairs(items) do
        table.insert(formattedItems, string.format("%s x%d", item.name, item.amount))
    end
    local itemsString = #formattedItems > 0 and table.concat(formattedItems, "\n") or "No items logged"

    local embed = {
        {
            ["title"] = canceled and "❌ Crafting Canceled" or "✅ Crafting Completed",
            ["color"] = canceled and 16711680 or 65280,
            ["fields"] = {
                { ["name"] = "Player", ["value"] = playerName, ["inline"] = true },
                { ["name"] = "Bench Used", ["value"] = bench, ["inline"] = true },
                { ["name"] = canceled and "Returned Items" or "Items Crafted", ["value"] = itemsString, ["inline"] = false },
                { ["name"] = "XP & Level", ["value"] = xpMessage, ["inline"] = false }
            },
            ["footer"] = { ["text"] = "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") }
        }
    }

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST', json.encode({username = "Crafting Logs", embeds = embed}), { ['Content-Type'] = 'application/json' })
end