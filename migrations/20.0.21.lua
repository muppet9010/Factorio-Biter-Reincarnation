-- Remove the old value. We re-create it on Startup so new value will always be populated. Replaced due to spelling error.
global.reincarantionChanceList = nil ---@type nil --@cspell:ignore reincarantionChanceList # As we are fixing the old spelling mistake.

-- Update the setting of it was the old default of 10, to the new default of 50.
if settings.global["biter_reincarnation-max_reincarnations_per_second"].value --[[@as uint]] == 10 then
    local max_reincarnations_per_second = settings.global["biter_reincarnation-max_reincarnations_per_second"]
    max_reincarnations_per_second.value = 50
    settings.global["biter_reincarnation-max_reincarnations_per_second"] = max_reincarnations_per_second
end

-- Set the value of the new global.reincarnationQueueCurrentIndex if we need too.
if global.reincarnationQueue ~= nil and next(global.reincarnationQueue) ~= nil and (global.reincarnationQueueCurrentIndex == nil or global.reincarnationQueueCurrentIndex == 0) then
    global.reincarnationQueueCurrentIndex = #global.reincarnationQueue
end
