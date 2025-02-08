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