import std/endians
import std/streams
import binstream

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


template implReader(name, tp: untyped) =
  proc `name`*(this: CdrReader): `tp` =
    if this.littleEndian:
      result = this.ss.`readLe name`()
    else:
      result = this.ss.`readBe name`()


implReader(Uint8, uint8)
implReader(Uint16, uint16)
implReader(Uint32, uint32)
implReader(Uint64, uint64)

implReader(Int8, int8)
implReader(Int16, int16)
implReader(Int32, int32)
implReader(Int64, int64)

  
proc readString*(): string =
    const length = this.uint32();
    if (length <= 1) {
      this.offset += length;
      return "";
    
    const data = new Uint8Array(this.view.buffer, this.view.byteOffset + this.offset, length - 1);
    const value = this.textDecoder.decode(data);
    this.offset += length;
    return value;
  }

proc readSequenceLength*(): number =
    return this.uint32();
  

proc readInt8Array*(count: number = this.sequenceLength()): Int8Array =
    const array = new Int8Array(this.view.buffer, this.view.byteOffset + this.offset, count);
    this.offset += count;
    return array;
  

proc readUint8Array*(count: number = this.sequenceLength()): Uint8Array =
    const array = new Uint8Array(this.view.buffer, this.view.byteOffset + this.offset, count);
    this.offset += count;
    return array;
  

proc readInt16Array*(count: number = this.sequenceLength()): Int16Array =
    return this.typedArray(Int16Array, "getInt16", count);
  

proc readUint16Array*(count: number = this.sequenceLength()): Uint16Array =
    return this.typedArray(Uint16Array, "getUint16", count);
  

proc readInt32Array*(count: number = this.sequenceLength()): Int32Array =
    return this.typedArray(Int32Array, "getInt32", count);
  

proc readUint32Array*(count: number = this.sequenceLength()): Uint32Array =
    return this.typedArray(Uint32Array, "getUint32", count);
  

proc readInt64Array*(count: number = this.sequenceLength()): BigInt64Array =
    return this.typedArray(BigInt64Array, "getBigInt64", count);
  

proc readUint64Array*(count: number = this.sequenceLength()): BigUint64Array =
    return this.typedArray(BigUint64Array, "getBigUint64", count);
  

proc readFloat32Array*(count: number = this.sequenceLength()): Float32Array =
    return this.typedArray(Float32Array, "getFloat32", count);
  

proc readFloat64Array*(count: number = this.sequenceLength()): Float64Array =
    return this.typedArray(Float64Array, "getFloat64", count);
  

proc readStringArray*(count: number = this.sequenceLength()): string[] =
    const output: string[] = [];
    for (let i = 0; i < count; i++) {
      output.push(this.string());
    
    return output;
  }
