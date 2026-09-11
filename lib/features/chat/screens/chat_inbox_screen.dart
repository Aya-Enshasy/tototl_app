import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/storage/user_session_storage.dart';
import '../models/chat_conversation.dart';
import '../services/firebase_chat_service.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    super.key,
    this.defaultRecipientId,
    this.defaultRecipientName,
  });

  /// Legacy compatibility only. The inbox no longer depends on a hardcoded
  /// recipient. Conversations are loaded from Firebase for the authenticated
  /// user stored in [UserSessionStorage].
  @Deprecated('The inbox now resolves conversations from the signed-in user.')
  final String? defaultRecipientId;

  @Deprecated('The inbox now resolves conversations from the signed-in user.')
  final String? defaultRecipientName;

  @override
  State<ChatInboxScreen> createState() =>
      _ChatInboxScreenState();
}

class _ChatInboxScreenState
    extends State<ChatInboxScreen> {
  final TextEditingController
  _searchController =
  TextEditingController();

  String? _userId;

  String _userName =
      'User';

  String _userPhotoUrl =
      '';

  String _query =
      '';

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
    final id =
    await UserSessionStorage
        .getUserId();

    final name =
    await UserSessionStorage
        .getName();

    final photo =
    await UserSessionStorage
        .getProfilePhotoUrl();

    if (!mounted) {
      return;
    }

    setState(() {
      _userId =
          id?.toString();

      _userName =
      name?.trim().isNotEmpty ==
          true
          ? name!.trim()
          : 'User';

      _userPhotoUrl =
          photo?.trim() ?? '';
    });
  }

  void _open(
      ChatConversation conversation,
      ) {
    final id =
        _userId;

    if (id == null ||
        id == conversation.partnerId) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) =>
            ChatScreen(
              currentUserId:
              id,
              currentUserName:
              _userName,
              currentUserPhotoUrl:
              _userPhotoUrl,
              partnerId:
              conversation.partnerId,
              partnerName:
              conversation.partnerName,
              partnerPhotoUrl:
              conversation.partnerPhotoUrl,
            ),
      ),
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_userId == null) {
      return const ColoredBox(
        color:
        AppColors.bg,
        child:
        Center(
          child:
          CircularProgressIndicator(
            color:
            AppColors.logoTurquoiseDark,
          ),
        ),
      );
    }

    return ColoredBox(
      color:
      AppColors.bg,
      child:
      SafeArea(
        child:
        Column(
          children: [
            _InboxHeader(
              name:
              _userName,
              photoUrl:
              _userPhotoUrl,
            ),

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                12,
              ),
              child:
              _SearchBox(
                controller:
                _searchController,
                onChanged:
                    (value) {
                  setState(() {
                    _query =
                        value
                            .trim()
                            .toLowerCase();
                  });
                },
              ),
            ),

            Expanded(
              child:
              StreamBuilder<
                  List<
                      ChatConversation>>(
                stream:
                FirebaseChatService
                    .instance
                    .conversationsFor(
                  _userId!,
                ),
                builder:
                    (
                    context,
                    snapshot,
                    ) {
                  if (snapshot
                      .hasError) {
                    return RefreshIndicator(
                      color:
                      AppColors.logoTurquoiseDark,
                      onRefresh:
                      _loadUser,
                      child:
                      ListView(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        children:
                        const [
                          SizedBox(
                            height:
                            120,
                          ),
                          _InboxError(),
                        ],
                      ),
                    );
                  }

                  final chats =
                      snapshot.data ??
                          const <
                              ChatConversation>[];

                  final visible =
                  _query.isEmpty
                      ? chats
                      : chats
                      .where(
                        (
                        chat,
                        ) {
                      return chat
                          .partnerName
                          .toLowerCase()
                          .contains(
                        _query,
                      ) ||
                          chat
                              .lastMessage
                              .toLowerCase()
                              .contains(
                            _query,
                          );
                    },
                  )
                      .toList();

                  if (visible
                      .isEmpty) {
                    return RefreshIndicator(
                      color:
                      AppColors.logoTurquoiseDark,
                      onRefresh:
                      _loadUser,
                      child:
                      ListView(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        children: [
                          _InboxEmpty(
                            searching:
                            _query.isNotEmpty,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color:
                    AppColors.logoTurquoiseDark,
                    onRefresh:
                    _loadUser,
                    child:
                    ListView.separated(
                      physics:
                      const AlwaysScrollableScrollPhysics(
                        parent:
                        BouncingScrollPhysics(),
                      ),
                      padding:
                      const EdgeInsets.fromLTRB(
                        18,
                        2,
                        18,
                        100,
                      ),
                      itemCount:
                      visible.length,
                      separatorBuilder:
                          (
                          _,
                          __,
                          ) =>
                      const Divider(
                        height:
                        1,
                        indent:
                        64,
                        color:
                        AppColors.cardBorder,
                      ),
                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final chat =
                        visible[index];

                        final mine =
                            chat.lastSenderId ==
                                _userId;

                        return _ConversationTile(
                          chat:
                          chat,
                          mine:
                          mine,
                          onTap:
                              () => _open(
                            chat,
                          ),
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
    );
  }
}

class _InboxHeader
    extends StatelessWidget {
  const _InboxHeader({
    required this.name,
    required this.photoUrl,
  });

  final String name;
  final String photoUrl;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        10,
      ),
      child:
      Row(
        children: [
          _InboxAvatar(
            name:
            name,
            photoUrl:
            photoUrl,
            size:
            47,
          ),

          const SizedBox(
            width:
            11,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chat',
                  style:
                  TextStyle(
                    color:
                    AppColors.navy,
                    fontSize:
                    22,
                    height:
                    1,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing:
                    -.5,
                  ),
                ),
                const SizedBox(
                  height:
                  5,
                ),
                Text(
                  name,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    AppColors.grey,
                    fontSize:
                    10.5,
                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width:
            40,
            height:
            40,
            decoration:
            const BoxDecoration(
              color:
              Colors.white,
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color:
              AppColors.logoTurquoiseDark,
              size:
              19,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox
    extends StatelessWidget {
  const _SearchBox({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController
  controller;

  final ValueChanged<String>
  onChanged;

  @override
  Widget build(
      BuildContext context,
      ) {
    return TextField(
      controller:
      controller,
      onChanged:
      onChanged,
      textInputAction:
      TextInputAction.search,
      style:
      const TextStyle(
        color:
        AppColors.navy,
        fontSize:
        12,
        fontWeight:
        FontWeight.w600,
      ),
      decoration:
      InputDecoration(
        hintText:
        'Search conversations',
        hintStyle:
        const TextStyle(
          color:
          AppColors.lightGrey,
          fontSize:
          11.5,
        ),
        prefixIcon:
        const Icon(
          Icons.search_rounded,
          color:
          AppColors.grey,
          size:
          20,
        ),
        filled:
        true,
        fillColor:
        Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(
          vertical:
          13,
        ),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          const BorderSide(
            color:
            AppColors.cardBorder,
          ),
        ),
        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          const BorderSide(
            color:
            AppColors.cardBorder,
          ),
        ),
        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          borderSide:
          const BorderSide(
            color:
            AppColors.logoTurquoise,
            width:
            1.2,
          ),
        ),
      ),
    );
  }
}

class _ConversationTile
    extends StatelessWidget {
  const _ConversationTile({
    required this.chat,
    required this.mine,
    required this.onTap,
  });

  final ChatConversation chat;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final time =
    chat.lastMessageAt == 0
        ? ''
        : DateFormat(
      'h:mm a',
    ).format(
      DateTime
          .fromMillisecondsSinceEpoch(
        chat.lastMessageAt,
      ),
    );

    final preview =
    chat.lastMessage
        .trim()
        .isEmpty
        ? 'No messages yet'
        : '${mine ? 'You: ' : ''}${chat.lastMessage}';

    return Material(
      color:
      Colors.transparent,
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          17,
        ),
        child:
        Padding(
          padding:
          const EdgeInsets.symmetric(
            vertical:
            11,
            horizontal:
            2,
          ),
          child:
          Row(
            children: [
              _InboxAvatar(
                name:
                chat.partnerName,
                photoUrl:
                chat.partnerPhotoUrl,
                size:
                50,
                online:
                true,
              ),

              const SizedBox(
                width:
                12,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                          Text(
                            chat.partnerName,
                            maxLines:
                            1,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              color:
                              AppColors.navy,
                              fontSize:
                              13.5,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                        ),

                        if (time
                            .isNotEmpty)
                          Text(
                            time,
                            style:
                            const TextStyle(
                              color:
                              AppColors.lightGrey,
                              fontSize:
                              9.5,
                              fontWeight:
                              FontWeight.w500,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height:
                      5,
                    ),

                    Text(
                      preview,
                      maxLines:
                      1,
                      overflow:
                      TextOverflow.ellipsis,
                      style:
                      TextStyle(
                        color:
                        mine
                            ? AppColors.grey
                            : AppColors.logoTurquoiseDark,
                        fontSize:
                        11.2,
                        fontWeight:
                        mine
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxAvatar
    extends StatelessWidget {
  const _InboxAvatar({
    required this.name,
    required this.photoUrl,
    required this.size,
    this.online = false,
  });

  final String name;
  final String photoUrl;
  final double size;
  final bool online;

  @override
  Widget build(
      BuildContext context,
      ) {
    final clean =
    photoUrl.trim();

    final initial =
    name.trim().isEmpty
        ? '?'
        : name
        .trim()
        .characters
        .first
        .toUpperCase();

    return SizedBox(
      width:
      size,
      height:
      size,
      child:
      Stack(
        clipBehavior:
        Clip.none,
        children: [
          Positioned.fill(
            child:
            ClipOval(
              child:
              clean.isNotEmpty
                  ? Image.network(
                clean,
                fit:
                BoxFit.cover,
                errorBuilder:
                    (
                    context,
                    error,
                    stackTrace,
                    ) =>
                    _InboxAvatarFallback(
                      initial:
                      initial,
                    ),
              )
                  : _InboxAvatarFallback(
                initial:
                initial,
              ),
            ),
          ),

          if (online)
            Positioned(
              right:
              0,
              bottom:
              0,
              child:
              Container(
                width:
                size * .24,
                height:
                size * .24,
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFF25C76F,
                  ),
                  shape:
                  BoxShape.circle,
                  border:
                  Border.all(
                    color:
                    AppColors.bg,
                    width:
                    2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _InboxAvatarFallback
    extends StatelessWidget {
  const _InboxAvatarFallback({
    required this.initial,
  });

  final String initial;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      alignment:
      Alignment.center,
      decoration:
      const BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            AppColors.logoTurquoise,
            AppColors.blue,
          ],
        ),
      ),
      child:
      Text(
        initial,
        style:
        const TextStyle(
          color:
          Colors.white,
          fontSize:
          18,
          fontWeight:
          FontWeight.w900,
        ),
      ),
    );
  }
}

class _InboxEmpty
    extends StatelessWidget {
  const _InboxEmpty({
    required this.searching,
  });

  final bool searching;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        34,
        90,
        34,
        30,
      ),
      child:
      Column(
        children: [
          Container(
            width:
            76,
            height:
            76,
            decoration:
            const BoxDecoration(
              color:
              AppColors.blueBg,
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons.chat_bubble_outline_rounded,
              color:
              AppColors.logoTurquoiseDark,
              size:
              32,
            ),
          ),

          const SizedBox(
            height:
            17,
          ),

          Text(
            searching
                ? 'No conversations found'
                : 'No conversations yet',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              AppColors.navy,
              fontSize:
              16,
              fontWeight:
              FontWeight.w900,
            ),
          ),

          const SizedBox(
            height:
            6,
          ),

          Text(
            searching
                ? 'Try another name or message.'
                : 'Your direct conversations will appear here.',
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              AppColors.grey,
              fontSize:
              11.2,
              height:
              1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxError
    extends StatelessWidget {
  const _InboxError();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const Padding(
      padding:
      EdgeInsets.all(
        24,
      ),
      child:
      Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            color:
            AppColors.red,
            size:
            30,
          ),
          SizedBox(
            height:
            10,
          ),
          Text(
            'Could not load conversations.',
            textAlign:
            TextAlign.center,
            style:
            TextStyle(
              color:
              AppColors.navy,
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
