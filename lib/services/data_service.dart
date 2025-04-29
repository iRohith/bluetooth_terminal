import 'dart:convert';

import 'package:bluetooth_terminal/services/connection_service.dart';
import 'package:bluetooth_terminal/services/log_service.dart';
import 'package:bluetooth_terminal/services/storage_service.dart';
import 'package:bluetooth_terminal/utils/constants.dart';
import 'package:get/get.dart';

class DataService extends GetxService {
  static DataService get to => Get.find();

  final storageService = StorageService.to;
  final logService = LogService.to;
  final connectionService = ConnectionService.to;

  final _variables = <int, RxDouble>{};
  final _rxvars = <String, dynamic>{};

  Worker? _varsUpdateWorker;

  Rx<T> getVar<T>(String key, T defaultValue, {bool save = false}) {
    Rx<T>? ret = _rxvars[key];
    if (ret == null) {
      ret = defaultValue.obs;
      _rxvars[key] = ret;

      if (save){
        final obj = storageService.prefs.get(key);

        if (obj != null) {
          if (obj is List<String>) {
            ret.value = (T as dynamic).fromJson(jsonDecode(obj.first));
          } else if (obj is T) {
            ret.value = obj as T;
          }
        }

        debounce(ret, (v) async {
          if (v is int){
            storageService.prefs.setInt(key, v);
          } else if (v is double){
            storageService.prefs.setDouble(key, v);
          } else if (v is bool){
            storageService.prefs.setBool(key, v);
          } else if (v is String){
            storageService.prefs.setString(key, v);
          } else {
            storageService.prefs.setStringList(key, [jsonEncode(ret!.toJson())]);
          }
        });
      }
    }
    return ret;
  }

  void removeAllVarsWithPrefix<T>(String prefix) {
    for (final e in _rxvars.entries) {
      if (e.key.startsWith(prefix)) {
        final Rx<T> rx = _rxvars.remove(e.key);
        rx.close();
      }
    }
  }

  RxDouble getVariable(int id) {
    var ret = _variables[id];
    if (ret == null) {
      ret = 0.0.obs;
      _variables[id] = ret;
    }
    return ret;
  }

  bool hasVariable(int id) => _variables.containsKey(id);

  void reset() {
    _variables.clear();
  }

  @override
  void onInit() {
    super.onInit();

    _varsUpdateWorker?.dispose();
    _varsUpdateWorker = ever(ConnectionService.to.currentPacket, (dp) {
      if (dp.cmd == FLOAT_RECV) {
        getVariable(dp.id).value = dp.value;
      }
    });
  }

  @override
  void onClose() {
    _varsUpdateWorker?.dispose();
    super.onClose();
  }
}
