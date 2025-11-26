import 'package:flutter_test/flutter_test.dart';
import 'package:tester_heartbeat_sdk/tester_heartbeat_sdk.dart';

void main() {
  test('TesterHeartbeatSDK exposes singleton', () {
    expect(TesterHeartbeatSDK.instance, isNotNull);
  });
}
