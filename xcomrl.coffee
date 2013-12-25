## Core ext
random_int = (n) ->
  Math.floor Math.random() * n

dist2 = (x, y) ->
  Math.sqrt x * x + y * y

current_time = () ->
  (new Date()).getTime()

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc

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

## Pure UI (display and input) stuff, no logic here
## one thing this is aware of (and maybe shouldn't be) is map size, currently hardcoded
## Nothing outside this class should ever do any jQuery or DOM access or such stuff
class UI
  constructor: ->
    @canvas = document.getElementById("main_canvas")
    @ctx = @canvas.getContext("2d")
    @ctx.font = "18px Courier"
    @ctx.lineCap = "round"
    @mouse_x = null
    @mouse_y = null
    @decorations = []
    $(@canvas).bind "mousemove", (event) =>
      [@mouse_x, @mouse_y] = @event_xy_to_cell(event)
      null
    $(@canvas).bind "mouseout", (event) ->
      @mouse_x = null
      @mouse_y = null
      null
  event_xy_to_cell: (event) ->
    rect = @canvas.getBoundingClientRect()
    [
      Math.floor((event.clientX - rect.left) / 24),
      Math.floor((event.clientY - rect.top) / 24),
    ]
  styles:
    "soldier 1": {icon: "1",bg: "#000",fg: "#fff"}
    "soldier 2": {icon: "2",bg: "#000",fg: "#fff"}
    "soldier 3": {icon: "3",bg: "#000",fg: "#fff"}
    "soldier 4": {icon: "4",bg: "#000",fg: "#fff"}
    sectoid: {icon: "s",bg: "#800",fg: "#f00"}
    thin_man: {icon: "t",bg: "#800",fg: "#f00"}
    muton: {icon: "m",bg: "#800",fg: "#f00"}
    muton_elite: {icon: "e",bg: "#800",fg: "#f00"}
    car: {icon: "c",bg: "#afa",fg: "#0f0"}
    wall: {icon: "W",bg: "#afa",fg: "#080"}
    door: {icon: "D",bg: "#aaf",fg: "#008"}
    "abducted cow": {icon: "C",bg: "#afa",fg: "#080"}
    "abducted goat": {icon: "g",bg: "#afa",fg: "#0f0"}
    rock: {icon: "r",bg: "#afa",fg: "#080"}
    movement_highlight: {bg: "#ccf"}
    dash_movement_highlight: {bg: "#eef"}
    dead: {icon: "X",bg: "#000",fg: "#800"}
  clear_canvas: ->
    @ctx.clearRect 0, 0, @canvas.width, @canvas.height
  draw_cell: (i, j, style) ->
    @ctx.fillStyle = style
    @ctx.fillRect i*24+1, j*24+1, 24-2, 24-2
  draw_text_sprite: (obj) ->
    x = obj.x
    y = obj.y
    style = @styles[obj.style]
    @draw_cell x, y, style.bg
    if style.icon
      @ctx.fillStyle = style.fg
      xsz = @ctx.measureText(style.icon).width
      @ctx.fillText style.icon, x * 24 + 12 - xsz / 2, y * 24 + 12 + 6
  draw_all_bounds: (i, j, style) ->
    x0 = i * 24
    y0 = j * 24
    @ctx.strokeStyle = style
    @ctx.beginPath()
    @ctx.moveTo x0, y0
    @ctx.lineTo x0 + 24, y0
    @ctx.lineTo x0 + 24, y0 + 24
    @ctx.lineTo x0, y0 + 24
    @ctx.lineTo x0, y0
    @ctx.stroke()
  draw_grid: ->
    @ctx.lineWidth = 1
    for i in [0..29]
      for j in [0..29]
        @draw_all_bounds i, j, "#ccc"
  highlight_current_soldier: (x,y) ->
    @ctx.lineWidth = 3
    @draw_all_bounds x, y, "#f00"
  highlight_mouseover: ->
    return if @mouse_x is null or @mouse_y is null
    @ctx.lineWidth = 2
    @draw_all_bounds @mouse_x, @mouse_y, "#00f"
  highlight_target_in_fire_range: (x,y) ->
    @ctx.lineWidth = 2
    @draw_all_bounds x, y, "#00a"
  replace_content_if_differs: (target_id, fn) ->
    target = $("##{target_id}")
    source = $("<div></div>")
    fn source
    source_html = source[0].innerHTML
    target_html = target[0].innerHTML
    if source_html != target_html
      target.empty()
      target.append source_html
  display_decoration: (decoration) ->
    switch decoration.type
      when 'fire trail'
        @ctx.strokeStyle = '#f00'
        @ctx.beginPath()
        @ctx.moveTo decoration.x0*24+12, decoration.y0*24+12
        @ctx.lineTo decoration.x1*24+12, decoration.y1*24+12
        @ctx.stroke()
      when 'text'
        @ctx.fillStyle = '#f00'
        @ctx.fillText decoration.msg, decoration.x*24+12 , decoration.y*24+12
  display_decorations: ->
    time = current_time()
    @decorations = (d for d in @decorations when time <= d.timeout)
    @display_decoration(d) for d in @decorations
  add_fire_trail: (shooter, target, msg) ->
    @decorations.push
      type: 'fire trail'
      x0: shooter.x
      y0: shooter.y
      x1: target.x
      y1: target.y
      timeout: current_time() + 1500
    @add_message target.x, target.y, msg
  add_message: (x,y,msg) ->
    @decorations.push
      type: 'text'
      x: x
      y: y
      msg: msg
      timeout: current_time() + 3000

