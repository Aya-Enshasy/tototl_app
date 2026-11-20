import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Route visibility for local debug testing. Never records route arguments,
/// user input, tokens or serialized models.
class TototlRouteDebugObserver extends NavigatorObserver {
  void _log(String action, Route<dynamic>? route) {
    if (!kDebugMode) return;
    debugPrint('[TOTOTL][NAV][$action] route=${route?.runtimeType}');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log('PUSH', route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _log('POP', route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _log('REPLACE', newRoute);
  }
}
