import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Simplified emulator detection heuristics.
class EmulatorCheck {
  final DeviceInfoPlugin _plugin;

  EmulatorCheck({DeviceInfoPlugin? plugin})
      : _plugin = plugin ?? DeviceInfoPlugin();

  Future<bool> isEmulator() async {
    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      final fingerprint = info.fingerprint.toLowerCase();
      final model = info.model.toLowerCase();
      final brand = info.brand.toLowerCase();
      final product = info.product.toLowerCase();
      return fingerprint.contains('generic') ||
          model.contains('sdk') ||
          model.contains('emulator') ||
          brand.contains('generic') ||
          product.contains('sdk');
    }

    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      final model = info.utsname.machine.toLowerCase();
      return model.contains('simulator') || model.contains('x86');
    }

    return false;
  }
}
