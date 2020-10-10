local Reincarnation = require("scripts/reincarnation")
local EventScheduler = require("utility/event-scheduler")

local function CreateGlobals()
    Reincarnation.CreateGlobals()
end

local function OnLoad()
    Reincarnation.OnLoad()
end

local function OnStartup()
    CreateGlobals()
    OnLoad()

    Reincarnation.OnStartup()
end

script.on_init(OnStartup)
script.on_configuration_changed(OnStartup)
script.on_load(OnLoad)
EventScheduler.RegisterScheduler()
