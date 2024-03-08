discard """
  action: "compile"
"""
proc f() {.raises: [ValueError].} =
  raise (ref ValueError)()

try:
  f()
except CatchableError: #[tt.Hint
       ^ Only ValueError is raised here which is more specific [ExceptTooBroad] ]#
  discard

type
  CommonError = object of CatchableError
  FooError = object of CommonError
  BarError = object of CommonError

proc multi() =
  if true:
    raise (ref FooError)()
  else:
    raise (ref BarError)()

try:
  multi()
except CatchableError: #[tt.Hint
       ^ Only CommonError is raised here which is more specific [ExceptTooBroad] ]#
  discard

try:
  multi()
except BarError:
  discard
except CommonError: #[tt.Hint
       ^ Only FooError is raised here which is more specific [ExceptTooBroad] ]#
  discard
