local Utils = require("utility/utils")
local Events = require("utility/events")
local EventScheduler = require("utility/event-scheduler")
local Logging = require("utility/logging")
local BiomeTrees = require("utility/functions/biome-trees")
local SharedData = require("shared-data")
local Reincarnation = {}

local maxQueueCyclesPerSecond = 60
local reincarnationType = {tree = "tree", burningTree = "burningTree", rock = "rock", cliff = "cliff"}
local unitsIgnored = {character = "character", compilatron = "compilatron"}
local movableEntityTypes = {unit = "unit", character = "character", car = "car", tank = "tank", ["spider-vehicle"] = "spider-vehicle"}

Reincarnation.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_runtime_mod_setting_changed, "Reincarnation.UpdateSetting", Reincarnation.UpdateSetting)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "Reincarnation.OnEntityDiedUnit", Reincarnation.OnEntityDiedUnit, "TypeIsUnit", {{filter = "type", type = "unit"}})
    EventScheduler.RegisterScheduledEventType("Reincarnation.ProcessReincarnationQueue", Reincarnation.ProcessReincarnationQueue)
end

Reincarnation.OnStartup = function()
    Reincarnation.UpdateSetting(nil)
    --Do at an offset from 0 to try and avoid bunching on other scheduled things ticks
    if not EventScheduler.IsEventScheduled("Reincarnation.ProcessReincarnationQueue", nil, nil) then
        EventScheduler.ScheduleEvent(6 + game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    end
end

Reincarnation.CreateGlobals = function()
    global.reincarantionChanceList = global.reincarantionChanceList or {}
    global.largeReincarnationsPush = global.largeReincarnationsPush or false
    global.rawTreeOnDeathChance = global.rawTreeOnDeathChance or 0
    global.rawBurningTreeOnDeathChance = global.rawBurningTreeOnDeathChance or 0
    global.rawRockOnDeathChance = global.rawRockOnDeathChance or 0
    global.rawCliffOnDeathChance = global.rawCliffOnDeathChance or 0
    --global.rawExplosionOnDeathChance = global.rawExplosionOnDeathChance or 0
    --global.rawWaterOnDeathChance = global.rawWaterOnDeathChance or 0
    --global.rawLandfillOnDeathChance = global.rawLandfillOnDeathChance or 0
    global.reincarnationQueue = global.reincarnationQueue or {}
    global.reincarnationQueueProcessDelay = global.reincarnationQueueProcessDelay or 0
    global.reincarnationQueueToDoPerSecond = global.reincarnationQueueToDoPerSecond or 0
    global.reincarnationQueueDoneThisSecond = global.reincarnationQueueDoneThisSecond or 0
    global.reincarnationQueueCyclesPerSecond = global.reincarnationQueueCyclesPerSecond or 0
    global.reincarnationQueueCyclesDoneThisSecond = global.reincarnationQueueCyclesDoneThisSecond or 0
    global.maxTicksWaitForReincarnation = global.maxTicksWaitForReincarnation or 0
end

Reincarnation.UpdateSetting = function(event)
    local settingName
    if event ~= nil then
        settingName = event.setting
    end

    if settingName == "biter_reincarnation-turn_to_tree_chance_percent" or settingName == nil then
        global.rawTreeOnDeathChance = tonumber(settings.global["biter_reincarnation-turn_to_tree_chance_percent"].value) / 100
    end

    if settingName == "biter_reincarnation-turn_to_burning_tree_chance_percent" or settingName == nil then
        global.rawBurningTreeOnDeathChance = tonumber(settings.global["biter_reincarnation-turn_to_burning_tree_chance_percent"].value) / 100
    end

    if settingName == "biter_reincarnation-turn_to_rock_chance_percent" or settingName == nil then
        global.rawRockOnDeathChance = tonumber(settings.global["biter_reincarnation-turn_to_rock_chance_percent"].value) / 100
    end

    if settingName == "biter_reincarnation-turn_to_cliff_chance_percent" or settingName == nil then
        global.rawCliffOnDeathChance = tonumber(settings.global["biter_reincarnation-turn_to_cliff_chance_percent"].value) / 100
    end

    --if settingName == "turn-to-explosion-chance-percent" or settingName == nil then
    --    global.rawExplosionOnDeathChance = tonumber(settings.global["turn-to-explosion-chance-percent"].value) / 100
    --end

    --if settingName == "turn-to-water-chance-percent" or settingName == nil then
    --    global.rawWaterOnDeathChance = tonumber(settings.global["turn-to-water-chance-percent"].value) / 100
    --end

    --if settingName == "turn-to-landfill-chance-percent" or settingName == nil then
    --    global.rawLandfillOnDeathChance = tonumber(settings.global["turn-to-landfill-chance-percent"].value) / 100
    --end

    if settingName == "biter_reincarnation-large_reincarnations_push" or settingName == nil then
        global.largeReincarnationsPush = settings.global["biter_reincarnation-large_reincarnations_push"].value
    end

    if settingName == "biter_reincarnation-max_reincarnations_per_second" or settingName == nil then
        local perSecond = settings.global["biter_reincarnation-max_reincarnations_per_second"].value
        local cyclesPerSecond = math.min(perSecond, maxQueueCyclesPerSecond)
        global.reincarnationQueueToDoPerSecond = perSecond
        global.reincarnationQueueCyclesPerSecond = cyclesPerSecond
        global.reincarnationQueueProcessDelay = math.floor(60 / cyclesPerSecond)
    end

    if settingName == "biter_reincarnation-max_seconds_wait_for_reincarnation" or settingName == nil then
        global.maxTicksWaitForReincarnation = settings.global["biter_reincarnation-max_seconds_wait_for_reincarnation"].value * 60
    end

    local reincarantionChanceList = {
        {name = reincarnationType.tree, chance = global.rawTreeOnDeathChance},
        {name = reincarnationType.burningTree, chance = global.rawBurningTreeOnDeathChance},
        {name = reincarnationType.rock, chance = global.rawRockOnDeathChance},
        {name = reincarnationType.cliff, chance = global.rawCliffOnDeathChance}
    }
    global.reincarantionChanceList = Utils.NormaliseChanceList(reincarantionChanceList, "chance", true)
end

Reincarnation.ProcessReincarnationQueue = function()
    EventScheduler.ScheduleEvent(game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    local debug = false
    Logging.Log("", debug)

    local doneThisCycle = 0
    if global.reincarnationQueueCyclesDoneThisSecond >= global.reincarnationQueueCyclesPerSecond then
        Logging.Log("reseting current global counts", debug)
        global.reincarnationQueueDoneThisSecond = 0
        global.reincarnationQueueCyclesDoneThisSecond = 0
    end
    local toDoThisCycle = math.floor((global.reincarnationQueueToDoPerSecond - global.reincarnationQueueDoneThisSecond) / (global.reincarnationQueueCyclesPerSecond - global.reincarnationQueueCyclesDoneThisSecond))
    Logging.Log("toDoThisCycle: " .. toDoThisCycle .. " reached via...", debug)
    Logging.Log("math.floor((" .. global.reincarnationQueueToDoPerSecond .. " - " .. global.reincarnationQueueDoneThisSecond .. ") / (" .. global.reincarnationQueueCyclesPerSecond .. " - " .. global.reincarnationQueueCyclesDoneThisSecond .. "))", debug)
    global.reincarnationQueueCyclesDoneThisSecond = global.reincarnationQueueCyclesDoneThisSecond + 1
    for k, details in pairs(global.reincarnationQueue) do
        table.remove(global.reincarnationQueue, k)
        if details.loggedTick + global.maxTicksWaitForReincarnation >= game.tick then
            local surface, targetPosition, type = details.surface, details.position, details.type
            if type == reincarnationType.tree then
                BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
            elseif type == reincarnationType.burningTree then
                local createdTree = BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
                if createdTree ~= nil then
                    targetPosition = createdTree.position
                end
                Reincarnation.AddTreeFireToPosition(surface, targetPosition)
            elseif type == reincarnationType.rock then
                Reincarnation.AddRockNearPosition(surface, targetPosition)
            elseif type == reincarnationType.cliff then
                --TODO
            else
                game.print("TODO: " .. tostring(type))
            end
            doneThisCycle = doneThisCycle + 1
            global.reincarnationQueueDoneThisSecond = global.reincarnationQueueDoneThisSecond + 1
            Logging.Log("1 reincarnation done", debug)
        end
        if doneThisCycle >= toDoThisCycle then
            return
        end
    end
end

Reincarnation.OnEntityDiedUnit = function(event)
    local entity = event.entity
    if not entity.has_flag("breaths-air") then
        return
    end
    if unitsIgnored[entity.name] then
        return
    end

    local surface = entity.surface
    local targetPosition = entity.position
    local type = Utils.GetRandomEntryFromNormalisedDataSet(global.reincarantionChanceList, "chance")
    table.insert(global.reincarnationQueue, {loggedTick = event.tick, surface = surface, position = targetPosition, type = type.name})
end

Reincarnation.AddTreeFireToPosition = function(surface, targetPosition)
    --make 2 lots of fire to ensure the tree catches fire
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition, raise_built = true}
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition, raise_built = true}
end

