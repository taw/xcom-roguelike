## Core ext
random_int = (n) ->
  Math.floor Math.random() * n

dist2 = (x, y) ->
  Math.sqrt x * x + y * y

Function::property = (prop, desc) ->
  Object.defineProperty @prototype, prop, desc
