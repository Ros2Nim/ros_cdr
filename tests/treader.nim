# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import strutils
import stew/byteutils

import cdr/cdrtypes
import cdr/reader

# Example tf2_msgs/TFMessage
const tf2_msg_TFMessage: string =
     "0001000001000000cce0d158f08cf9060a000000626173655f6c696e6b000000060000007261646172000000ae47e17a14ae0e4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f03f"

proc near*[T: SomeFloat](x, y: T, eps: T): bool =
  result = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T): bool =
  near(x, y, 1.0e-6)
proc `~=` *[T: float32](x, y: T): bool =
  near(x, y, 1.0e-4)

suite "CdrReader":
  test "parses an example tf2_msgs/TFMessage message":
    
    let data = $cast[string](tf2_msg_TFMessage.hexToSeqByte())
    check tf2_msg_TFMessage == data.toHex().toLowerAscii()

    # echo "tf2_msg_TFMessage: ", toHex(data)
    let reader = newCdrReader(data)
    check(reader.decodedBytes == 4)
    check(reader.kind == EncapsulationKind.CDR_LE)

    # 00,01,00,00_01,00,00,00_cc,e0,d1,58_f08cf9060a000000626173655f6c696e6b000000060000007261646172000000ae47e17a14ae0e4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f03f
    # geometry_msgs/TransformStamped[] transforms
    check(reader.sequenceLength() == 1)
    # std_msgs/Header header
    # time stamp
    check(reader.readuint32() == 1490149580) # uint32 sec // 0x58D1E0CC
    check(reader.readuint32() == 117017840) # uint32 nsec
    let xx = reader.readString()
    echo "xx:len: ", xx.len(), " ", "base_link".len()
    echo "xx: `", xx, "`"
    check(xx == "base_link") # string frame_id
    echo ""
    let yy = reader.readString()
    echo "yy:len: ", yy.len(), " ", "radar".len()
    echo "yy: `", yy, "`"
    check(yy == "radar") # string child_frame_id
    # geometry_msgs/Transform transform
    # geometry_msgs/Vector3 translation
    check(reader.readfloat64() ~= 3.835) # float64 x
    check(reader.readfloat64() ~= 0) # float64 y
    check(reader.readfloat64() ~= 0) # float64 z
    # geometry_msgs/Quaternion rotation
    check(reader.readfloat64() ~= 0) # float64 x
    check(reader.readfloat64() ~= 0) # float64 y
    check(reader.readfloat64() ~= 0) # float64 z
    check(reader.readfloat64() ~= 1) # float64 w

    check(reader.getPosition() == data.len())
    check(reader.decodedBytes() == data.len)
    check(reader.byteLength() == data.len)
