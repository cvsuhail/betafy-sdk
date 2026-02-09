import 'package:flutter/widgets.dart';
import '../../tester_heartbeat_sdk.dart';

/// Route observer that automatically tracks screen views
class BetafyRouteObserver extends RouteObserver<ModalRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is ModalRoute) {
      final routeName = route.settings.name ?? 'unknown_screen';
      TesterHeartbeatSDK.trackScreenView(routeName);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute is ModalRoute && route is ModalRoute) {
      final routeName = previousRoute.settings.name ?? 'unknown_screen';
      TesterHeartbeatSDK.trackScreenView(routeName);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is ModalRoute) {
      final routeName = newRoute.settings.name ?? 'unknown_screen';
      TesterHeartbeatSDK.trackScreenView(routeName);
    }
  }
}
