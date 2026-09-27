import 'package:flutter/material.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../../../chat/screens/chat_inbox_screen.dart';

/// Real conversations are listed here. The shortcut is temporary until a
/// selected pilot ID is passed from the pilot search screen.
class CompanyMessagesScreen extends StatelessWidget {
  const CompanyMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) =>  ChatInboxScreen(
    defaultRecipientId: '1',
    defaultRecipientName: 'Pilot #1',
  );
}
