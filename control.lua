local Trees = require("scripts/trees")
local Utils = require("utility/utils")

local function BiterDied(entity)
    local surface = entity.surface
    local targetPosition = entity.position
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
            Trees.AddTreeFireToPosition(surface, targetPosition)
        end
    end
end

local function OnEntityDamaged(event)
    local entity = event.entity
    if entity.health > 0 then
        return
    end
    if entity.force ~= game.forces.enemy then
        return
    end
    if entity.type ~= "unit" then
        return
    end

    if global.preventBitersReincarnatingFromFireDeath and (event.damage_type.name == "fire" or event.damage_type.name == "cold") then
        return
    end
    BiterDied(entity)
end

local function UpdateSetting(settingName)
    if settingName == "burst-into-flames-chance-percent" or settingName == nil then
        global.burningTreeOnDeathChance = tonumber(settings.global["burst-into-flames-chance-percent"].value) / 100
    end
    if settingName == "turn-to-tree-chance-percent" or settingName == nil then
        global.treeOnDeathChance = tonumber(settings.global["turn-to-tree-chance-percent"].value) / 100
    end
    if settingName == "prevent-biters-reincarnating-from-fire-death" or settingName == nil then
        global.preventBitersReincarnatingFromFireDeath = settings.global["prevent-biters-reincarnating-from-fire-death"].value
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
    global.preventBitersReincarnatingFromFireDeath = global.preventBitersReincarnatingFromFireDeath or false
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
script.on_event(defines.events.on_entity_damaged, OnEntityDamaged)

remote.add_interface(
    "biter_reincarnation",
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
    }
)
