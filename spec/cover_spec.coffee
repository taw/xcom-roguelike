## Specs based mostly on http://i.imgur.com/eqnBg.gif

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

test_covers = (name, attrs) ->
  test name, ->
    translation =
      'In the open': 'in_the_open'
      'Flanked': 'flanked'
      'Low cover (20)': 'half_cover'
      'High cover (40)': 'full_cover'
    map = setup_map(attrs['map'])
    for target_idx, val of attrs
      continue if target_idx == 'map'
      target = map.unit_index[target_idx]
      for expected, shooter_idx of val
        shooter = map.unit_index[shooter_idx]
        actual = translation[map.cover_status(shooter, target).description]
        ok(actual==expected, "Expected #{target_idx} to be #{expected} by #{shooter_idx}, was #{actual}")

test_covers 'Basic cover situation 1',
  map: [
    "     2"
    "1    "
  ]
  1: {in_the_open: 2}
  2: {in_the_open: 1}

test_covers 'Basic cover situation 2',
  map: [
    "     .2"
    ".1   . "
    "..   . "
    "3.   .4"
  ]
  1: {flanked: 2}
  2: {half_cover: 1}
  3: {half_cover: 4}
  4: {half_cover: 3}
