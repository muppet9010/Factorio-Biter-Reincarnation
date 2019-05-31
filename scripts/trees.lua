local TreeData = require("scripts/tree-data")
local TileData = require("scripts/tile_data")

local Trees = {}
local logNonPositives = false
local logPositives = false

local function GetRandomFloatInRange(lower, upper)
    return lower + math.random() * (upper - lower)
end

local function GetRandomTreeTypeForTileData(tileData)
    if tileData.type == "water" then
        return nil
    end
    local rangeInt = math.random(1, #tileData.tempRanges)
    local tempRange = tileData.tempRanges[rangeInt]
    local moistureRange = tileData.moistureRanges[rangeInt]
    local tempScaleMultiplyer = GetRandomFloatInRange(tempRange[1], tempRange[2])
    local tileTemp = 35 - (tempScaleMultiplyer * 35)
    local tileMoisture = GetRandomFloatInRange(moistureRange[1], moistureRange[2])

    local suitableTrees = {}
    for _, tree in pairs(TreeData) do
        if tree.tempRange[1] <= tileTemp and tree.tempRange[2] >= tileTemp and tree.moistureRange[1] <= tileMoisture and tree.moistureRange[2] >= tileMoisture then
            table.insert(suitableTrees, tree)
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

    local selectedTree = suitableTrees[math.random(1, #suitableTrees)]
    return selectedTree.name
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
    return surface.create_entity {name = "fire-flame-on-tree", position = targetPosition}
end

return Trees