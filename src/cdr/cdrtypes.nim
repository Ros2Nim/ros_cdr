import std/[endians, streams]

type
  EncapsulationKind* = enum
    CDR_BE = 0,
    CDR_LE = 1,
    PL_CDR_BE = 2,
    PL_CDR_LE = 3

type
  CdrError* = object of ValueError

proc writeBe*[T: SomeInteger|SomeFloat](s: Stream, x: T) =
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

proc writeLe*[T: SomeInteger|SomeFloat](s: Stream, x: T) =
  ## LittleEndian version of generic write procedure. Writes `x` to the stream `s`. Implementation:
  var tmp: T
  when sizeof(T) == 1:
    tmp = x
  elif sizeof(T) == 2:
    litleEndian16(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 4:
    littleEndian32(tmp.addr, x.unsafeAddr)
  elif sizeof(T) == 8:
    littleEndian64(tmp.addr, x.unsafeAddr)
  else:
    error("unhandled size")
  writeData(s, addr(tmp), sizeof(x))

proc readBe*[T: SomeInteger|SomeFloat](ss: Stream, x: typedesc[T]): T =
  ## BigEndian version of generic write procedure. Writes `x` to the stream `s`. Implementation:
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

proc readLe*[T: SomeInteger|SomeFloat](ss: Stream, x: typedesc[T]): T =
  ## LittleEndian version of generic write procedure. Writes `x` to the stream `s`. Implementation:
  var tmp: T
  assert ss.readData(addr(tmp), sizeof(x)) == sizeof(x)
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
  