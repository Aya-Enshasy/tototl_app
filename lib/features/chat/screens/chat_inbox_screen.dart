import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/storage/user_session_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../models/chat_conversation.dart';
import '../services/firebase_chat_service.dart';
import 'chat_screen.dart';
import 'dart:ui' as ui;

String _ui(String source) => AppLanguage.text(source);

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    super.key,
    this.defaultRecipientId,
    this.defaultRecipientName,
  });

  /// Kept only so older callers do not break.
  ///
  /// The inbox resolves the signed-in user and real Firebase conversations;
  /// it no longer opens a hardcoded pilot.
  @Deprecated('The inbox loads real conversations for the signed-in user.')
  final String? defaultRecipientId;

  @Deprecated('The inbox loads real conversations for the signed-in user.')
  final String? defaultRecipientName;

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  final TextEditingController _searchController = TextEditingController();

  String? _userId;
  String _userName = _ui('User');
  String _userPhotoUrl = '';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final id = await UserSessionStorage.getUserId();
    final name = await UserSessionStorage.getName();
    final photo = await UserSessionStorage.getProfilePhotoUrl();

    if (!mounted) return;

    setState(() {
      _userId = id?.toString();
      _userName = name?.trim().isNotEmpty == true
          ? name!.trim()
          : _ui('User');
      _userPhotoUrl = photo?.trim() ?? '';
    });
  }

  void _open(ChatConversation conversation) {
    final id = _userId;

    if (id == null || id == conversation.partnerId) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          currentUserId: id,
          currentUserName: _userName,
          currentUserPhotoUrl: _userPhotoUrl,
          partnerId: conversation.partnerId,
          partnerName: conversation.partnerName,
          partnerPhotoUrl: conversation.partnerPhotoUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const ColoredBox(
        color: AppColors.bg,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.logoTurquoiseDark,
          ),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.bg,
        child: SafeArea(
          child: Column(
            children: [
              const _MessagesHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 9),
                child: _SearchBox(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 2, 18, 9),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _AllPill(),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ChatConversation>>(
                  stream: FirebaseChatService.instance.conversationsFor(
                    _userId!,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return RefreshIndicator(
                        color: AppColors.logoTurquoiseDark,
                        onRefresh: _loadUser,
                        child:   ListView(
                          physics: AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 120),
                            _InboxError(),
                          ],
                        ),
                      );
                    }

                    final chats =
                        snapshot.data ?? const <ChatConversation>[];

                    final visible = _query.isEmpty
                        ? chats
                        : chats.where((chat) {
                      return chat.partnerName
                          .toLowerCase()
                          .contains(_query) ||
                          chat.lastMessage
                              .toLowerCase()
                              .contains(_query);
                    }).toList();

                    if (visible.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.logoTurquoiseDark,
                        onRefresh: _loadUser,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            _InboxEmpty(
                              searching: _query.isNotEmpty,
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.logoTurquoiseDark,
                      onRefresh: _loadUser,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          3,
                          18,
                          100,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 64,
                          color: AppColors.cardBorder,
                        ),
                        itemBuilder: (context, index) {
                          final chat = visible[index];
                          final mine = chat.lastSenderId == _userId;

                          return _ConversationTile(
                            chat: chat,
                            mine: mine,
                            onTap: () => _open(chat),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _ui('Messages'),
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -.25,
              ),
            ),
          ),
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.cardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withOpacity(.025),
                  blurRadius: 9,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.logoTurquoiseDark,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AppColors.navy,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: _ui('Search conversations'),
        hintStyle: const TextStyle(
          color: AppColors.lightGrey,
          fontSize: 11.4,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.grey,
          size: 19,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AppColors.logoTurquoise,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class _AllPill extends StatelessWidget {
  const _AllPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 23),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.logoTurquoise.withOpacity(.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        _ui('All'),
        style: const TextStyle(
          color: AppColors.logoTurquoiseDark,
          fontSize: 10.6,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.chat,
    required this.mine,
    required this.onTap,
  });

  final ChatConversation chat;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = chat.lastMessageAt == 0
        ? ''
        : DateFormat('h:mm a').format(
      DateTime.fromMillisecondsSinceEpoch(chat.lastMessageAt),
    );

    final cleanMessage = chat.lastMessage.trim();

    final preview = cleanMessage.isEmpty
        ? _ui('No messages yet')
        : "${mine ? '${_ui('You')}: ' : ''}$cleanMessage";

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _InboxAvatar(
                name: chat.partnerName,
                photoUrl: chat.partnerPhotoUrl,
                size: 52,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.partnerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty)
                          Text(
                            time,
                            style: const TextStyle(
                              color: AppColors.lightGrey,
                              fontSize: 9.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 11,
                          color: AppColors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _ui('Private conversation'),
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 9.7,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mine
                            ? AppColors.grey
                            : AppColors.logoTurquoiseDark,
                        fontSize: 10.8,
                        fontWeight:
                        mine ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.lightGrey,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({
    required this.name,
    required this.photoUrl,
    required this.size,
  });

  final String name;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final clean = photoUrl.trim();

    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: clean.isNotEmpty
            ? Image.network(
          clean,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _InboxAvatarFallback(initial: initial),
        )
            : _InboxAvatarFallback(initial: initial),
      ),
    );
  }
}

class _InboxAvatarFallback extends StatelessWidget {
  const _InboxAvatarFallback({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.logoTurquoise,
            AppColors.blue,
          ],
        ),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({
    required this.searching,
  });

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 92, 34, 30),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  color: AppColors.blueBg,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const Icon(
                Icons.forum_outlined,
                color: AppColors.logoTurquoiseDark,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            searching
                ? _ui('No conversations found')
                : _ui('Your messages live here'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? _ui('Try another name or message.')
                : _ui(
              'Talk with pilots about your work and keep important updates in one place.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 10.8,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxError extends StatelessWidget {
  const _InboxError();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color: AppColors.red,
            size: 30,
          ),
          SizedBox(height: 10),
          Text(
            'Could not load conversations.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
