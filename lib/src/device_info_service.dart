import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import 'models/device_data.dart';
import 'utils/shared_prefs.dart';

class DeviceInfoService {
  DeviceInfoService({
    DeviceInfoPlugin? deviceInfoPlugin,
    SharedPrefsStore? prefsStore,
    Uuid? uuid,
  })  : _deviceInfo = deviceInfoPlugin ?? DeviceInfoPlugin(),
        _prefsStore = prefsStore,
        _uuid = uuid ?? const Uuid();

  final DeviceInfoPlugin _deviceInfo;
  SharedPrefsStore? _prefsStore;
  final Uuid _uuid;

  DeviceData? _cached;

  Future<SharedPrefsStore> get _prefs async {
    return _prefsStore ??= await SharedPrefsStore.instance();
  }

  Future<DeviceData> loadDeviceData() async {
    if (_cached != null) return _cached!;

    final prefs = await _prefs;
    var installId = prefs.installId;
    installId ??= _uuid.v4();
    if (prefs.installId == null) {
      await prefs.persistInstallId(installId);
    }

    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      final detectedId = info.id.isNotEmpty
          ? info.id
          : (info.serialNumber.isNotEmpty
              ? info.serialNumber
              : 'unknown_android');
      _cached = DeviceData(
        deviceId: detectedId,
        installId: installId,
        appPackageName: packageInfo.packageName,
        platform: 'android',
        model: info.model,
        osVersion: info.version.release,
      );
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      final identifier = info.identifierForVendor ?? installId;
      _cached = DeviceData(
        deviceId: identifier,
        installId: installId,
        appPackageName: packageInfo.packageName,
        platform: 'ios',
        model: info.utsname.machine,
        osVersion: info.systemVersion,
      );
    } else {
      _cached = DeviceData(
        deviceId: 'unsupported',
        installId: installId,
        appPackageName: packageInfo.packageName,
        platform: Platform.operatingSystem,
        model: Platform.localHostname,
        osVersion: Platform.version,
      );
    }

    return _cached!;
  }
}
