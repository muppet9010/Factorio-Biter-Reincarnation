local PrototypeUtils = require("utility.helper-utils.prototype-utils-data-stage")
local SharedData = require("shared-data")

for _, rockType in pairs(SharedData.RockTypes) do
    local name, placementName = rockType.name, rockType.placementName
    local origPrototype = data.raw["simple-entity"][name]
    data:extend({ PrototypeUtils.CreateLandPlacementTestEntityPrototype(origPrototype, placementName, "other") })
end
