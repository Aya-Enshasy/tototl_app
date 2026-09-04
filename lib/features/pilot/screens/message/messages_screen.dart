import 'package:flutter/material.dart';

import '../../../chat/screens/chat_inbox_screen.dart';

/// Uses company user ID 3 until the company directory is connected.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) => const ChatInboxScreen(
    defaultRecipientId: '3',
    defaultRecipientName: 'Company #3',
  );
}
