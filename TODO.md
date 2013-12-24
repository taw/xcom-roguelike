* make fire trail for miss look like one

* share more code between soldiers and aliens
* Rewriting the code with classes, attribute getters etc. will probably clean up a lot of things

* different alien types by level

* aliens should shoot most vulnerable soldier

* inter-level summary screen
* display detailed gun stats (as mouseover popup?)
* displapy ability description (as mouseover popup?)

* per-action cooldown system (reset on new_level etc.)
* a few more randomly generated objects
* make run&gun work

* a few more alien types (floaters, heavy floaters) - for now possibly without any special stuff
* melee aliens (berserkers) - for now without any special stuff

* aliens should take 1 second or so per action (once movement trail are done)

* low cover objects
* sidearms
* soldiers and aliens in one structure
* basic cover/flanking
* movement trails
* movement by 1.0 / 1.4, not full Euclidean distance (if it works)
* grenades
* aliens preference for cover and for staying close to each other
* level ups (for at least stats)
* full line of sight test for shooting (maybe ignoring covers)
* make rocket work
* dashing
* class ability for snipers
* class ability for supports
* maybe free aim (once there are destructible covers)

* A* http://www.briangrinstead.com/blog/astar-search-algorithm-in-javascript-updated
* perk tree ideas from http://www.nexusmods.com/xcom/mods/88/ ?
* Overwatch system will be a big upgrade much later
* Some not completely stupid level generation as well

Ability tree idea - training roulette pool:
* resilience
* SCOPE
* executioner
* ammo conservation
* disabling shot
* grenadier (needs: grenades)
* alien granades (needs: granades)
* headshot (depends on class)
* snapshot (depends on class)
* field medic (needs: per-soldier action system)
* bring em on (needs: squad line of sight)
* HEAT ammo (needs: robotic soldiers)
* tactical sense (needs: line of sight)
* aggression (needs: line of sight)
* low cover (needs: low cover)
* gunslinger (needs: pistols, exclusive with arc thrower)
* arc thrower (needs~ pistol, goes into pistol slot, exclusive with gunslinger)
* rocketeer (needs: fire rocket, depends on class)
* will to survive (depends on correct flanking system)
