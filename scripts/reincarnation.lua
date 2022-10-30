local Events = require("utility.manager-libraries.events")
local EventScheduler = require("utility.manager-libraries.event-scheduler")
local Logging = require("utility.helper-utils.logging-utils")
local BiomeTrees = require("utility.functions.biome-trees")
local SharedData = require("shared-data")
local RandomChance = require("utility.functions.random-chance")
local EntityUtils = require("utility.helper-utils.entity-utils")
local Reincarnation = {}

---@class ReincarnationChanceEntry
---@field name string
---@field chance double # Normalised chance value.

---@class ReincarnationQueueEntry
---@field loggedTick uint
---@field surface LuaSurface
---@field position MapPosition
---@field type string
---@field orientation double

local MaxQueueCyclesPerSecond = 60
---@enum ReincarnationType
local ReincarnationType = { tree = "tree", burningTree = "burningTree", rock = "rock", cliff = "cliff" }
---@enum UnitsIgnored
local UnitsIgnored = { character = "character", compilatron = "compilatron" }
---@enum MovableEntityTypes
local MovableEntityTypes = { unit = "unit", character = "character", car = "car", tank = "tank", ["spider-vehicle"] = "spider-vehicle" }

local DebugLogging = false

Reincarnation.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_runtime_mod_setting_changed, "Reincarnation.UpdateSetting", Reincarnation.UpdateSetting)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "Reincarnation.OnEntityDiedUnit", Reincarnation.OnEntityDiedUnit, { { filter = "type", type = "unit" } })
    EventScheduler.RegisterScheduledEventType("Reincarnation.ProcessReincarnationQueue", Reincarnation.ProcessReincarnationQueue)
end

Reincarnation.OnStartup = function()
    BiomeTrees.OnStartup()
    Reincarnation.UpdateSetting(nil)
    -- Do at an offset from 0 to try and avoid bunching on other scheduled things ticks
    if not EventScheduler.IsEventScheduledOnce("Reincarnation.ProcessReincarnationQueue", nil, nil) then
        EventScheduler.ScheduleEventOnce(6 + game.tick + global.reincarnationQueueProcessDelay--[[@as uint]] , "Reincarnation.ProcessReincarnationQueue", nil, nil)
    end
end

Reincarnation.CreateGlobals = function()
    global.reincarnationChanceList = global.reincarnationChanceList or {} ---@type ReincarnationChanceEntry[]
    global.largeReincarnationsPush = global.largeReincarnationsPush or false ---@type boolean
    global.rawTreeOnDeathChance = global.rawTreeOnDeathChance or 0 ---@type double
    global.rawBurningTreeOnDeathChance = global.rawBurningTreeOnDeathChance or 0 ---@type double
    global.rawRockOnDeathChance = global.rawRockOnDeathChance or 0 ---@type double
    global.rawCliffOnDeathChance = global.rawCliffOnDeathChance or 0 ---@type double
    global.reincarnationQueue = global.reincarnationQueue or {} ---@type ReincarnationQueueEntry[]
    global.reincarnationQueueProcessDelay = global.reincarnationQueueProcessDelay or 0 ---@type uint
    global.reincarnationQueueProcessedPerSecond = global.reincarnationQueueProcessedPerSecond or 0 ---@type uint
    global.reincarnationQueueDoneThisSecond = global.reincarnationQueueDoneThisSecond or 0 ---@type uint
    global.reincarnationQueueCyclesPerSecond = global.reincarnationQueueCyclesPerSecond or 0 ---@type uint
    global.reincarnationQueueCyclesDoneThisSecond = global.reincarnationQueueCyclesDoneThisSecond or 0 ---@type uint
    global.maxTicksWaitForReincarnation = global.maxTicksWaitForReincarnation or 0 ---@type uint
end

--- Called when a runtime setting is updated.
---@param event on_runtime_mod_setting_changed|nil
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

    if settingName == "biter_reincarnation-large_reincarnations_push" or settingName == nil then
        global.largeReincarnationsPush = settings.global["biter_reincarnation-large_reincarnations_push"].value
    end

    if settingName == "biter_reincarnation-max_reincarnations_per_second" or settingName == nil then
        local perSecond = settings.global["biter_reincarnation-max_reincarnations_per_second"].value
        local cyclesPerSecond = math.min(perSecond, MaxQueueCyclesPerSecond)
        global.reincarnationQueueProcessedPerSecond = perSecond
        global.reincarnationQueueCyclesPerSecond = cyclesPerSecond
        global.reincarnationQueueProcessDelay = math.floor(60 / cyclesPerSecond)
    end

    if settingName == "biter_reincarnation-max_seconds_wait_for_reincarnation" or settingName == nil then
        global.maxTicksWaitForReincarnation = settings.global["biter_reincarnation-max_seconds_wait_for_reincarnation"].value * 60
    end

    global.reincarnationChanceList = {
        { name = ReincarnationType.tree, chance = global.rawTreeOnDeathChance },
        { name = ReincarnationType.burningTree, chance = global.rawBurningTreeOnDeathChance },
        { name = ReincarnationType.rock, chance = global.rawRockOnDeathChance },
        { name = ReincarnationType.cliff, chance = global.rawCliffOnDeathChance }
    }
    RandomChance.NormaliseChanceList(global.reincarnationChanceList, "chance", true)
