local SharedData = {}
local RandomChance = require("utility.functions.random-chance")

--- Makes a placement version name of the main entity name.
---@param name string
---@return string
local MakePlacementName = function(name)
    return "biter_reincarnation_" .. name .. "_placement"
end

---@class RockTypeChance
---@field name string # Name of the actual rock entity.
---@field chance double # Normalised chance value across all rock types.
---@field placementName string # The name of the special placement test entity.

---@type RockTypeChance[]
SharedData.RockTypes = {
    { name = "rock-huge", chance = 20 },
    { name = "rock-big", chance = 40 },
    { name = "sand-rock-big", chance = 40 }
}
for _, rockType in pairs(SharedData.RockTypes) do
    rockType.placementName = MakePlacementName(rockType.name)
end
RandomChance.NormaliseChanceList(SharedData.RockTypes, "chance", false)

return SharedData
