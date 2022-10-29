# Factorio-Biter-Reincarnation

When an enemy unit dies it tries to reincarnate back in to nature, be it a tree, rock or cliff. Occasionally the angry ones can burst into a flaming tree.

Reincarnation Types
===============

- Tree - Will be biome appropriate for where the biter dies, using the natural tile under player placed flooring (concrete).
- Burning Tree - Will be a regular tree that is on fire. The fire will spread to any adjacent tree.
- Rocks - Will generally be the big rock types, with the occasional huge rock. Where possible the rocks will appear on clear ground, however, if needed they will crush or push entities out of the way.
- Cliffs - Where possible the cliffs will appear on clear ground, however, if needed they will crush or push entities out of the way.

Mod Behavior
===============

- Any units that breath air will trigger reincarnation then they die. The exception is the player character and compilatron.
- If the combined chance of events occurring is greater than 100(%) the ratio of values will be utilised. If below 100% chance then there is the possibility of no event happening.
- When biters die they join a reincarnation queue. The processing speed of the queue is controllable by mod settings so you can limit the impact of UPS drops.
- Mod setting to control if large reincarnations will try and push anything movable out of the way (up to 2 tiles). Anything not moved will be crushed. Movable things include units, player characters and vehicles.
- Mod setting to control tree fire spread to aid compatibility with other mods and very high tree maps.

Mod Incompatibility
==============
- If biter dies on a vanilla game tile or with Alien Biomes mod a biome specific tree will be selected, otherwise the tree will be random on other modded tiles. Should support and handle fully defined custom tree types, otherwise they will be ignored.