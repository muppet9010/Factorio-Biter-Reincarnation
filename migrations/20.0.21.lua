-- Remove the old value. We re-create it on Startup so new value will always be populated. Replaced due to spelling error.
global.reincarantionChanceList = nil ---@type nil --@cspell:ignore reincarantionChanceList # As we are fixing the old spelling mistake.

-- Update the setting of it was the old default of 10, to the new default of 100.
if settings.global["biter_reincarnation-max_reincarnations_per_second"].value --[[@as uint]] == 10 then
    local max_reincarnations_per_second = settings.global["biter_reincarnation-max_reincarnations_per_second"]
    max_reincarnations_per_second.value = 100
    settings.global["biter_reincarnation-max_reincarnations_per_second"] = max_reincarnations_per_second
end
