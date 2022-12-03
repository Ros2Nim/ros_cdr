import std/endians
import std/streams

import cdrtypes

type
  CdrReader* = ref object
    ss*: StringStream
    kind*: EncapsulationKind
    littleEndian*: bool
    hostLittleEndian*: bool

proc getPosition*(this: CdrReader): int =
  return this.ss.getPosition()

proc decodedBytes*(this: CdrReader): int =
  return this.ss.getPosition()

proc byteLength*(this: CdrReader): int =
  return this.ss.data.len()

proc newCdrReader*(data: string): CdrReader =
  new result
  if data.len < 4:
    raise newException(CdrError,
      "Invalid CDR data size " & $data.len() & ", minimum size is at least 4-bytes",
    )
  result.ss = newStringStream(data)
  result.ss.setPosition(1)
  result.kind = result.ss.readUint8().EncapsulationKind
  result.littleEndian = result.kind in [CDR_LE, PL_CDR_LE]
  result.ss.setPosition(4)

proc align(this: CdrReader, size: int): void =
    let alignment = (this.ss.getPosition() - 4) mod size
    echo "set alignment: ", size, " align: ", alignment, " to ", $(size-alignment)
    if (alignment > 0):
      this.ss.setPosition(this.ss.getPosition() + size - alignment)

proc read*[T: SomeInteger|SomeFloat](this: CdrReader, tp: typedesc[T]): T =
  this.align(sizeof(tp))
  if this.littleEndian:
    result = this.ss.readLe(tp)
  else:
    result = this.ss.readBe(tp)

proc readBe*[T: SomeInteger|SomeFloat](this: CdrReader, tp: typedesc[T]): T =
  this.align(sizeof(tp))
  result = this.ss.readBe(tp)

import os

proc readString*(this: CdrReader): string =
    let ll = this.read(uint32).int
    if ll > 100:
      raise newException(CdrError, "error, len too large: " & $ll)
    if ll <= 1:
      return ""
    result = this.ss.readStr(ll-1)
    # this.ss.setPosition(this.ss.getPosition()+1)
    assert this.ss.readChar() == char(0)

proc sequenceLength*(this: CdrReader): int =
    return int(this.ss.readuint32())
  
proc readArray*[T: SomeInteger|SomeFloat](
    this: CdrReader,
    count: int = this.sequenceLength()
): seq[T] =
  when sizeof(T) == 1:
    result = newSeq[int8](count)
    let cnt = this.ss.readData(result.addr, count)
    if cnt != count:
      raise newException(CdrError, "error reading int8 array")
  else:
    result = newSeqOfCap[T](count)
    for i in 0 ..< count:
      result.add(this.ss.read(T))

proc readStringArray*(this: CdrReader, count: int = this.sequenceLength()): seq[string] =
    result = newSeqOfCap[string](count)
    for i in 0 ..< count:
      result.add(this.readString())
