local SharedData = {}
local Utils = require("utility/utils")

local MakePlacementName = function(name)
    return "biter_reincarnation_" .. name .. "_placement"
end

SharedData.RockTypes = {
    {name = "rock-huge", chance = 20},
    {name = "rock-big", chance = 40},
    {name = "sand-rock-big", chance = 40}
}
for _, rockType in pairs(SharedData.RockTypes) do
    rockType.placementName = MakePlacementName(rockType.name)
end
Utils.NormaliseChanceList(SharedData.RockTypes, "chance", false)

return SharedData
