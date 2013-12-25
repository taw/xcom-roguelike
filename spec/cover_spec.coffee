## Specs based mostly on http://i.imgur.com/eqnBg.gif

setup_map = (lines) ->
  map = new Map()
  map.unit_index = {}
  for line, y in lines
    for char, x in line
      switch char
        when '1', '2', '3', '4', '5', '6', '7', '8', '9'
          alien = new Sectoid(x, y)
          map.aliens.push alien
          map.unit_index[char] = alien
        when '.'
          map.objects.push x: x, y: y, style: "abducted goat", cover: 20
        when 'x'
          map.objects.push x: x, y: y, style: "abducted cow", cover: 40
        when ' '
          null
  map

test_covers = (name, attrs) ->
  test name, ->
    translation =
      'Invisible': 'invisible'
      'In the open': 'in_the_open'
      'Flanked': 'flanked'
      'Low cover (20)': 'half_cover'
      'High cover (40)': 'full_cover'
    map = setup_map(attrs['map'])
    for target_idx, val of attrs
      continue if target_idx == 'map'
      target = map.unit_index[target_idx]
      for shooter_idx, expected of val
        shooter = map.unit_index[shooter_idx]
        actual = translation[map.cover_status(shooter, target).description]
        if actual==expected
          ok(true, "#{target_idx} is #{expected} by #{shooter_idx} as expected")
        else
          ok(false, "Expected #{target_idx} to be #{expected} by #{shooter_idx}, was #{actual}")

test_covers 'Basic cover situation 1',
  map: [
    "     2"
    "1    "
  ]
  1:
    2: 'in_the_open'
  2:
    1: 'in_the_open'

test_covers 'Basic cover situation 2',
  map: [
    "     .2"
    ".1   . "
    "..   . "
    "3.   .4"
  ]
  1:
    2: 'flanked'
  2:
    1: 'half_cover'
  3:
    4: 'half_cover'
  4:
    3: 'half_cover'

test_covers 'Line of fire 1',
  map: [
    "1                 "
    ".                ."
    "                 2"
  ]
  1:
    2: 'half_cover'
  2:
    1: 'half_cover'

test_covers 'Line of fire 2',
  map: [
    " 2  3  4 "
    "    .    "
    " 5 .1. 6 "
    "         "
    " 7  8  9 "
  ]
  1:
    2: 'half_cover'
    3: 'half_cover'
    4: 'half_cover'
    5: 'half_cover'
    6: 'half_cover'
    7: 'half_cover'
    8: 'flanked'
    9: 'half_cover'

test_covers 'Line of fire 3',
  map: [
    "          x "
    "          2x"
    "            "
    " ....3      "
    "1....       "
  ]
  2:
    1: 'flanked'
  3:
    1: 'half_cover'

test_covers 'Side stepping',
  map: [
    " 3         x"
    "4...1x    2x"
    "     x      "
  ]
  1:
    2: 'full_cover'
    3: 'half_cover'
    4: 'half_cover'
  2:
    1: 'flanked'
  3:
    1: 'flanked'      # FIXME: Known bug due to lack of sidestepping implementation
  4:
    1: 'half_cover'

test_covers 'Line of sight',
  map: [
    "          x "
    "          x2"
    " .        x "
    "1.    x    4"
    " .    x  3  "
    "      x     "
  ]
  2:
    1: 'invisible'
  3:
    1: 'invisible'
  4:
    1: 'invisible'

test_covers 'Line of sight sidestepping',
  map: [
    " 1      "
    " x      "
    "    xxx "
    "    2 3 "
    "        "
    " 4.     "
  ]
  2:
    1: 'full_cover'
  3:
    1: 'invisible'
  4:
    1: 'flanked'

test_covers 'Miscellaneous scenarios 1',
  map: [
    " 1   "
    " ...2"
    "3... "
    "   4 "
  ]
  1:
    3: 'half_cover'
  2:
    1: 'half_cover'
  3:
    1: 'flanked'
    2: 'half_cover'
    4: 'half_cover'
  4:
    3: 'flanked'

test_covers 'Miscellaneous scenarios 2',
  map: [
    "   1 "
    " xxx "
    "2xxx3"
    "   4 "
  ]
  1:
    2: 'invisible'
  3:
    2: 'full_cover'
  4:
    2: 'flanked'

# This depends on shapeof the box (0.6 radius circle currently a lot)
test_covers 'Miscellaneous scenarios 3',
  map: [
    "....      "
    "123   xxx4"
    "....    x "
  ]
  1:
    4: 'half_cover'
  2:
    4: 'half_cover'
  3:
    4: 'invisible'
  4:
    1: 'full_cover'
    2: 'full_cover'
    3: 'invisible' # invisibility must be mutual

test_covers 'Miscellaneous scenarios 4',
  map: [
    "......"
    " 1  2 "
  ]
  1:
    2: 'flanked'
  2:
    1: 'flanked'

test_covers 'Miscellaneous scenarios 5',
  map: [
    ".      ."
    "1 .2x  3"
    ".      ."
  ]
  1:
    2: 'flanked'
  2:
    1: 'half_cover'
    3: 'full_cover'
  3:
    2: 'half_cover'

test_covers 'Miscellaneous scenarios 6 (cannot sidestep into other units or half-cover)',
  map: [
    ".  .   ."
    "1 .2x  3"
    ". .4   ."
  ]
  1:
    2: 'flanked'
    4: 'half_cover'
  2:
    1: 'half_cover'
    3: 'invisible'
  3:
    2: 'invisible'
    4: 'half_cover'
  4:
    1: 'half_cover'
    3: 'flanked'

# In-game scenario
test_covers 'Miscellaneous scenarios 7',
  map: [
    "    xxxxx  "
    "  xxx 1.x  "
    "        x  "
    "        xxx"
    "    2.  3  "
  ]
  1:
    2: 'flanked'
    3: 'half_cover'
  2:
    1: 'half_cover'
  3:
    1: 'full_cover'
