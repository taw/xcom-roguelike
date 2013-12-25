## Core ext
random_int = (n) ->
  Math.floor Math.random() * n

dist2 = (x, y) ->
  Math.sqrt x * x + y * y

current_time = () ->
  (new Date()).getTime()

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc
