when not defined(nimHasSystemRaisesDefect):
  {.pragma: systemRaisesDefect.}

proc supportsCopyMem(t: typedesc): bool {.magic: "TypeTrait".} =
  discard

type
  BackwardsIndex* = distinct int ## Type that is constructed by `^` for
                                 ## reversed array accesses.
                                 ## (See `^ template <#^.t,int>`_)

template `^`*(x: int): BackwardsIndex = BackwardsIndex(x)
  ## Builtin `roof`:idx: operator that can be used for convenient array access.
  ## `a[^x]` is a shortcut for `a[a.len-x]`.
  ##
  ##   ```
  ##   let
  ##     a = [1, 3, 5, 7, 9]
  ##     b = "abcdefgh"
  ##
  ##   echo a[^1] # => 9
  ##   echo b[^2] # => g
  ##   ```

proc `[]`*[T](s: openArray[T]; i: BackwardsIndex): T {.inline, systemRaisesDefect.} =
  system.`[]`(s, s.len - int(i))

proc `[]`*[Idx, T](a: array[Idx, T]; i: BackwardsIndex): T {.inline, systemRaisesDefect.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: string; i: BackwardsIndex): char {.inline, systemRaisesDefect.} = s[s.len - int(i)]

proc `[]`*[T](s: var openArray[T]; i: BackwardsIndex): var T {.inline, systemRaisesDefect.} =
  system.`[]`(s, s.len - int(i))
proc `[]`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex): var T {.inline, systemRaisesDefect.} =
  a[Idx(a.len - int(i) + int low(a))]
proc `[]`*(s: var string; i: BackwardsIndex): var char {.inline, systemRaisesDefect.} = s[s.len - int(i)]

proc `[]=`*[T](s: var openArray[T]; i: BackwardsIndex; x: T) {.inline, systemRaisesDefect.} =
  system.`[]=`(s, s.len - int(i), x)
proc `[]=`*[Idx, T](a: var array[Idx, T]; i: BackwardsIndex; x: T) {.inline, systemRaisesDefect.} =
  a[Idx(a.len - int(i) + int low(a))] = x
proc `[]=`*(s: var string; i: BackwardsIndex; x: char) {.inline, systemRaisesDefect.} =
  s[s.len - int(i)] = x

template `..^`*(a, b: untyped): untyped =
  ## A shortcut for `.. ^` to avoid the common gotcha that a space between
  ## '..' and '^' is required.
  a .. ^b

template `..<`*(a, b: untyped): untyped =
  ## A shortcut for `a .. pred(b)`.
  ##   ```
  ##   for i in 5 ..< 9:
  ##     echo i # => 5; 6; 7; 8
  ##   ```
  a .. (when b is BackwardsIndex: succ(b) else: pred(b))

template `[]`*(s: string; i: int): char = arrGet(s, i)
template `[]=`*(s: string; i: int; val: char) = arrPut(s, i, val)

template `^^`(s, i: untyped): untyped =
  (when i is BackwardsIndex: s.len - int(i) else: int(i))

template spliceImpl(s, a, L, b: typed): untyped =
  # make room for additional elements or cut:
  var shift = b.len - max(0,L)  # ignore negative slice size
  var newLen = s.len + shift
  if shift > 0:
    # enlarge:
    setLen(s, newLen)
    for i in countdown(newLen-1, a+b.len): movingCopy(s[i], s[i-shift])
  else:
    for i in countup(a+b.len, newLen-1): movingCopy(s[i], s[i-shift])
    # cut down:
    setLen(s, newLen)
  # fill the hole:
  for i in 0 ..< b.len: s[a+i] = b[i]

template raiseIndexErrorImpl(b: int, length: int, body: untyped) =
  when compileOption("boundChecks"):
    if b <= length:
      body
    else:
      raiseIndexError3(b, 0, length-1)
  else:
    body

proc `[]`*[T, U: Ordinal](s: string, x: HSlice[T, U]): string {.inline, systemRaisesDefect.} =
  ## Slice operation for strings.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  runnableExamples:
    var s = "abcdef"
    assert s[1..3] == "bcd"
  let a = s ^^ x.a
  let b = s ^^ x.b
  let L = b - a + 1
  result = newString(L)
  template impl =
    for i in 0 ..< L: result[i] = s[i + a]
  when nimvm:
    impl()
  else:
    when notJSnotNims:
      if L > 0:
        raiseIndexErrorImpl(b, s.len):
          copyMem(addr result[0], addr s[a], L)
    else:
      impl()

