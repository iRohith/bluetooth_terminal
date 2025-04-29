import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluetooth_terminal/modals/data_packet.dart';
import 'package:bluetooth_terminal/connectors/base_connector.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:crypto/crypto.dart';

class MockConnector extends BaseConnector {
  final bool idleMode;
  final List<int> _pending = [];
  late final String _pwd;
  double lastPing = 0;

  final stopwatch = Stopwatch()..start();

  MockConnector({this.idleMode = true}) {
    _pwd = sha256.convert(utf8.encode("12345678")).toString();
  }

  @override
  Future<bool> init() async {
    return true;
  }

  @override
  Future<bool> dispose() async {
    return true;
  }

  @override
  Future<bool> connect() async {
    connected.value = true;
    return true;
  }

  @override
  Future<bool> disconnect() async {
    connected.value = false;
    return true;
  }

  @override
  Stream<int> read() async* {
    if (idleMode) {
      while (connected.value) {
        await Future.delayed(const Duration(seconds: 1));
      }
      yield -1;
      return;
    }

    final Random random = Random();
    Uint8List buffer = Uint8List(PACKET_SIZE);

    int i = 1;
    double x = 0.0;

    DataPacket dp = DataPacket(cmd: 0, id: 0);

    while (connected.value) {
      var val = random.nextDouble();

      if (i == 0x3) {
        val = sin(x);
      } else if (i == 0x5) {
        val = 0.5 * (val * 0.3 + 0.3 * (1 + cos(x * 5)));
      }

      dp = DataPacket(cmd: FLOAT_RECV, id: i++, value: val);
      dp.toBuffer(buffer);

      for (int i = 0; i < PACKET_SIZE; ++i) {
        yield buffer[i];
      }

      if (_pending.isNotEmpty) {
        for (int b in _pending) {
          yield b;
        }
        _pending.clear();
      }

      if (i > 10) {
        final ms = stopwatch.elapsedMilliseconds;

        i = 1;
        x = 2 * pi * (ms * 0.001) / 5;
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    yield -1;
  }

  @override
  Future<int> write(Uint8List buffer) async {
    if (idleMode) return buffer.length;

    final cmd = buffer[0];

    if (cmd == PASSWORD_SEND) {
      Future.delayed(const Duration(seconds: 3), () {
        if (_pwd == utf8.decode(buffer.sublist(1, 65), allowMalformed: true)) {
          _pending.addAll(DataPacket(cmd: PASSWORD_VALID, id: 0).toBuffer(null));
        } else {
          _pending.addAll(DataPacket(cmd: PASSWORD_INVALID, id: 0).toBuffer(null));
        }
      });
    } else if (cmd == PING) {
      Future.delayed(const Duration(milliseconds: 10), (){
        _pending.addAll(buffer.take(PACKET_SIZE));
      });
    }

    return buffer.length;
  }
}
