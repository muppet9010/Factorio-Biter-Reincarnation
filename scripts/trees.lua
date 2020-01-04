local TileData = require("scripts/tile_data")
local Utils = require("utility/utils")

local Trees = {}
local logNonPositives = false
local logPositives = false
local logData = false

Trees.CreateGlobals = function()
    global.treeData = global.treeData or {}
end

Trees.OnStartup = function()
    remote.remove_interface("biter_reincarnation")
    remote.add_interface(
        "biter_reincarnation",
        {
            get_random_tree_type_for_position = function(surface, position)
                return Trees.GetRandomTreeTypeForPosition(surface, position)
            end,
            add_random_tile_based_tree_near_position = function(surface, position, distance)
                return Trees.AddTileBasedTreeNearPosition(surface, position, distance)
            end,
            add_tree_fire_to_position = function(surface, position)
                return Trees.AddTreeFireToPosition(surface, position)
            end
        }
    )
    Trees.PopulateTreeData()
end

local function AddTree(name, temperature_optimal, temperature_range, water_optimal, water_range, probability)
    local treeDetail = {}
    treeDetail.name = name
    treeDetail.tempRange = {
        temperature_optimal - (temperature_range * 1.5),
        temperature_optimal + (temperature_range * 1.5)
    }
    treeDetail.moistureRange = {
        water_optimal - (water_range * 1.5),
        water_optimal + (water_range * 1.5)
    }
    treeDetail.probability = probability
    global.treeData[treeDetail.name] = treeDetail
end

Trees.PopulateTreeData = function()
    global.treeData = {}
    for _, prototype in pairs(game.entity_prototypes) do
        if prototype.type == "tree" and prototype.autoplace_specification ~= nil then
            local autoplace = nil
            for _, peak in pairs(prototype.autoplace_specification.peaks) do
                if peak.temperature_optimal ~= nil then
                    autoplace = peak
                end
            end
            if autoplace ~= nil then
                AddTree(prototype.name, autoplace.temperature_optimal, autoplace.temperature_range, autoplace.water_optimal, autoplace.water_range, prototype.autoplace_specification.max_probability)
            end
        end
    end
    if logData then
        log(serpent.block(global.treeData))
        log(serpent.block(TileData))
    end
end

local function GetRandomTreeTypeForTileData(tileData)
    if tileData.type == "water" or tileData.type == "no-trees" then
        return nil
    end
    local rangeInt = math.random(1, #tileData.tempRanges)
    local tempRange = tileData.tempRanges[rangeInt]
    local moistureRange = tileData.moistureRanges[rangeInt]
    local tempScaleMultiplyer = Utils.GetRandomFloatInRange(tempRange[1], tempRange[2])
    local tileTemp = math.max(5, (tempScaleMultiplyer * 35))
    local tileMoisture = Utils.GetRandomFloatInRange(moistureRange[1], moistureRange[2])

    local suitableTrees = {}
    local currentChance = 0
    for _, tree in pairs(global.treeData) do
        if tree.tempRange[1] <= tileTemp and tree.tempRange[2] >= tileTemp and tree.moistureRange[1] <= tileMoisture and tree.moistureRange[2] >= tileMoisture then
            local treeEntry = {
                chanceStart = currentChance,
                chanceEnd = currentChance + tree.probability,
                tree = tree
            }
            table.insert(suitableTrees, treeEntry)
            currentChance = treeEntry.chanceEnd
        end
    end
    if #suitableTrees == 0 then
        if logNonPositives then
            game.print("No tree found for conditions: tile: " .. tileData.name .. "   temp: " .. tileTemp .. "    moisture: " .. tileMoisture)
        end
        return nil
    end
    if logPositives then
        game.print("trees found for conditions: tile: " .. tileData.name .. "   temp: " .. tileTemp .. "    moisture: " .. tileMoisture)
    end

    local highestChance = suitableTrees[#suitableTrees].chanceEnd
    local chanceValue = math.random() * highestChance
    for _, treeEntry in pairs(suitableTrees) do
        if chanceValue >= treeEntry.chanceStart and chanceValue <= treeEntry.chanceEnd then
            return treeEntry.tree.name
        end
    end

    return nil
end

Trees.GetRandomTreeTypeForPosition = function(surface, position)
    local tile = surface.get_tile(position)
    local tileData = TileData[tile.name]
    if tileData == nil then
        local tileName = tile.hidden_tile
        tileData = TileData[tileName]
        if tileData == nil then
            game.print("Failed to get tile data for ''" .. tostring(tile.name) .. "'' and hidden tile '" .. tostring(tileName) .. "'")
            return
        end
    end
    return GetRandomTreeTypeForTileData(tileData)
end

Trees.AddTileBasedTreeNearPosition = function(surface, position, distance)
    local treeType = Trees.GetRandomTreeTypeForPosition(surface, position)
    if treeType == nil then
        if logNonPositives then
            game.print("no tree was found")
        end
        return
    end
    local newPosition = surface.find_non_colliding_position(treeType, position, distance, 0.2)
    if newPosition == nil then
        if logNonPositives then
            game.print("No position for new tree found")
        end
        return
    end
    local newTree = surface.create_entity {name = treeType, position = newPosition, force = "neutral"}
    if newTree == nil then
        game.print("Failed to create tree at found position")
        return
    end
    if logPositives then
        game.print("tree added successfully, type: " .. treeType .. "    position: " .. newPosition.x .. ", " .. newPosition.y)
    end
    return newTree
end

Trees.AddTreeFireToPosition = function(surface, targetPosition)
    --make 2 lots of fire to ensure the tree catches fire
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition}
    surface.create_entity {name = "fire-flame-on-tree", position = targetPosition}
end

return Trees
