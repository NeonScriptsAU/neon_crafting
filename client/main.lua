local isCrafting = false
local playerLevel = 0
local playerXP = 0
local currentBench = nil

RegisterNetEvent('neon_crafting:receiveLevel', function(xp, level)
    playerXP = xp
    playerLevel = level
    if currentBench then
        openBench(currentBench)
        currentBench = nil
    end
end)

function requestPlayerXP(bench)
    currentBench = bench
    TriggerServerEvent('neon_crafting:requestLevel')
end

function openBench(bench)
    local benchData = Config.Crafting[bench]
    if not benchData then return end
    if playerLevel < benchData.level then
        lib.notify({ type = 'error', description = 'Your crafting level is too low to use this bench!' })
        return
    end

    local menuId = "crafting_menu_" .. bench
    local items = exports.ox_inventory:Items()
    local maxXP = Config.LevelSystem.xpperlevel[playerLevel + 1] or Config.LevelSystem.defaultXP
    local progressPercent = math.floor((playerXP / maxXP) * 100)
    progressPercent = math.max(0, math.min(100, progressPercent))

    local options = {
        {
            title = "Crafting Level: " .. playerLevel,
            icon = "fa-solid fa-chart-simple",
            description = "Current Crafting Progress | XP: " .. playerXP .. " / " .. maxXP,
            colorScheme = "blue",
            progress = progressPercent
        }
    }

    for itemName, itemData in pairs(benchData.crafting_items) do
        local itemLabel = items[itemName] and items[itemName].label or itemName
        local itemIcon = ('nui://ox_inventory/web/images/%s.png'):format(itemName)
        local metadata = {}

        table.insert(metadata, { label = "Crafting Mats" })

        for reqItem, reqAmount in pairs(itemData.required_items) do
            local reqLabel = items[reqItem] and items[reqItem].label or reqItem
            table.insert(metadata, { label = reqLabel, value = reqAmount })
        end
        if itemData.blueprint then
            local blueprintLabel = items[itemData.blueprint] and items[itemData.blueprint].label or itemData.blueprint
            table.insert(metadata, { label = "Blueprint", value = blueprintLabel })
        end

        table.insert(options, {
            title = itemLabel,
            icon = itemIcon,
            metadata = metadata,
            arrow = true,
            onSelect = function()
                selectItem(bench, itemName)
            end
        })
    end

    lib.registerContext({ id = menuId, title = benchData.BenchTitle, options = options })
    lib.showContext(menuId)
end

function selectItem(bench, item)
    if isCrafting then
        lib.notify({ type = 'error', description = "You're already crafting something!" })
        return
    end

    local benchData = Config.Crafting[bench]
    local itemData = benchData.crafting_items[item]
    if not benchData or not itemData then return end

    local items = exports.ox_inventory:Items()
    local itemLabel = items[item] and items[item].label or item
    local amount = lib.inputDialog(('Enter Amount to Craft (%s)'):format(itemLabel), { { type = 'number', label = 'Amount', min = 1, default = 1 } })
    if not amount or tonumber(amount[1]) < 1 then return end
    amount = tonumber(amount[1])

    isCrafting = true
    TriggerServerEvent('neon_crafting:startCrafting', bench, item, amount)
end

RegisterNetEvent('neon_crafting:startProgress', function(duration, bench, item, amount, materialsUsed)
    local items = exports.ox_inventory:Items()
    local itemLabel = items[item] and items[item].label or item
    local labelText = "Crafting x" .. amount .. " " .. itemLabel .. (amount > 1 and "s" or "") .. "..."

    local success = lib.progressBar({
        duration = duration * 1000,
        label = labelText,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = "mini@repair", clip = "fixing_a_ped" }
    })

    isCrafting = false

    if success then
        TriggerServerEvent('neon_crafting:finishCrafting', bench, item, amount)
    else
        TriggerServerEvent('neon_crafting:returnMaterials', bench, materialsUsed)
    end
end)

RegisterNetEvent('neon_crafting:craftingSuccess', function(message)
    isCrafting = false
    lib.notify({ type = 'success', description = message })
end)

RegisterNetEvent('neon_crafting:craftingFailed', function(message)
    isCrafting = false
    lib.notify({ type = 'error', description = message })
end)

CreateThread(function()
    for benchName, benchData in pairs(Config.Crafting) do
        local coords = benchData.location
        local distance = benchData.distance or 2.0

        if Config.Interaction == 'ox_target' then
            exports.ox_target:addBoxZone({
                coords = coords,
                size = vec3(1.0, 1.0, 1.5),
                rotation = 0,
                debug = false,
                options = {
                    {
                        label = benchData.BenchTitle,
                        icon = "fa-solid fa-wrench",
                        onSelect = function()
                            requestPlayerXP(benchName)
                        end
                    }
                }
            })
        elseif Config.Interaction == 'textui' then
            local zone = lib.zones.sphere({
                coords = coords,
                radius = distance,
                debug = false,
                inside = function()
                    lib.showTextUI('[E] ' .. benchData.BenchTitle, { position = "top-center" })
                    if IsControlJustReleased(0, 38) then
                        requestPlayerXP(benchName)
                    end
                end,
                onExit = function()
                    lib.hideTextUI()
                end
            })
        end
    end
end)