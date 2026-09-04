class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    this.partnerPhotoUrl = '',
  });

  final String id;
  final String partnerId;
  final String partnerName;
  final String lastMessage;
  final int lastMessageAt;
  final String lastSenderId;
  final String partnerPhotoUrl;

  factory ChatConversation.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    int timestamp(dynamic value) {
      if (value is int) return value;

      return int.tryParse(
        value?.toString() ?? '',
      ) ??
          0;
    }

    return ChatConversation(
      id: id,
      partnerId:
      map['partnerId']?.toString() ?? '',
      partnerName:
      map['partnerName']?.toString() ??
          'Conversation',
      lastMessage:
      map['lastMessage']?.toString() ?? '',
      lastMessageAt:
      timestamp(map['lastMessageAt']),
      lastSenderId:
      map['lastSenderId']?.toString() ??
          '',
      partnerPhotoUrl:
      map['partnerPhotoUrl']
          ?.toString()
          .trim() ??
          '',
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.sentAt,
    this.type = ChatMessageType.text,
    this.mediaUrl = '',
    this.mediaDurationMs = 0,
    this.mimeType = '',
    this.replyToId = '',
    this.replyToText = '',
    this.replyToSenderId = '',
    this.replyToType = ChatMessageType.text,
    this.reactions = const {},
    this.deleted = false,
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final int sentAt;

  /// text | image | voice
  final String type;

  final String mediaUrl;

  /// Used for voice messages.
  final int mediaDurationMs;

  final String mimeType;

  final String replyToId;
  final String replyToText;
  final String replyToSenderId;
  final String replyToType;

  /// reactionCode -> user ids.
  ///
  /// The service guarantees that each user can have at most ONE reaction
  /// on a message at a time.
  final Map<String, Set<String>> reactions;

  final bool deleted;

  factory ChatMessage.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    final rawTime = map['sentAt'];

    final reactionMap =
    <String, Set<String>>{};

    final rawReactions =
    map['reactions'];

    if (rawReactions is Map) {
      for (final entry
      in rawReactions.entries) {
        final code =
        entry.key.toString();

        final rawUsers =
            entry.value;

        if (rawUsers is! Map) {
          continue;
        }

        final users =
        <String>{};

        for (final userEntry
        in rawUsers.entries) {
          if (userEntry.value == true) {
            users.add(
              userEntry.key.toString(),
            );
          }
        }

        if (users.isNotEmpty) {
          reactionMap[code] =
              users;
        }
      }
    }

    return ChatMessage(
      id: id,
      senderId:
      map['senderId']?.toString() ?? '',
      receiverId:
      map['receiverId']?.toString() ??
          '',
      text:
      map['text']?.toString() ?? '',
      sentAt:
      rawTime is int
          ? rawTime
          : int.tryParse(
        rawTime?.toString() ??
            '',
      ) ??
          0,
      type:
      _cleanType(
        map['type'],
      ),
      mediaUrl:
      map['mediaUrl']?.toString() ??
          '',
      mediaDurationMs:
      _asInt(
        map['mediaDurationMs'],
      ) ??
          0,
      mimeType:
      map['mimeType']?.toString() ??
          '',
      replyToId:
      map['replyToId']?.toString() ??
          '',
      replyToText:
      map['replyToText']?.toString() ??
          '',
      replyToSenderId:
      map['replyToSenderId']
          ?.toString() ??
          '',
      replyToType:
      _cleanType(
        map['replyToType'],
      ),
      reactions:
      reactionMap,
      deleted:
      map['deleted'] == true,
    );
  }

  bool get isText =>
      type == ChatMessageType.text;

  bool get isImage =>
      type == ChatMessageType.image;

  bool get isVoice =>
      type == ChatMessageType.voice;

  bool get hasReply =>
      replyToId.trim().isNotEmpty &&
          replyToText.trim().isNotEmpty;

  String get previewText {
    if (deleted) {
      return 'Message deleted';
    }

    if (isImage) {
      return '📷 Photo';
    }

    if (isVoice) {
      return '🎙 Voice message';
    }

    return text.trim().isEmpty
        ? 'Message'
        : text.trim();
  }

  String get displayText =>
      deleted
          ? 'Message deleted'
          : text;

  String? reactionByUser(
      String userId,
      ) {
    for (final entry
    in reactions.entries) {
      if (entry.value.contains(userId)) {
        return entry.key;
      }
    }

    return null;
  }

  bool reactedBy(
      String userId,
      String reactionCode,
      ) {
    return reactions[reactionCode]
        ?.contains(userId) ??
        false;
  }
}

class ChatMessageType {
  ChatMessageType._();

  static const String text =
      'text';

  static const String image =
      'image';

  static const String voice =
      'voice';
}

class ChatReaction {
  const ChatReaction({
    required this.code,
    required this.emoji,
  });

  final String code;
  final String emoji;
}

const chatReactions =
<ChatReaction>[
  ChatReaction(
    code: 'fire',
    emoji: '🔥',
  ),
  ChatReaction(
    code: 'heart',
    emoji: '❤️',
  ),
  ChatReaction(
    code: 'laugh',
    emoji: '😂',
  ),
  ChatReaction(
    code: 'wow',
    emoji: '😮',
  ),
  ChatReaction(
    code: 'sad',
    emoji: '😢',
  ),
  ChatReaction(
    code: 'pray',
    emoji: '🙏',
  ),
];

String emojiForReaction(
    String code,
    ) {
  for (final reaction in chatReactions) {
    if (reaction.code == code) {
      return reaction.emoji;
    }
  }

  return '👍';
}

String _cleanType(
    dynamic raw,
    ) {
  final value =
      raw?.toString().trim().toLowerCase() ??
          '';

  if (value == ChatMessageType.image ||
      value == ChatMessageType.voice) {
    return value;
  }

  return ChatMessageType.text;
}

int? _asInt(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(
    value.toString(),
  );
}
