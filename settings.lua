data:extend(
    {
        {
            name = "biter_reincarnation-tree_fire_max_hop_count",
            type = "int-setting",
            default_value = -1,
            minimum_value = -1,
            maximum_value = 65535,
            setting_type = "startup",
            order = "1001"
        }
    }
)

data:extend(
    {
        {
            name = "biter_reincarnation-turn_to_tree_chance_percent",
            type = "int-setting",
            default_value = 90,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1001"
        },
        {
            name = "biter_reincarnation-turn_to_burning_tree_chance_percent",
            type = "int-setting",
            default_value = 1,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1002"
        },
        {
            name = "biter_reincarnation-turn_to_rock_chance_percent",
            type = "int-setting",
            default_value = 8,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1003"
        },
        {
            name = "biter_reincarnation-turn_to_cliff_chance_percent",
            type = "int-setting",
            default_value = 1,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1004"
        },
        {
            name = "biter_reincarnation-large_reincarnations_push",
            type = "bool-setting",
            default_value = true,
            setting_type = "runtime-global",
            order = "1101"
        },
        {
            name = "biter_reincarnation-max_reincarnations_per_second",
            type = "int-setting",
            default_value = 50,
            minimum_value = 1,
            setting_type = "runtime-global",
            order = "1201"
        },
        {
            name = "biter_reincarnation-max_seconds_wait_for_reincarnation",
            type = "int-setting",
            default_value = 5,
            minimum_value = 1,
            setting_type = "runtime-global",
            order = "1202"
        },
        {
            name = "biter_reincarnation-blacklisted_prototype_names",
            type = "string-setting",
            allow_blank = true,
            default_value = "compilatron",
            setting_type = "runtime-global",
            order = "2000"
        },
        {
            name = "biter_reincarnation-blacklisted_force_names",
            type = "string-setting",
            allow_blank = true,
            default_value = "player",
            setting_type = "runtime-global",
            order = "2001"
        }
    }
)
