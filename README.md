# Factorio-Biter-Reincarnation

When a Biter or Spitter (any unit that breaths air) dies it tries to reincarnate into the true perpetual enemy, a tree. Occasionally the very angry ones fail and burst into flames.

The tree type (living and dead) will be biome appropriate for where the biter dies. Only base game tiles are supported, but modded trees should behave correctly. When the death is on a player placed ground type (floor) the underlying tile type is used.

The chance of a tree or burning tree appearing on enemy unit death is fully configurable. If the combined chance of events occuring is greater than 100% the ratio of values will be utilised. If below 100% chance then there is the possibility of no event happening.

When biters die they join a reincarnation queue. The processing speed of the queue is controlable by mod settings so you can limitthe impact of UPS drops.

Doesn't support modded tiles or mods that do their own map creation and so new landscape mods aren't supported.
Only reacts to units that breaths air and has an internal blacklist to avoid unintentional reactions to other mods. If there are mods that it should react to please request them.
Settings to control tree fire spread to aid compatibility with other mods and very high tree maps.

Alien biomes isn't supported as I haven't worked out how to dynamically handle its various tile & tree environment variations.