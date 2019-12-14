local Trees = require("scripts/trees")
local Reincarnation = require("scripts/reincarnation")
local Events = require("utility/events")
local EventScheduler = require("utility/event-scheduler")

local function CreateGlobals()
    Trees.CreateGlobals()
    Reincarnation.CreateGlobals()
end

local function OnLoad()
    Reincarnation.OnLoad()
end

local function OnStartup()
    CreateGlobals()
    OnLoad()

    Reincarnation.OnStartup()
    Trees.OnStartup()
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_load(OnLoad)
Events.RegisterEvent(defines.events.on_runtime_mod_setting_changed)
--Events.RegisterEvent(defines.events.on_entity_damaged, "TypeIsUnit", {{filter = "type", type = "unit"}})
Events.RegisterEvent(defines.events.on_entity_died, "TypeIsUnit", {{filter = "type", type = "unit"}})
EventScheduler.RegisterScheduler()
