local SharedData = {}
local Utils = require("utility/utils")

SharedData.RockTypes = {
    {name = "rock-huge", chance = 20},
    {name = "rock-big", chance = 40},
    {name = "sand-rock-big", chance = 40}
}
for _, rockType in pairs(SharedData.RockTypes) do
    rockType.placementName = "biter_reincarnation_" .. rockType.name .. "_placement"
end
Utils.NormaliseChanceList(SharedData.RockTypes, "chance", false)

return SharedData
