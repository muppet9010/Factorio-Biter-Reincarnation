local TreeData = require("tree-data")
local TileData = require("tile_data")

local logNonPositives = false
local logPositives = false
--log(serpent.block(TreeData))
--log(serpent.block(TileData))


local function GetRandomFloatInRange(lower, upper)
    return lower + math.random() * (upper - lower);
end


local function GetTreeTypeForTileData(tileData)
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
        if logNonPositives then game.print("No tree found for conditions: tile: " .. tileData.name .. "   temp: " .. tileTemp .. "    moisture: " .. tileMoisture) end
        return nil
    end
    if logPositives then game.print("trees found for conditions: tile: " .. tileData.name .. "   temp: " .. tileTemp .. "    moisture: " .. tileMoisture) end

    local selectedTree = suitableTrees[math.random(1, #suitableTrees)]
    return selectedTree.name
end


local function AddTileBasedTreeToPosition(surface, position)
    local tile = surface.get_tile(position)
    local tileData = TileData[tile.name]
    if tileData == nil then
        tile = tile.hidden_tile
        tileData = TileData[tile.name]
    end
    local treeType = GetTreeTypeForTileData(tileData)
    if treeType == nil then
        if logNonPositives then game.print("no tree was found") end
        return
    end
    local newPosition = surface.find_non_colliding_position(treeType, position, 2, 0.3)
    if newPosition == nil then
        if logNonPositives then game.print("No position for new tree found") end
        return
    end
    local newTree = surface.create_entity{name=treeType, position=newPosition, force="neutral"}
    if newTree == nil then
        game.print("Failed to create tree at found position")
        return
    end
    if logPositives then game.print("tree added successfully, type: " .. treeType .. "    position: " .. newPosition.x .. ", " .. newPosition.y) end
end


local function AddTreeFireToPosition(surface, targetPosition)
    surface.create_entity{name="fire-flame-on-tree", position=targetPosition}
end


local function OnEntityDied(event)
    local diedEntity = event.entity
    if diedEntity.force ~= game.forces.enemy then return end
    if diedEntity.type ~= "unit" then return end
    local surface = diedEntity.surface
    local targetPosition = diedEntity.position
    AddTileBasedTreeToPosition(surface, targetPosition)
    if math.random(1,100) == 1 then
        AddTreeFireToPosition(surface, targetPosition)
    end
end


script.on_event(defines.events.on_entity_died, OnEntityDied)
