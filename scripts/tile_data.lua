--Raw data lifted from base\prototypes\tile\tiles.lua, version 17.5



local function SortLowHigh(values)
    local val1 = values[1]
    local val2 = values[2]
    if val1 <= val2 then
        return {val1, val2}
    else
        return {val2, val1}
    end
end


local tileDetails = {}
local function AddTileDetails(tileName, type, range1, range2)
    local tempRanges = nil
    local moistureRanges = nil
    if range1 ~= nil then
        tempRanges = {SortLowHigh(range1[1])}
        moistureRanges = {SortLowHigh(range1[2])}
    end
    if range2 ~= nil then
        table.insert(tempRanges, SortLowHigh(range2[1]))
        table.insert(moistureRanges, SortLowHigh(range2[2]))
    end
    tileDetails[tileName] = {name = tileName, type = type, tempRanges = tempRanges, moistureRanges = moistureRanges}
end


AddTileDetails("grass-1", "grass", {{0, 0.7}, {1, 1}})
AddTileDetails("grass-2", "grass", {{0.45, 0.45}, {1, 0.8}})
AddTileDetails("grass-3", "grass", {{0, 0.6}, {0.65, 0.9}})
AddTileDetails("grass-4", "grass", {{0, 0.5}, {0.55, 0.7}})
AddTileDetails("dry-dirt", "dirt", {{0.45, 0}, {0.55, 0.35}})
AddTileDetails("dirt-1", "dirt", {{0, 0.25}, {0.45, 0.3}}, {{0.4, 0}, {0.45, 0.25}})
AddTileDetails("dirt-2", "dirt", {{0, 0.3}, {0.45, 0.35}})
AddTileDetails("dirt-3", "dirt", {{0, 0.35}, {0.55, 0.4}})
AddTileDetails("dirt-4", "dirt", {{0.55, 0}, {0.6, 0.35}}, {{0.6, 0.3}, {1, 0.35}})
AddTileDetails("dirt-5", "dirt", {{0, 0.4}, {0.55, 0.45}})
AddTileDetails("dirt-6", "dirt", {{0, 0.45}, {0.55, 0.5}})
AddTileDetails("dirt-7", "dirt", {{0, 0.5}, {0.55, 0.55}})
AddTileDetails("sand-1", "sand", {{0, 0}, {0.25, 0.15}})
AddTileDetails("sand-2", "sand", {{0, 0.15}, {0.3, 0.2}}, {{0.25, 0}, {0.3, 0.15}})
AddTileDetails("sand-3", "sand", {{0, 0.2}, {0.4, 0.25}}, {{0.3, 0}, {0.4, 0.2}})
AddTileDetails("red-desert-0", "desert", {{0.55, 0.35}, {1, 0.5}})
AddTileDetails("red-desert-1", "desert", {{0.6, 0}, {0.7, 0.3}}, {{0.7, 0.25}, {1, 0.3}})
AddTileDetails("red-desert-2", "desert", {{0.7, 0}, {0.8, 0.25}}, {{0.8, 0.2}, {1, 0.25}})
AddTileDetails("red-desert-3", "desert", {{0.8, 0}, {1, 0.2}})
AddTileDetails("water", "water")
AddTileDetails("deepwater", "water")
AddTileDetails("water-green", "water")
AddTileDetails("deepwater-green", "water")
AddTileDetails("water-shallow", "water")
AddTileDetails("water-mud", "water")

return tileDetails
