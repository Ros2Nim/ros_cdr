# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest
import strutils

import cdr/cdrtypes
import cdr/reader

# Example tf2_msgs/TFMessage
const tf2_msg_TFMessage: string =
  static:
    let str = "0001000001000000cce0d158f08cf9060a000000626173655f6c696e6b000000060000007261646172000000ae47e17a14ae0e4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f03f"
    var data = newString(str.len() div 2)
    for i in countup(0, str.len()-2, 2):
      data.add(cast[char](fromHex[uint8](str[i..i+1])))
    data

proc near*[T: SomeFloat](x, y: T, eps: T): bool =
  result = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T): bool =
  near(x, y, 1.0e-6)
proc `~=` *[T: float32](x, y: T): bool =
  near(x, y, 1.0e-4)

suite "CdrReader":
  test "parses an example tf2_msgs/TFMessage message":
    
    let reader = newCdrReader(tf2_msg_TFMessage[0..^1])
    check(reader.decodedBytes == 4)

    # geometry_msgs/TransformStamped[] transforms
    check(reader.sequenceLength() == 1)
    # std_msgs/Header header
    # time stamp
    check(reader.readuint32() == 1490149580) # uint32 sec
    check(reader.readuint32() == 117017840) # uint32 nsec
    check(reader.readstring() == "base_link") # string frame_id
    check(reader.readstring() == "radar") # string child_frame_id
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

    check(reader.getPosition() == tf2_msg_TFMessage.len())
    check(reader.kind == EncapsulationKind.CDR_LE)
    check(reader.decodedBytes() == tf2_msg_TFMessage.len)
    check(reader.byteLength() == tf2_msg_TFMessage.len)
