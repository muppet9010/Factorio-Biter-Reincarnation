local Trees = require("scripts/trees")

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
    if math.random() <= global.treeOnDeathChance then
        Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
    elseif math.random() <= global.burningTreeOnDeathChance then
        local createdTree = Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
        if createdTree ~= nil then
            Trees.AddTreeFireToPosition(createdTree.surface, createdTree.position)
        end
    end
end

local function UpdateSetting(settingName)
    if settingName == "burst-into-flames-chance-percent" or settingName == nil then
        global.burningTreeOnDeathChance = tonumber(settings.global["burst-into-flames-chance-percent"].value) / 100
    end
    if settingName == "turn-to-tree-chance-percent" or settingName == nil then
        global.treeOnDeathChance = tonumber(settings.global["turn-to-tree-chance-percent"].value) / 100
    end
end

local function CreateGlobals()
    global.treeOnDeathChance = global.treeOnDeathChance or 0
    global.burningTreeOnDeathChance = global.burningTreeOnDeathChance or 0
end

local function OnStartup()
    CreateGlobals()
    UpdateSetting(nil)
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