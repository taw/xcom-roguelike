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
