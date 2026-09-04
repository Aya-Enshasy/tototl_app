import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/chat_conversation.dart';

class FirebaseChatService {
  FirebaseChatService._();

  static final FirebaseChatService instance =
  FirebaseChatService._();

  static const String _databaseUrl =
      'https://tototl-290a9-default-rtdb.firebaseio.com';

  final FirebaseDatabase _database =
  FirebaseDatabase.instanceFor(
    app:
    Firebase.app(),
    databaseURL:
    _databaseUrl,
  );

  String conversationIdFor(
      String firstUserId,
      String secondUserId,
      ) {
    final ids = [
      firstUserId.trim(),
      secondUserId.trim(),
    ]..sort();

    return ids.join('_');
  }

  Stream<List<ChatConversation>> conversationsFor(
      String userId,
      ) {
    return _database
        .ref(
      'userChats/$userId',
    )
        .onValue
        .map(
          (event) {
        final raw =
            event.snapshot.value;

        if (raw is! Map) {
          return const <ChatConversation>[];
        }

        final chats =
        raw.entries
            .where(
              (entry) =>
          entry.value is Map,
        )
            .map(
              (entry) =>
              ChatConversation.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(
                  entry.value as Map,
                ),
              ),
        )
            .toList()
          ..sort(
                (a, b) =>
                b.lastMessageAt.compareTo(
                  a.lastMessageAt,
                ),
          );

        return chats;
      },
    );
  }

  Stream<List<ChatMessage>> messagesFor(
      String conversationId,
      ) {
    return _database
        .ref(
      'chats/$conversationId/messages',
    )
        .orderByChild(
      'sentAt',
    )
        .onValue
        .map(
          (event) {
        final raw =
            event.snapshot.value;

        if (raw is! Map) {
          return const <ChatMessage>[];
        }

        final messages =
        raw.entries
            .where(
              (entry) =>
          entry.value is Map,
        )
            .map(
              (entry) =>
              ChatMessage.fromMap(
                entry.key.toString(),
                Map<dynamic, dynamic>.from(
                  entry.value as Map,
                ),
              ),
        )
            .toList()
          ..sort(
                (a, b) =>
                a.sentAt.compareTo(
                  b.sentAt,
                ),
          );

        return messages;
      },
    );
  }

  Future<void> sendMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String text,
    String senderPhotoUrl = '',
    String receiverPhotoUrl = '',
    ChatMessage? replyTo,
  }) async {
    final cleanText =
    text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    await _sendCore(
      senderId:
      senderId,
      senderName:
      senderName,
      senderPhotoUrl:
      senderPhotoUrl,
      receiverId:
      receiverId,
      receiverName:
      receiverName,
      receiverPhotoUrl:
      receiverPhotoUrl,
      type:
      ChatMessageType.text,
      text:
      cleanText,
      mediaUrl:
      '',
      mediaDurationMs:
      0,
      mimeType:
      '',
      replyTo:
      replyTo,
    );
  }

  Future<void> sendMediaMessage({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required String type,
    required String mediaUrl,
    String senderPhotoUrl = '',
    String receiverPhotoUrl = '',
    String text = '',
    int mediaDurationMs = 0,
    String mimeType = '',
    ChatMessage? replyTo,
  }) async {
    final cleanType =
    type.trim().toLowerCase();

    if (cleanType !=
        ChatMessageType.image &&
        cleanType !=
            ChatMessageType.voice) {
      throw ArgumentError(
        'Unsupported media message type: $type',
      );
    }

    final cleanUrl =
    mediaUrl.trim();

    if (cleanUrl.isEmpty) {
      throw ArgumentError(
        'mediaUrl cannot be empty.',
      );
    }

    await _sendCore(
      senderId:
      senderId,
      senderName:
      senderName,
      senderPhotoUrl:
      senderPhotoUrl,
      receiverId:
      receiverId,
      receiverName:
      receiverName,
      receiverPhotoUrl:
      receiverPhotoUrl,
      type:
      cleanType,
      text:
      text.trim(),
      mediaUrl:
      cleanUrl,
      mediaDurationMs:
      mediaDurationMs,
      mimeType:
      mimeType.trim(),
      replyTo:
      replyTo,
    );
  }

  Future<void> forwardMessage({
    required String senderId,
    required String senderName,
    required String senderPhotoUrl,
    required String receiverId,
    required String receiverName,
    required String receiverPhotoUrl,
    required ChatMessage message,
  }) async {
    if (message.deleted) {
      return;
    }

    if (message.isImage ||
        message.isVoice) {
      await sendMediaMessage(
        senderId:
        senderId,
        senderName:
        senderName,
        senderPhotoUrl:
        senderPhotoUrl,
        receiverId:
        receiverId,
        receiverName:
        receiverName,
        receiverPhotoUrl:
        receiverPhotoUrl,
        type:
        message.type,
        mediaUrl:
        message.mediaUrl,
        mediaDurationMs:
        message.mediaDurationMs,
        mimeType:
        message.mimeType,
        text:
        message.text,
      );

      return;
    }

    await sendMessage(
      senderId:
      senderId,
      senderName:
      senderName,
      senderPhotoUrl:
      senderPhotoUrl,
      receiverId:
      receiverId,
      receiverName:
      receiverName,
      receiverPhotoUrl:
      receiverPhotoUrl,
      text:
      message.text,
    );
  }

  Future<void> _sendCore({
    required String senderId,
    required String senderName,
    required String senderPhotoUrl,
    required String receiverId,
    required String receiverName,
    required String receiverPhotoUrl,
    required String type,
    required String text,
    required String mediaUrl,
    required int mediaDurationMs,
    required String mimeType,
    ChatMessage? replyTo,
  }) async {
    final conversationId =
    conversationIdFor(
      senderId,
      receiverId,
    );

    final messageRef =
    _database
        .ref(
      'chats/$conversationId/messages',
    )
        .push();

    final now =
        DateTime.now()
            .millisecondsSinceEpoch;

    final messageData =
    <String, dynamic>{
      'senderId':
      senderId,
      'receiverId':
      receiverId,
      'type':
      type,
      'text':
      text,
      'mediaUrl':
      mediaUrl,
      'mediaDurationMs':
      mediaDurationMs,
      'mimeType':
      mimeType,
      'sentAt':
      ServerValue.timestamp,
      'deleted':
      false,
    };

    if (replyTo != null &&
        !replyTo.deleted) {
      messageData['replyToId'] =
          replyTo.id;

      messageData['replyToText'] =
          replyTo.previewText;

      messageData['replyToSenderId'] =
          replyTo.senderId;

      messageData['replyToType'] =
          replyTo.type;
    }

    final preview =
    _previewFor(
      type:
      type,
      text:
      text,
    );

    final updates =
    <String, dynamic>{
      'chats/$conversationId/participantIds/$senderId':
      true,
      'chats/$conversationId/participantIds/$receiverId':
      true,

      'chats/$conversationId/lastMessage':
      preview,

      'chats/$conversationId/lastMessageAt':
      ServerValue.timestamp,

      'chats/$conversationId/lastSenderId':
      senderId,

      'chats/$conversationId/messages/${messageRef.key}':
      messageData,

      'userChats/$senderId/$conversationId':
      {
        'partnerId':
        receiverId,
        'partnerName':
        receiverName,
        'partnerPhotoUrl':
        receiverPhotoUrl.trim(),
        'lastMessage':
        preview,
        'lastMessageAt':
        now,
        'lastSenderId':
        senderId,
      },

      'userChats/$receiverId/$conversationId':
      {
        'partnerId':
        senderId,
        'partnerName':
        senderName,
        'partnerPhotoUrl':
        senderPhotoUrl.trim(),
        'lastMessage':
        preview,
        'lastMessageAt':
        now,
        'lastSenderId':
        senderId,
      },
    };

    await _database
        .ref()
        .update(
      updates,
    );
  }

  /// One reaction per user, per message.
  ///
  /// Selecting a different reaction removes the old one first.
  /// Selecting the same reaction again removes it.
  Future<void> setSingleReaction({
    required String conversationId,
    required ChatMessage message,
    required String userId,
    required String reactionCode,
  }) async {
    if (message.deleted) {
      return;
    }

    final currentCode =
    message.reactionByUser(
      userId,
    );

    final knownCodes =
    <String>{
      ...chatReactions.map(
            (reaction) =>
        reaction.code,
      ),
      ...message.reactions.keys,
    };

    final updates =
    <String, dynamic>{};

    for (final code
    in knownCodes) {
      updates[
      'chats/$conversationId/messages/${message.id}/reactions/$code/$userId'] =
      null;
    }

    // Same reaction = toggle it off.
    if (currentCode !=
        reactionCode) {
      updates[
      'chats/$conversationId/messages/${message.id}/reactions/$reactionCode/$userId'] =
      true;
    }

    await _database
        .ref()
        .update(
      updates,
    );
  }

  Future<void> deleteMessage({
    required String conversationId,
    required ChatMessage message,
  }) async {
    if (message.id.trim().isEmpty) {
      return;
    }

    await _database
        .ref()
        .update(
      {
        'chats/$conversationId/messages/${message.id}/deleted':
        true,

        'chats/$conversationId/messages/${message.id}/text':
        '',

        'chats/$conversationId/messages/${message.id}/mediaUrl':
        '',

        'chats/$conversationId/messages/${message.id}/reactions':
        null,
      },
    );

    await _refreshConversationPreview(
      conversationId,
    );
  }

  Future<void> _refreshConversationPreview(
      String conversationId,
      ) async {
    final snapshot =
    await _database
        .ref(
      'chats/$conversationId',
    )
        .get();

    final raw =
        snapshot.value;

    if (raw is! Map) {
      return;
    }

    final map =
    Map<dynamic, dynamic>.from(
      raw,
    );

    final rawMessages =
    map['messages'];

    final participants =
    map['participantIds'];

    if (rawMessages is! Map ||
        participants is! Map) {
      return;
    }

    final messages =
    rawMessages.entries
        .where(
          (entry) =>
      entry.value is Map,
    )
        .map(
          (entry) =>
          ChatMessage.fromMap(
            entry.key.toString(),
            Map<dynamic, dynamic>.from(
              entry.value as Map,
            ),
          ),
    )
        .toList()
      ..sort(
            (a, b) =>
            b.sentAt.compareTo(
              a.sentAt,
            ),
      );

    if (messages.isEmpty) {
      return;
    }

    final latest =
        messages.first;

    final preview =
        latest.previewText;

    final previewTime =
    latest.sentAt > 0
        ? latest.sentAt
        : DateTime.now()
        .millisecondsSinceEpoch;

    final updates =
    <String, dynamic>{
      'chats/$conversationId/lastMessage':
      preview,

      'chats/$conversationId/lastMessageAt':
      previewTime,

      'chats/$conversationId/lastSenderId':
      latest.senderId,
    };

    for (final participant
    in participants.entries) {
      if (participant.value !=
          true) {
        continue;
      }

      final userId =
      participant.key.toString();

      updates[
      'userChats/$userId/$conversationId/lastMessage'] =
          preview;

      updates[
      'userChats/$userId/$conversationId/lastMessageAt'] =
          previewTime;

      updates[
      'userChats/$userId/$conversationId/lastSenderId'] =
          latest.senderId;
    }

    await _database
        .ref()
        .update(
      updates,
    );
  }

  String _previewFor({
    required String type,
    required String text,
  }) {
    if (type ==
        ChatMessageType.image) {
      return '📷 Photo';
    }

    if (type ==
        ChatMessageType.voice) {
      return '🎙 Voice message';
    }

    final clean =
    text.trim();

    return clean.isEmpty
        ? 'Message'
        : clean;
  }
}
