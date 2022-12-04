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
    if (alignment > 0):
      this.ss.setPosition(this.ss.getPosition() + size - alignment)

proc seek*(this: CdrReader, relativeOffset: int): void =
  ##/**
  ##  * Seek the current read pointer a number of bytes relative to the current position. Note that
  ##  * seeking before the four-byte header is invalid
  ##  * @param relativeOffset A positive or negative number of bytes to seek
  ##  */
  let newOffset = this.ss.getPosition() + relativeOffset
  if newOffset < 4 or newOffset >= this.ss.data.len:
    raise newException(CdrError, "seek(" & $relativeOffset & ") failed, " & $newOffset & " is outside the data range")
  this.ss.setPosition newOffset

proc seekTo*(this: CdrReader, offset: int): void =
  ##
  ## Seek to an absolute byte position in the data. Note that seeking before the four-byte header is
  ## invalid
  ## @param offset An absolute byte offset in the range of [4-byteLength)
  ##
  if offset < 4 or offset >= this.ss.data.len:
    raise newException(CdrError, "seekTo(" & $offset & ") failed, value is outside the data range");
  this.ss.setPosition(offset)

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

proc readStr*(this: CdrReader): string =
    let length = int(this.read(uint32))
    if length <= 1:
      for i in 0..<length:
        discard this.ss.readChar()
      return ""
    result = this.ss.readStr(length-1)
    # this.ss.setPosition(this.ss.getPosition()+1)
    let ch = this.ss.readChar()
    assert ch == char(0)

proc sequenceLength*(this: CdrReader): int =
    return int(this.read(uint32))
  
proc readSeq*[T: SomeInteger|SomeFloat](
    this: CdrReader,
    tp: typedesc[T],
    count: int
): seq[T] =
  when sizeof(T) == 1:
    result = newSeq[T](count)
    let cnt = this.ss.readData(result.addr, count)
    if cnt != count:
      raise newException(CdrError, "error reading int8 array")
  else:
    result = newSeqOfCap[T](count)
    for i in 0 ..< count:
      result.add(this.read(tp))

proc readSeq*[T: SomeInteger|SomeFloat](
    this: CdrReader,
    tp: typedesc[T],
): seq[T] =
  let count = this.sequenceLength()
  readSeq(this, tp, count)

proc readStrSeq*(
    this: CdrReader,
    count: int
): seq[string] =
  result = newSeqOfCap[string](count)
  for i in 0 ..< count:
    result.add(this.readStr())

proc readStrSeq*(
    this: CdrReader,
): seq[string] =
  let count = this.sequenceLength()
  echo "readStrSeq:count: ", count
  readStrSeq(this, count)
