local Utils = require("utility/utils")
local SharedData = require("shared-data")

for _, rockType in pairs(SharedData.RockTypes) do
    local name, placementName = rockType.name, rockType.placementName
    local origPrototype = data.raw["simple-entity"][name]
    data:extend({Utils.CreateLandPlacementTestEntityPrototype(origPrototype, placementName, "other")})
end
