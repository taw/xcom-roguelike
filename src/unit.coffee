## Guns
GunTypes =
  pistol: {damage: 1, crit: 1, crit_chance: 0, range: 10}
  laser_pistol: {damage: 2, crit: 3, crit_chance: 10, range: 10}
  plasma_pistol: {damage: 3, crit: 4, crit_chance: 0, range: 10}

  shotgun: {damage: 4, crit: 6, crit_chance: 20, range: 10, far_range: 5, ammomax: 4}
  scatter_laser: {damage: 6, crit: 9, crit_chance: 20, range: 10, far_range: 5, ammomax: 4}
  alloy_cannon: {damage: 9, crit: 13, crit_chance: 20, range: 10, far_range: 5, ammomax: 4}

  rifle: {damage: 3, crit: 4, crit_chance: 10, range: 10, ammomax: 4}
  laser_rifle: {damage: 5, crit: 7, crit_chance: 10, range: 10, ammomax: 4}
  light_plasma_rifle: {damage: 5, crit: 7, crit_chance: 10, range: 10, ammomax: 4, aimbonus: 10}
  plasma_rifle: {damage: 7, crit: 10, crit_chance: 10, range: 10, ammomax: 4}

  sniper_rifle: {damage: 4, crit: 6, crit_chance: 25, range: 20, min_range: 5, two_actions: true, ammomax: 4}
  laser_sniper_rifle: {damage: 6, crit: 9, crit_chance: 30, range: 20, min_range: 5, two_actions: true, ammomax: 4}
  plasma_sniper_rifle: {damage: 9, crit: 13, crit_chance: 35, range: 20, min_range: 5, two_actions: true, ammomax: 4}

  lmg: {damage: 4, crit: 6, crit_chance: 0, range: 10, ammomax: 3}
  heavy_laser: {damage: 6, crit: 9, crit_chance: 0, range: 10, ammomax: 3}
  heavy_plasma: {damage: 9, crit: 13, crit_chance: 0, range: 10, ammomax: 3}

## Unit
class Unit
  constructor: (attrs) ->
    for key, val of attrs
      @[key] = val
    @defense ||= 0
    @abilities ||= []
  start_new_level: () ->
    @hp = @hpmax
    @ammo = @ammomax
  start_new_turn: () ->
    if @hp > 0
      @actions = 2
    else
      @actions = 0
    @overwatch = false
  @property 'gun',
    get: -> GunTypes[@gun_type]
  @property 'ammomax',
    get: ->
      if 'Ammo conservation' in @abilities
        @gun.ammomax * 2
      else
        @gun.ammomax
  @property 'gun_needs_two_actions',
    get: -> @gun.two_actions and not @has_ability('Snapshot')
  @property 'gun_damage',
    get: -> @gun.damage
  @property 'gun_crit_damage',
    get: -> @gun.crit
  @property 'alive',
    get: -> @hp > 0
  @property 'must_reload',
    get: -> @ammo == 0
  @property 'can_reload',
    get: -> @ammo == @ammomax
  action_move: (x,y) ->
    @x = x
    @y = y
    @actions -= 1
  action_reload: () ->
    @ammo = @ammomax
    @actions = 0
  action_overwatch: () ->
    @overwatch = true
    @actions = 0
  register_kill: (victim) ->
  take_damage: (damage) ->
    @hp -= damage
    if @hp <= 0
      @hp = 0
      @style = "dead"
      @actions = 0
      @overwatch = false
  aim_penalty_for_distance: (distance) ->
    # Aim penalty of up to -20 if too far
    if @gun.far_range and distance >= @gun.far_range
      Math.round(20 * (distance - @gun.far_range) / (@gun.range - @gun.far_range))
    # Aim penalty of up to -20 if too close
    else if @gun.near_range and @distance <= @gun.near_range
      Math.round(20 * (@gun.near_range - distance) / @gun.near_range)
    else
      0
  in_fire_range: (target) ->
    dist2(@x - target.x, @y - target.y) <= @gun.range
  has_ability: (ability) ->
    ability in @abilities

class Alien extends Unit

class Sectoid extends Alien
  constructor: (x,y) ->
    super
      x: x
      y: y
      style: "sectoid"
      hpmax: 3
      mobility: 5
      aim: 65
      gun_type: 'plasma_pistol'

class ThinMan extends Alien
  constructor: (x,y) ->
    super
      x: x
      y: y
      style: "thin_man"
      hpmax: 3
      mobility: 7
      aim: 65
      gun_type: 'light_plasma_rifle'

class Muton extends Alien
  constructor: (x,y) ->
    super
      x: x
      y: y
      style: "muton"
      hpmax: 6
      mobility: 5
      aim: 70
      gun_type: 'plasma_rifle'
      abilities: ['alien_grenade']

class MutonElite extends Alien
  constructor: (x,y) ->
    super
      x: x
      y: y
      style: "muton_elite"
      hpmax: 14
      mobility: 5
      aim: 80
      defense: 20
      gun_type: 'heavy_plasma'
      abilities: ['alien_grenade']

class Soldier extends Unit
  constructor: (attrs) ->
    super
    @xp ||= 0
    @level ||= 1
    @promotion_options ||= []
  @property 'rank',
    get: ->
      ['Rookie', 'Squaddie', 'Corporal', 'Sergeant', 'Lieutenant', 'Major', 'Colonel'][@level] || "General (#{@level-6} stars)"
  @property 'xp_for_next_promotion',
    get: ->
      @level * 30
  @property 'ability_pool',
    get: ->
      _.difference(['Resilience', 'Low profile', 'SCOPE', 'Ammo conservation', 'Executioner', 'Laser weapons', 'Sprinter'], @abilities)
  setup_promotion: ->
    @promotion_options = _.sample(@ability_pool, 2)
  gain_ability: (ability) ->
    @abilities.push ability
    @mobility += 2 if ability == 'Sprinter'
    if ability == 'Laser weapons'
      switch @gun_type
        when 'shotgun'
          @gun_type = 'scatter_laser'
        when 'rifle'
          @gun_type = 'laser_rifle'
        when 'sniper_rifle'
          @gun_type = 'laser_sniper_rifle'
        when 'lmg'
          @gun_type = 'heavy_laser'
      @ammo = @ammomax
  promotion: (ability) ->
    @promotion_options = []
    @level++
    if @level % 2 == 0
      @hpmax++
      @hp++
    @aim += 5
    @gain_ability(ability)
    if @xp >= @xp_for_next_promotion
      @setup_promotion()
  register_kill: (victim) ->
    @xp += 30
    if @xp >= @xp_for_next_promotion
      @setup_promotion()