## Everything below is a very dirty mix of UI, logic, and other stuff
$ ->
  ## Instance variables
  ui = new UI()
  map = new Map()
  current_soldier_idx = null
  current_mode = null

  ## Everything else

  current_soldier = ->
    map.soldiers[current_soldier_idx]

  display_soldier_info = (soldier) ->
    ui.replace_content_if_differs "soldier_info", (updated) ->
      updated.append "<div>#{soldier.rank} #{soldier.name}</div>"
      updated.append "<div>HP: #{soldier.hp}/#{soldier.hpmax}</div>"
      updated.append "<div>Aim: #{soldier.aim}</div>"
      updated.append "<div>Mobility: #{soldier.mobility}</div>"
      updated.append "<div>XP: #{soldier.xp}</div>"
      updated.append "<div>Actions: #{soldier.actions}/2</div>"
      if soldier.overwatch
        updated.append "<div>On overwatch</div>"
      updated.append "<div><b>Equipment</b></div>"
      updated.append "<div>#{soldier.gun_type} (#{soldier.ammo}/#{soldier.ammomax})</div>"
      updated.append "<div><b>Abilities</b></div>"
      for ability in soldier.abilities
        updated.append "<div>#{ability}</div>"

  highlight_current_soldier = ->
    x = current_soldier().x
    y = current_soldier().y
    ui.highlight_current_soldier x, y

  # TODO: this should go within Alien
  random_move = (alien) ->
    range = map.compute_range(alien.x, alien.y, alien.mobility)
    move = range[random_int(range.length)]
    alien.action_move move.x, move.y

  any_alien_in_range = ->
    for alien in map.live_aliens
      return true if current_soldier().in_fire_range(alien)
    false

  # TODO: this should go within Alien
  process_alien_actions = (alien) ->
    return if alien.hp is 0
    random_move(alien)
    if alien.ammo == 0
      alien.action_reload()
    else
      soldiers_in_range = (soldier for soldier in map.live_soldiers when alien.in_fire_range(soldier))
      if soldiers_in_range.length
        fire_action alien, soldier
      else
        random_move alien

  aliens_turn = ->
    for alien in map.aliens
      alien.start_new_turn()
    for alien in map.aliens
      process_alien_actions alien

  start_new_turn = ->
    for soldier in map.soldiers
      soldier.start_new_turn()
    current_mode = "move"
    current_soldier_idx = 0
    unless map.all_soldiers_dead
      while current_soldier().hp == 0
        current_soldier_idx++

  find_next_soldier_idx = ->
    for i in [(current_soldier_idx+1)...map.soldiers.length]
      return i if map.soldiers[i].actions > 0
    if current_soldier_idx != 0
      for i in [0..(current_soldier_idx-1)]
        return i if map.soldiers[i].actions > 0
    null

  ## Actions
  next_soldier = ->
    i = find_next_soldier_idx()
    if i is null
      current_soldier_idx = 0
      end_turn()
    else
      current_soldier_idx = i
    current_mode = "move"

  end_turn = ->
    aliens_turn()
    start_new_turn()

  action_reload = ->
    soldier = current_soldier()
    soldier.action_reload()
    ui.add_message soldier.x, soldier.y, 'Reload'
    next_soldier()

  action_overwatch = ->
    soldier = current_soldier()
    soldier.action_overwatch()
    ui.add_message soldier.x, soldier.y, 'Overwatch'
    next_soldier()

  action_promotion = (choice) ->
    soldier = current_soldier()
    ability = soldier.promotion_options[choice]
    soldier.promotion(ability)

  highlight_current_soldier_move_range = ->
    soldier = current_soldier()
    if soldier.actions == 2
      for cell in map.compute_range(soldier.x, soldier.y, 2*soldier.mobility)
        ui.draw_text_sprite x: cell.x, y: cell.y, style: "dash_movement_highlight"
    for cell in map.compute_range(soldier.x, soldier.y, soldier.mobility)
      ui.draw_text_sprite x: cell.x, y: cell.y, style: "movement_highlight"

  highlight_current_soldier_fire_range = ->
    for alien in map.live_aliens
      if current_soldier().in_fire_range(alien)
        ui.highlight_target_in_fire_range(alien.x, alien.y)

  # TODO: maybe some of this should go within Soldier or Map ???
  potential_actions = ->
    soldier = current_soldier()
    actions = []
    actions.push key: 'e', label: 'End turn'
    if soldier.hp > 0
      if soldier.promotion_options.length
        for ability, i in soldier.promotion_options
          actions.push key: "#{i+1}", label: "Promotion - #{ability}"
      if soldier.actions > 0
        if soldier.ammo < soldier.ammomax
          actions.push key: 'r', label: 'Reload'
        if current_mode == 'fire'
          actions.push key: 'm', label: 'Move'
        if soldier.ammo > 0
          if !soldier.gun_needs_two_actions or soldier.actions == 2
            actions.push key: 'o', label: 'Overwatch'
            if current_mode == 'move'
              if any_alien_in_range()
                actions.push key: 'f', label: 'Fire'
              else
                actions.push key: 'f', label: 'Fire', inactive: 'no targets in range'
        else
          actions.push key: 'o', label: 'Overwatch', inactive: 'no ammo'
          actions.push key: 'f', label: 'Fire', inactive: 'no ammo'
    if find_next_soldier_idx() isnt null
      actions.push key: 'n', label: 'Next soldier'
    _.sortBy actions, (action) ->
      action.key

  action_is_valid = (key) ->
    for action in potential_actions()
      return true if action.key == key and not action.inactive
    false

  perform_action = (key) ->
    return unless action_is_valid(key)
    # Interface/global action
    end_turn() if key is 'e'
    current_mode = 'fire' if key is 'f'
    current_mode = 'move' if key is 'm'
    next_soldier() if key is 'n'
    # Soldier actions
    action_reload() if key is 'r'
    action_overwatch() if key is 'o'
    action_promotion(0) if key is '1'
    action_promotion(1) if key is '2'
    action_promotion(2) if key is '3'

  display_available_actions = ->
    ui.replace_content_if_differs "actions", (updated) ->
      for action in potential_actions()
        if action.inactive
          updated.append("<div class='inactive_action'>#{action.key} #{action.label} (#{action.inactive})</div>")
        else
          updated.append("<div class='action' data-key='#{action.key}'>#{action.key} #{action.label}</div>")

  display_mouseover_object = ->
    ui.replace_content_if_differs "mouseover_object", (updated) ->
      return if ui.mouse_x is null or ui.mouse_y is null
      updated.append "<div class='coordinates'>x=" + ui.mouse_x + " y=" + ui.mouse_y + "</div>"
      found = map.find_object(ui.mouse_x, ui.mouse_y)
      object = found.object
      switch found.type
        when "soldier"
          updated.append "<div>#{object.rank} #{object.name} (#{object.hp}/#{object.hpmax})</div>"
        when "alien"
          updated.append "<div>Alien #{object.style} (#{object.hp}/#{object.hpmax})</div>"
          if current_soldier().in_fire_range(object)
            updated.append "<div>In range (hit #{map.hit_chance(current_soldier(), object)}%, crit #{map.crit_chance(current_soldier(), object)}%)</div>"
          else
            updated.append "<div>Out of range</div>"
          updated.append "<div>#{map.cover_status(current_soldier(), object).description}</div>"
        when "object"
          updated.append "<div>#{object.style}</div>"
          updated.append "<div>Cover level #{object.cover}</div>"
        when "empty"
          updated.append "<div>Empty</div>"

  fire_action = (shooter, target) ->
    shooter.actions = 0
    shooter.ammo -= 1
    if Math.random() * 100 < map.hit_chance(shooter, target)
      if Math.random() * 100 < map.crit_chance(shooter, target)
        target.take_damage shooter.gun_damage
        ui.add_fire_trail shooter, target, "#{shooter.gun_damage}"
      else
        target.take_damage shooter.gun_crit_damage
        ui.add_fire_trail shooter, target, "#{shooter.gun_crit_damage}"
      if target.hp is 0
        shooter.register_kill target
    else
      ui.add_fire_trail shooter, target, "X"

  clicked_on = (x, y) ->
    return if map.all_soldiers_dead
    soldier = current_soldier()
    object_clicked = map.find_object(x, y)
    if object_clicked.type == "soldier"
      current_soldier_idx = map.soldiers.indexOf(object_clicked.object)
      return
    if current_mode is "move" and soldier.actions > 0
      if map.in_move_range(soldier, x, y)
        soldier.action_move x, y
    if current_mode is "fire" and soldier.actions > 0
      return unless soldier.in_fire_range(x: x, y: y)
      object_clicked = map.find_object(x, y)
      return if object_clicked.type != "alien"
      fire_action soldier, object_clicked.object
    next_soldier() if soldier.actions is 0

  display_info = ->
    ui.replace_content_if_differs "map_info", (updated) ->
      updated.append("Level #{map.level_number}")
    display_soldier_info current_soldier()
    display_mouseover_object()
    display_available_actions()
    ui.replace_content_if_differs "game_status", (updated) ->
      if map.all_soldiers_dead
        updated.append("You lost!")
      else if map.all_aliens_dead
        map.generate_level()
        start_new_turn()

  draw_map = ->
    ui.clear_canvas()
    ui.draw_grid()
    ui.draw_text_sprite(drawable) for drawable in map.soldiers
    ui.draw_text_sprite(drawable) for drawable in map.aliens
    ui.draw_text_sprite(drawable) for drawable in map.objects
    ui.highlight_mouseover()
    if current_soldier()
      highlight_current_soldier()
      highlight_current_soldier_move_range() if current_mode is "move"
      highlight_current_soldier_fire_range() if current_mode is "fire"
    display_info()
    ui.display_decorations()

  # TODO: Some of this code should go within UI
  $(ui.canvas).bind "click", (event) ->
    [x, y] = ui.event_xy_to_cell(event)
    clicked_on x, y
    null
  $(document).bind "keypress", (event) ->
    return if map.all_soldiers_dead
    perform_action String.fromCharCode(event.which).toLowerCase()
    null
  $("#actions").on "click", ".action", (event) ->
    perform_action $(event.target).data("key")
    null
  main_loop = ->
    draw_map()
    null

  map.generate_initial_squad()
  map.generate_level()
  start_new_turn()
  # TODO: window.requestAnimationFrame(main_loop); ???
  setInterval main_loop, 1000.0 / 60.0
  null
