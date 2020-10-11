# Factorio-Biter-Reincarnation

When an enemy unit dies it tries to reincarnate back in to nature, be it a tree, rock or cliff. Occasionally the angry ones can burst into a flaming tree.

Reincarnation Types
===============

- Tree - Will be biome appropriate for where the biter dies. Only base game tiles are supported, but modded trees should behave correctly. When the death is on a player placed ground type (floor) the underlying tile type is used.
- Burning Tree - Will be a regular tree that is on fire. Ths fire will spread to any adjacant tree.
- Rocks - Will generally be the big rock types, with the occasional huge rock. Where possible the rocks will appear on clear ground, however, if needed they will crush or push entities out of the way.
- Cliffs - Where possible the cliffs will appear on clear ground, however, if needed they will crush or push entities out of the way.

Mod Behaviour
===============

- Any units that breath air will trigger reincarnation then they die. The exception is the player character and compilatron.
- If the combined chance of events occuring is greater than 100(%) the ratio of values will be utilised. If below 100% chance then there is the possibility of no event happening.
- When biters die they join a reincarnation queue. The processing speed of the queue is controlable by mod settings so you can limitthe impact of UPS drops.
- Mod setting to control if large reincarnations will try and push anything movable out of the way (up to 2 tiles). Anything not moved will be crushed. Movable things include units, player characters and vehicles.
- Mod setting to control tree fire spread to aid compatibility with other mods and very high tree maps.

Mod Incompatibility
==============
- Doesn't support modded tiles or mods that do their own map creation and so new landscape mods aren't supported.
- Alien biomes isn't supported as I haven't worked out how to dynamically handle its various tile & tree environment variations.