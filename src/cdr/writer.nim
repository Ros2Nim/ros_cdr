
import std/endians
import std/streams
import std/options

import cdrtypes

export options

const
  DEFAULT_CAPACITY = 16
  BUFFER_COPY_THRESHOLD = 10

type
  CdrWriterOpts* = object

  CdrWriter* = ref object
    littleEndian: bool
    buffer: string
    array: seq[uint8]
    ss: StringStream

proc data*(this: CdrWriter): string =
  return this.ss.data[0..<this.ss.getPosition]

proc getPosition*(this: CdrWriter, ): int =
  return this.ss.getPosition()

proc isLittleEndian*(this: CdrWriter, ): bool =
  return this.littleEndian

proc resizeIfNeeded(ss: StringStream, additionalBytes: int) =
  let capacity = ss.getPosition() + additionalBytes
  if (ss.data.len() < capacity):
    ss.data.setLen(capacity)

proc newCdrWriter*(
    buffer: Option[string] = none(string),
    size: Option[int] = none(int),
    kind: Option[EncapsulationKind] = none(EncapsulationKind)
): CdrWriter =
  new result

  if (buffer.isSome):
    result.ss = newStringStream(buffer.get())
  elif (size.isSome):
    result.ss = newStringStream(newString(size.get()))
  else:
    result.ss = newStringStream(newString(DEFAULT_CAPACITY))

  let kind = if kind.isSome: kind.get()
           else: EncapsulationKind.CDR_LE
  result.littleEndian = kind in [CDR_LE, PL_CDR_LE]
  echo "kind: ", kind

  # Write the Representation Id and Offset fields
  result.ss.write(0'u8) # Upper bits of EncapsulationKind, unused
  result.ss.write(kind.uint8)

  # The RTPS specification does not define any settings for the 2 byte
  # options field and further states that a receiver should not interpret it
  # when it reads the options field
  result.ss.writeBe(0'u16)
  assert result.ss.getPosition() == 4

proc align*(this: CdrWriter, size: int, bytesToWrite: int = size): void =
    let alignment = (this.ss.getPosition() - 4) mod size
    let padding = if alignment > 0: size - alignment else: 0
    echo "set alignment: ", size, " align: ", alignment, " to ", $(size-alignment)

    # // Write padding bytes
    for i in 0 ..< padding:
      this.ss.write(0'u8)

proc write*[T: SomeFloat|SomeInteger](this: CdrWriter, val: T): CdrWriter {.discardable.} =
  this.align(sizeof(T))
  result = this
  if this.littleEndian:
    this.ss.writeLe(val)
  else:
    this.ss.writeBe(val)

proc writeBe*[T: SomeFloat | SomeInteger](this: CdrWriter, val: T): CdrWriter {.discardable.} =
  this.align(sizeof(T))
  this.ss.writeBe(val)

proc write*(this: CdrWriter, value: string): CdrWriter {.discardable.} =
  let strlen = value.len
  this.write(uint32(strlen+1))
  this.ss.write(value)
  this.write(uint8(0)) # add null terminator
  return this

proc sequenceLength*(this: CdrWriter, value: int): CdrWriter {.discardable.} =
  return this.write(uint32(value))

proc writeArray*[T: SomeInteger|SomeFloat|string](
    this: CdrWriter,
    value: openArray[T],
    writeLength: bool = false
): CdrWriter {.discardable.} =
    echo "writeArray: TP: ", $(T)
    if writeLength == true:
      this.sequenceLength(value.len)
    this.ss.resizeIfNeeded(value.len)
    for v in value:
      this.write(v)
    return this
