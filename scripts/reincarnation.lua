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
    global.reincarnationQueueProcessedPerSecond = global.reincarnationQueueProcessedPerSecond or 0
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
        global.reincarnationQueueProcessedPerSecond = perSecond
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
    local tasksThisCycle = math.floor((global.reincarnationQueueProcessedPerSecond - global.reincarnationQueueDoneThisSecond) / (global.reincarnationQueueCyclesPerSecond - global.reincarnationQueueCyclesDoneThisSecond))
    Logging.Log("tasksThisCycle: " .. tasksThisCycle .. " reached via...", debug)
    Logging.Log("math.floor((" .. global.reincarnationQueueProcessedPerSecond .. " - " .. global.reincarnationQueueDoneThisSecond .. ") / (" .. global.reincarnationQueueCyclesPerSecond .. " - " .. global.reincarnationQueueCyclesDoneThisSecond .. "))", debug)
    global.reincarnationQueueCyclesDoneThisSecond = global.reincarnationQueueCyclesDoneThisSecond + 1
    for k, details in pairs(global.reincarnationQueue) do
        table.remove(global.reincarnationQueue, k)
        if details.loggedTick + global.maxTicksWaitForReincarnation >= game.tick then
            local surface, targetPosition, type, orientation = details.surface, details.position, details.type, details.orientation
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
                Reincarnation.AddCliffNearPosition(surface, targetPosition, orientation)
            else
                error("unsupported type: " .. type)
            end
            doneThisCycle = doneThisCycle + 1
            global.reincarnationQueueDoneThisSecond = global.reincarnationQueueDoneThisSecond + 1
            Logging.Log("1 reincarnation done", debug)
        end
        if doneThisCycle >= tasksThisCycle then
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

    local details = {
        loggedTick = event.tick,
        surface = entity.surface,
        position = entity.position,
        type = Utils.GetRandomEntryFromNormalisedDataSet(global.reincarantionChanceList, "chance").name,
        orientation = entity.orientation
    }
    table.insert(global.reincarnationQueue, details)
end

Reincarnation.AddTreeFireToPosition = function(surface, targetPosition)
    --make 2 lots of fire to ensure the tree catches fire
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition, raise_built = true}
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition, raise_built = true}
end

Reincarnation.AddRockNearPosition = function(surface, targetPosition)
    local debug = true
    local typeData = Utils.GetRandomEntryFromNormalisedDataSet(SharedData.RockTypes, "chance")

    local newPosition = surface.find_non_colliding_position(typeData.name, targetPosition, 2, 0.2)
    local displaceRequired = false
    if newPosition == nil then
        newPosition = surface.find_non_colliding_position(typeData.placementName, targetPosition, 2, 0.2)
        displaceRequired = true
    end
    if newPosition == nil then
        Logging.LogPrint("No position for new rock found", debug)
        return nil
    end

    local rockEntity = surface.create_entity {name = typeData.name, position = newPosition, force = "neutral", raise_built = true}
    if rockEntity == nil then
        Logging.LogPrint("Failed to create rock at found position")
        return nil
    end

    if displaceRequired then
        Reincarnation.DisplaceEntitiesInBoundingBox(surface, rockEntity)
    end
end

Reincarnation.DisplaceEntitiesInBoundingBox = function(surface, createdEntity)
    for _, entity in pairs(Utils.ReturnAllObjectsInArea(surface, createdEntity.bounding_box, true, nil, true, true, {createdEntity})) do
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
                entity.die("neutral", createdEntity)
            end
        end
    end
end

Reincarnation.AddCliffNearPosition = function(surface, targetPosition, orientation)
    local cliffPositionCenter = {
        x = (math.floor(targetPosition.x / 4) * 4) + 2,
        y = (math.floor(targetPosition.y / 4) * 4) + 2.5
    }

    local cliffPositionLeft, cliffPositionRight, generalFacing, cliffTypeLeft, cliffTypeRight
    if orientation >= 0.875 or orientation < 0.125 then
        --biter heading northish
        generalFacing = "north-south"
        cliffTypeLeft = "none-to-west"
        cliffTypeRight = "east-to-none"
    elseif orientation >= 0.125 and orientation < 0.375 then
        --biter heading eastish
        generalFacing = "east-west"
        cliffTypeLeft = "none-to-north"
        cliffTypeRight = "none-to-west"
    elseif orientation >= 0.375 and orientation < 0.625 then
        --biter heading southish
        generalFacing = "north-south"
        cliffTypeLeft = "west-to-none"
        cliffTypeRight = "none-to-east"
    elseif orientation >= 0.625 and orientation < 0.875 then
        --biter heading westish
        generalFacing = "east-west"
        cliffTypeLeft = "north-to-none"
        cliffTypeRight = "east-to-none"
    end
    if generalFacing == "north-south" then
        if cliffPositionCenter.x - targetPosition.x < 0 then
            cliffPositionRight = cliffPositionCenter
            cliffPositionLeft = {x = cliffPositionCenter.x + 4, y = cliffPositionCenter.y}
        else
            cliffPositionLeft = cliffPositionCenter
            cliffPositionRight = {x = cliffPositionCenter.x - 4, y = cliffPositionCenter.y}
        end
        if cliffPositionCenter.y - targetPosition.y < -2 then
            cliffPositionRight.y = cliffPositionRight.y + 4
            cliffPositionLeft.y = cliffPositionLeft.y + 4
        end
    elseif generalFacing == "east-west" then
        if cliffPositionCenter.y - targetPosition.y < 0 then
            cliffPositionRight = cliffPositionCenter
            cliffPositionLeft = {y = cliffPositionCenter.y + 4, x = cliffPositionCenter.x}
        else
            cliffPositionLeft = cliffPositionCenter
            cliffPositionRight = {y = cliffPositionCenter.y - 4, x = cliffPositionCenter.x}
        end
        if cliffPositionCenter.x - targetPosition.x < -2 then
            cliffPositionRight.x = cliffPositionRight.x + 4
            cliffPositionLeft.x = cliffPositionLeft.x + 4
        end
    end

    local cliffEntityLeft = surface.create_entity {name = "cliff", position = cliffPositionLeft, force = "neutral", cliff_orientation = cliffTypeLeft, raise_built = true}
    local cliffEntityRight = surface.create_entity {name = "cliff", position = cliffPositionRight, force = "neutral", cliff_orientation = cliffTypeRight, raise_built = true}

    if cliffEntityLeft == nil or not cliffEntityLeft.valid or cliffEntityRight == nil or not cliffEntityRight.valid then
        -- One of the cliffs isn't good so remove both silently.
        if cliffEntityLeft ~= nil and cliffEntityLeft.valid then
            cliffEntityLeft.destroy(false, false)
        end
        if cliffEntityRight ~= nil and cliffEntityRight.valid then
            cliffEntityRight.destroy(false, false)
        end
    end

    Reincarnation.DisplaceEntitiesInBoundingBox(surface, cliffEntityLeft)
    Reincarnation.DisplaceEntitiesInBoundingBox(surface, cliffEntityRight)
end

return Reincarnation
