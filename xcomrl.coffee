$ ->
  canvas = document.getElementById("main_canvas")
  ctx = canvas.getContext("2d")
  ctx.font = "18px Courier"
  ctx.lineCap = "round"
  soldiers = []
  aliens = []
  objects = []
  random_int = (n) ->
    Math.floor Math.random() * n

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

      when 1
        aliens.push
          x: x
          y: y
          style: "muton"
          hp: 6
          hpmax: 6
          mobility: 5
          aim: 75

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
    null

  generate_level = ->
    soldiers.push
      name: "Alice"
      x: 1
      y: 1
      style: "soldier 1"
      hp: 4
      hpmax: 4
      aim: 65
      mobility: 5

    soldiers.push
      name: "Bob"
      x: 3
      y: 3
      style: "soldier 2"
      hp: 4
      hpmax: 4
      aim: 65
      mobility: 5

    soldiers.push
      name: "Charlie"
      x: 1
      y: 3
      style: "soldier 3"
      hp: 4
      hpmax: 4
      aim: 65
      mobility: 5

    soldiers.push
      name: "Diana"
      x: 3
      y: 1
      style: "soldier 4"
      hp: 4
      hpmax: 4
      aim: 65
      mobility: 5

    i = 0

    while i < 6
      j = 0

      while j < 6
        populate_level_fragment i * 5, j * 5  if i isnt 0 or j isnt 0
        j++
      i++

  current_soldier = undefined
  mouse_x = undefined
  mouse_y = undefined
  current_mode = undefined
  styles =
    "soldier 1":
      icon: "1"
      bg: "#000"
      fg: "#fff"

    "soldier 2":
      icon: "2"
      bg: "#000"
      fg: "#fff"

    "soldier 3":
      icon: "3"
      bg: "#000"
      fg: "#fff"

    "soldier 4":
      icon: "4"
      bg: "#000"
      fg: "#fff"

    sectoid:
      icon: "s"
      bg: "#800"
      fg: "#f00"

    muton:
      icon: "m"
      bg: "#800"
      fg: "#f00"

    berserker:
      icon: "B"
      bg: "#800"
      fg: "#f00"

    car:
      icon: "c"
      bg: "#afa"
      fg: "#0f0"

    wall:
      icon: "W"
      bg: "#afa"
      fg: "#0f0"

    door:
      icon: "D"
      bg: "#aaf"
      fg: "#00f"

    movement_highlight:
      bg: "#ccf"

    dead:
      icon: "X"
      bg: "#000"
      fg: "#800"

  dist2 = (x, y) ->
    Math.sqrt x * x + y * y

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
    i = 0

    while i < 30
      j = 0

      while j < 30
        draw_all_bounds i, j, "#ccc"
        j++
      i++

  draw_objects = ->
    $.each soldiers, ->
      draw_text_sprite this
      null

    $.each aliens, ->
      draw_text_sprite this
      null

    $.each objects, ->
      draw_text_sprite this
      null


  display_soldier_info = (soldier) ->
    $("#soldier_info").empty()
    $("#soldier_info").append "<div class='name'>Rookie " + soldier.name + "</div>"
    $("#soldier_info").append "<div class='hp'>HP: " + soldier.hp + "/" + soldier.hpmax + "</div>"
    $("#soldier_info").append "<div class='aim'>Aim: " + soldier.aim + "</div>"
    $("#soldier_info").append "<div class='mobility'>Mobility: " + soldier.mobility + "</div>"
    $("#soldier_info").append "<div class='actions'>Actions: " + soldier.actions + "/2</div>"

  highlight_current_soldier = ->
    x = soldiers[current_soldier].x
    y = soldiers[current_soldier].y
    ctx.lineWidth = 3
    draw_all_bounds x, y, "#f00"

  random_move = (alien) ->
    range = compute_range(alien.x, alien.y, alien.mobility)
    move = range[random_int(range.length)]
    alien.x = move.x
    alien.y = move.y
    alien.actions -= 1

  process_alien_actions = (alien) ->
    return  if alien.hp is 0
    random_move alien
    $.each soldiers, ->
      if in_fire_range(alien, this)
        fire_action alien, this
        return
      null

    random_move alien  if alien.actions > 0

  aliens_turn = ->
    $.each aliens, ->
      if @hp > 0
        @actions = 2
      else
        @actions = 0
      @overwatch = false
      null

    $.each aliens, ->
      process_alien_actions this
      null


  start_new_turn = ->
    $.each soldiers, ->
      console.log(this)
      if @hp > 0
        @actions = 2
      else
        @actions = 0
      @overwatch = false
      null

    current_mode = "move"
    current_soldier = 0


  ###
  Actions *****
  ###
  next_soldier = ->
    console.log(soldiers)
    i = current_soldier + 1
    until i is current_soldier
      i %= soldiers.length
      break if soldiers[i].actions > 0
      i += 1
    if i is current_soldier
      current_soldier = 0
      end_turn()
    else
      current_soldier = i
    current_mode = "move"

  fire_mode = ->
    current_mode = "fire"

  end_turn = ->
    aliens_turn()
    start_new_turn()

  overwatch = ->
    soldiers[current_soldier].overwatch = true
    soldiers[current_soldier].actions = 0
    next_soldier()

  highlight_mouseover = ->
    ctx.lineWidth = 2
    draw_all_bounds mouse_x, mouse_y, "#00f"


  # TODO: Doing this function properly is actually fairly nontrivial, this is very dirty approximation
  compute_range = (x0, y0, m) ->
    range = []
    dy = -m

    for dy in [-m..m]

      for dx in [-m..m]
        continue  if dx * dx + dy * dy > m * m
        x = x0 + dx
        y = y0 + dy
        continue  if is_object_present(x, y)
        continue  if x < 0 or y < 0 or x >= 30 or y >= 30
        range.push
          x: x
          y: y

    range

  highlight_current_soldier_move_range = ->
    soldier = soldiers[current_soldier]
    $.each compute_range(soldier.x, soldier.y, soldier.mobility), ->
      draw_text_sprite
        x: @x
        y: @y
        style: "movement_highlight"
      null

  # TODO: highlight
  highlight_current_soldier_fire_range = ->
    soldier = soldiers[current_soldier]

  display_available_actions = ->
    null
  # TODO: make this soldier specific

  find_object = (x, y) ->
    try
      $.each soldiers, ->
        if @x is x and @y is y
          throw
            type: "soldier"
            object: this
        null

      $.each aliens, ->
        if @x is x and @y is y
          throw
            type: "alien"
            object: this
        null

      $.each objects, ->
        if @x is x and @y is y
          throw
            type: "object"
            object: this
        null

      throw type: "empty"
    catch err

      # Found the object!
      return err

  is_object_present = (x, y) ->
    found = find_object(x, y)
    found.type isnt "empty"

  display_mouseover_object = ->
    $("#mouseover_object").empty()
    return  if mouse_x is null or mouse_y is null
    $("#mouseover_object").append "<div class='coordinates'>x=" + mouse_x + " y=" + mouse_y + "</div>"
    found = find_object(mouse_x, mouse_y)
    object = found.object
    switch found.type
      when "soldier"
        $("#mouseover_object").append "<div>Rookie " + object.name + " (" + object.hp + "/" + object.hpmax + ")</div>"
      when "alien"
        $("#mouseover_object").append "<div>Alien " + object.style + " (" + object.hp + "/" + object.hpmax + ")</div>"
        if in_fire_range(soldiers[current_soldier], object)
          $("#mouseover_object").append "<div>In range (hit chance " + hit_chance(soldiers[current_soldier], object) + "%)</div>"
        else
          $("#mouseover_object").append "<div>Out of range</div>"
      when "object"
        $("#mouseover_object").append "<div>object " + object.style + "</div>"
      when "empty"
        $("#mousover_object").append "<div>Empty</div>"

  in_move_range = (soldier, x, y) ->
    range = compute_range(soldier.x, soldier.y, soldier.mobility)
    try
      $.each range, ->
        throw "found"  if @x is x and @y is @y
        null
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

    # Aim penalty of up to -20 based on distance
    chance -= Math.round(4 * (distance - 5))  if distance >= 5

    # -40 if next to an object (TODO: flanking direction)
    chance -= 40  if find_object(target.x + 1, target.y).type is "object" or find_object(target.x - 1, target.y).type is "object" or find_object(target.x, target.y + 1).type is "object" or find_object(target.x, target.y - 1).type is "object"
    chance

  fire_action = (shooter, target) ->
    chance = hit_chance(shooter, target)
    shooter.actions = 0
    take_damage target, 3  if Math.random() * 100 < chance

  in_fire_range = (shooter, target) ->
    gun_range = 10
    distance = dist2(shooter.x - target.x, shooter.y - target.y)
    distance <= gun_range

  clicked_on = (x, y) ->
    soldier = soldiers[current_soldier]
    if current_mode is "move"
      if in_move_range(soldier, x, y)
        soldier.x = x
        soldier.y = y
        soldier.actions -= 1
    if current_mode is "fire"
      return  unless in_fire_range(soldier,
        x: x
        y: y
      )
      found = find_object(x, y)
      return  if found.type isnt "alien"
      fire_action soldier, found.object
    next_soldier()  if soldier.actions is 0

  display_info = ->
    display_soldier_info soldiers[current_soldier]
    display_mouseover_object()
    display_available_actions()

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
    rect = canvas.getBoundingClientRect()
    x = Math.floor((event.clientX - rect.left) / 24)
    y = Math.floor((event.clientY - rect.top) / 24)
    clicked_on x, y
    null

  $(document).bind "keypress", (event) ->
    # console.log(event);
    # 'e' for end turn
    end_turn()  if event.keyCode is 101
    # 'f' for fire
    fire_mode()  if event.keyCode is 102
    # 'n' for next
    next_soldier()  if event.keyCode is 110
    # 'o' for overwatch
    overwatch()  if event.keyCode is 111
    null

  main_loop = ->
    draw_map()
    null

  generate_level()
  start_new_turn()
  setInterval main_loop, 1000.0 / 60.0
  null

# TODO: window.requestAnimationFrame(main_loop); ???
