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
  cover_status: (shooter, target) ->
    left    = @cover_level(target.x - 1, target.y)
    right   = @cover_level(target.x + 1, target.y)
    top     = @cover_level(target.x, target.y - 1)
    bottom  = @cover_level(target.x, target.y + 1)
    best_cover = _.max([left,right,top,bottom])
    cover = _.max([
      if shooter.x < target.x then left else 0,
      if shooter.x > target.x then right else 0,
      if shooter.y < target.y then top else 0,
      if shooter.y > target.y then bottom else 0,
    ])
    cover = 40 if cover == 20 and target.has_ability('Low profile')
    description = if best_cover == 0
      "In the open"
    else if cover == 0
      "Flanked"
    else if cover <= 20
      "Low cover (#{cover})"
    else
      "High cover (#{cover})"
    {
      description: description
      cover: cover
    }
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
    if chance > 100
      100
    else if chance < 0
      0
    else
      chance
  crit_chance: (shooter, target) ->
    chance = shooter.gun.crit_chance
    return 0 if shooter.has_ability('Resilience')
    chance += 10 if shooter.has_ability('SCOPE')
    chance += 50 if @cover_status(shooter, target).cover == 0
    chance
  in_move_range: (unit, x, y) ->
    for cell in @compute_range(unit.x, unit.y, unit.mobility)
      return true if cell.x is x and cell.y is y
    false
