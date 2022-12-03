## Helpers for Stream's

import endians

when system.cpuEndian == littleEndian:
  proc topByte*(val: uint8): uint8 {.inline.} = val
  proc topByte*(val: uint16): uint8 {.inline.} = uint8(val and 0xFF)
  proc topByte*(val: uint32): uint8 {.inline.} = uint8(val and 0xFF)
  proc topByte*(val: uint64): uint8 {.inline.} = uint8(val and 0xFF)

  proc writeBeUint8*[ByteStream](s: ByteStream, val: uint8) =
    s.write(val)
  proc writeBeUint16*[ByteStream](s: ByteStream, val: uint16) =
    var res: uint16
    swapEndian16(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeBeUint32*[ByteStream](s: ByteStream, val: uint32) =
    var res: uint32
    swapEndian32(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeBeUint64*[ByteStream](s: ByteStream, val: uint64) =
    var res: uint64
    swapEndian64(addr(res), unsafeAddr(val))
    s.write(res)

  proc readBeUint8*[ByteStream](s: ByteStream): uint8 =
    result = cast[uint8](s.readInt8())
  proc readBeUint16*[ByteStream](s: ByteStream): uint16 =
    var tmp: uint16 = cast[uint16](s.readInt16())
    swapEndian16(addr(result), addr(tmp))
  proc readBeUint32*[ByteStream](s: ByteStream): uint32 =
    var tmp: uint32 = cast[uint32](s.readInt32())
    swapEndian32(addr(result), addr(tmp))
  proc readBeUint64*[ByteStream](s: ByteStream): uint64 =
    var tmp: uint64 = cast[uint64](s.readInt64())
    swapEndian64(addr(result), addr(tmp))

  proc writeLeUint8*[ByteStream](s: ByteStream, val: uint8) = s.write(val)
  proc writeLeUint16*[ByteStream](s: ByteStream, val: uint16) = s.write(val)
  proc writeLeUint32*[ByteStream](s: ByteStream, val: uint32) = s.write(val)
  proc writeLeUint64*[ByteStream](s: ByteStream, val: uint64) = s.write(val)

  proc readLeUint8*[ByteStream](s: ByteStream): uint16 = cast[uint8](s.readChar())
  proc readLeUint16*[ByteStream](s: ByteStream): uint16 = cast[uint16](s.readInt16())
  proc readLeUint32*[ByteStream](s: ByteStream): uint32 = cast[uint32](s.readInt32())
  proc readLeUint64*[ByteStream](s: ByteStream): uint64 = cast[uint64](s.readInt64())

else:
  proc topByte*(val: uint8): uint8 {.inline.} = val
  proc topByte*(val: uint16): uint8 {.inline.} = (val shr 8) and 0xFF
  proc topByte*(val: uint32): uint8 {.inline.} = (val shr 24) and 0xFF
  proc topByte*(val: uint64): uint8 {.inline.} = uint8((val shr 56) and 0xFF)

  proc writeBeUint8*[ByteStream](s: ByteStream, val: uint8) = s.write(val)
  proc writeBeUint16*[ByteStream](s: ByteStream, val: uint16) = s.write(val)
  proc writeBeUint32*[ByteStream](s: ByteStream, val: uint32) = s.write(val)
  proc writeBeUint64*[ByteStream](s: ByteStream, val: uint64) = s.write(val)

  proc readBeUint8*[ByteStream](s: ByteStream): uint16 = cast[uint8](s.readChar())
  proc readBeUint16*[ByteStream](s: ByteStream): uint16 = cast[uint16](s.readInt16())
  proc readBeUint32*[ByteStream](s: ByteStream): uint32 = cast[uint32](s.readInt32())
  proc readBeUint64*[ByteStream](s: ByteStream): uint64 = cast[uint64](s.readInt64())

  proc writeLeUint8*[ByteStream](s: ByteStream, val: uint8) =
    s.write(val)
  proc writeLeUint16*[ByteStream](s: ByteStream, val: uint16) =
    var res: uint16
    swapEndian16(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeLeUint32*[ByteStream](s: ByteStream, val: uint32) =
    var res: uint32
    swapEndian32(addr(res), unsafeAddr(val))
    s.write(res)
  proc writeLeUint64*[ByteStream](s: ByteStream, val: uint64) =
    var res: uint64
    swapEndian64(addr(res), unsafeAddr(val))
    s.write(res)

  proc readLeUint8*[ByteStream](s: ByteStream): uint8 =
    result = cast[uint8](s.readInt8())
  proc readLeUint16*[ByteStream](s: ByteStream): uint16 =
    var tmp: uint16 = cast[uint16](s.readInt16())
    swapEndian16(addr(result), addr(tmp))
  proc readLeUint32*[ByteStream](s: ByteStream): uint32 =
    var tmp: uint32 = cast[uint32](s.readInt32())
    swapEndian32(addr(result), addr(tmp))
  proc readLeUint64*[ByteStream](s: ByteStream): uint64 =
    var tmp: uint64 = cast[uint64](s.readInt64())
    swapEndian64(addr(result), addr(tmp))
