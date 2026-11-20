import 'package:flutter/material.dart';
import '../../../notifications/screens/notifications_screen.dart';

/// Legacy route kept so old callers still open the real API-backed inbox.
@Deprecated('Use NotificationsScreen from features/notifications/screens.')
class PilotNotificationsScreen extends StatelessWidget {
  const PilotNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => const NotificationsScreen();
}
