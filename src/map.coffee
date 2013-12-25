clamp_probability = (chance) ->
  return 0 if chance < 0
  return 100 if chance > 100
  chance

## Map
class Map
  constructor: ->
    @level_number = 0
    @soldiers     = []
    @aliens       = []
    @objects      = []
  # populate 5x5 level
  populate_level_fragment: (x0, y0) ->
    x = x0 + random_int(4)
    y = y0 + random_int(4)
    switch random_int(20)
      when 0, 1, 2, 3
        if @level_number <= 2
          @aliens.push new Sectoid(x, y)
        else if @level_number <= 4
          @aliens.push new ThinMan(x, y)
        else if @level_number <= 6
          @aliens.push new Muton(x, y)
        else
          @aliens.push new MutonElite(x, y)
      when 4, 5
        @objects.push x: x,    y: y,    style: "car", cover: 20
        @objects.push x: x,    y: y+1,  style: "car", cover: 20
      when 6, 7
        @objects.push x: x,    y: y,    style: "car", cover: 20
        @objects.push x: x+1,  y: y,    style: "car", cover: 20
      when 8, 9, 10, 11
        @objects.push x: x0,   y: y0,   style: "wall", cover: 40
        @objects.push x: x0,   y: y0+1, style: "wall", cover: 40
        @objects.push x: x0,   y: y0+2, style: "door", cover: 40
        @objects.push x: x0,   y: y0+3, style: "wall", cover: 40
        @objects.push x: x0,   y: y0+4, style: "wall", cover: 40
        @objects.push x: x0+1, y: y0,   style: "wall", cover: 40
        @objects.push x: x0+2, y: y0,   style: "door", cover: 40
        @objects.push x: x0+3, y: y0,   style: "wall", cover: 40
        @objects.push x: x0+4, y: y0,   style: "wall", cover: 40
      when 12
        @objects.push x: x,    y: y,    style: "abducted cow", cover: 40
      when 13
        @objects.push x: x,    y: y,    style: "abducted goat", cover: 20
      when 14, 15
        @objects.push x: x,    y: y,    style: "rock", cover: 40
  generate_initial_squad: ->
    @soldiers.push(
      new Soldier
        name: "Alice"
        style: "soldier 1"
        hpmax: 7
        aim: 70
        mobility: 5
        gun_type: 'shotgun'
        sidearm_type: 'pistol'
        abilities: ['Run and gun']
    )
    @soldiers.push(
      new Soldier
        name: "Bob"
        style: "soldier 2"
        hpmax: 7
        aim: 67
        mobility: 5
        gun_type: 'lmg'
        abilities: ['Fire rocket']
    )
    @soldiers.push(
      new Soldier
        name: "Charlie"
        style: "soldier 3"
        hpmax: 6
        aim: 75
        mobility: 5
        sidearm_type: 'pistol'
        gun_type: 'sniper_rifle'
    )
    @soldiers.push(
      new Soldier
        name: "Diana"
        style: "soldier 4"
        hpmax: 7
        aim: 70
        mobility: 5
        gun_type: 'rifle'
        sidearm_type: 'pistol'
        abilities: ['Smoke grenade']
    )
  generate_level: ->
    @level_number++
    @objects = []
    @aliens  = []
    @soldiers[0].x = 1
    @soldiers[0].y = 1
    @soldiers[1].x = 3
    @soldiers[1].y = 3
    @soldiers[2].x = 1
    @soldiers[2].y = 3
    @soldiers[3].x = 3
    @soldiers[3].y = 1
    aliens = []
    for i in [0..5]
      for j in [0..5]
        if i isnt 0 or j isnt 0
          @populate_level_fragment i * 5, j * 5
    for soldier in @soldiers
      soldier.start_new_level()
    for alien in @aliens
      alien.start_new_level()
  @property 'live_soldiers',
    get: -> (soldier for soldier in @soldiers when soldier.hp > 0)
  @property 'live_aliens',
    get: -> (alien for alien in @aliens when alien.hp > 0)
  @property 'all_soldiers_dead',
    get: -> (true for soldier in @soldiers when soldier.hp > 0).length == 0
  @property 'all_aliens_dead',
    get: -> (true for alien in @aliens when alien.hp > 0).length == 0

  find_object: (x, y) ->
    for soldier in @soldiers
      if soldier.x is x and soldier.y is y
        return type: "soldier", object: soldier
    for alien in @aliens
      if alien.x is x and alien.y is y
        return type: "alien", object: alien
    for object in @objects
      if object.x is x and object.y is y
        return type: "object", object: object
    return type: "empty"
  is_object_present: (x, y) ->
    @find_object(x, y).type != "empty"
  cover_level: (x, y) ->
    found = @find_object(x, y)
    if found.type == 'object'
      found.object.cover
    else
      0
  # FIXME: This algorithm does circle, not axis-aligned box, for simplicity
  object_blocks_line_of_sight: (shooter, target, object) ->
    {x:x0, y:y0} = shooter
    {x:x1, y:y1} = target
    {x:xo, y:yo} = object
    dx1 = x1 - x0
    dy1 = y1 - y0
    dxo = xo - x0
    dyo = yo - y0
    ld1 = dist2(dx1, dy1)
    ldo = dist2(dxo, dyo)
    # This formula is correct
    proj_v = (dxo*dx1 + dyo*dy1) / ld1 / ld1
    # Point on the segment closest to the circle of radius 0.6 (halfway between 0.5 or 0.7)
    if proj_v <= 0
      xc = x0
      yc = y0
    else if proj_v >= 1.0
      xc = x1
      yc = y1
    else
      xc = x0 + proj_v * dx1
      yc = y0 + proj_v * dy1
    dist2(xc-xo, yc-yo) <= 0.6
  is_visible: (shooter, target) ->
    return true if shooter.x == target.x and shooter.y == target.y
    for object in @objects
      continue unless object.cover == 40
      return false if @object_blocks_line_of_sight(shooter, target, object)
    true
  sidestep_spots: (unit) ->
    spots = []
    {x:x, y:y} = unit
    left   = @find_object(x-1, y)
    right  = @find_object(x+1, y)
    top    = @find_object(x,   y-1)
    bottom = @find_object(x,   y+1)
    spots.push(x: x, y: y)
    spots.push(x: x-1, y: y) if left.type   == 'empty'
    spots.push(x: x+1, y: y) if right.type  == 'empty'
    spots.push(x: x, y: y-1) if top.type    == 'empty'
    spots.push(x: x, y: y+1) if bottom.type == 'empty'
    spots
  best_cover: (unit) ->
    _.max([
      @cover_level(unit.x - 1, unit.y)
      @cover_level(unit.x + 1, unit.y)
      @cover_level(unit.x, unit.y - 1)
      @cover_level(unit.x, unit.y + 1)
    ])
  static_cover_level: (shooter, target) ->
    left    = @cover_level(target.x - 1, target.y)
    right   = @cover_level(target.x + 1, target.y)
    top     = @cover_level(target.x, target.y - 1)
    bottom  = @cover_level(target.x, target.y + 1)
    _.max([
      if shooter.x < target.x then left else 0,
      if shooter.x > target.x then right else 0,
      if shooter.y < target.y then top else 0,
      if shooter.y > target.y then bottom else 0,
    ])
  cover_status: (shooter, target) ->
    possible_shots = [1000] # FIXME: This makes no sense except as a stupid hack, they're just not visible
    for spot1 in @sidestep_spots(shooter)
      for spot2 in @sidestep_spots(target)
        if @is_visible(spot1, spot2)
          possible_shots.push @static_cover_level(spot1, target)
    best_cover = @best_cover(target)
    cover = _.min(possible_shots)
    cover = 40 if cover == 20 and target.has_ability('Low profile')
    effective_cover = cover
    effective_cover *= 2 if target.hunker_down
    description = if cover == 1000
      "Invisible"
    else if best_cover == 0
      "In the open"
    else if cover == 0
      "Flanked"
    else if cover <= 20
      "Low cover (#{effective_cover})"
    else
      "High cover (#{effective_cover})"
    {
      description: description
      cover: effective_cover
    }
  can_shoot_at: (shooter, target) ->
    return false unless shooter.in_fire_range(target)
    return false unless @is_visible(shooter, target)
    true
  can_shoot_sidearm_at: (shooter, target) ->
    return false unless shooter.in_sidearm_fire_range(target)
    return false unless @is_visible(shooter, target)
    true
  # TODO: Doing this function properly is actually fairly nontrivial, this is very dirty approximation
  compute_range: (x0, y0, m) ->
    range = []
    for dy in [-m..m]
      for dx in [-m..m]
        continue if dx * dx + dy * dy > m * m
        x = x0 + dx
        y = y0 + dy
        continue if x < 0 or y < 0 or x >= 30 or y >= 30
        continue if @is_object_present(x, y)
        range.push x: x, y: y
    range
  hit_chance: (shooter, target) ->
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    chance = shooter.aim - target.defense - shooter.aim_penalty_for_distance(distance) - @cover_status(shooter, target).cover + (shooter.gun.aimbonus || 0)
    chance += 10 if shooter.has_ability('SCOPE')
    chance += 10 if shooter.has_ability('Executioner') and target.hp*2 < target.hpmax
    clamp_probability(chance)
  sidearm_hit_chance: (shooter, target) ->
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    chance = shooter.aim - target.defense - @cover_status(shooter, target).cover
    chance += 10 if shooter.has_ability('Executioner') and target.hp*2 < target.hpmax
    clamp_probability(chance)
  crit_chance: (shooter, target) ->
    chance = shooter.gun.crit_chance
    return 0 if shooter.has_ability('Resilience')
    chance += 10 if shooter.has_ability('SCOPE')
    chance += 50 if @cover_status(shooter, target).cover == 0
    clamp_probability(chance)
  sidearm_crit_chance: (shooter, target) ->
    chance = shooter.sidearm.crit_chance
    return 0 if shooter.has_ability('Resilience')
    chance += 50 if @cover_status(shooter, target).cover == 0
    clamp_probability(chance)
  in_move_range: (unit, x, y) ->
    for cell in @compute_range(unit.x, unit.y, unit.mobility)
      return true if cell.x is x and cell.y is y
    false
