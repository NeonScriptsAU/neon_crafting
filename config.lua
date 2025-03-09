Config = {}

Config.Version = true -- This will print new updates in server console.
Config.AmazingScripts = true -- Using Amazing Scripts!

Config.Framework = 'QB'  -- Options: 'QB' or 'ESX' (If Using QBX Use 'QB')

-- Choose interaction method: 'ox_target' for target system, 'textui' for text-based UI
Config.Interaction = 'ox_target'  -- Options: 'ox_target' or 'textui'

-- Crafting Level System
Config.LevelSystem = {
    maxlevel = 10, -- Set to 'false' for unlimited levels
    default_xp = 500, -- Default XP required if not explicitly set
    xpperlevel = {
        [0] = 0,
        [1] = 100,
        [2] = 300,
        [3] = 600,
        [4] = 1000,
        [5] = 1500,
        [6] = 2100,
        [7] = 2800,
        [8] = 3600,
        [9] = 4500,
        [10] = 5500,
        -- Next level here. If you don't put all levels here it will use 'default_xp'
    }
}

-- Define crafting benches and items
Config.Crafting = {    
    ["gun_bench"] = { -- Name of the crafting bench
        BenchTitle = "Weapon Crafting", -- Title displayed in the UI
        level = 0,-- Mnimum level required to use this bench
        location = vector3(210.0658, 272.9489, 105.5853), -- Set location of the crafting bench
        distance = 2.0, -- Required distance to interact
        crafting_items = {
            ["WEAPON_PISTOL"] = { -- Item that can be crafted
                required_items = { -- Materials needed
                    steel = 5,
                    plastic = 2
                },
                blueprint = "blueprint_pistol", -- Requires this blueprint, or set to false if not needed
                craft_time = 10, -- Time in seconds to craft (multiplied by amount)
                xp = 20 -- XP gained per craft
            },
            ["WEAPON_KNIFE"] = {
                required_items = {
                    iron = 5
                },
                blueprint = false,
                craft_time = 5,
                xp = 10
            }
        }
    },
    ["armor_bench"] = {
        BenchTitle = "Armor Crafting",
        level = 5,
        location = vector3(200.5, 300.7, 50.9),
        distance = 1.5,
        crafting_items = {
            ["armor"] = {
                required_items = {
                    steel = 10,
                    fabric = 5
                },
                blueprint = false,
                craft_time = 15,
                xp = 30
            }
        }
    }
}