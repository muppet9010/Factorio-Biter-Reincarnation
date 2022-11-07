# Factorio-Biter-Reincarnation

When an enemy unit or worm dies it tries to reincarnate back in to nature, be it a tree, rock or cliff. Occasionally the angry ones can burst into a flaming tree.

![Biter Reincarnation Example](https://giant.gfycat.com/WeeklyReasonableGuineapig.mp4)




Reincarnation Types
===============

- Tree - Will be biome appropriate for where the biter dies, using the natural tile under player placed flooring (concrete).
- Burning Tree - Will be a regular tree that is on fire. The fire will spread to any adjacent tree.
- Rocks - Will generally be the big rock types, with the occasional huge rock. Where possible the rocks will appear on clear ground, however, if needed they will crush or push entities out of the way.
- Cliffs - A small cliff will appear around the position the biter died. They will crush or push entities out of the way.
- Water - Only worms can make water on their death. The water will be where the biter died and be shallow so that things can still walk over it.




Mod Behavior
===============

- Any units will trigger reincarnation then they die. Optionally worms can also reincarnate when they die. See mod settings for control over what units and worms reincarnate in to.
- If the combined chance of events occurring is greater than 100(%) the ratio of values will be utilised. If below 100% chance then there is the possibility of no event happening.
- When biters die they join a reincarnation queue. The recording to the queue and processing of the queue is controllable by mod settings so you can limit the impact on UPS, thus avoiding game slowdown in excessively heavy combat situations. The mod settings to control how many reincarnations to do per second and the max wait time collectively apply a cap to the number of reincarnations that are tracked and completed, thus limiting max UPS impact. If you want all reincarnations to occur regardless of possible UPS impact during extreme biter death periods set these setting very high and all reincarnations will occur.
- Mod setting to control if large reincarnations will try and push anything movable out of the way (up to 2 tiles). Anything not moved will be crushed. Movable things include units, player characters and vehicles. Large reincarnations are rocks and cliffs.
- When water tiles are created no entities on top of them will be removed, so ore on that tile or an adjacent building or cliff has no risk of being removed. Shallow water is used as players, biters and vehicles can walk over it.
- Mod setting to control tree fire spread to aid compatibility with other mods and very high tree maps.
- Mod settings to allow blacklisting named entity or forces from reincarnating. By default the `player` force and `compilatron` are blacklisted.




Mod Compatibility
==============

- The mod is designed to integrate elegantly with the Biter Revive mod. Only 1 reaction will occur for a dead biter; Any biters that don't revive will be available for reincarnation. With reviving biters not also being valid for reincarnating.
- If a biter dies on a vanilla or Alien Biomes mod tile a biome related tree will be selected (best endeavours). For other modded tiles a truly random tree will be selected.
- The mod should support and handle fully defined custom tree types that can be applied automatically via map generation, otherwise these custom trees will be ignored for tree selection.