--[[
    Used to get tile (biome) appropriate trees, rather than just select any old tree. Means they will generally fit in to the map better, although vanilla forest types don't always fully match the biome they are in.
    Will only nicely handle vanilla and Alien Biomes tiles and trees, modded tiles will get a random tree if they are a land-ish type tile.
    Usage:
        - Require the file at usage locations.
        - Call the BiomeTrees.OnStartup() for script.on_init and script.on_configuration_changed. This will load the meta tables of the mod fresh from the current tiles and trees. This is needed as on large mods it may take a few moments and we don't want to lag the game on first usage.
        - Call the desired public functions when needed. These are the ones at the top of the file without an "_" at the start of the function name.
    Supports specifically coded modded trees with meta data. If a tree has tile restrictions this is used for selection after temp and water, otherwise the tags of tile and tree are checked. This logic comes from supporting alien biomes.
]]
--
-- CODE NOTES: Some of these objects aren't terribly well typed or even named fields. This is a legacy code and doesn't really ever get touched so left as minimal typing for time being.

local TableUtils = require("utility.helper-utils.table-utils")
local LoggingUtils = require("utility.helper-utils.logging-utils")

-- At present these sub files aren't typed at all.
local BaseGameData = require("utility.functions.biome-trees-data.base-game")
local AlienBiomesData = require("utility.functions.biome-trees-data.alien-biomes")

local BiomeTrees = {} ---@class Utility_BiomeTrees

--- Debug testing/logging options. Al should be false in releases.
local LogPlacedNonPositives = false
local LogPlacedPositives = false
local LogSuitableNonPositives = false
local LogSuitablePositives = false
local LogInputData = false
local LogTags = false -- Enable with other logging options to include details about tag checking.

---@class UtilityBiomeTrees_EnvironmentData
---@field moistureRangeAttributeNames UtilityBiomeTrees_MoistureRangeAttributeNames
---@field tileTemperatureCalculationSettings UtilityBiomeTrees_TileTemperatureCalculationSettings
---@field tileData UtilityBiomeTrees_TilesDetails
---@field treesMetaData? UtilityBiomeTrees_TreesMetaData # If non nil then must have contents.
---@field deadTreeNames string[]
---@field randomTreeLastResort string

---@class UtilityBiomeTrees_MoistureRangeAttributeNames
---@field optimal string
---@field range string

---@class UtilityBiomeTrees_TileTemperatureCalculationSettings
---@field scaleMultiplier? double
---@field min? double
---@field max? double

---@alias UtilityBiomeTrees_TreesMetaData table<string, UtilityBiomeTrees_TreeMetaData> # Key'd by tree name.
---@class UtilityBiomeTrees_TreeMetaData
---@field [1] table<string, string> # Tag color string as key and value.
---@field [2] table<string, string> # The names of tiles that the tree can only go on, tile name is the key and value in table.

---@alias UtilityBiomeTrees_TilesDetails table<string, UtilityBiomeTrees_TileDetails> # Key'd by tile name.

---@class UtilityBiomeTrees_TileDetails
---@field name string
---@field type UtilityBiomeTrees_TileType
---@field tempRanges UtilityBiomeTrees_valueRange[]
---@field moistureRanges UtilityBiomeTrees_valueRange[]
---@field tag? string

---@class UtilityBiomeTrees_RawTileData
---@field [1] UtilityBiomeTrees_TileType
---@field [2]? UtilityBiomeTrees_valueRange[] # tempRanges
---@field [3]? UtilityBiomeTrees_valueRange[] # moistureRanges
---@field [4]? string # tag

---@class UtilityBiomeTrees_valueRange
---@field [1] double # Min in this range. Alien biomes is -1 to 1. But likely the game supports any double.
---@field [2] double # Max in this range. Alien biomes is -1 to 1. But likely the game supports any double.

