

type 
  CdrSizeCalculator* = ref object
    # Two bytes for Representation Id and two bytes for Options
    offset: int # 4

proc incrementAndReturn(this: CdrSizeCalculator, byteCount: int): int =
  # Increments the offset by `byteCount` and any required padding bytes and
  # returns the new offset
  let alignment = (this.offset - 4) mod byteCount
  if (alignment > 0):
    this.offset += byteCount - alignment
  this.offset += byteCount;
  return this.offset;

proc add*[T: SomeInteger|SomeFloat](
    this: CdrSizeCalculator,
    tp: typedesc[T]
): int {.discardable.} =
  return this.incrementAndReturn(sizeof(T))

proc addStr*(
    this: CdrSizeCalculator,
    length: int
): int =
  this.add(uint32)
  this.offset += length + 1 # Add one for the null terminator
  return this.offset

proc sequenceLength*(this: CdrSizeCalculator): int =
  return this.add(uint32)
