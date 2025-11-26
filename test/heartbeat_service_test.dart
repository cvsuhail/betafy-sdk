import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tester_heartbeat_sdk/src/device_info_service.dart';
import 'package:tester_heartbeat_sdk/src/firebase_service.dart';
import 'package:tester_heartbeat_sdk/src/heartbeat_service.dart';
import 'package:tester_heartbeat_sdk/src/models/device_data.dart';
import 'package:tester_heartbeat_sdk/src/models/heartbeat_event.dart';
import 'package:tester_heartbeat_sdk/src/utils/emulator_check.dart';

class _MockVoidCallback extends Mock {
  void call();
}

class _MockDeviceInfoService extends Mock implements DeviceInfoService {}

class _MockFirebaseService extends Mock implements FirebaseHeartbeatService {}

class _MockEmulatorCheck extends Mock implements EmulatorCheck {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HeartbeatService', () {
    late _MockDeviceInfoService deviceInfo;
    late _MockFirebaseService firebase;
    late _MockEmulatorCheck emulator;
    late DeviceData deviceData;

    setUp(() {
      registerFallbackValue(
        HeartbeatEvent(
          gigId: 'gig',
          testerId: 'tester',
          sessionId: 'session',
          timestamps: [DateTime.now().toUtc()],
          deviceData: DeviceData(
            deviceId: 'dev',
            installId: 'inst',
            appPackageName: 'pkg',
            platform: 'android',
            model: 'model',
            osVersion: '14',
          ),
          isEmulator: false,
        ),
      );
      deviceInfo = _MockDeviceInfoService();
      firebase = _MockFirebaseService();
      emulator = _MockEmulatorCheck();
      SharedPreferences.setMockInitialValues({});
      deviceData = DeviceData(
        deviceId: 'dev',
        installId: 'inst',
        appPackageName: 'pkg',
        platform: 'android',
        model: 'model',
        osVersion: '14',
      );
      when(() => deviceInfo.loadDeviceData())
          .thenAnswer((_) async => deviceData);
      when(() => firebase.initialize()).thenAnswer((_) async {});
      when(() => firebase.logHeartbeat(any())).thenAnswer(
        (_) async => HeartbeatResponse(
          completedStreak: false,
          multiAccountDetected: false,
          deviceMismatch: false,
        ),
      );
      when(() => emulator.isEmulator()).thenAnswer((_) async => false);
    });

    test('initializes and queues heartbeat', () async {
      final onEmulator = _MockVoidCallback();
      final onMulti = _MockVoidCallback();

      final service = HeartbeatService(
        gigId: 'gig',
        testerId: 'tester',
        onEmulatorDetected: onEmulator.call,
        onMultiAccountDetected: onMulti.call,
        deviceInfoService: deviceInfo,
        firebaseHeartbeatService: firebase,
        emulatorCheck: emulator,
      );

      await service.initialize();
      await service.waitForReady();
      await service.sendHeartbeat();

      verifyNever(onEmulator.call);
      verifyNever(onMulti.call);
      verify(() => firebase.logHeartbeat(any()))
          .called(greaterThanOrEqualTo(1));
    });
  });
}
