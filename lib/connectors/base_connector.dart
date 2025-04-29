import 'dart:typed_data';

import 'package:get/get.dart';

abstract class BaseConnector {
  Future<bool> init();

  Future<bool> dispose();

  Future<bool> connect();

  Future<bool> disconnect();

  Future<int> write(Uint8List buffer);

  Stream<int> read();

  final connected = false.obs;
}
