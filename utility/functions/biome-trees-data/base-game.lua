-- Vanilla - 1.1.70


local TableUtils = require("utility.helper-utils.table-utils")
local Data = {} ---@class Utility_BiomeTrees_BaseGame

--[[
    These values are lifted from Factorio source code files. \data\base\prototypes\tile\tiles.lua
    We can't handle the odd ones that use a noise expression rather than have real values, so have to just ignore the ranges passed in as a function. Only 1 tile has been observed to have this to date.

    At the top of the lua file add:
        local muppetTable = {}
    At the start of the `autoplace_settings` function add the below to capture each call to it:
        local inputRanges = {...}
        local range1 = inputRanges[1] if range1 ~= nil and type(range1) == "function" then range1 = nil end
        local range2 = inputRanges[2] if range2 ~= nil and type(range2) == "function" then range2 = nil end
        muppetTable[noise_name] = {
            "allow-trees",
            range1,
            range2
        }
    At the very end of the file add:
        log("\r\n\r\n\r\n\r\n" .. "Muppet Tile Data:" .. "\r\n\r\n" .. serpent.block(muppetTable) .. "\r\n\r\n\r\n")
]]
---@return UtilityBiomeTrees_RawTilesData
Data.GetTileData = function()
    -- Any tile not listed will have a random tree placed on it assuming the player can walk on the tile, otherwise no tree.

    -- The ones we can programmatically generate.
    local tileData1 = {
        ["dirt-1"] = {
            "allow-trees",
            {
                {
                    0,
                    0.25
                },
                {
                    0.45,
                    0.3
                }
            },
            {
                {
                    0.4,
                    0
                },
                {
                    0.45,
                    0.25
                }
            }
        },
        ["dirt-2"] = {
            "allow-trees",
            {
                {
                    0,
                    0.3
                },
                {
                    0.45,
                    0.35
                }
            }
        },
        ["dirt-3"] = {
            "allow-trees",
            {
                {
                    0,
                    0.35
                },
                {
                    0.55,
                    0.4
                }
            }
        },
        ["dirt-4"] = {
            "allow-trees",
            {
                {
                    0.55,
                    0
                },
                {
                    0.6,
                    0.35
                }
            },
            {
                {
                    0.6,
                    0.3
                },
                {
                    1,
                    0.35
                }
            }
        },
        ["dirt-5"] = {
            "allow-trees",
            {
                {
                    0,
                    0.4
                },
                {
                    0.55,
                    0.45
                }
            }
        },
        ["dirt-6"] = {
            "allow-trees",
            {
                {
                    0,
                    0.45
                },
                {
                    0.55,
                    0.5
                }
            }
        },
        ["dirt-7"] = {
            "allow-trees",
            {
                {
                    0,
                    0.5
                },
                {
                    0.55,
                    0.55
                }
            }
        },
        ["dry-dirt"] = {
            "allow-trees",
            {
                {
                    0.45,
                    0
                },
                {
                    0.55,
                    0.35
                }
            }
        },
        ["grass-1"] = {
            "allow-trees",
            {
                {
                    0,
                    0.7
                },
                {
                    1,
                    1
                }
            }
        },
        ["grass-2"] = {
            "allow-trees",
            {
                {
                    0.45,
                    0.45
                },
                {
                    1,
                    0.8
                }
            }
        },
        ["grass-3"] = {
            "allow-trees",
            {
                {
                    0,
                    0.6
                },
                {
                    0.65,
                    0.9
                }
            }
        },
        ["grass-4"] = {
            "allow-trees",
            {
                {
                    0,
                    0.5
                },
                {
                    0.55,
                    0.7
                }
            }
        },
        ["red-desert-0"] = {
            "allow-trees",
            {
                {
                    0.55,
                    0.35
                },
                {
                    1,
                    0.5
                }
            }
        },
        ["red-desert-1"] = {
            "allow-trees",
            {
                {
                    0.6,
                    0
                },
                {
                    0.7,
                    0.3
                }
            },
            {
                {
                    0.7,
                    0.25
                },
                {
                    1,
                    0.3
                }
            }
        },
        ["red-desert-2"] = {
            "allow-trees",
            {
                {
                    0.7,
                    0
                },
                {
                    0.8,
                    0.25
                }
            },
            {
                {
                    0.8,
                    0.2
                },
                {
                    1,
                    0.25
                }
            }
        },
        ["red-desert-3"] = {
            "allow-trees",
            {
                {
                    0.8,
                    0
                },
                {
                    1,
                    0.2
                }
            }
        },
        ["sand-1"] = {
            "allow-trees",
            {
                {
                    0,
                    0
                },
                {
                    0.25,
                    0.15
                }
            }
        },
        ["sand-2"] = {
            "allow-trees",
            {
                {
                    0,
                    0.15
                },
                {
                    0.3,
                    0.2
                }
            },
            {
                {
                    0.25,
                    0
                },
                {
                    0.3,
                    0.15
                }
            }
        },
        ["sand-3"] = {
            "allow-trees",
            {
                {
                    0,
                    0.2
                },
                {
                    0.4,
                    0.25
                }
            },
            {
                {
                    0.3,
                    0
                },
                {
                    0.4,
                    0.2
                }
            }
        }
    }

    -- The tiles we manually define.
    local tileData2 = {
        ["water"] = { "water" },
        ["deepwater"] = { "water" },
        ["water-green"] = { "water" },
        ["deepwater-green"] = { "water" },
        ["water-shallow"] = { "water" },
        ["water-mud"] = { "water" },
        ["out-of-map"] = { "no-trees" },
        ["landfill"] = { "allow-trees", { { 0, 0 }, { 0.25, 0.15 } } }, --same as sand-1
        ["nuclear-ground"] = { "allow-trees", { { 0, 0 }, { 0.25, 0.15 } } } --same as sand-1
    }

    -- Hard code dirt-2 to have the same second range as dirt-1. By default dirt 2 doesn't have a second range. As from the raw input data it seems that no proper tree matches the conditions of dirt-2. Probably an oversight in main Factorio and due to the erratic way forests are created this never materialises as an issue. By keeping dirt-2's first range vanilla any custom trees in this range will also be included still, but for truly vanilla trees we will at least get dirt-1's.
    tileData1["dirt-2"][3] = tileData1["dirt-1"][3] ---@diagnostic disable-line:no-unknown

    return TableUtils.TableMergeCopies({ tileData1, tileData2 })
end

return Data
