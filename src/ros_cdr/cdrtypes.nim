import std/[endians, streams]

type
  EncapsulationKind* = enum
    CDR_BE = 0,
    CDR_LE = 1,
    PL_CDR_BE = 2,
    PL_CDR_LE = 3

type
  CdrError* = object of ValueError
  CdrBasicTypes* = SomeInteger or SomeFloat or bool or byte or char

proc writeBe*[T: CdrBasicTypes](s: Stream, x: T) =
  ## BigEndian version of generic write procedure. Writes `x` to the stream `s`. Implementation:
  var tmp: T
  when sizeof(T) == 1:
    tmp = x
  elif sizeof(T) == 2:
    bigEndian16(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 4:
    bigEndian32(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 8:
    bigEndian64(tmp.addr, x.unsafeAddr)
  else:
    error("unhandled size")
  writeData(s, addr(tmp), sizeof(x))

proc writeLe*[T: CdrBasicTypes](s: Stream, x: T) =
  ## LittleEndian version of generic write procedure. Writes `x` to the stream `s`. Implementation:
  var tmp: T
  static:
    echo "writeLe: ", typeof(T)
  when sizeof(T) == 1:
    tmp = x
  elif sizeof(T) == 2:
    littleEndian16(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 4:
    littleEndian32(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 8:
    littleEndian64(tmp.addr, x.unsafeAddr)
  else:
    error("unhandled size")
  writeData(s, addr(tmp), sizeof(x))

proc readBe*[T: CdrBasicTypes](ss: StringStream, x: typedesc[T]): T =
  ## BigEndian version of generic read procedure. 
  var tmp: T
  assert ss.readData(addr(tmp), sizeof(x)) == sizeof(x)
  when sizeof(T) == 1:
    result = tmp
  elif sizeof(T) == 2:
    bigEndian16(result.addr, tmp.addr)
  elif sizeof(T) == 4:
    bigEndian32(result.addr, tmp.addr)
  elif sizeof(T) == 8:
    bigEndian64(result.addr, tmp.addr)
  else:
    error("unhandled size")

proc readLe*[T: CdrBasicTypes](ss: StringStream, x: typedesc[T]): T =
  ## LittleEndian version of generic read procedure. 
  var tmp: T
  let cnt = ss.readData(addr(tmp), sizeof(x))
  assert cnt == sizeof(x)
  when sizeof(T) == 1:
    result = tmp
  elif sizeof(T) == 2:
    littleEndian16(result.addr, tmp.addr)
  elif sizeof(T) == 4:
    littleEndian32(result.addr, tmp.addr)
  elif sizeof(T) == 8:
    littleEndian64(result.addr, tmp.addr)
  else:
    error("unhandled size")
  
proc writeBe*[T: bool](s: Stream, x: T) =
  writeBe(s, if x: 1'u8 else: 0'u8)
proc writeLe*[T: bool](s: Stream, x: T) =
  writeLe(s, if x: 1'u8 else: 0'u8)
proc readBe*[T: bool](ss: StringStream, x: typedesc[T]): T =
  let res = readBe(ss, int8)
  if res: true else: false
proc readLe*[T: bool](ss: StringStream, x: typedesc[T]): T =
  let res = readLe(ss, int8)
  if res: true else: false