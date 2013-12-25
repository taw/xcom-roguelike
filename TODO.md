* make run&gun work
* grenades
* make rockets work
* class ability for supports

* display ability cooldown
* friendly fire warning (or not lol)
* soldier perks test suite
* try to disentangle spaghetti code a bit more
* make fire trail for miss look like misses
* make fire trail aware of side-stepping
* aliens should shoot most vulnerable soldier
* inter-level summary screen
* display detailed gun stats (as mouseover popup?)
* display ability description (as mouseover popup?)
* chitin plating should provide melee protection
* per-action cooldown system (reset on new_level etc.)
* no-cover aliens (floaters / heavy floaters) - they supposedly can't side-step cover
* stat upgrades should be class-specific
* destructible objects (with explosives only for now)
* @ctx.lineWidth management is a mess
* aliens should take 1 second or so per action (once movement trail are done)
* aliens preference for cover and for staying close to each other
* MeleeAlien, RangedAlien, FlyingAlien etc. classes ???
* a few more alien types (floaters, heavy floaters) - for now possibly without any special stuff
* berserkers
* find_object to return actual object
* MapObject class
* soldiers and aliens in one structure
* movement trails
* movement by 1.0 / 1.4, not full Euclidean distance (if it works)
* full line of sight test for shooting (maybe ignoring covers)
* dashing
* class ability for snipers
* maybe free aim (once there are destructible covers)
* make doors actually work

* A* http://www.briangrinstead.com/blog/astar-search-algorithm-in-javascript-updated
* perk tree ideas from http://www.nexusmods.com/xcom/mods/88/ ?
* Overwatch system will be a big upgrade much later
* Some not completely stupid level generation as well

Ability tree idea - training roulette pool:
* disabling shot
* will to survive
* snapshot (depends on class) - currently broken version in the code
* grenadier (needs: grenades)
* alien granades (needs: granades)
* headshot (depends on class)
* field medic (needs: per-soldier action system)
* bring em on (needs: squad line of sight)
* HEAT ammo (needs: robotic soldiers)
* tactical sense (needs: line of sight)
* aggression (needs: line of sight)
* gunslinger (needs: pistols, exclusive with arc thrower)
* arc thrower (needs: pistol, goes into pistol slot, exclusive with gunslinger)
* rocketeer (needs: fire rocket, depends on class)

* check for more ideas later (gene mods, MECs, other abilities, psi)
