
type
  EncapsulationKind* = enum
    CDR_BE = 0,
    CDR_LE = 1,
    PL_CDR_BE = 2,
    PL_CDR_LE = 3

type
  CdrError* = object of ValueError
