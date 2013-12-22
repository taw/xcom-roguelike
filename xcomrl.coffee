$ ->
  ## Static global data
  styles =
    "soldier 1": {icon: "1",bg: "#000",fg: "#fff"}
    "soldier 2": {icon: "2",bg: "#000",fg: "#fff"}
    "soldier 3": {icon: "3",bg: "#000",fg: "#fff"}
    "soldier 4": {icon: "4",bg: "#000",fg: "#fff"}
    sectoid: {icon: "s",bg: "#800",fg: "#f00"}
    muton: {icon: "m",bg: "#800",fg: "#f00"}
    berserker: {icon: "B",bg: "#800",fg: "#f00"}
    car: {icon: "c",bg: "#afa",fg: "#0f0"}
    wall: {icon: "W",bg: "#afa",fg: "#0f0"}
    door: {icon: "D",bg: "#aaf",fg: "#00f"}
    movement_highlight: {bg: "#ccf"}
    dead: {icon: "X",bg: "#000",fg: "#800"}

  guns =
    rifle: {damage: 3, crit: 4, crit_chance: 10, range: 10}
    shotgun: {damage: 4, crit: 6, crit_chance: 20, range: 10, far_range: 5}
    lmg: {damage: 4, crit: 6, crit_chance: 0, range: 10}
    sniper_rifle: {damage: 4, crit: 6, crit_chance: 25, range: 20, min_range: 5}
    plasma_pistol: {damage: 3, crit: 4, crit_chance: 10, range: 10}
    light_plasma_rifle: {damage: 5, crit: 7, crit_chance: 10, range: 10}

  ## Instance variables
  canvas = document.getElementById("main_canvas")
  ctx = canvas.getContext("2d")
  ctx.font = "18px Courier"
  ctx.lineCap = "round"
  soldiers = []
  aliens = []
  objects = []
  current_soldier_idx = undefined
  mouse_x = undefined
  mouse_y = undefined
  current_mode = undefined

  ## Core ext
  random_int = (n) ->
    Math.floor Math.random() * n

  dist2 = (x, y) ->
    Math.sqrt x * x + y * y


  # populate 5x5 level
  populate_level_fragment = (x0, y0) ->
    x = x0 + random_int(4)
    y = y0 + random_int(4)
    switch random_int(10)
      when 0
        aliens.push
          x: x
          y: y
          style: "sectoid"
          hp: 3
          hpmax: 3
          mobility: 5
          aim: 65
          gun: 'plasma_pistol'

      when 1
        aliens.push
          x: x
          y: y
          style: "muton"
          hp: 6
          hpmax: 6
          mobility: 5
          aim: 75
          gun: 'light_plasma_rifle'

      when 2, 3
        objects.push
          x: x
          y: y
          style: "car"

        objects.push
          x: x
          y: y + 1
          style: "car"

      when 4, 5
        objects.push
          x: x
          y: y
          style: "car"

        objects.push
          x: x + 1
          y: y
          style: "car"

      when 6, 7
        objects.push
          x: x0
          y: y0
          style: "wall"

        objects.push
          x: x0
          y: y0 + 1
          style: "wall"

        objects.push
          x: x0
          y: y0 + 2
          style: "door"

        objects.push
          x: x0
          y: y0 + 3
          style: "wall"

        objects.push
          x: x0
          y: y0 + 4
          style: "wall"

        objects.push
          x: x0 + 1
          y: y0
          style: "wall"

        objects.push
          x: x0 + 2
          y: y0
          style: "door"

        objects.push
          x: x0 + 3
          y: y0
          style: "wall"

        objects.push
          x: x0 + 4
          y: y0
          style: "wall"

  generate_level = ->
    soldiers.push
      name: "Alice"
      x: 1
      y: 1
      style: "soldier 1"
      hp: 7
      hpmax: 7
      aim: 70
      mobility: 5
      gun: 'shotgun'
      xp: 0

    soldiers.push
      name: "Bob"
      x: 3
      y: 3
      style: "soldier 2"
      hp: 7
      hpmax: 7
      aim: 67
      mobility: 5
      gun: 'lmg'
      xp: 0

    soldiers.push
      name: "Charlie"
      x: 1
      y: 3
      style: "soldier 3"
      hp: 6
      hpmax: 6
      aim: 75
      mobility: 5
      gun: 'sniper_rifle'
      xp: 0

    soldiers.push
      name: "Diana"
      x: 3
      y: 1
      style: "soldier 4"
      hp: 7
      hpmax: 7
      aim: 70
      mobility: 5
      gun: 'rifle'
      xp: 0

    for i in [0..5]
      for j in [0..5]
        if i isnt 0 or j isnt 0
          populate_level_fragment i * 5, j * 5

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

  display_soldier_info = (soldier) ->
    $("#soldier_info").empty()
    $("#soldier_info").append "<div class='name'>Squaddie #{soldier.name}</div>"
    $("#soldier_info").append "<div class='hp'>HP: #{soldier.hp}/#{soldier.hpmax}</div>"
    $("#soldier_info").append "<div class='aim'>Aim: #{soldier.aim}</div>"
    $("#soldier_info").append "<div class='mobility'>Mobility: #{soldier.mobility}</div>"
    $("#soldier_info").append "<div class='xp'>XP: #{soldier.xp}</div>"
    $("#soldier_info").append "<div class='actions'>Actions: #{soldier.actions}/2</div>"

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
      if in_fire_range(current_soldier(), alien)
        return true
    false

  process_alien_actions = (alien) ->
    return if alien.hp is 0
    random_move alien
    for soldier in live_soldiers()
      if in_fire_range(alien, soldier)
        fire_action alien, soldier
    random_move alien  if alien.actions > 0

  aliens_turn = ->
    for alien in aliens
      if alien.hp > 0
        alien.actions = 2
      else
        alien.actions = 0
      alien.overwatch = false
    for alien in live_aliens()
      process_alien_actions alien

  start_new_turn = ->
    for soldier in soldiers
      if soldier.hp > 0
        soldier.actions = 2
      else
        soldier.actions = 0
      soldier.overwatch = false
    current_mode = "move"
    current_soldier_idx = 0

  find_next_soldier_idx = ->
    i = current_soldier_idx + 1
    until i is current_soldier_idx
      i %= soldiers.length
      break if soldiers[i].actions > 0
      i += 1
    if i is current_soldier_idx
      null
    else
      i

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

  overwatch = ->
    current_soldier().overwatch = true
    current_soldier().actions = 0
    next_soldier()

  highlight_mouseover = ->
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
    for cell in compute_range(soldier.x, soldier.y, soldier.mobility)
      draw_text_sprite
        x: cell.x
        y: cell.y
        style: "movement_highlight"

  highlight_current_soldier_fire_range = ->
    for alien in live_aliens()
      if in_fire_range(current_soldier(), alien)
        ctx.lineWidth = 2
        draw_all_bounds alien.x, alien.y, "#00a"

  display_available_actions = ->
    $("#actions").empty()
    if current_mode == 'move'
      if any_alien_in_range()
        $("#actions").append("<div class='action'>f Fire</div>")
      else
        $("#actions").append("<div class='inactive_action'>f Fire (no targets)</div>")
    if current_mode == 'fire'
      $("#actions").append("<div class='action'>m Move</div>")
    $("#actions").append("<div class='action'>o Overwatch</div>")
    $("#actions").append("<div class='action'>e End turn</div>")
    if find_next_soldier_idx() isnt null
      $("#actions").append("<div class='action'>n Next soldier</div>")

  find_object = (x, y) ->
    try
      for soldier in soldiers
        if soldier.x is x and soldier.y is y
          throw type: "soldier", object: soldier
      for alien in aliens
        if alien.x is x and alien.y is y
          throw type: "alien", object: alien
      for object in objects
        if object.x is x and object.y is y
          throw type: "object", object: object
      throw type: "empty"
    catch err
      # Found the object!
      return err

  is_object_present = (x, y) ->
    found = find_object(x, y)
    found.type isnt "empty"

  display_mouseover_object = ->
    $("#mouseover_object").empty()
    return if mouse_x is null or mouse_y is null
    $("#mouseover_object").append "<div class='coordinates'>x=" + mouse_x + " y=" + mouse_y + "</div>"
    found = find_object(mouse_x, mouse_y)
    object = found.object
    switch found.type
      when "soldier"
        $("#mouseover_object").append "<div>Squaddie #{object.name} (#{object.hp}/#{object.hpmax})</div>"
      when "alien"
        $("#mouseover_object").append "<div>Alien #{object.style} (#{object.hp}/#{object.hpmax})</div>"
        if in_fire_range(current_soldier(), object)
          $("#mouseover_object").append "<div>In range (hit chance #{hit_chance(current_soldier(), object)}%)</div>"
        else
          $("#mouseover_object").append "<div>Out of range</div>"
      when "object"
        $("#mouseover_object").append "<div>object #{object.style}</div>"
      when "empty"
        $("#mousover_object").append "<div>Empty</div>"

  in_move_range = (soldier, x, y) ->
    range = compute_range(soldier.x, soldier.y, soldier.mobility)
    try
      for cell in range
        throw "found" if cell.x is x and cell.y is y
      return false
    catch err
      return true

  take_damage = (target, damage) ->
    target.hp -= damage
    if target.hp <= 0
      target.hp = 0
      target.style = "dead"

  hit_chance = (shooter, target) ->
    chance = shooter.aim
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    gun = guns[shooter.gun]

    # Aim penalty of up to -20 if too far
    if gun.far_range and distance >= gun.far_range
      chance -= Math.round(20 * (distance - gun.far_range) / (gun.range - gun.far_range))

    # Aim penalty of up to -20 if too close
    if gun.near_range and distance <= gun.near_range
      chance -= Math.round(20 * (gun.near_range - distance) / gun.near_range)

    # -40 if next to an object (TODO: flanking direction)
    chance -= 40  if find_object(target.x + 1, target.y).type is "object" or find_object(target.x - 1, target.y).type is "object" or find_object(target.x, target.y + 1).type is "object" or find_object(target.x, target.y - 1).type is "object"
    chance

  register_kill = (shooter, target) ->
    if shooter.xp isnt null
      shooter.xp += 30

  fire_action = (shooter, target) ->
    gun = guns[shooter.gun]
    chance = hit_chance(shooter, target)
    shooter.actions = 0
    return unless Math.random() * 100 < chance
    if Math.random() * 100 < gun.crit_chance
      take_damage target, gun.damage
    else
      take_damage target, gun.crit
    if target.hp is 0
      register_kill shooter, target

  in_fire_range = (shooter, target) ->
    gun_range = guns[shooter.gun].range
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    distance <= gun_range

  clicked_on = (x, y) ->
    soldier = current_soldier()
    if current_mode is "move"
      if in_move_range(soldier, x, y)
        soldier.x = x
        soldier.y = y
        soldier.actions -= 1
    if current_mode is "fire"
      return unless in_fire_range(soldier, x: x, y: y)
      found = find_object(x, y)
      return  if found.type isnt "alien"
      fire_action soldier, found.object
    next_soldier()  if soldier.actions is 0

  all_soldiers_dead = ->
    (true for soldier in soldiers when soldier.hp > 0).length == 0

  all_aliens_dead = ->
    (true for alien in aliens when alien.hp > 0).length == 0

  display_info = ->
    display_soldier_info current_soldier()
    display_mouseover_object()
    display_available_actions()
    $("#game_status").empty()
    if all_soldiers_dead()
      $("#game_status").append("You lost!")
    if all_aliens_dead()
      $("#game_status").append("You won!")

  draw_map = ->
    clear_canvas()
    draw_grid()
    draw_objects()
    highlight_mouseover()
    highlight_current_soldier()
    highlight_current_soldier_move_range() if current_mode is "move"
    highlight_current_soldier_fire_range() if current_mode is "fire"
    display_info()

  $(canvas).bind "mousemove", (event) ->
    rect = canvas.getBoundingClientRect()
    mouse_x = Math.floor((event.clientX - rect.left) / 24)
    mouse_y = Math.floor((event.clientY - rect.top) / 24)
    null

  $(canvas).bind "click", (event) ->
    if all_soldiers_dead()
      return
    rect = canvas.getBoundingClientRect()
    x = Math.floor((event.clientX - rect.left) / 24)
    y = Math.floor((event.clientY - rect.top) / 24)
    clicked_on x, y
    null

  $(document).bind "keypress", (event) ->
    if all_soldiers_dead()
      return
    char = String.fromCharCode(event.which).toLowerCase()
    end_turn() if char is 'e'
    fire_mode() if char is 'f'
    move_mode() if char is 'm'
    next_soldier() if char is 'n'
    overwatch() if char is 'o'
    null

  main_loop = ->
    draw_map()
    null

  generate_level()
  start_new_turn()
  setInterval main_loop, 1000.0 / 60.0
  null

# TODO: window.requestAnimationFrame(main_loop); ???
