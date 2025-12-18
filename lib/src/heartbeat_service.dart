import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

import 'device_info_service.dart';
import 'firebase_service.dart';
import 'models/device_data.dart';
import 'models/heartbeat_event.dart';
import 'utils/emulator_check.dart';
import 'utils/shared_prefs.dart';

class HeartbeatService with WidgetsBindingObserver {
  HeartbeatService({
    required this.gigId,
    required this.testerId,
    required VoidCallback onEmulatorDetected,
    required VoidCallback onMultiAccountDetected,
    Duration heartbeatInterval = const Duration(hours: 1),
    DeviceInfoService? deviceInfoService,
    FirebaseHeartbeatService? firebaseHeartbeatService,
    EmulatorCheck? emulatorCheck,
    SharedPrefsStore? prefsStore,
    Uuid? uuid,
    FirebaseOptions? sdkFirebaseOptions,
  })  : _onEmulatorDetected = onEmulatorDetected,
        _onMultiAccountDetected = onMultiAccountDetected,
        _heartbeatInterval = heartbeatInterval,
        _deviceInfoService = deviceInfoService ?? DeviceInfoService(),
        _firebaseService = firebaseHeartbeatService ?? 
            FirebaseHeartbeatService(options: sdkFirebaseOptions),
        _emulatorCheck = emulatorCheck ?? EmulatorCheck(),
        _prefsStore = prefsStore,
        _uuid = uuid ?? const Uuid();

  final String gigId;
  final String testerId;
  final VoidCallback _onEmulatorDetected;
  final VoidCallback _onMultiAccountDetected;
  final Duration _heartbeatInterval;
  final DeviceInfoService _deviceInfoService;
  final FirebaseHeartbeatService _firebaseService;
  final EmulatorCheck _emulatorCheck;
  SharedPrefsStore? _prefsStore;
  final Uuid _uuid;

  late final String _sessionId;
  late DeviceData deviceData;
  late bool _isEmulator;

  final List<HeartbeatEvent> _pendingEvents = [];
  Timer? _debounceTimer;
  bool _sending = false;
  bool _ready = false;
  HeartbeatEvent? lastEvent;

  Future<SharedPrefsStore> get _prefs async {
    return _prefsStore ??= await SharedPrefsStore.instance();
  }

  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.addObserver(this);
    _sessionId = _uuid.v4();
    deviceData = await _deviceInfoService.loadDeviceData();
    _isEmulator = await _emulatorCheck.isEmulator();
    if (_isEmulator) {
      _onEmulatorDetected();
    }
    await _hydratePending();
    await _firebaseService.initialize();
    await sendHeartbeat();
    _ready = true;
  }

  Future<void> waitForReady() async {
    while (!_ready) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sendHeartbeat();
    }
  }

  Future<void> sendHeartbeat() async {
    final now = DateTime.now().toUtc();
    final event = HeartbeatEvent(
      gigId: gigId,
      testerId: testerId,
      sessionId: _sessionId,
      timestamps: [now],
      deviceData: deviceData,
      isEmulator: _isEmulator,
    );
    _pendingEvents.add(event);
    lastEvent = event;
    await _storePending();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_heartbeatInterval, _flushQueue);
    unawaited(_flushQueue());
  }

  Future<void> _flushQueue() async {
    if (_sending) return;
    if (_pendingEvents.isEmpty) return;
    _sending = true;

    try {
      while (_pendingEvents.isNotEmpty) {
        final event = _pendingEvents.first;
        final response = await _firebaseService.logHeartbeat(event);

        if (response.multiAccountDetected || response.deviceMismatch) {
          _onMultiAccountDetected();
          break;
        }

        _pendingEvents.removeAt(0);
        await _storePending();
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> _hydratePending() async {
    final prefs = await _prefs;
    final raw = await prefs.pendingHeartbeats();
    if (raw.isEmpty) return;
    _pendingEvents
      ..clear()
      ..addAll(raw.map(HeartbeatEvent.decode));
  }

  Future<void> _storePending() async {
    final prefs = await _prefs;
    if (_pendingEvents.isEmpty) {
      await prefs.clearPending();
      return;
    }
    final serialized = _pendingEvents.map((e) => e.encode()).toList();
    await prefs.savePending(serialized);
    await prefs.pruneOldest(50);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
  }
}
