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
  pistol: {damage: 1, crit: 1, crit_chance: 1, range: 10}
  plasma_pistol: {damage: 3, crit: 4, crit_chance: 10, range: 10}
  shotgun: {damage: 4, crit: 6, crit_chance: 20, range: 10, far_range: 5, ammomax: 4}
  rifle: {damage: 3, crit: 4, crit_chance: 10, range: 10, ammomax: 4}
  light_plasma_rifle: {damage: 5, crit: 7, crit_chance: 10, range: 10, ammomax: 4}
  plasma_rifle: {damage: 7, crit: 10, crit_chance: 10, range: 10, ammomax: 4}
  sniper_rifle: {damage: 4, crit: 6, crit_chance: 25, range: 20, min_range: 5, two_actions: true, ammomax: 4}
  lmg: {damage: 4, crit: 6, crit_chance: 0, range: 10, ammomax: 3}
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
    get: -> @gun.ammomax
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

class Soldier extends Unit
  constructor: (attrs) ->
    super
    @xp ||= 0
  register_kill: (victim) ->
    @xp += 30

$ ->
  ## Static global data
  styles =
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
    rock: {icon: "r",bg: "#afa",fg: "#8f8"}
    movement_highlight: {bg: "#ccf"}
    dash_movement_highlight: {bg: "#eef"}
    dead: {icon: "X",bg: "#000",fg: "#800"}

  ## Instance variables
  canvas = document.getElementById("main_canvas")
  ctx = canvas.getContext("2d")
  ctx.font = "18px Courier"
  ctx.lineCap = "round"
  soldiers = []
  aliens = []
  objects = []
  current_soldier_idx = null
  mouse_x = null
  mouse_y = null
  current_mode = null
  level_number = 0
  decorations = []

  ## Create aliens

  create_sectoid = (x,y) ->
    new Unit
      x: x
      y: y
      style: "sectoid"
      hpmax: 3
      mobility: 5
      aim: 65
      gun_type: 'plasma_pistol'

  create_thin_man = (x,y) ->
    new Unit
      x: x
      y: y
      style: "thin_man"
      hpmax: 3
      mobility: 7
      aim: 65
      gun_type: 'light_plasma_rifle'

  create_muton = (x,y) ->
    new Unit
      x: x
      y: y
      style: "muton"
      hpmax: 6
      mobility: 5
      aim: 70
      gun_type: 'plasma_rifle'
      abilities: ['alien_grenade']

  create_muton_elite = (x,y) ->
    new Unit
      x: x
      y: y
      style: "muton_elite"
      hpmax: 14
      mobility: 5
      aim: 80
      defense: 20
      gun_type: 'heavy_plasma'
      abilities: ['alien_grenade']

  ## Everything else

  # populate 5x5 level
  populate_level_fragment = (x0, y0) ->
    x = x0 + random_int(4)
    y = y0 + random_int(4)
    switch random_int(20)
      when 0, 1, 2, 3
        if level_number <= 2
          aliens.push create_sectoid(x, y)
        else if level_number <= 4
          aliens.push create_thin_man(x, y)
        else if level_number <= 6
          aliens.push create_muton(x, y)
        else
          aliens.push create_muton_elite(x, y)
      when 4, 5
        objects.push x: x, y: y,     style: "car", cover: 20
        objects.push x: x, y: y + 1, style: "car", cover: 20
      when 6, 7
        objects.push x: x,     y: y, style: "car", cover: 20
        objects.push x: x + 1, y: y, style: "car", cover: 20
      when 8, 9, 10, 11
        objects.push x: x0,   y: y0,   style: "wall", cover: 40
        objects.push x: x0,   y: y0+1, style: "wall", cover: 40
        objects.push x: x0,   y: y0+2, style: "door", cover: 40
        objects.push x: x0,   y: y0+3, style: "wall", cover: 40
        objects.push x: x0,   y: y0+4, style: "wall", cover: 40
        objects.push x: x0+1, y: y0,   style: "wall", cover: 40
        objects.push x: x0+2, y: y0,   style: "door", cover: 40
        objects.push x: x0+3, y: y0,   style: "wall", cover: 40
        objects.push x: x0+4, y: y0,   style: "wall", cover: 40
      when 12
        objects.push x: x,    y: y,    style: "abducted cow", cover: 40
      when 13
        objects.push x: x,    y: y,    style: "rock", cover: 40

  generate_initial_squad = ->
    soldiers.push(
      new Soldier
        name: "Alice"
        style: "soldier 1"
        hpmax: 7
        aim: 70
        mobility: 5
        gun_type: 'shotgun'
        abilities: ['Run and gun']
    )
    soldiers.push(
      new Soldier
        name: "Bob"
        style: "soldier 2"
        hpmax: 7
        aim: 67
        mobility: 5
        gun_type: 'lmg'
        abilities: ['Fire rocket']
    )
    soldiers.push(
      new Soldier
        name: "Charlie"
        style: "soldier 3"
        hpmax: 6
        aim: 75
        mobility: 5
        gun_type: 'sniper_rifle'
    )
    soldiers.push(
      new Soldier
        name: "Diana"
        style: "soldier 4"
        hpmax: 7
        aim: 70
        mobility: 5
        gun_type: 'rifle'
    )
  generate_level = ->
    level_number++
    soldiers[0].x = 1
    soldiers[0].y = 1
    soldiers[1].x = 3
    soldiers[1].y = 3
    soldiers[2].x = 1
    soldiers[2].y = 3
    soldiers[3].x = 3
    soldiers[3].y = 1
    aliens = []
    for i in [0..5]
      for j in [0..5]
        if i isnt 0 or j isnt 0
          populate_level_fragment i * 5, j * 5
    for soldier in soldiers
      soldier.start_new_level()
    for alien in aliens
      alien.start_new_level()

  clear_canvas = ->
    ctx.clearRect 0, 0, canvas.width, canvas.height

  draw_cell = (i, j, style) ->
    ctx.fillStyle = style
    ctx.fillRect i * 24 + 1, j * 24 + 1, 24 - 2, 24 - 2

  draw_text_sprite = (obj) ->
    x = obj.x
    y = obj.y
    style = styles[obj.style]
    draw_cell x, y, style.bg
    if style.icon
      ctx.fillStyle = style.fg
      xsz = ctx.measureText(style.icon).width
      ctx.fillText style.icon, x * 24 + 12 - xsz / 2, y * 24 + 12 + 6

  draw_all_bounds = (i, j, style) ->
    x0 = i * 24
    y0 = j * 24
    ctx.strokeStyle = style
    ctx.beginPath()
    ctx.moveTo x0, y0
    ctx.lineTo x0 + 24, y0
    ctx.lineTo x0 + 24, y0 + 24
    ctx.lineTo x0, y0 + 24
    ctx.lineTo x0, y0
    ctx.stroke()

  draw_grid = ->
    ctx.lineWidth = 1
    for i in [0..29]
      for j in [0..29]
        draw_all_bounds i, j, "#ccc"

  draw_objects = ->
    for soldier in soldiers
      draw_text_sprite soldier
    for alien in aliens
      draw_text_sprite alien
    for object in objects
      draw_text_sprite object

  current_soldier = ->
    soldiers[current_soldier_idx]

  replace_content_if_differs = (target, fn) ->
    source = $("<div></div>")
    fn source
    source_html = source[0].innerHTML
    target_html = target[0].innerHTML
    if source_html != target_html
      target.empty()
      target.append source_html

  display_soldier_info = (soldier) ->
    replace_content_if_differs $("#soldier_info"), (updated) ->
      updated.append "<div>Squaddie #{soldier.name}</div>"
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
    ctx.lineWidth = 3
    draw_all_bounds x, y, "#f00"

  random_move = (alien) ->
    range = compute_range(alien.x, alien.y, alien.mobility)
    move = range[random_int(range.length)]
    alien.x = move.x
    alien.y = move.y
    alien.actions -= 1

  live_soldiers = ->
    (soldier for soldier in soldiers when soldier.hp > 0)

  live_aliens = ->
    (alien for alien in aliens when alien.hp > 0)

  any_alien_in_range = ->
    for alien in live_aliens()
      return true if current_soldier().in_fire_range(alien)
    false

  process_alien_actions = (alien) ->
    return if alien.hp is 0
    random_move alien
    if alien.ammo == 0
      alien.action_reload()
    else
      soldiers_in_range = (soldier for soldier in live_soldiers() when alien.in_fire_range(soldier))
      if soldiers_in_range.length
        fire_action alien, soldier
      else
        random_move alien

  aliens_turn = ->
    for alien in aliens
      alien.start_new_turn()
    for alien in live_aliens()
      process_alien_actions alien

  start_new_turn = ->
    for soldier in soldiers
      soldier.start_new_turn()
    current_mode = "move"
    current_soldier_idx = 0
    unless all_soldiers_dead()
      while current_soldier().hp == 0
        current_soldier_idx++

  find_next_soldier_idx = ->
    for i in [(current_soldier_idx+1)...soldiers.length]
      return i if soldiers[i].actions > 0
    if current_soldier_idx != 0
      for i in [0..(current_soldier_idx-1)]
        return i if soldiers[i].actions > 0
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

  fire_mode = ->
    current_mode = "fire"

  move_mode = ->
    current_mode = "move"

  end_turn = ->
    aliens_turn()
    start_new_turn()

  action_reload = ->
    soldier = current_soldier()
    soldier.action_reload()
    decorations.push
      type: 'text'
      x: soldier.x
      y: soldier.y
      msg: 'Reload'
      timeout: current_time() + 3000
    next_soldier()

  action_overwatch = ->
    soldier = current_soldier()
    soldier.action_overwatch()
    decorations.push
      type: 'text'
      x: soldier.x
      y: soldier.y
      msg: 'Overwatch'
      timeout: current_time() + 3000
    next_soldier()

  highlight_mouseover = ->
    return if mouse_x is null or mouse_y is null
    ctx.lineWidth = 2
    draw_all_bounds mouse_x, mouse_y, "#00f"

  # TODO: Doing this function properly is actually fairly nontrivial, this is very dirty approximation
  compute_range = (x0, y0, m) ->
    range = []
    for dy in [-m..m]
      for dx in [-m..m]
        continue if dx * dx + dy * dy > m * m
        x = x0 + dx
        y = y0 + dy
        continue if x < 0 or y < 0 or x >= 30 or y >= 30
        continue if is_object_present(x, y)
        range.push x: x, y: y
    range

  highlight_current_soldier_move_range = ->
    soldier = current_soldier()
    if soldier.actions == 2
      for cell in compute_range(soldier.x, soldier.y, 2*soldier.mobility)
        draw_text_sprite x: cell.x, y: cell.y, style: "dash_movement_highlight"
    for cell in compute_range(soldier.x, soldier.y, soldier.mobility)
      draw_text_sprite x: cell.x, y: cell.y, style: "movement_highlight"

  highlight_current_soldier_fire_range = ->
    for alien in live_aliens()
      if current_soldier().in_fire_range(alien)
        ctx.lineWidth = 2
        draw_all_bounds alien.x, alien.y, "#00a"

  potential_actions = ->
    soldier = current_soldier()
    gun = soldier.gun

    actions = []
    actions.push key: 'e', label: 'End turn'
    if soldier.hp > 0
      if soldier.ammo < gun.ammomax
        actions.push key: 'r', label: 'Reload'
      if current_mode == 'fire'
        actions.push key: 'm', label: 'Move'
      if soldier.ammo > 0
        if !gun.two_actions or soldier.actions == 2
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
    fire_mode() if key is 'f'
    move_mode() if key is 'm'
    next_soldier() if key is 'n'
    # Soldier actions
    action_reload() if key is 'r'
    action_overwatch() if key is 'o'

  display_available_actions = ->
    replace_content_if_differs $("#actions"), (updated) ->
      for action in potential_actions()
        if action.inactive
          updated.append("<div class='inactive_action'>#{action.key} #{action.label} (#{action.inactive})</div>")
        else
          updated.append("<div class='action' data-key='#{action.key}'>#{action.key} #{action.label}</div>")

  find_object = (x, y) ->
    for soldier in soldiers
      if soldier.x is x and soldier.y is y
        return type: "soldier", object: soldier
    for alien in aliens
      if alien.x is x and alien.y is y
        return type: "alien", object: alien
    for object in objects
      if object.x is x and object.y is y
        return type: "object", object: object
    return type: "empty"

  is_object_present = (x, y) ->
    find_object(x, y).type isnt "empty"

  display_mouseover_object = ->
    replace_content_if_differs $("#mouseover_object"), (updated) ->
      return if mouse_x is null or mouse_y is null
      updated.append "<div class='coordinates'>x=" + mouse_x + " y=" + mouse_y + "</div>"
      found = find_object(mouse_x, mouse_y)
      object = found.object
      switch found.type
        when "soldier"
          updated.append "<div>Squaddie #{object.name} (#{object.hp}/#{object.hpmax})</div>"
        when "alien"
          updated.append "<div>Alien #{object.style} (#{object.hp}/#{object.hpmax})</div>"
          if current_soldier().in_fire_range(object)
            updated.append "<div>In range (hit chance #{hit_chance(current_soldier(), object)}%)</div>"
          else
            updated.append "<div>Out of range</div>"
          updated.append "<div>#{cover_status(current_soldier(), object).description}</div>"
        when "object"
          updated.append "<div>object #{object.style}</div>"
          updated.append "<div>Cover level #{object.cover}</div>"
        when "empty"
          updated.append "<div>Empty</div>"

  in_move_range = (soldier, x, y) ->
    range = compute_range(soldier.x, soldier.y, soldier.mobility)
    for cell in range
      return true if cell.x is x and cell.y is y
    false

  cover_level = (x, y) ->
    # TODO: implement low cover too
    object = find_object(x, y)
    if object.type == 'object'
      object.cover
    else
      0

  cover_status = (shooter, target) ->
    left    = cover_level(target.x - 1, target.y)
    right   = cover_level(target.x + 1, target.y)
    top     = cover_level(target.x, target.y - 1)
    bottom  = cover_level(target.x, target.y + 1)
    best_cover = _.max([left,right,top,bottom])
    cover = _.max([
      if shooter.x < target.x then left else 0,
      if shooter.x > target.x then right else 0,
      if shooter.y < target.y then top else 0,
      if shooter.y > target.y then bottom else 0,
    ])
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

  hit_chance = (shooter, target) ->
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    chance = shooter.aim - target.defense - shooter.aim_penalty_for_distance(distance) - cover_status(shooter, target).cover
    if chance > 100
      100
    else if chance < 0
      0
    else
      chance

  fire_trail = (shooter, target, msg) ->
    decorations.push
      type: 'fire trail'
      x0: shooter.x
      y0: shooter.y
      x1: target.x
      y1: target.y
      timeout: current_time() + 1500
    decorations.push
      type: 'text'
      x: target.x
      y: target.y
      msg: msg
      timeout: current_time() + 3000

  fire_action = (shooter, target) ->
    gun = shooter.gun
    chance = hit_chance(shooter, target)
    shooter.actions = 0
    shooter.ammo -= 1
    if Math.random() * 100 < chance
      if Math.random() * 100 < gun.crit_chance
        target.take_damage gun.damage
        fire_trail shooter, target, "#{gun.damage}"
      else
        target.take_damage gun.crit
        fire_trail shooter, target, "#{gun.crit}"
      if target.hp is 0
        shooter.register_kill target
    else
      fire_trail shooter, target, "X"

  clicked_on = (x, y) ->
    soldier = current_soldier()
    object_clicked = find_object(x, y)

    if object_clicked.type == "soldier"
      current_soldier_idx = soldiers.indexOf(object_clicked.object)

    if current_mode is "move" and soldier.actions > 0
      if in_move_range(soldier, x, y)
        soldier.x = x
        soldier.y = y
        soldier.actions -= 1
    if current_mode is "fire"
      return unless soldier.in_fire_range(x: x, y: y)
      object_clicked = find_object(x, y)
      return if object_clicked.type != "alien"
      fire_action soldier, object_clicked.object
    next_soldier()  if soldier.actions is 0

  all_soldiers_dead = ->
    (true for soldier in soldiers when soldier.hp > 0).length == 0

  all_aliens_dead = ->
    (true for alien in aliens when alien.hp > 0).length == 0

  display_info = ->
    replace_content_if_differs $("#map_info"), (updated) ->
      updated.append("Level #{level_number}")
    display_soldier_info current_soldier()
    display_mouseover_object()
    display_available_actions()
    replace_content_if_differs $("#game_status"), (updated) ->
      if all_soldiers_dead()
        updated.append("You lost!")
      else if all_aliens_dead()
        generate_level()

  display_decorations = ->
    time = current_time()
    decorations = _.filter decorations, (decoration) ->
      time <= decoration.timeout
    for decoration in decorations
      switch decoration.type
        when 'fire trail'
          ctx.strokeStyle = '#f00'
          ctx.beginPath()
          ctx.moveTo decoration.x0*24+12, decoration.y0*24+12
          ctx.lineTo decoration.x1*24+12, decoration.y1*24+12
          ctx.stroke()
        when 'text'
          ctx.fillStyle = '#f00'
          ctx.fillText decoration.msg, decoration.x*24+12 , decoration.y*24+12

  draw_map = ->
    clear_canvas()
    draw_grid()
    draw_objects()
    highlight_mouseover()
    if current_soldier()
      highlight_current_soldier()
      highlight_current_soldier_move_range() if current_mode is "move"
      highlight_current_soldier_fire_range() if current_mode is "fire"
    display_info()
    display_decorations()

  $(canvas).bind "mousemove", (event) ->
    rect = canvas.getBoundingClientRect()
    mouse_x = Math.floor((event.clientX - rect.left) / 24)
    mouse_y = Math.floor((event.clientY - rect.top) / 24)
    null

  $(canvas).bind "click", (event) ->
    return if all_soldiers_dead()
    rect = canvas.getBoundingClientRect()
    x = Math.floor((event.clientX - rect.left) / 24)
    y = Math.floor((event.clientY - rect.top) / 24)
    clicked_on x, y
    null

  $(canvas).bind "mouseout", (event) ->
    mouse_x = null
    mouse_y = null
    null

  $(document).bind "keypress", (event) ->
    return if all_soldiers_dead()
    perform_action String.fromCharCode(event.which).toLowerCase()
    null

  $("#actions").on "click", ".action", (event) ->
    perform_action $(event.target).data("key")
    null

  main_loop = ->
    draw_map()
    null

  generate_initial_squad()
  generate_level()
  start_new_turn()
  # TODO: window.requestAnimationFrame(main_loop); ???
  setInterval main_loop, 1000.0 / 60.0
  null
