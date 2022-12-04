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

proc writeExampleMessage(writer: CdrWriter) =
  # // geometry_msgs/TransformStamped[] transforms
  writer.sequenceLength(1)
  # // std_msgs/Header header
  # // time stamp
  writer.write uint32(1490149580) #// uint32 sec
  writer.write uint32(117017840) #// uint32 nsec
  writer.write "base_link" #// string frame_id
  writer.write "radar" #// string child_frame_id
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
  
  test "serializes an example message with external preallocation":
    let data = $cast[string](tf2_msg_TFMessage.hexToSeqByte())
    check tf2_msg_TFMessage == data.toHex().toLowerAscii()

    var writer = newCdrWriter(buffer = some newString(100))
    check writer.isLittleEndian() == true
    writeExampleMessage(writer)
    let res_msg_TFMessage = toHex(writer.data).toLowerAscii
    check(res_msg_TFMessage == tf2_msg_TFMessage)

  test "round trips all data types":
    let writer = newCdrWriter()
    writer.write(int8 -1);
    writer.write(uint8 2);
    writer.write(int16 -300);
    writer.write(uint16 400);
    writer.write(int32 -500_000);
    writer.write(uint32 600_000);
    writer.write(int64 -7_000_000_001);
    writer.write(uint64 8_000_000_003);
    writer.writeBe(uint16 0x1234);
    writer.writeBe(uint32 0x12345678);
    writer.writeBe(uint64 0x123456789abcdef0);
    writer.write(float32 -9.14);
    writer.write(float64 1.7976931348623158e100);
    writer.write("abc");
    writer.sequenceLength(42);
    let data = writer.data;
    check(data.len == 80);

    let reader = newCdrReader(data)
    check(reader.read(int8) == -1);
    check(reader.read(uint8) == 2);
    check(reader.read(int16) == -300);
    check(reader.read(uint16) == 400);
    check(reader.read(int32) == -500_000);
    check(reader.read(uint32) == 600_000);
    check(reader.read(int64) == -7_000_000_001);
    check(reader.read(uint64) == 8_000_000_003);
    check(reader.readBe(uint16) == 0x1234);
    check(reader.readBe(uint32) == 0x12345678);
    check(reader.readBe(uint64) == 0x123456789abcdef0);
    check(reader.read(float32) ~= -9.14);
    check(reader.read(float64) ~= 1.7976931348623158e100);
    check(reader.readStr() == "abc");
    check(reader.sequenceLength() == 42);