---@class UtilityBiomeTrees_TreeDetails
---@field name string
---@field tempRange UtilityBiomeTrees_valueRange
---@field moistureRange UtilityBiomeTrees_valueRange
---@field probability double
---@field tags? table<string, string> # Tag color string as key and value.
---@field exclusivelyOnNamedTiles? table<string, string> # The names of tiles that the tree can only go on, tile name is the key and value in table.

---@class UtilityBiomeTrees_suitableTree
---@field chanceStart double
---@field chanceEnd double
---@field tree UtilityBiomeTrees_TreeDetails

---@alias UtilityBiomeTrees_TileType "allow-trees"|"water"|"no-trees"

MOD = MOD or {} ---@class MOD
MOD.UTILITYBiomeTrees_TileTreePossibilities = MOD.UTILITYBiomeTrees_TileTreePossibilities or {} ---@type table<string, UtilityBiomeTrees_suitableTree[]> # A table of tile name to its weighted tree possibilities.

----------------------------------------------------------------------------------
--                          PUBLIC FUNCTIONS
----------------------------------------------------------------------------------

--- Called from Factorio script.on_init and script.on_configuration_changed events to parse over the tile and trees and make the lookup tables we'll need at run time.
BiomeTrees.OnStartup = function()
    -- Always recreate on game startup/config changed to handle any mod changed trees, tiles, etc.
    global.UTILITYBIOMETREES = {}
    global.UTILITYBIOMETREES.environmentData = BiomeTrees._GetEnvironmentData() ---@type UtilityBiomeTrees_EnvironmentData
    global.UTILITYBIOMETREES.tileData = global.UTILITYBIOMETREES.environmentData.tileData ---@type UtilityBiomeTrees_TilesDetails
    global.UTILITYBIOMETREES.treeData = BiomeTrees._GetTreeData() ---@type UtilityBiomeTrees_TreeDetails[]
    if LogInputData then
        LoggingUtils.ModLog("\r\n" .. "treeData: \r\n" .. serpent.block(global.UTILITYBIOMETREES.treeData), false)
        LoggingUtils.ModLog("\r\n" .. "tileData: \r\n" .. serpent.block(global.UTILITYBIOMETREES.tileData), false)
    end
end

