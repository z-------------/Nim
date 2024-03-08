discard """
  action: "compile"
"""
proc f() {.raises: [].} = discard

try:
  f()
except CatchableError: #[tt.Hint
       ^ CatchableError does not catch anything here [ExceptRedundant] ]#
  discard

proc f2() =
  if true:
    raise (ref ValueError)()
  else:
    raise (ref IOError)()

try:
  f2()
except CatchableError:
  discard
except IOError: #[tt.Hint
       ^ IOError does not catch anything here [ExceptRedundant] ]#
  discard

proc f3() {.raises: [CatchableError].} =
  f2()

try:
  f3()
except ValueError: #[tt.Hint
       ^ ValueError might not catch anything here [ExceptRedundant] ]#
  discard
