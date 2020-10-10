--do here so that other mods can add any custom tress
local maxTreeFireHop = tonumber(settings.startup["biter_reincarnation-tree_fire_max_hop_count"].value)
if maxTreeFireHop > -1 then
    data.raw["fire"]["fire-flame"].maximum_spread_count = maxTreeFireHop
    data.raw["fire"]["fire-flame-on-tree"].maximum_spread_count = maxTreeFireHop
end