Reincarnation.AddRockNearPosition = function(surface, targetPosition)
    local debug = true
    local rockType = Utils.GetRandomEntryFromNormalisedDataSet(SharedData.RockTypes, "chance")

    local newPosition = surface.find_non_colliding_position(rockType.name, targetPosition, 2, 0.2)
    local displaceRequired = false
    if newPosition == nil then
        newPosition = surface.find_non_colliding_position(rockType.placementName, targetPosition, 2, 0.2)
        displaceRequired = true
    end
    if newPosition == nil then
        Logging.LogPrint("No position for new rock found", debug)
        return nil
    end

    local newRock = surface.create_entity {name = rockType.name, position = newPosition, force = "neutral", raise_built = true}
    if newRock == nil then
        Logging.LogPrint("Failed to create rock at found position")
        return nil
    end

    if displaceRequired then
        for _, entity in pairs(Utils.ReturnAllObjectsInArea(surface, newRock.bounding_box, true, nil, true, true, {newRock})) do
            local entityMoved = false
            if global.largeReincarnationsPush then
                if movableEntityTypes[entity.type] ~= nil then
                    local entityNewPosition = surface.find_non_colliding_position(entity.name, entity.position, 2, 0.1)
                    if entityNewPosition ~= nil then
                        entity.teleport(entityNewPosition)
                        entityMoved = true
                    end
                end
                if not entityMoved then
                    entity.die("neutral", newRock)
                end
            end
        end
    end
end

return Reincarnation
