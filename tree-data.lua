--Raw data lifted from base\prototypes\entity\demo-trees.lua, version 17.5


local treeDetails = {}
local function AddTree(type, identifier, temperature_optimal, temperature_range, water_optimal, water_range)
    local treeDetail = {}
    treeDetail.name = "tree-0" .. type
    if identifier ~= nil then
        treeDetail.name = treeDetail.name .. "-" .. identifier
    end
    treeDetail.tempRange = {
        temperature_optimal - (temperature_range * 1.5),
        temperature_optimal + (temperature_range * 1.5)
    }
    treeDetail.moistureRange = {
        water_optimal - (water_range * 1.5),
        water_optimal + (water_range * 1.5)
    }
    treeDetails[treeDetail.name] = treeDetail
end






----------------- Green Trees
-- olive green trees.  seem to like desert edges
AddTree(1, nil, 30, 5, 0.75, 0.25)

-- lightish green trees
-- changed these around so they no longer appear in the middle of deserts
AddTree(2, nil, 17, 7, 0.65, 0.1)
AddTree(3, nil, 25, 5, 0.8, 0.1)

-- dark bluish green trees
-- these like muddy and grassy areas
-- might want to reduce tree noise influence a little bit still
AddTree(4, nil, 12, 7, 0.6, 0.2)

-- bright green tree
-- likes moisture
-- might want to reduce static influence more when adding other trees back in
AddTree(5, nil, 12, 7, 0.8, 0.2)
AddTree(9, nil, 30, 5, 0.45, 0.05)

----------------- desert edge trees?
-- multicolored pastel trees
-- small clumps in the desert
AddTree(2, "red", 17, 7, 0.45, 0.05)
AddTree(7, nil, 25, 10, 0.20, 0.05)

----------------- brown desert trees
-- let's try to avoid placing these in large clumps
AddTree(6, nil, 22, 13, 0.10, 0.05)
AddTree(6, "brown", 22, 13, 0.10, 0.05)
AddTree(9, "brown", 25, 10, 0.20, 0.05)
AddTree(9, "red", 15, 10, 0.20, 0.05)

----------------- Desert trees
AddTree(8, nil, 20, 5, 0.10, 0.10)
AddTree(8, "brown", 20, 5, 0.10, 0.10)
AddTree(8, "red", -5, 5, 0.05, 0.05)

----------------- Dead trees
local deadTress = {"dry-tree", "dead-tree-desert", "dead-grey-trunk", "dead-dry-hairy-tree", "dry-hairy-tree"}
for _, name in pairs(deadTress) do
    treeDetails[name] = {
        name = name,
        tempRange = {
            20,
            35
        },
        moistureRange = {
            0,
            10
        }
    }
end


return treeDetails