--- Get a biome appropriate tree's name or nil if one isn't allowed there.
---@param surface LuaSurface
---@param position MapPosition
---@return string|nil treeName
BiomeTrees.GetBiomeTreeName = function(surface, position)
    -- Returns the tree name or nil if tile isn't land type
    local tile = surface.get_tile(position--[[@as TilePosition # handled equally by Factorio in this API function.]] )
    local tileData = global.UTILITYBIOMETREES.tileData[tile.name]
    if tileData == nil then
        local tileName = tile.hidden_tile
        if tileName ~= nil then
            tileData = global.UTILITYBIOMETREES.tileData[tileName]
        end
        if tileData == nil then
            LoggingUtils.ModLog("Failed to get tile data for '" .. tostring(tile.name) .. "' and hidden tile '" .. tostring(tileName) .. "'", true, LogPlacedNonPositives)
            return BiomeTrees.GetRandomTreeLastResort(tile)
        end
    end
    if tileData.type ~= "allow-trees" then
        return nil
    end

    -- Load tree possibilities for this tile.
    local suitableTrees = MOD.UTILITYBiomeTrees_TileTreePossibilities[tileData.name]
    if suitableTrees == nil then
        suitableTrees = BiomeTrees._GetTreePossibilitiesForTileData(tileData)
        MOD.UTILITYBiomeTrees_TileTreePossibilities[tileData.name] = suitableTrees
    end
    if #suitableTrees == 0 then
        return BiomeTrees.GetRandomTreeLastResort(tile)
    end

    -- Find our chance tree for this time.
    local highestChance, treeFound = suitableTrees[#suitableTrees].chanceEnd, false
    local treeName ---@type string
    local chanceValue = math.random() * highestChance
    for _, treeEntry in pairs(suitableTrees) do
        if chanceValue >= treeEntry.chanceStart and chanceValue <= treeEntry.chanceEnd then
            treeName = treeEntry.tree.name
            treeFound = true
            break
        end
    end
    if not treeFound then
        return nil
    end

    return treeName
end

--- Add a biome appropriate tree to a spare space near the target position.
---@param surface LuaSurface
---@param position MapPosition
---@param distance double
---@return LuaEntity|nil createdTree
---@return MapPosition|nil treePosition
---@return string|nil treeName
BiomeTrees.AddBiomeTreeNearPosition = function(surface, position, distance)
    -- Returns the tree entity if one found and created or nil
    local treeName = BiomeTrees.GetBiomeTreeName(surface, position)
    if treeName == nil then
        LoggingUtils.ModLog("no tree was found", true, LogPlacedNonPositives)
        return nil, nil, nil
    end
    local newPosition = surface.find_non_colliding_position(treeName, position, distance, 0.2)
    if newPosition == nil then
        LoggingUtils.ModLog("No position for new tree found", true, LogPlacedNonPositives)
        return nil, nil, nil
    end
    local newTree = surface.create_entity { name = treeName, position = newPosition, force = "neutral", raise_built = true, create_build_effect_smoke = false }
    if newTree == nil then
        LoggingUtils.LogPrintError("Failed to create tree at found position", LogPlacedPositives or LogPlacedNonPositives)
        return nil, nil, nil
    end
    LoggingUtils.ModLog("tree added successfully, name: " .. treeName .. "    position: " .. newPosition.x .. ", " .. newPosition.y, true, LogPlacedPositives)
    return newTree, newPosition, treeName
end

--- Get a random (truly random) dead tree name if the tile allows trees to be placed.
---@param tile LuaTile
---@return string|nil deadTreeName
BiomeTrees.GetRandomDeadTree = function(tile)
    if tile ~= nil and tile.collides_with("player-layer") then
        -- Is a non-land tile
        return nil
    else
        return global.UTILITYBIOMETREES.environmentData.deadTreeNames[math.random(#global.UTILITYBIOMETREES.environmentData.deadTreeNames)]
    end
end

--- Get a random (truly random) alive tree name if the tile allows trees to be placed.
---@param tile LuaTile
---@return string|nil treeName
BiomeTrees.GetTrulyRandomTree = function(tile)
    if tile ~= nil and tile.collides_with("player-layer") then
        -- Is a non-land tile
        return nil
    else
        return global.UTILITYBIOMETREES.treeData[math.random(#global.UTILITYBIOMETREES.treeData)].name
    end
end

--- Get a random (truly random) tree name for the tile type (alive/dead tree), if the tile allows trees to be placed.
---@param tile LuaTile
---@return string|nil treeName
BiomeTrees.GetRandomTreeLastResort = function(tile)
    -- Gets the a tree from the list of last resort based on the mod active.
    if global.UTILITYBIOMETREES.environmentData.randomTreeLastResort == "GetTrulyRandomTree" then
        return BiomeTrees.GetTrulyRandomTree(tile)
    elseif global.UTILITYBIOMETREES.environmentData.randomTreeLastResort == "GetRandomDeadTree" then
        return BiomeTrees.GetRandomDeadTree(tile)
    end
end

----------------------------------------------------------------------------------
--                          PRIVATE FUNCTIONS
----------------------------------------------------------------------------------

--- Return the full weighted tree chances for this tile.
---@param tileData UtilityBiomeTrees_TileDetails
---@return UtilityBiomeTrees_suitableTree[]
BiomeTrees._GetTreePossibilitiesForTileData = function(tileData)
    local suitableTrees = {} ---@type UtilityBiomeTrees_suitableTree[]
    local currentChance = 0
    local treeTempMin, treeTempMax, treeMoistureMin, treeMoistureMax
    local logTileDetails = LogSuitableNonPositives or LogSuitablePositives or LogTags
    if logTileDetails then LoggingUtils.ModLog("\r\n" .. tileData.name, false) end

    -- Try varying decreasing accuracy requirements on the tiles until we find a tree that matches. Generally we find one at accuracy of 1, but old code had this so assume some cases (modded?) this isn't the case and we find one near the ranges. The 0.1 variation is applied to both the upper and lower values and so is equivalent to a 20% total widening of range criteria.
    for rangeAccuracy = 1, 1.5, 0.1 do
        -- For each temp/moisture range of the tile repeat the tree detection logic.
        for rangeNumber = 1, #tileData.tempRanges do
            -- Get the range values based on the degraded accuracy we have resorted too.
            local tileTempRange = tileData.tempRanges[rangeNumber]
            local tileTempMin, tileTempMax = BiomeTrees._CalculateTileTemperature(tileTempRange[1] / rangeAccuracy), BiomeTrees._CalculateTileTemperature(tileTempRange[2] * rangeAccuracy)
            local tileMoistureRange = tileData.moistureRanges[rangeNumber]
            local tileMoistureMin, tileMoistureMax = tileMoistureRange[1] / rangeAccuracy, tileMoistureRange[2] * rangeAccuracy
            if logTileDetails then LoggingUtils.ModLog("Tile Details:" .. "\r\n    tileTempMin: " .. tileTempMin .. "\r\n    tileTempMax: " .. tileTempMax .. "\r\n    tileMoistureMin: " .. tileMoistureMin .. "\r\n    tileMoistureMax: " .. tileMoistureMax, false) end

            for _, tree in pairs(global.UTILITYBIOMETREES.treeData) do
                treeTempMin, treeTempMax, treeMoistureMin, treeMoistureMax = tree.tempRange[1], tree.tempRange[2], tree.moistureRange[1], tree.moistureRange[2]
                if treeTempMin <= tileTempMax and treeTempMax >= tileTempMin and treeMoistureMin <= tileMoistureMax and treeMoistureMax >= tileMoistureMin then
                    local include = false
                    if tree.exclusivelyOnNamedTiles ~= nil then
                        -- As there are exclusive tiles for this tree, only base inclusion on the tile type.
                        if tree.exclusivelyOnNamedTiles[tileData.name] then
                            if LogTags then LoggingUtils.ModLog("exclusive tile type match", false) end
                            include = true
                        end
                    else
                        -- No exclusive tile restrictions so check tags.
                        if tileData.tag == nil then
                            -- No tile restriction tag so can just include.
                            include = true
                        elseif tree.tags ~= nil then
                            -- There are tree restriction tags that need checking.
                            if tree.tags[tileData.tag] then
                                if LogTags then LoggingUtils.ModLog("tile tag: " .. tileData.tag .. "  --- tree tags: " .. TableUtils.TableKeyToCommaString(tree.tags), false) end
                                include = true
                            end
                        end
                    end

                    if (include) then
                        --TODO: this needs to weight the tree probability based on how much of the tile-tree temp and moisture ranges overlap. So a tree that overlaps much more of the tiles ranges should have its tree probability much higher than one that doesn't. As we don;t know where on the tiles range the square actually was in map gen, just that it got that tile.
                        local treeEntry = {
                            chanceStart = currentChance,
                            chanceEnd = currentChance + tree.probability,
                            tree = tree
                        }
                        suitableTrees[#suitableTrees + 1] = treeEntry
                        currentChance = treeEntry.chanceEnd
                    end
                end
            end
        end

        -- If we found some trees on the current accuracy no need to try any others.
        if #suitableTrees > 0 then
            if LogSuitablePositives then LoggingUtils.ModLog(#suitableTrees .. " found on accuracy: " .. rangeAccuracy, false) end
            break
        else
            if LogSuitableNonPositives then LoggingUtils.ModLog(#suitableTrees .. " found on accuracy: " .. rangeAccuracy, false) end
        end
    end

    -- Record the end result if we want it.
    if #suitableTrees == 0 then
        if LogSuitableNonPositives then LoggingUtils.ModLog("No tree found for tile: " .. tileData.name, true) end
    else
        if LogSuitablePositives then
            LoggingUtils.ModLog("trees found for tile: " .. tileData.name, true)
            LoggingUtils.ModLog("suitableTrees: \r\n" .. serpent.block(suitableTrees), false)
        end
    end
    return suitableTrees
end

--- Gets the environment data from the tile prototypes in the current game.
---@return UtilityBiomeTrees_EnvironmentData
BiomeTrees._GetEnvironmentData = function()
    -- Used to handle the differing tree to tile value relationships of mods vs base game. This assumes that either or is in use as I believe the 2 are incompatible in map generation.
    local environmentData = {} ---@type UtilityBiomeTrees_EnvironmentData
    if game.active_mods["alien-biomes"] then
        environmentData.moistureRangeAttributeNames = { optimal = "water_optimal", range = "water_max_range" }
        environmentData.tileTemperatureCalculationSettings = {
            -- on scale of -0.5 to 1.5 = -50 to 150. -15 is lowest temp tree +125 is highest temp tree.
            scaleMultiplier = 100,
            max = 125,
            min = -15
        }
        environmentData.tileData = BiomeTrees._ProcessTilesRawData(AlienBiomesData.GetTileData())
        local tagToColors = AlienBiomesData.GetTileTagToTreeColors()
        for _, tile in pairs(environmentData.tileData) do
            if tile.tag ~= nil then
                if tagToColors[tile.tag] then
                    tile.tag = tagToColors[tile.tag]
                else
                    LoggingUtils.LogPrintError("Failed to find tile to tree color mapping for tile tag: ' " .. tile.tag .. "'", LogSuitablePositives or LogSuitableNonPositives)
                end
            end
        end
        environmentData.treesMetaData = AlienBiomesData.GetTreesMetaData()
        environmentData.deadTreeNames = { "dead-tree-desert", "dead-grey-trunk", "dead-dry-hairy-tree", "dry-hairy-tree", "dry-tree" }
        environmentData.randomTreeLastResort = "GetRandomDeadTree"
    else
        environmentData.moistureRangeAttributeNames = { optimal = "water_optimal", range = "water_range" }
        environmentData.tileTemperatureCalculationSettings = {
            -- on scale of 0 to 1 = 0 to 35. 5 is the lowest tempt tree.
            scaleMultiplier = 35,
            min = 5
        }
        environmentData.tileData = BiomeTrees._ProcessTilesRawData(BaseGameData.GetTileData())
        environmentData.treesMetaData = nil
        environmentData.deadTreeNames = { "dead-tree-desert", "dead-grey-trunk", "dead-dry-hairy-tree", "dry-hairy-tree", "dry-tree" }
        environmentData.randomTreeLastResort = "GetTrulyRandomTree"
    end

    return environmentData
end

--- Gets the runtime tree data from the prototype data.
---@return UtilityBiomeTrees_TreeDetails[]
BiomeTrees._GetTreeData = function()
    local treeDataArray = {} ---@type UtilityBiomeTrees_TreeDetails[]
    local treeData, prototypeName
    local environmentData = global.UTILITYBIOMETREES.environmentData
    local moistureRangeAttributeNames = global.UTILITYBIOMETREES.environmentData.moistureRangeAttributeNames
    local treePrototypes = game.get_filtered_entity_prototypes({ { filter = "type", type = "tree" }, { mode = "and", filter = "autoplace" } })

    for _, prototype in pairs(treePrototypes) do
        local autoplace ---@type AutoplaceSpecificationPeak|nil
        for _, peak in pairs(prototype.autoplace_specification.peaks) do
            if peak.temperature_optimal ~= nil or peak[moistureRangeAttributeNames.optimal] ~= nil then
                autoplace = peak
                break
            end
        end

        if autoplace ~= nil then
            -- Use really wide range defaults for missing moisture values as likely unspecified by mods to mean ALL.
            prototypeName = prototype.name
            ---@type UtilityBiomeTrees_TreeDetails
            treeData = {
                name = prototypeName,
                tempRange = {
                    (autoplace.temperature_optimal or 0) - (autoplace.temperature_range or 0),
                    (autoplace.temperature_optimal or 1) + (autoplace.temperature_range or 0)
                },
                moistureRange = {
                    (autoplace[moistureRangeAttributeNames.optimal] or 0) - (autoplace[moistureRangeAttributeNames.range] or 0),
                    (autoplace[moistureRangeAttributeNames.optimal] or 1) + (autoplace[moistureRangeAttributeNames.range] or 0)
                },
                probability = prototype.autoplace_specification.max_probability or 0.01
            }
            if environmentData.treesMetaData ~= nil and environmentData.treesMetaData[prototypeName] ~= nil then
                treeData.tags = environmentData.treesMetaData[prototypeName][1]
                treeData.exclusivelyOnNamedTiles = environmentData.treesMetaData[prototypeName][2]
            end
            treeDataArray[#treeDataArray + 1] = treeData
        end
    end

    return treeDataArray
end

--- Add a tile to the tileDetails table from its raw data.
---@param tileDetails UtilityBiomeTrees_TilesDetails
---@param tileName string
---@param type UtilityBiomeTrees_TileType
---@param range1? UtilityBiomeTrees_valueRange[]
---@param range2? UtilityBiomeTrees_valueRange[]
---@param tag? string
BiomeTrees._AddTileDetails = function(tileDetails, tileName, type, range1, range2, tag)
    local tempRanges = {} ---@type UtilityBiomeTrees_valueRange[]
    local moistureRanges = {} ---@type UtilityBiomeTrees_valueRange[]
    if range1 ~= nil then
        tempRanges[#tempRanges + 1] = { range1[1][1] or 0, range1[2][1] or 0 }
        moistureRanges[#moistureRanges + 1] = { range1[1][2] or 0, range1[2][2] or 0 }
    end
    if range2 ~= nil then
        tempRanges[#tempRanges + 1] = { range2[1][1] or 0, range2[2][1] or 0 }
        moistureRanges[#moistureRanges + 1] = { range2[1][2] or 0, range2[2][2] or 0 }
    end
    tileDetails[tileName] = { name = tileName, type = type, tempRanges = tempRanges, moistureRanges = moistureRanges, tag = tag } ---@type UtilityBiomeTrees_TileDetails
end

--- Processes raw tile data in to a tiles details table.
---@param rawTilesData table<string, UtilityBiomeTrees_RawTileData>
---@return UtilityBiomeTrees_TilesDetails
BiomeTrees._ProcessTilesRawData = function(rawTilesData)
    local tilesDetails = {} ---@type UtilityBiomeTrees_TilesDetails
    for name, rawTileData in pairs(rawTilesData) do
        BiomeTrees._AddTileDetails(tilesDetails, name, rawTileData[1], rawTileData[2], rawTileData[3], rawTileData[4])
    end
    return tilesDetails
end

--- Takes a raw tile temperature and processes it against the environment data.
---@param tileTemperature double
---@return double environmentScaledTileTemperature
BiomeTrees._CalculateTileTemperature = function(tileTemperature)
    local tileTemperatureCalculationSettings = global.UTILITYBIOMETREES.environmentData.tileTemperatureCalculationSettings
    if tileTemperatureCalculationSettings.scaleMultiplier ~= nil then
        tileTemperature = tileTemperature * tileTemperatureCalculationSettings.scaleMultiplier
    end
    if tileTemperatureCalculationSettings.max ~= nil then
        tileTemperature = math.min(tileTemperatureCalculationSettings.max--[[@as double]] , tileTemperature)
    end
    if tileTemperatureCalculationSettings.min ~= nil then
        tileTemperature = math.max(tileTemperatureCalculationSettings.min--[[@as double]] , tileTemperature)
    end
    return tileTemperature
end

return BiomeTrees
