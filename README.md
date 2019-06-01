# Factorio-Biter-Reincarnation

When a Biter or Spitter dies it tries to reincarnate into the true perpetual enemy, a tree. Occasionally the very angry ones fail and burst into flames.

The tree type (living and dead) will be biome appropriate for where the biter dies. Only base game tiles are supported, but modded trees should behave correctly. When the death is on a player placed ground type (floor) the underlying tile type is used.

The chance of a tree or burning tree appearing on enemy unit death is fully configurable. Combined chance of events occuring can be greater than 100%. The ratio of values will be utilised. Below 100% chance means possibility of no event happening.

A script interface is included to allow other mods to utilise the logic. See the end of control.lua for the remote interface registration.

Currently doesn't support modded tiles and so new landscape mods aren't supported.