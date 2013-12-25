setup_map = (lines) ->
  map = new Map()
  map.unit_index = {}
  for line, y in lines
    for char, x in line
      switch char
        when '1', '2', '3', '4', '5', '6'
          alien = new Sectoid(x, y)
          map.aliens.push alien
          map.unit_index[char] = alien
        when '.'
          map.objects.push x: x, y: y, style: "abducted goat", cover: 20
        when 'x'
          map.objects.push x: x, y: y, style: "abducted cow", cover: 20
        when ' '
          null
  map

cover_status = (map, shooter_idx, target_idx, expected) ->
  shooter = map.unit_index["#{shooter_idx}"]
  target = map.unit_index["#{target_idx}"]
  actual = map.cover_status(shooter, target).description
  ok(actual == expected, "Expected #{shooter_idx} to #{target_idx} to be: #{expected}, was #{actual}")

test 'Cover system', ->
  map = setup_map [
    "     .2"
    ".1   . "
    "..   . "
  ]
  cover_status map, 2, 1, 'Flanked'
  cover_status map, 1, 2, 'Low cover (20)'
