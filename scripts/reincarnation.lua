local Utils = require("utility/utils")
local Events = require("utility/events")
local EventScheduler = require("utility/event-scheduler")
local Logging = require("utility/logging")
local BiomeTrees = require("utility/functions/biome-trees")

local Reincarnation = {}
local maxQueueCyclesPerSecond = 60

Reincarnation.OnLoad = function()
    Events.RegisterHandlerEvent(defines.events.on_runtime_mod_setting_changed, "Reincarnation.UpdateSetting", Reincarnation.UpdateSetting)
    Events.RegisterHandlerEvent(defines.events.on_entity_died, "Reincarnation.OnEntityDiedUnit", Reincarnation.OnEntityDiedUnit, "TypeIsUnit", {{filter = "type", type = "unit"}})
    EventScheduler.RegisterScheduledEventType("Reincarnation.ProcessReincarnationQueue", Reincarnation.ProcessReincarnationQueue)
end

Reincarnation.OnStartup = function()
    Reincarnation.UpdateSetting(nil)
    --Do at an offset from 0 to try and avoid bunching on other scheduled thigns ticks
    if not EventScheduler.IsEventScheduled("Reincarnation.ProcessReincarnationQueue", nil, nil) then
        EventScheduler.ScheduleEvent(6 + game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    end
end

Reincarnation.CreateGlobals = function()
    global.rawTreeOnDeathChance = global.rawTreeOnDeathChance or 0
    global.chanceTreeOnDeathChance = global.chanceTreeOnDeathChance or 0
    global.rawBurningTreeOnDeathChance = global.rawBurningTreeOnDeathChance or 0
    global.chanceBurningTreeOnDeathChance = global.chanceBurningTreeOnDeathChance or 0
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

    if settingName == "burst-into-flames-chance-percent" or settingName == nil then
        global.rawBurningTreeOnDeathChance = tonumber(settings.global["burst-into-flames-chance-percent"].value) / 100
    end
    if settingName == "turn-to-tree-chance-percent" or settingName == nil then
        global.rawTreeOnDeathChance = tonumber(settings.global["turn-to-tree-chance-percent"].value) / 100
    end
    if settingName == "burst-into-flames-chance-percent" or settingName == "turn-to-tree-chance-percent" or settingName == nil then
        local totalChance = global.rawBurningTreeOnDeathChance + global.rawTreeOnDeathChance
        local multiplier = 1
        if totalChance > 1 then
            multiplier = multiplier / totalChance
        end
        global.chanceBurningTreeOnDeathChance = global.rawBurningTreeOnDeathChance * multiplier
        global.chanceTreeOnDeathChance = global.rawTreeOnDeathChance * multiplier
    end

    if settingName == "max_reincarnations_per_second" or settingName == nil then
        local perSecond = settings.global["max_reincarnations_per_second"].value
        local cyclesPerSecond = math.min(perSecond, maxQueueCyclesPerSecond)
        global.reincarnationQueueToDoPerSecond = perSecond
        global.reincarnationQueueCyclesPerSecond = cyclesPerSecond
        global.reincarnationQueueProcessDelay = math.floor(60 / cyclesPerSecond)
    end

    if settingName == "max_seconds_wait_for_reincarnation" or settingName == nil then
        global.maxTicksWaitForReincarnation = settings.global["max_seconds_wait_for_reincarnation"].value * 60
    end
end

Reincarnation.AddReincarnatonToQueue = function(surface, position, type)
    table.insert(global.reincarnationQueue, {loggedTick = game.tick, surface = surface, position = position, type = type})
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
            if type == "tree" then
                BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
            elseif type == "burningTree" then
                local createdTree = BiomeTrees.AddBiomeTreeNearPosition(surface, targetPosition, 2)
                if createdTree ~= nil then
                    targetPosition = createdTree.position
                end
                Reincarnation.AddTreeFireToPosition(surface, targetPosition)
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

Reincarnation.BiterDied = function(entity)
    local surface = entity.surface
    local targetPosition = entity.position
    local random = math.random()
    local chance = global.chanceTreeOnDeathChance
    if Utils.FuzzyCompareDoubles(random, "<", chance) then
        Reincarnation.AddReincarnatonToQueue(surface, targetPosition, "tree")
    else
        chance = chance + global.chanceBurningTreeOnDeathChance
        if Utils.FuzzyCompareDoubles(random, "<", chance) then
            Reincarnation.AddReincarnatonToQueue(surface, targetPosition, "burningTree")
        end
    end
end

Reincarnation.OnEntityDiedUnit = function(event)
    local entity = event.entity
    if entity.force.name ~= "enemy" then
        return
    end
    Reincarnation.BiterDied(entity)
end

Reincarnation.AddTreeFireToPosition = function(surface, targetPosition)
    --make 2 lots of fire to ensure the tree catches fire
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition}
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition}
end

return Reincarnation
