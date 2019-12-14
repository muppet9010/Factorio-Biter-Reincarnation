local Utils = require("utility/utils")
local Events = require("utility/events")
local EventScheduler = require("utility/event-scheduler")
local Trees = require("scripts/trees")
--local Logging = require("utility/logging")
local Reincarnation = {}

Reincarnation.OnLoad = function()
    Events.RegisterHandler(defines.events.on_runtime_mod_setting_changed, "Reincarnation", Reincarnation.UpdateSetting)
    Events.RegisterHandler(defines.events.on_entity_damaged, "Reincarnation", Reincarnation.OnEntityDamagedUnit, "TypeIsUnit")
    EventScheduler.RegisterScheduledEventType("Reincarnation.ProcessReincarnationQueue", Reincarnation.ProcessReincarnationQueue)
end

Reincarnation.OnStartup = function()
    Reincarnation.UpdateSetting(nil)
    if not EventScheduler.IsEventScheduled("Reincarnation.ProcessReincarnationQueue", nil, nil) then
        EventScheduler.ScheduleEvent(3 + game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    end
end

Reincarnation.CreateGlobals = function()
    global.treeOnDeathChance = global.treeOnDeathChance or 0
    global.burningTreeOnDeathChance = global.burningTreeOnDeathChance or 0
    global.preventBitersReincarnatingFromFireDeath = global.preventBitersReincarnatingFromFireDeath or false
    global.reincarnationQueue = global.reincarnationQueue or {}
    global.maxReincarnationsPerSecond = global.maxReincarnationsPerSecond or 0
    global.reincarnationQueueProcessDelay = global.reincarnationQueueProcessDelay or 0
    global.maxTicksWaitForReincarnation = global.maxTicksWaitForReincarnation or 0
end

Reincarnation.UpdateSetting = function(event)
    local settingName
    if event ~= nil then
        settingName = event.setting
    end

    if settingName == "burst-into-flames-chance-percent" or settingName == nil then
        global.burningTreeOnDeathChance = tonumber(settings.global["burst-into-flames-chance-percent"].value) / 100
    end
    if settingName == "turn-to-tree-chance-percent" or settingName == nil then
        global.treeOnDeathChance = tonumber(settings.global["turn-to-tree-chance-percent"].value) / 100
    end
    if settingName == "burst-into-flames-chance-percent" or settingName == "turn-to-tree-chance-percent" or settingName == nil then
        local totalChance = global.burningTreeOnDeathChance + global.treeOnDeathChance
        if totalChance > 1 then
            local multiplier = 1 / totalChance
            global.burningTreeOnDeathChance = global.burningTreeOnDeathChance * multiplier
            global.treeOnDeathChance = global.treeOnDeathChance * multiplier
        end
    end

    if settingName == "prevent-biters-reincarnating-from-fire-death" or settingName == nil then
        global.preventBitersReincarnatingFromFireDeath = settings.global["prevent-biters-reincarnating-from-fire-death"].value
    end

    if settingName == "max_reincarnations_per_second" or settingName == nil then
        global.maxReincarnationsPerSecond = settings.global["max_reincarnations_per_second"].value
        global.reincarnationQueueProcessDelay = 60 / global.maxReincarnationsPerSecond
    end

    if settingName == "max_seconds_wait_for_reincarnation" or settingName == nil then
        global.maxTicksWaitForReincarnation = settings.global["max_seconds_wait_for_reincarnation"].value * 60
    end
end

Reincarnation.AddReincarnatonToQueue = function(surface, position, type)
    table.insert(global.reincarnationQueue, {loggedTick = game.tick, surface = surface, position = position, type = type})
end

Reincarnation.ProcessReincarnationQueue = function()
    EventScheduler.ScheduleEvent(3 + game.tick + global.reincarnationQueueProcessDelay, "Reincarnation.ProcessReincarnationQueue", nil, nil)
    for k, details in pairs(global.reincarnationQueue) do
        table.remove(global.reincarnationQueue, k)
        if details.loggedTick + global.maxTicksWaitForReincarnation >= game.tick then
            local surface, targetPosition, type = details.surface, details.position, details.type
            if type == "tree" then
                Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
            elseif type == "" then
                local createdTree = Trees.AddTileBasedTreeNearPosition(surface, targetPosition, 2)
                if createdTree ~= nil then
                    targetPosition = createdTree.position
                end
                Trees.AddTreeFireToPosition(surface, targetPosition)
            end
            return
        end
    end
end

Reincarnation.BiterDied = function(entity)
    local surface = entity.surface
    local targetPosition = entity.position
    local random = math.random()
    local chance = global.treeOnDeathChance
    if Utils.FuzzyCompareDoubles(random, "<", chance) then
        Reincarnation.AddReincarnatonToQueue(surface, targetPosition, "tree")
    else
        chance = chance + global.burningTreeOnDeathChance
        if Utils.FuzzyCompareDoubles(random, "<", chance) then
            Reincarnation.AddReincarnatonToQueue(surface, targetPosition, "burningTree")
        end
    end
end

Reincarnation.OnEntityDamagedUnit = function(event)
    local entity = event.entity
    if entity.health > 0 then
        return
    end
    if entity.force.name ~= "enemy" then
        return
    end
    if global.preventBitersReincarnatingFromFireDeath and (event.damage_type.name == "fire" or event.damage_type.name == "cold") then
        return
    end
    Reincarnation.BiterDied(entity)
end

return Reincarnation
