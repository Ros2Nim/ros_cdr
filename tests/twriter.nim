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
import cdr/writer

# Example tf2_msgs/TFMessage
const tf2_msg_TFMessage: string =
     "0001000001000000cce0d158f08cf9060a000000626173655f6c696e6b000000060000007261646172000000ae47e17a14ae0e4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000f03f"

proc near*[T: SomeFloat](x, y: T, eps: T): bool =
  result = abs(x-y) < eps
proc `~=` *[T: float64](x, y: T): bool =
  near(x, y, 1.0e-6)
proc `~=` *[T: float32](x, y: T): bool =
  near(x, y, 1.0e-4)

proc writeExampleMessage(writer: CdrWriter) =
  # // geometry_msgs/TransformStamped[] transforms
  writer.sequenceLength(1)
  # // std_msgs/Header header
  # // time stamp
  writer.write uint32(1490149580) #// uint32 sec
  writer.write uint32(117017840) #// uint32 nsec
  writer.writeStr "base_link" #// string frame_id
  writer.writeStr "radar" #// string child_frame_id
  # // geometry_msgs/Transform transform
  # // geometry_msgs/Vector3 translation
  writer.write float64(3.835) #// float64 x
  writer.write float64(0) #// float64 y
  writer.write float64(0) #// float64 z
  # // geometry_msgs/Quaternion rotation
  writer.write float64(0) #// float64 x
  writer.write float64(0) #// float64 y
  writer.write float64(0) #// float64 z
  writer.write float64(1) #// float64 w

suite "CdrWriter":
  test "serializes an example message with internal preallocation":
    let data = $cast[string](tf2_msg_TFMessage.hexToSeqByte())
    check tf2_msg_TFMessage == data.toHex().toLowerAscii()

    var writer = newCdrWriter(size = some 100)
    check writer.isLittleEndian() == true
    writeExampleMessage(writer)
    check(writer.getPosition() == 100)
    let res_msg_TFMessage = toHex(writer.data).toLowerAscii
    check(res_msg_TFMessage == tf2_msg_TFMessage)
