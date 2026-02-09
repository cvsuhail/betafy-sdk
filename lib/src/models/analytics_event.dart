import 'dart:convert';

/// Different types of analytics events that can be tracked
enum AnalyticsEventType {
  screenView,
  buttonClick,
  featureUsage,
  error,
  crash,
  customEvent,
}

/// Detailed analytics event for tracking user interactions and app behavior
class AnalyticsEvent {
  AnalyticsEvent({
    required this.eventType,
    required this.eventName,
    required this.timestamp,
    this.screenName,
    this.duration,
    this.properties,
    this.errorMessage,
    this.stackTrace,
  });

  final AnalyticsEventType eventType;
  final String eventName;
  final DateTime timestamp;
  final String? screenName;
  final Duration? duration;
  final Map<String, dynamic>? properties;
  final String? errorMessage;
  final String? stackTrace;

  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType.toString().split('.').last,
      'eventName': eventName,
      'timestamp': timestamp.toUtc().toIso8601String(),
      if (screenName != null) 'screenName': screenName,
      if (duration != null) 'duration': duration!.inMilliseconds,
      if (properties != null) 'properties': properties,
      if (errorMessage != null) 'errorMessage': errorMessage,
      if (stackTrace != null) 'stackTrace': stackTrace,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      eventType: AnalyticsEventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['eventType'],
        orElse: () => AnalyticsEventType.customEvent,
      ),
      eventName: json['eventName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      screenName: json['screenName'] as String?,
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
      properties: json['properties'] as Map<String, dynamic>?,
      errorMessage: json['errorMessage'] as String?,
      stackTrace: json['stackTrace'] as String?,
    );
  }

  String encode() => jsonEncode(toJson());

  static AnalyticsEvent decode(String raw) =>
      AnalyticsEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Session data for tracking user sessions
class SessionData {
  SessionData({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    this.screenViews = const [],
    this.totalDuration,
    this.crashCount = 0,
    this.errorCount = 0,
  });

  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  List<String> screenViews;
  Duration? totalDuration;
  int crashCount;
  int errorCount;

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toUtc().toIso8601String(),
      if (endTime != null) 'endTime': endTime!.toUtc().toIso8601String(),
      'screenViews': screenViews,
      if (totalDuration != null) 'totalDuration': totalDuration!.inMilliseconds,
      'crashCount': crashCount,
      'errorCount': errorCount,
    };
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      screenViews: (json['screenViews'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalDuration: json['totalDuration'] != null
          ? Duration(milliseconds: json['totalDuration'] as int)
          : null,
      crashCount: json['crashCount'] as int? ?? 0,
      errorCount: json['errorCount'] as int? ?? 0,
    );
  }
}

/// Crash report data
class CrashReport {
  CrashReport({
    required this.timestamp,
    required this.error,
    required this.stackTrace,
    this.fatal = true,
    this.context,
    this.deviceInfo,
  });

  final DateTime timestamp;
  final String error;
  final String stackTrace;
  final bool fatal;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? deviceInfo;

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toUtc().toIso8601String(),
      'error': error,
      'stackTrace': stackTrace,
      'fatal': fatal,
      if (context != null) 'context': context,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      timestamp: DateTime.parse(json['timestamp'] as String),
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String,
      fatal: json['fatal'] as bool? ?? true,
      context: json['context'] as Map<String, dynamic>?,
      deviceInfo: json['deviceInfo'] as Map<String, dynamic>?,
    );
  }

  String encode() => jsonEncode(toJson());

  static CrashReport decode(String raw) =>
      CrashReport.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
