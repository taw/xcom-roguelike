## Everything below is a very dirty mix of UI, logic, and other stuff
## Hopefully as much of this can be unentangled as possible
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
    {x:x, y:y} = current_soldier()
    ui.highlight_current_soldier x, y

  # TODO: this should go within Alien
  random_move = (alien) ->
    range = map.compute_range(alien.x, alien.y, alien.mobility)
    move = range[random_int(range.length)]
    alien.action_move move.x, move.y

  any_alien_in_range = ->
    for alien in map.live_aliens
      return true if map.can_shoot_at(current_soldier(), alien)
    false

  # TODO: this should go within Alien
  process_alien_actions = (alien) ->
    return if alien.hp is 0
    random_move(alien)
    if alien.must_reload
      alien.action_reload()
    else
      soldiers_in_range = (soldier for soldier in map.live_soldiers when map.can_shoot_at(alien, soldier))
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
      current_soldier_idx++ until current_soldier().alive

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
      if map.can_shoot_at(current_soldier(), alien)
        ui.highlight_target_in_fire_range(alien.x, alien.y)

  # TODO: maybe some of this should go within Soldier or Map ???
  potential_actions = ->
    soldier = current_soldier()
    actions = []
    actions.push key: 'e', label: 'End turn'
    if soldier.alive
      if soldier.promotion_options.length
        for ability, i in soldier.promotion_options
          actions.push key: "#{i+1}", label: "Promotion - #{ability}"
      if soldier.actions > 0
        if soldier.can_reload
          actions.push key: 'r', label: 'Reload'
        if current_mode == 'fire'
          actions.push key: 'm', label: 'Move'
        if !soldier.must_reload
          if soldier.actions == 2 or not soldier.gun_needs_two_actions
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
          if map.can_shoot_at(current_soldier(), object)
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
      object_clicked = map.find_object(x, y)
      return unless object_clicked.type == "alien"
      return unless map.can_shoot_at(soldier, object_clicked.object)
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
  # # TODO: window.requestAnimationFrame(main_loop); ???
  setInterval main_loop, 1000.0 / 60.0
  null
