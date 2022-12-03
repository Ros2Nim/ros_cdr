import std/endians
import std/streams

import cdrtypes

type
  CdrReader* = ref object
    ss*: StringStream
    littleEndian*: bool
    hostLittleEndian*: bool

proc decodedBytes*(this: CdrReader): int =
  return this.ss.getPosition()

proc byteLength*(this: CdrReader): int =
  return this.ss.data.len()


proc init*(kd: typedesc[CdrReader], data: string): CdrReader =
  new result
  if data.byteLength < 4:
    raise newException(CdrError,
      "Invalid CDR data size " & $data.len() & ", minimum size is at least 4-bytes",
    )
  result.view = newStringStream(data)
  let kind = result.view.readInt8().EncapsulationKind

  result.littleEndian = kind == CDR_LE or kind == PL_CDR_LE
  result.view.setPosition(4)


proc swapEndian8(x, y: ptr) = discard
proc readInt8(ss: Stream): int8 = cast[int8](ss.readChar())
proc readUint8(ss: Stream): uint8 = cast[uint8](ss.readChar())
proc readUint16(ss: Stream): uint16 = cast[uint16](ss.readInt16())
proc readUint32(ss: Stream): uint32 = cast[uint32](ss.readInt32())
proc readUint64(ss: Stream): uint64 = cast[uint64](ss.readInt64())

template implReader(NAME, TP, BS: untyped) =
  proc `read NAME`*(this: CdrReader): `TP BS` =
    when system.cpuEndian == littleEndian:
      if this.littleEndian:
        result = this.ss.`read NAME BS`()
      else:
        var tmp: `TP BS` = this.ss.`read NAME BS`()
        `swapEndian BS`(addr(result), addr(tmp))
    else: # bigendian
      if this.littleEndian:
        var tmp: `TP BS` = this.ss.`read NAME BS`()
        `swapEndian BS`(addr(result), addr(tmp))
      else:
        result = this.ss.`read NAME BS`()

implReader(Uint, uint, 8)
implReader(Uint, uint, 16)
implReader(Uint, uint, 32)
implReader(Uint, uint, 64)

implReader(Int, int, 8)
implReader(Int, int, 16)
implReader(Int, int, 32)
implReader(Int, int, 64)


proc readString*(this: CdrReader): string =
    let length = int(this.ss.readuint32())
    if length <= 1:
      return ""
    return this.ss.readStr(length)

proc sequenceLength*(this: CdrReader): int =
    return int(this.ss.readuint32())
  
proc readInt8Array*(this: CdrReader, count: int = this.sequenceLength()): seq[int8] =
    result = newSeqOfCap[int8](count)
    let cnt = this.ss.readData(result.addr, count)
    if cnt != count:
      raise newException(CdrError, "error reading int8 array")
  
proc readUint8Array*(this: CdrReader, count: int = this.sequenceLength()): seq[uint8] =
    result = newSeqOfCap[uint8](count)
    let cnt = this.ss.readData(result.addr, count)
    if cnt != count:
      raise newException(CdrError, "error reading int8 array")


proc readInt16Array*(count: int = this.sequenceLength()): Int16Array =
    return this.typedArray(Int16Array, "getInt16", count);
  

proc readUint16Array*(count: int = this.sequenceLength()): Uint16Array =
    return this.typedArray(Uint16Array, "getUint16", count);
  

proc readInt32Array*(count: int = this.sequenceLength()): Int32Array =
    return this.typedArray(Int32Array, "getInt32", count);
  

proc readUint32Array*(count: int = this.sequenceLength()): Uint32Array =
    return this.typedArray(Uint32Array, "getUint32", count);
  

proc readInt64Array*(count: int = this.sequenceLength()): BigInt64Array =
    return this.typedArray(BigInt64Array, "getBigInt64", count);
  

proc readUint64Array*(count: int = this.sequenceLength()): BigUint64Array =
    return this.typedArray(BigUint64Array, "getBigUint64", count);
  

proc readFloat32Array*(count: int = this.sequenceLength()): Float32Array =
    return this.typedArray(Float32Array, "getFloat32", count);
  

proc readFloat64Array*(count: int = this.sequenceLength()): Float64Array =
    return this.typedArray(Float64Array, "getFloat64", count);
  

proc readStringArray*(count: int = this.sequenceLength()): string[] =
    const output: string[] = [];
    for (let i = 0; i < count; i++) {
      output.push(this.string());
    
    return output;
  }
