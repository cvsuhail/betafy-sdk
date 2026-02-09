import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../models/analytics_event.dart';
import '../firebase_service.dart';

/// Service for tracking detailed analytics events
class AnalyticsService with WidgetsBindingObserver {
  AnalyticsService({
    required this.gigId,
    required this.testerId,
    required FirebaseHeartbeatService firebaseService,
  })  : _firebaseService = firebaseService,
        _uuid = const Uuid();

  final String gigId;
  final String testerId;
  final FirebaseHeartbeatService _firebaseService;
  final Uuid _uuid;

  SessionData? _currentSession;
  final List<AnalyticsEvent> _pendingEvents = [];
  final List<CrashReport> _pendingCrashes = [];
  Timer? _flushTimer;
  bool _sending = false;

  String? _currentScreen;
  DateTime? _screenStartTime;

  /// Initialize the analytics service
  Future<void> initialize() async {
    WidgetsBinding.instance.addObserver(this);
    _startNewSession();
    
    // Flush events every 5 minutes
    _flushTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _flushPendingData();
    });
  }

  /// Start a new session
  void _startNewSession() {
    _currentSession = SessionData(
      sessionId: _uuid.v4(),
      startTime: DateTime.now().toUtc(),
    );
  }

  /// End the current session
  void _endCurrentSession() {
    if (_currentSession != null) {
      _currentSession!.endTime = DateTime.now().toUtc();
      _currentSession!.totalDuration = _currentSession!.endTime!
          .difference(_currentSession!.startTime);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _endCurrentSession();
      _flushPendingData();
    } else if (state == AppLifecycleState.resumed) {
      _startNewSession();
    }
  }

  /// Track a screen view
  void trackScreenView(String screenName) {
    // End previous screen tracking if exists
    if (_currentScreen != null && _screenStartTime != null) {
      final duration = DateTime.now().difference(_screenStartTime!);
      trackEvent(
        AnalyticsEvent(
          eventType: AnalyticsEventType.screenView,
          eventName: 'screen_view',
          timestamp: DateTime.now().toUtc(),
          screenName: _currentScreen,
          duration: duration,
        ),
      );
    }

    // Start tracking new screen
    _currentScreen = screenName;
    _screenStartTime = DateTime.now();

    // Add to session data
    if (_currentSession != null) {
      _currentSession!.screenViews.add(screenName);
    }
  }

  /// Track a button click or user interaction
  void trackButtonClick(String buttonName, {Map<String, dynamic>? properties}) {
    trackEvent(
      AnalyticsEvent(
        eventType: AnalyticsEventType.buttonClick,
        eventName: 'button_click',
        timestamp: DateTime.now().toUtc(),
        screenName: _currentScreen,
        properties: {
          'buttonName': buttonName,
          if (properties != null) ...properties,
        },
      ),
    );
  }

  /// Track feature usage
  void trackFeatureUsage(String featureName, {Duration? duration, Map<String, dynamic>? properties}) {
    trackEvent(
      AnalyticsEvent(
        eventType: AnalyticsEventType.featureUsage,
        eventName: 'feature_usage',
        timestamp: DateTime.now().toUtc(),
        screenName: _currentScreen,
        duration: duration,
        properties: {
          'featureName': featureName,
          if (properties != null) ...properties,
        },
      ),
    );
  }

  /// Track a custom event
  void trackCustomEvent(String eventName, {Map<String, dynamic>? properties}) {
    trackEvent(
      AnalyticsEvent(
        eventType: AnalyticsEventType.customEvent,
        eventName: eventName,
        timestamp: DateTime.now().toUtc(),
        screenName: _currentScreen,
        properties: properties,
      ),
    );
  }

  /// Track an error (non-fatal)
  void trackError(String errorMessage, {String? stackTrace, Map<String, dynamic>? context}) {
    if (_currentSession != null) {
      _currentSession!.errorCount++;
    }

    trackEvent(
      AnalyticsEvent(
        eventType: AnalyticsEventType.error,
        eventName: 'error',
        timestamp: DateTime.now().toUtc(),
        screenName: _currentScreen,
        errorMessage: errorMessage,
        stackTrace: stackTrace,
        properties: context,
      ),
    );
  }

  /// Track a crash (fatal error)
  void trackCrash(String error, String stackTrace, {Map<String, dynamic>? context}) {
    if (_currentSession != null) {
      _currentSession!.crashCount++;
    }

    final crashReport = CrashReport(
      timestamp: DateTime.now().toUtc(),
      error: error,
      stackTrace: stackTrace,
      fatal: true,
      context: context,
    );

    _pendingCrashes.add(crashReport);
    
    // Immediately flush crash reports
    _flushPendingData();
  }

  /// Track a generic event
  void trackEvent(AnalyticsEvent event) {
    _pendingEvents.add(event);

    // Auto-flush if we have too many pending events
    if (_pendingEvents.length >= 50) {
      _flushPendingData();
    }
  }

  /// Flush pending analytics data to Firebase
  Future<void> _flushPendingData() async {
    if (_sending) return;
    if (_pendingEvents.isEmpty && _pendingCrashes.isEmpty) return;

    _sending = true;

    try {
      // Send analytics events
      if (_pendingEvents.isNotEmpty) {
        await _firebaseService.logAnalytics(
          gigId: gigId,
          testerId: testerId,
          sessionData: _currentSession,
          events: List.from(_pendingEvents),
        );
        _pendingEvents.clear();
      }

      // Send crash reports
      if (_pendingCrashes.isNotEmpty) {
        await _firebaseService.logCrashReports(
          gigId: gigId,
          testerId: testerId,
          crashes: List.from(_pendingCrashes),
        );
        _pendingCrashes.clear();
      }
    } catch (e) {
      debugPrint('Failed to flush analytics: $e');
    } finally {
      _sending = false;
    }
  }

  /// Get current session data
  SessionData? get currentSession => _currentSession;

  /// Get pending events count
  int get pendingEventsCount => _pendingEvents.length;

  /// Get pending crashes count
  int get pendingCrashesCount => _pendingCrashes.length;

  /// Dispose the service
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushTimer?.cancel();
    _endCurrentSession();
    _flushPendingData();
  }
}
