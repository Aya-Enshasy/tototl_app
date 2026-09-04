import 'package:flutter/material.dart';

import '../screens/admin_shell_screen.dart';

// ============================================================================
// ADMIN ROUTE HELPER
//
// Use this in your existing Splash/Login role routing.
// It does not replace your Pilot/Company routing.
// ============================================================================

class AdminRouteHelper {
  AdminRouteHelper._();

  static bool isAdmin(
    Map<String, dynamic>? user,
  ) {
    if (user == null) {
      return false;
    }

    final rawRole =
        user['role'] ??
        user['user_type'] ??
        user['type'];

    final role =
        rawRole
            ?.toString()
            .trim()
            .toLowerCase() ??
            '';

    return role == 'admin';
  }

  static Widget? screenForUser(
    Map<String, dynamic>? user,
  ) {
    if (!isAdmin(user)) {
      return null;
    }

    return const AdminShellScreen();
  }
}
