data:extend(
    {
        {
            name = "tree-fire-max-hope-count",
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
            name = "turn-to-tree-chance-percent",
            type = "int-setting",
            default_value = 100,
            minomum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1001"
        },
        {
            name = "burst-into-flames-chance-percent",
            type = "int-setting",
            default_value = 1,
            minimum_value = 0,
            maximum_value = 100,
            setting_type = "runtime-global",
            order = "1002"
        },
        {
            name = "prevent-biters-reincarnating-from-fire-death",
            type = "bool-setting",
            default_value = false,
            setting_type = "runtime-global",
            order = "1003"
        },
        {
            name = "max_reincarnations_per_second",
            type = "int-setting",
            default_value = 3,
            minimum_value = 1,
            maximum_value = 60,
            setting_type = "runtime-global",
            order = "1004"
        },
        {
            name = "max_seconds_wait_for_reincarnation",
            type = "int-setting",
            default_value = 5,
            minimum_value = 1,
            setting_type = "runtime-global",
            order = "1005"
        }
    }
)
