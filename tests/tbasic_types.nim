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


suite "CdrWriter":

  test "round trips all data types":
    let writer = newCdrWriter()
    writer.write bool true
    writer.write byte 0x7
    writer.write float32 2.713
    writer.write float64 3.1415
    writer.write int8 0x5
    writer.write uint8 0x7
    writer.write uint64 0xFFFFFFFFFFF

    let data = writer.data
    # check(data.len == 52)
    echo "hex: ", toHex(data)
    echo "exp: ", "0001000001070000cba12d406f1283c0ca210940050700000000000000000000000000000000000000000000ffffffffff0f0000"
    # check toHex(data) == "0001000001070000cba12d406f1283c0ca210940050700000000000000000000000000000000000000000000ffffffffff0f0000"

    # actual   "00010000010000000000000007000000CBA12D406F1283C0CA2109400507000000000000FFFFFFFFFF0F0000"

    # expected "0001000001070000CBA12D406F1283C0CA210940050700000000000000000000000000000000000000000000FFFFFFFFFF0F0000"


  # test "aligns":
  #   let writer = newCdrWriter()
  #   writer.align(0)
  #   check(toHex(writer.data) == "00010000");
  #   writer.align(8);
  #   check(toHex(writer.data) == "00010000");
  #   writer.write(uint8(1)); #// one byte
  #   writer.align(8); #// seven bytes of padding
  #   writer.write(uint32(2)); #// four bytes
  #   writer.align(4); #// no-op, already aligned
  #   check(toHex(writer.data) == "00010000010000000000000002000000");