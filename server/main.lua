local Framework = nil

if Config.Framework == 'QB' then
    Framework = exports['qb-core']:GetCoreObject()
elseif Config.Framework == 'ESX' then
    Framework = exports['es_extended']:getSharedObject()
end

RegisterNetEvent('neon_crafting:requestLevel', function()
    local src = source
    local Player = nil
    local identifier = nil

    if Config.Framework == 'QB' then
        Player = Framework.Functions.GetPlayer(src)
        identifier = Player and Player.PlayerData.citizenid or nil
    elseif Config.Framework == 'ESX' then
        Player = Framework.GetPlayerFromId(src)
        identifier = Player and Player.identifier or nil
    end

    if not identifier then return end

    exports.oxmysql:execute("SELECT xp_amount, level FROM neon_crafting_levels WHERE identifier = ?", {identifier}, function(result)
        if result and result[1] then
            TriggerClientEvent('neon_crafting:receiveLevel', src, result[1].xp_amount or 0, result[1].level or 0)
        else
            TriggerClientEvent('neon_crafting:receiveLevel', src, 0, 0)
        end
    end)
end)

RegisterNetEvent('neon_crafting:startCrafting', function(bench, item, amount)
    local src = source
    local Player = nil
    local identifier = nil

    if Config.Framework == 'QB' then
        Player = Framework.Functions.GetPlayer(src)
        identifier = Player.PlayerData.citizenid
    elseif Config.Framework == 'ESX' then
        Player = Framework.GetPlayerFromId(src)
        identifier = Player.identifier
    end

    if not identifier then return end

    local benchData = Config.Crafting[bench]
    if not benchData then return TriggerClientEvent('neon_crafting:craftingFailed', src, 'Invalid Bench') end

    local itemData = benchData.crafting_items[item]
    if not itemData then return TriggerClientEvent('neon_crafting:craftingFailed', src, 'Invalid Item') end

    local materialsUsed = {}

    for material, requiredAmount in pairs(itemData.required_items) do
        local totalRequired = requiredAmount * amount
        if exports.ox_inventory:Search(src, 'count', material) < totalRequired then
            TriggerClientEvent('neon_crafting:craftingFailed', src, 'Not enough ' .. material)
            return
        end
        table.insert(materialsUsed, { name = material, amount = totalRequired })
    end

    for _, material in ipairs(materialsUsed) do
        exports.ox_inventory:RemoveItem(src, material.name, material.amount)
    end

    TriggerClientEvent('neon_crafting:startProgress', src, itemData.craft_time * amount, bench, item, amount, materialsUsed)
end)

RegisterNetEvent('neon_crafting:returnMaterials', function(bench, materials)
    local src = source
    if not materials or #materials == 0 then return end

    for _, material in ipairs(materials) do
        exports.ox_inventory:AddItem(src, material.name, material.amount)
    end

    SendCraftingLog(src, bench, materials, 0, 0, true)

    TriggerClientEvent('neon_crafting:craftingFailed', src, 'Crafting canceled. Materials returned.')
end)

RegisterNetEvent('neon_crafting:finishCrafting', function(bench, item, amount)
    local src = source
    local Player = nil
    local identifier = nil

    if Config.Framework == 'QB' then
        Player = Framework.Functions.GetPlayer(src)
        identifier = Player.PlayerData.citizenid
    elseif Config.Framework == 'ESX' then
        Player = Framework.GetPlayerFromId(src)
        identifier = Player.identifier
    end

    if not identifier then return end

    local benchData = Config.Crafting[bench]
    if not benchData then return end

    local itemData = benchData.crafting_items[item]
    if not itemData then return end

    exports.oxmysql:execute("SELECT xp_amount, level FROM neon_crafting_levels WHERE identifier = ?", {identifier}, function(result)
        if not result or not result[1] then return end

        local currentXP = result[1].xp_amount or 0
        local currentLevel = result[1].level or 0
        local maxLevel = Config.LevelSystem.maxlevel
        local xpGained = itemData.xp * amount
        local newXP = currentXP + xpGained
        local newLevel = currentLevel

        while true do
            local xpRequired = Config.LevelSystem.xpperlevel[newLevel + 1] or Config.LevelSystem.defaultXP
            if newXP >= xpRequired then
                if maxLevel and newLevel >= maxLevel then break end
                newXP = newXP - xpRequired
                newLevel = newLevel + 1
            else
                break
            end
        end

        exports.oxmysql:execute("UPDATE neon_crafting_levels SET xp_amount = ?, level = ? WHERE identifier = ?", { newXP, newLevel, identifier })
        exports.ox_inventory:AddItem(src, item, amount)

        SendCraftingLog(src, bench, { { name = item, amount = amount } }, xpGained, newLevel, false)

        if newLevel > currentLevel then
            TriggerClientEvent('neon_crafting:craftingSuccess', src, 'Successfully crafted ' .. amount .. 'x ' .. item .. 
            '! You gained ' .. xpGained .. ' XP and leveled up to Level ' .. newLevel .. '!')
        else
            TriggerClientEvent('neon_crafting:craftingSuccess', src, 'Successfully crafted ' .. amount .. 'x ' .. item .. 
            '! You gained ' .. xpGained .. ' XP.')
        end
    end)
end)