proc `[]=`*[T, U: Ordinal](s: var string, x: HSlice[T, U], b: string) {.systemRaisesDefect.} =
  ## Slice assignment for strings.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed:
  ##
  runnableExamples:
    var s = "abcdefgh"
    s[1 .. ^2] = "xyz"
    assert s == "axyzh"

  var a = s ^^ x.a
  var xb = s ^^ x.b
  var L = xb - a + 1
  template impl =
    for i in 0..<L: s[i+a] = b[i]
  if L == b.len:
    when nimvm:
      impl()
    else:
      when notJSnotNims:
        if L > 0:
          raiseIndexErrorImpl(xb, s.len):
            when defined(nimSeqsV2):
              prepareMutation(s)
            copyMem(addr s[a], addr b[0], L)
      else:
        impl()
  else:
    spliceImpl(s, a, L, b)

proc `[]`*[Idx, T; U, V: Ordinal](a: array[Idx, T], x: HSlice[U, V]): seq[T] {.systemRaisesDefect.} =
  ## Slice operation for arrays.
  ## Returns the inclusive range `[a[x.a], a[x.b]]`:
  ##   ```
  ##   var a = [1, 2, 3, 4]
  ##   assert a[0..2] == @[1, 2, 3]
  ##   ```
  let xa = a ^^ x.a
  let xb = a ^^ x.b
  let L = xb - xa + 1
  result = newSeq[T](L)
  template impl =
    for i in 0..<L: result[i] = a[Idx(i + xa)]
  when nimvm:
    impl()
  else:
    when notJSnotNims and supportsCopyMem(T):
      if L > 0:
        raiseIndexErrorImpl(xb, a.len):
          copyMem(addr result[0], addr a[Idx(xa)], sizeof(T) * L)
    else:
      impl()

proc `[]=`*[Idx, T; U, V: Ordinal](a: var array[Idx, T], x: HSlice[U, V], b: openArray[T]) {.systemRaisesDefect.} =
  ## Slice assignment for arrays.
  runnableExamples:
    var a = [10, 20, 30, 40, 50]
    a[1..2] = @[99, 88]
    assert a == [10, 99, 88, 40, 50]
  let xa = a ^^ x.a
  let xb = a ^^ x.b
  let L = xb - xa + 1
  template impl =
    for i in 0..<L: a[Idx(i + xa)] = b[i]

  if L == b.len:
    when nimvm:
      impl()
    else:
      when notJSnotNims and supportsCopyMem(T):
        if L > 0:
          raiseIndexErrorImpl(xb, a.len):
            moveMem(addr a[Idx(xa)], addr b[0], sizeof(T) * L)
      else:
        impl()
  else:
    sysFatal(RangeDefect, "different lengths for slice assignment")

proc `[]`*[T; U, V: Ordinal](s: openArray[T], x: HSlice[U, V]): seq[T] {.systemRaisesDefect.} =
  ## Slice operation for sequences.
  ## Returns the inclusive range `[s[x.a], s[x.b]]`:
  ##   ```
  ##   var s = @[1, 2, 3, 4]
  ##   assert s[0..2] == @[1, 2, 3]
  ##   ```
  let a = s ^^ x.a
  let xb = s ^^ x.b
  let L = xb - a + 1
  newSeq(result, L)
  template impl =
    for i in 0 ..< L: result[i] = s[i + a]

  when nimvm:
    impl()
  else:
    when notJSnotNims and supportsCopyMem(T):
      if L > 0:
        raiseIndexErrorImpl(xb, s.len):
          copyMem(addr result[0], addr s[a], sizeof(T) * L)
    else:
      impl()

proc `[]=`*[T; U, V: Ordinal](s: var seq[T], x: HSlice[U, V], b: openArray[T]) {.systemRaisesDefect.} =
  ## Slice assignment for sequences.
  ##
  ## If `b.len` is not exactly the number of elements that are referred to
  ## by `x`, a `splice`:idx: is performed.
  runnableExamples:
    var s = @"abcdefgh"
    s[1 .. ^2] = @"xyz"
    assert s == @"axyzh"
  let a = s ^^ x.a
  let xb = s ^^ x.b
  let L = xb - a + 1
  template impl =
    for i in 0 ..< L: s[i+a] = b[i]
  if L == b.len:
    when nimvm:
      impl()
    else:
      when notJSnotNims and supportsCopyMem(T):
        if L > 0:
          raiseIndexErrorImpl(xb, s.len):
            moveMem(addr s[a], addr b[0], sizeof(T) * L)
      else:
        impl()
  else:
    spliceImpl(s, a, L, b)
