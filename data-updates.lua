local maxTreeFireHop = settings.startup["biter_reincarnation-tree_fire_max_hop_count"].value --[[@as int16 # Setting max value enforces max.]]
if maxTreeFireHop > -1 then
    ---@cast maxTreeFireHop uint16
    data.raw["fire"]["fire-flame"].maximum_spread_count = maxTreeFireHop
    data.raw["fire"]["fire-flame-on-tree"].maximum_spread_count = maxTreeFireHop
end
