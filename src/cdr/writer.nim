
import std/endians
import std/streams
import std/options

import cdrtypes

const
  DEFAULT_CAPACITY = 16
  BUFFER_COPY_THRESHOLD = 10

type
  CdrWriterOpts* = ref object
    buffer: Option[string]
    size: Option[int]
    kind: Option[EncapsulationKind]

  CdrWriter* = ref object
    littleEndian: bool
    hostLittleEndian: bool
    buffer: string
    array: seq[uint8]
    ss: StringStream