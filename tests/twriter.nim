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
    check(reader.read(int8) == -1'i8);
    check(reader.read(uint8) == 2'u8);
    check(reader.read(int16) == -300'i16);
    check(reader.read(uint16) == 400'u16);
    check(reader.read(int32) == -500_000'i32);
    check(reader.read(uint32) == 600_000'u32);
    check(reader.read(int64) == -7_000_000_001'i64);
    check(reader.read(uint64) == 8_000_000_003'u64);
    check(reader.readBe(uint16) == 0x1234'u16);
    check(reader.readBe(uint32) == 0x12345678'u32);
    check(reader.readBe(uint64) == 0x123456789abcdef0'u64);
    check(reader.read(float32) ~= -9.14'f32);
    check(reader.read(float64) ~= 1.7976931348623158e100'f64);
    check(reader.readStr() == "abc");
    check(reader.sequenceLength() == 42);
  
  test "round trip basic array type":
    let writer = newCdrWriter()
    writer.writeArray([-128'i8, 127, 3], true)

    echo "round trips: ", writer.data.len, " hex: ", writer.data.toHex
    let reader = newCdrReader(writer.data)
    let res = reader.readSeq(int8)
    check res.len == 3
    check(res == [-128'i8, 127, 3])

  test "round trips all array types":
    let writer = newCdrWriter()
    writer.writeArray([-128'i8, 127, 3])
    writer.writeArray([0'u8, 255, 3])
    writer.writeArray([-32768'i16, 32767, -3])
    writer.writeArray([0'u16, 65535, 3])
    writer.writeArray([-2147483648'i32, 2147483647, 3])
    writer.writeArray([0'u32, 4294967295'u32, 3])
    writer.writeArray([-9223372036854775808'i64, 9223372036854775807'i64, 3])
    writer.writeArray([0'u64, 18446744073709551615'u64, 3])

    echo "round trips: ", writer.data.toHex
    let reader = newCdrReader(writer.data)
    check(reader.readSeq(int8) == [-128'i8, 127, 3])
    check(reader.readSeq(uint8) == [0'u8, 255, 3])

  test "writes parameter lists":
    let writer = newCdrWriter(kind= some EncapsulationKind.PL_CDR_LE)
    writer.write(uint8(0x42))
    check(toHex(writer.data) == "0003000042")
    echo "lists"

  test "aligns":
    let writer = newCdrWriter()
    writer.align(0)
    check(toHex(writer.data) == "00010000");
    writer.align(8);
    check(toHex(writer.data) == "00010000");
    writer.write(uint8(1)); #// one byte
    writer.align(8); #// seven bytes of padding
    writer.write(uint32(2)); #// four bytes
    writer.align(4); #// no-op, already aligned
    check(toHex(writer.data) == "00010000010000000000000002000000");