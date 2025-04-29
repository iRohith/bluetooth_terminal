import 'dart:typed_data';

import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:equatable/equatable.dart';

class DataPacket extends Equatable {
  final int cmd;
  final double value;
  final int id;

  const DataPacket({required this.cmd, required this.id, this.value = 0});

  @override
  List<Object> get props => [cmd, id, value];

  DataPacket copyWith({int? cmd, double? value, int? id}) {
    return DataPacket(
      cmd: cmd ?? this.cmd,
      value: value ?? this.value,
      id: id ?? this.id,
    );
  }

  factory DataPacket.fromBuffer(Uint8List buffer, {int offset = 0, bool littleEndian = false}) {
    ByteData byteData = ByteData.view(buffer.buffer, offset);
    return DataPacket(
      cmd: byteData.getUint8(0),
      value: byteData.getFloat32(1, littleEndian ? Endian.little : Endian.big),
      id: byteData.getUint8(5),
    );
  }

  Uint8List toBuffer(Uint8List? buffer, {int offset = 0, bool littleEndian = false}) {
    buffer ??= Uint8List(PACKET_SIZE);
    ByteData byteData = ByteData.view(buffer.buffer, offset);
    byteData.setUint8(0, cmd);
    byteData.setFloat32(1, value, littleEndian ? Endian.little : Endian.big);
    byteData.setUint8(5, id);

    if (buffer.length - offset >= 8){
      byteData.setUint8(6, 0xFF);
      byteData.setUint8(7, 0xFF);
    }

    return buffer;
  }

  @override
  String toString() {
    return "Id: 0x${id.toRadixString(16).toUpperCase()}; Cmd: 0x${cmd.toRadixString(16).toUpperCase()}; Value: ${value.toStringAsFixed(3)}";
  }

  Map<String, dynamic> toJson() {
    return {'cmd': cmd, 'value': value, 'id': id};
  }

  factory DataPacket.fromJson(Map<String, dynamic> json) {
    return DataPacket(
      cmd: json['cmd'] as int,
      value: json['value']?.toDouble() ?? 0.0,
      id: json['id'] as int,
    );
  }
}
