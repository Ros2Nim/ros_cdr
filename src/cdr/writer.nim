
import std/endians
import std/streams
import std/options

import cdrtypes

const
  DEFAULT_CAPACITY = 16
  BUFFER_COPY_THRESHOLD = 10

type
  CdrWriterOpts* = object
    buffer: Option[string]
    size: Option[int]
    kind: Option[EncapsulationKind]

  CdrWriter* = ref object
    littleEndian: bool
    hostLittleEndian: bool
    buffer: string
    array: seq[uint8]
    ss: StringStream

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


proc data(this: CdrWriter): string =
  return this.ss.data

proc size(this: CdrWriter, ): int =
  return this.ss.getPosition()

proc resizeIfNeeded(ss: StringStream, additionalBytes: int) =
  let capacity = ss.getPosition() + additionalBytes
  if (ss.data.len() < capacity):
    ss.data.setLen(capacity)

proc initCdrWriter*(opts: CdrWriterOpts): CdrWriter =
    new result

    if (opts.buffer.isSome):
      result.ss = newStringStream(opts.buffer.get())
    elif (opts.size.isSome):
      result.ss = newStringStream(newString(opts.size.get()))
    else:
      result.ss = newStringStream(newString(DEFAULT_CAPACITY))

    let kind = if opts.kind.isSome: opts.kind.get()
               else: EncapsulationKind.CDR_LE
    result.littleEndian = kind in [CDR_LE, PL_CDR_LE]

    # Write the Representation Id and Offset fields
    result.ss.resizeIfNeeded(4)
    result.ss.write(0) # Upper bits of EncapsulationKind, unused
    result.ss.write(kind)

    # The RTPS specification does not define any settings for the 2 byte
    # options field and further states that a receiver should not interpret it
    # when it reads the options field
    result.ss.writeBe(0'u16)
    assert result.ss.getPosition() == 4

proc align(this: CdrWriter, size: int, bytesToWrite: int = size): void =
    let alignment = (this.ss.getPosition() - 4) mod size
    let padding = if alignment > 0: size - alignment else: 0
    echo "set alignment: ", size, " align: ", alignment, " to ", $(size-alignment)

    this.ss.resizeIfNeeded(padding + bytesToWrite);
    # // Write padding bytes
    for i in 0 ..< padding:
      this.ss.write(0'u8)


template implWriter(NAME, TP, BS: untyped) =
  proc `read NAME BS`*(this: CdrWriter): `TP BS` =
    this.align(BS div 8)
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

implWriter(Uint, uint, 8)
implWriter(Uint, uint, 16)
implWriter(Uint, uint, 32)
implWriter(Uint, uint, 64)

implWriter(Int, int, 8)
implWriter(Int, int, 16)
implWriter(Int, int, 32)
implWriter(Int, int, 64)

implWriter(Float, float, 32)
implWriter(Float, float, 64)

template implWriterBe(NAME, TP, BS: untyped) =
  proc `read NAME BS Be`*(this: CdrReader): `TP BS` =
    this.align(BS div 8)
    var tmp: `TP BS` = this.ss.`read NAME BS`()
    bigEndian16(addr(result), addr(tmp))

implWriterBe(Uint, uint, 8)
implWriterBe(Uint, uint, 16)
implWriterBe(Uint, uint, 32)
implWriterBe(Uint, uint, 64)

implWriterBe(Int, int, 8)
implWriterBe(Int, int, 16)
implWriterBe(Int, int, 32)
implWriterBe(Int, int, 64)
