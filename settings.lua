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
            minomum_value = 0,
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
        }
    }
)
