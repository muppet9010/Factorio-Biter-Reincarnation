local Trees = require("scripts/trees")
local Utils = require("utility/utils")

local function OnEntityDied(event)
    local diedEntity = event.entity
    if diedEntity.force ~= game.forces.enemy then
        return
    end
    if diedEntity.type ~= "unit" then
        return
    end
    local surface = diedEntity.surface
    local targetPosition = diedEntity.position
    local random = math.random()
    local chance = global.treeOnDeathChance
    if Utils.FuzzyCompareDoubles(random, "<", chance) then
        Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
    else
        chance = chance + global.burningTreeOnDeathChance
        if Utils.FuzzyCompareDoubles(random, "<", chance) then
            local createdTree = Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
            if createdTree ~= nil then
                targetPosition = createdTree.position
            end
            Trees.AddTreeFireToPosition(createdTree.surface, targetPosition)
        end
    end
end

local function UpdateSetting(settingName)
    if settingName == "burst-into-flames-chance-percent" or settingName == nil then
        global.burningTreeOnDeathChance = tonumber(settings.global["burst-into-flames-chance-percent"].value)/100
    end
    if settingName == "turn-to-tree-chance-percent" or settingName == nil then
        global.treeOnDeathChance = tonumber(settings.global["turn-to-tree-chance-percent"].value)/100
    end

    local totalChance = global.burningTreeOnDeathChance + global.treeOnDeathChance
    if totalChance > 1 then
        local multiplier = 1 / totalChance
        global.burningTreeOnDeathChance = global.burningTreeOnDeathChance * multiplier
        global.treeOnDeathChance = global.treeOnDeathChance * multiplier
    end
end

local function CreateGlobals()
    global.TreeData = global.TreeData or {}
    global.treeOnDeathChance = global.treeOnDeathChance or 0
    global.burningTreeOnDeathChance = global.burningTreeOnDeathChance or 0
end

local function OnStartup()
    CreateGlobals()
    UpdateSetting(nil)
    Trees.PopulateTreeData()
end

local function OnSettingChanged(event)
    UpdateSetting(event.setting)
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_event(defines.events.on_runtime_mod_setting_changed, OnSettingChanged)
script.on_event(defines.events.on_entity_died, OnEntityDied)

remote.add_interface("biter_reincarnation",
{
    get_random_tree_type_for_position = function(surface, position)
        return Trees.GetRandomTreeTypeForPosition(surface, position)
    end,
    add_random_tile_based_tree_near_position = function(surface, position, distance)
        return Trees.AddRandomTileBasedTreeNearPosition(surface, position, distance)
    end,
    add_tree_fire_to_position = function(surface, position)
        return Trees.AddTreeFireToPosition(surface, position)
    end
})

--TESTIGN REMOVE ME
--[[script.on_nth_tick(240, function()
    OnStartup()
    script.on_nth_tick(240, nil)
end)]]