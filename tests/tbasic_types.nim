# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import strutils
import stew/byteutils

import ros_cdr/cdrtypes
import ros_cdr/writer
import ros_cdr/reader

proc near*[T: SomeFloat](x, y: T, eps: T): bool =
  result = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T): bool =
  near(x, y, 1.0e-6)
proc `~=` *[T: float32](x, y: T): bool =
  near(x, y, 1.0e-4)


suite "Cdr Write":

  test "test_interface_files/msg/BasicTypes.msg":
    let writer = newCdrWriter()
    writer.write bool true
    writer.write byte 0x7
    writer.write float32 2.713
    writer.write float64 3.1415
    writer.write int8 0x5
    writer.write uint8 0x7
    writer.write int16 0x123
    writer.write uint16 0x123
    writer.write int32 0x56123
    writer.write uint32 0x56123
    writer.write int64 0x56123
    writer.write uint64 0xFF_FF_FF_FF_FF_FF_BB_AA'u64

    let data = writer.data
    echo "hex: ", toHex(data)
    check toHex(data) == "0001000001070000CBA12D406F1283C0CA210940050723012301000023610500236105002361050000000000AABBFFFFFFFFFFFF"