end

--- Process the reincarnation queue.
Reincarnation.ProcessReincarnationQueue = function()
    EventScheduler.ScheduleEventOnce(game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    if DebugLogging then Logging.ModLog("", false) end

    local doneThisCycle = 0
    if global.reincarnationQueueCyclesDoneThisSecond >= global.reincarnationQueueCyclesPerSecond then
        if DebugLogging then Logging.ModLog("resetting current global counts", false) end
        global.reincarnationQueueDoneThisSecond = 0
        global.reincarnationQueueCyclesDoneThisSecond = 0
    end
    local tasksThisCycle = math.floor((global.reincarnationQueueProcessedPerSecond - global.reincarnationQueueDoneThisSecond) / (global.reincarnationQueueCyclesPerSecond - global.reincarnationQueueCyclesDoneThisSecond))
    if DebugLogging then
        Logging.ModLog("tasksThisCycle: " .. tasksThisCycle .. " reached via...", false)
        Logging.ModLog("math.floor((" .. global.reincarnationQueueProcessedPerSecond .. " - " .. global.reincarnationQueueDoneThisSecond .. ") / (" .. global.reincarnationQueueCyclesPerSecond .. " - " .. global.reincarnationQueueCyclesDoneThisSecond .. "))", false)
    end
    global.reincarnationQueueCyclesDoneThisSecond = global.reincarnationQueueCyclesDoneThisSecond + 1
    for k, details in pairs(global.reincarnationQueue) do
        table.remove(global.reincarnationQueue, k)
        if details.loggedTick + global.maxTicksWaitForReincarnation >= game.tick then
            local surface, targetPosition, type, orientation = details.surface, details.position, details.type, details.orientation
            if surface ~= nil and surface.valid then
                if type == ReincarnationType.tree then
                    BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
                elseif type == ReincarnationType.burningTree then
                    local createdTree = BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
                    if createdTree ~= nil then
                        targetPosition = createdTree.position
                    end
                    Reincarnation.AddTreeFireToPosition(surface, targetPosition)
                elseif type == ReincarnationType.rock then
                    Reincarnation.AddRockNearPosition(surface, targetPosition)
                elseif type == ReincarnationType.cliff then
                    Reincarnation.AddCliffNearPosition(surface, targetPosition, orientation)
                else
                    error("unsupported type: " .. type)
                end
                doneThisCycle = doneThisCycle + 1
                global.reincarnationQueueDoneThisSecond = global.reincarnationQueueDoneThisSecond + 1
                if DebugLogging then Logging.ModLog("1 reincarnation done", false) end
            end
        end
        if doneThisCycle >= tasksThisCycle then
            return
        end
    end
end

--- Called when a unit type entity died.
---@param event on_entity_died
Reincarnation.OnEntityDiedUnit = function(event)
    local entity = event.entity
    if not entity.has_flag("breaths-air") then
        return
    end
    if UnitsIgnored[entity.name] then
        return
    end

    local selectedReincarnationType = RandomChance.GetRandomEntryFromNormalisedDataSet(global.reincarnationChanceList, "chance")
    if selectedReincarnationType == nil then
        return
    end
    ---@type ReincarnationQueueEntry
    local details = {
        loggedTick = event.tick,
        surface = entity.surface,
        position = entity.position,
        type = selectedReincarnationType.name,
        orientation = entity.orientation
    }
    table.insert(global.reincarnationQueue, details)
end

--- Add a fire for a tree at a given position.
---@param surface LuaSurface
---@param targetPosition MapPosition
Reincarnation.AddTreeFireToPosition = function(surface, targetPosition)
    -- Make 2 lots of fire to ensure the tree catches fire
    surface.create_entity { name = "fire-flame-on-tree", position = targetPosition, raise_built = true }
    surface.create_entity { name = "fire-flame-on-tree", position = targetPosition, raise_built = true }
end

--- Add a rock near a position.
---@param surface LuaSurface
---@param targetPosition MapPosition
Reincarnation.AddRockNearPosition = function(surface, targetPosition)
    local typeData = RandomChance.GetRandomEntryFromNormalisedDataSet(SharedData.RockTypes, "chance")

    local newPosition = surface.find_non_colliding_position(typeData.name, targetPosition, 2, 0.2)
    local displaceRequired = false
    if newPosition == nil then
        newPosition = surface.find_non_colliding_position(typeData.placementName, targetPosition, 2, 0.2)
        displaceRequired = true
    end
    if newPosition == nil then
        if DebugLogging then Logging.ModLog("No position for new rock found", true) end
        return
    end

    local rockEntity = surface.create_entity { name = typeData.name, position = newPosition, force = "neutral", raise_built = true }
    if rockEntity == nil then
        Logging.LogPrintWarning("Failed to create rock at found position")
        return
    end

    if displaceRequired then
        Reincarnation.DisplaceEntitiesInBoundingBox(surface, rockEntity)
    end
end

--- Move any teleportable entities in the bounding box of an entity out of the way. Anything non movable is just killed.
---@param surface LuaSurface
---@param createdEntity LuaEntity
Reincarnation.DisplaceEntitiesInBoundingBox = function(surface, createdEntity)
    for _, entity in pairs(EntityUtils.ReturnAllObjectsInArea(surface, createdEntity.bounding_box, true, nil, true, true, { createdEntity })) do
        local entityMoved = false
        if global.largeReincarnationsPush then
            if MovableEntityTypes[entity.type] ~= nil then
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

--- Add cliffs near the target position.
---@param surface LuaSurface
---@param targetPosition MapPosition
---@param orientation double
Reincarnation.AddCliffNearPosition = function(surface, targetPosition, orientation)
    local cliffPositionCenter = {
        x = (math.floor(targetPosition.x / 4) * 4) + 2,
        y = (math.floor(targetPosition.y / 4) * 4) + 2.5
    }

    local cliffPositionLeft, cliffPositionRight, generalFacing, cliffTypeLeft, cliffTypeRight
    if orientation >= 0.875 or orientation < 0.125 then
        -- Biter heading north-ish
        generalFacing = "north-south"
        cliffTypeLeft = "none-to-west"
        cliffTypeRight = "east-to-none"
    elseif orientation >= 0.125 and orientation < 0.375 then
        -- Biter heading east-ish
        generalFacing = "east-west"
        cliffTypeLeft = "none-to-north"
        cliffTypeRight = "none-to-west"
    elseif orientation >= 0.375 and orientation < 0.625 then
        -- Biter heading south-ish
        generalFacing = "north-south"
        cliffTypeLeft = "west-to-none"
        cliffTypeRight = "none-to-east"
    elseif orientation >= 0.625 and orientation < 0.875 then
        -- Biter heading west-ish
        generalFacing = "east-west"
        cliffTypeLeft = "north-to-none"
        cliffTypeRight = "east-to-none"
    end
    if generalFacing == "north-south" then
        if cliffPositionCenter.x - targetPosition.x < 0 then
            cliffPositionRight = cliffPositionCenter
            cliffPositionLeft = { x = cliffPositionCenter.x + 4, y = cliffPositionCenter.y }
        else
            cliffPositionLeft = cliffPositionCenter
            cliffPositionRight = { x = cliffPositionCenter.x - 4, y = cliffPositionCenter.y }
        end
        if cliffPositionCenter.y - targetPosition.y < -2 then
            cliffPositionRight.y = cliffPositionRight.y + 4
            cliffPositionLeft.y = cliffPositionLeft.y + 4
        end
    elseif generalFacing == "east-west" then
        if cliffPositionCenter.y - targetPosition.y < 0 then
            cliffPositionRight = cliffPositionCenter
            cliffPositionLeft = { y = cliffPositionCenter.y + 4, x = cliffPositionCenter.x }
        else
            cliffPositionLeft = cliffPositionCenter
            cliffPositionRight = { y = cliffPositionCenter.y - 4, x = cliffPositionCenter.x }
        end
        if cliffPositionCenter.x - targetPosition.x < -2 then
            cliffPositionRight.x = cliffPositionRight.x + 4
            cliffPositionLeft.x = cliffPositionLeft.x + 4
        end
    end

    local cliffEntityLeft = surface.create_entity { name = "cliff", position = cliffPositionLeft, force = "neutral", cliff_orientation = cliffTypeLeft, raise_built = true }
    local cliffEntityRight = surface.create_entity { name = "cliff", position = cliffPositionRight, force = "neutral", cliff_orientation = cliffTypeRight, raise_built = true }

    if cliffEntityLeft == nil or not cliffEntityLeft.valid or cliffEntityRight == nil or not cliffEntityRight.valid then
        -- One of the cliffs isn't good so remove both silently.
        if cliffEntityLeft ~= nil and cliffEntityLeft.valid then
            cliffEntityLeft.destroy({ do_cliff_correction = false, raise_destroy = false })
            cliffEntityLeft = nil
        end
        if cliffEntityRight ~= nil and cliffEntityRight.valid then
            cliffEntityRight.destroy({ do_cliff_correction = false, raise_destroy = false })
            cliffEntityRight = nil
        end

        if DebugLogging then Logging.ModLog("Cliffs failed to create so removed.", true) end

        -- Don't try to do anything further with the cliffs as it didn't create right.
        return
    end

    Reincarnation.DisplaceEntitiesInBoundingBox(surface, cliffEntityLeft)
    Reincarnation.DisplaceEntitiesInBoundingBox(surface, cliffEntityRight)
end

return Reincarnation
