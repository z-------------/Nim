discard """
  cmd: "nim $target --hintAsError:ExceptTooBroad:on --hintAsError:ExceptRedundant:on -d:testing $options $file"
"""
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
except CommonError: # OK
  discard
