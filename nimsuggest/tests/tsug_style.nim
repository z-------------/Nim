# apply user's style to suggested identifiers

type
  XYThing = object
    fieldFoo: int
    field_bar: float

proc initXYThing() = discard

let hello_world = 0


let x = XYT#[!]#
let y = XY_T#[!]#
discard XYThing().field_f#[!]#
discard XYThing().fieldB#[!]#

initX#[!]#
init_x#[!]#

discard hell#[!]#
discard helloW#[!]#
discard hello_w#[!]#

discard """
$nimsuggest --tester $file
>sug $1
sug;;skType;;tsug_style.XYThing;;XYThing;;*nimsuggest/tests/tsug_style.nim;;4;;2;;"";;100;;Prefix
sug;;skProc;;tsug_style.initXYThing;;proc ();;*nimsuggest/tests/tsug_style.nim;;8;;5;;"";;100;;Substr
>sug $2
sug;;skType;;tsug_style.XYThing;;XYThing;;*nimsuggest/tests/tsug_style.nim;;4;;2;;"";;100;;Prefix
sug;;skProc;;tsug_style.initXYThing;;proc ();;*nimsuggest/tests/tsug_style.nim;;8;;5;;"";;100;;Substr
>sug $3
sug;;skField;;field_foo;;int;;*nimsuggest/tests/tsug_style.nim;;5;;4;;"";;100;;Prefix
>sug $4
sug;;skField;;fieldBar;;float;;*nimsuggest/tests/tsug_style.nim;;6;;4;;"";;100;;Prefix
>sug $5
sug;;skProc;;tsug_style.initXYThing;;proc ();;*nimsuggest/tests/tsug_style.nim;;8;;5;;"";;100;;Prefix
>sug $6
sug;;skProc;;tsug_style.init_xy_thing;;proc ();;*nimsuggest/tests/tsug_style.nim;;8;;5;;"";;100;;Prefix
>sug $7
sug;;skLet;;tsug_style.hello_world;;int;;*nimsuggest/tests/tsug_style.nim;;10;;4;;"";;100;;Prefix
>sug $8
sug;;skLet;;tsug_style.helloWorld;;int;;*nimsuggest/tests/tsug_style.nim;;10;;4;;"";;100;;Prefix
>sug $9
sug;;skLet;;tsug_style.hello_world;;int;;*nimsuggest/tests/tsug_style.nim;;10;;4;;"";;100;;Prefix
"""
