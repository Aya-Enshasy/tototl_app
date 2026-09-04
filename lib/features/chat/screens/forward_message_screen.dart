import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/chat_conversation.dart';
import '../services/firebase_chat_service.dart';

class ForwardMessageScreen extends StatefulWidget {
  const ForwardMessageScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.currentUserPhotoUrl,
    required this.message,
  });

  final String currentUserId;
  final String currentUserName;
  final String currentUserPhotoUrl;

  final ChatMessage message;

  @override
  State<ForwardMessageScreen> createState() =>
      _ForwardMessageScreenState();
}

class _ForwardMessageScreenState
    extends State<ForwardMessageScreen> {
  final TextEditingController
  _searchController =
  TextEditingController();

  final Set<String>
  _sendingTo =
  <String>{};

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _forward(
      ChatConversation conversation,
      ) async {
    if (_sendingTo.contains(
      conversation.id,
    )) {
      return;
    }

    setState(() {
      _sendingTo.add(
        conversation.id,
      );
    });

    try {
      await FirebaseChatService.instance
          .forwardMessage(
        senderId:
        widget.currentUserId,
        senderName:
        widget.currentUserName,
        senderPhotoUrl:
        widget.currentUserPhotoUrl,
        receiverId:
        conversation.partnerId,
        receiverName:
        conversation.partnerName,
        receiverPhotoUrl:
        conversation.partnerPhotoUrl,
        message:
        widget.message,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior:
            SnackBarBehavior.floating,
            content:
            Text(
              'Message forwarded.',
            ),
          ),
        );

      Navigator.pop(
        context,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            behavior:
            SnackBarBehavior.floating,
            backgroundColor:
            AppColors.red,
            content:
            Text(
              'Could not forward the message.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _sendingTo.remove(
            conversation.id,
          );
        });
      }
    }
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,
      body:
      SafeArea(
        child:
        Column(
          children: [
            Container(
              padding:
              const EdgeInsets.fromLTRB(
                8,
                8,
                14,
                10,
              ),
              decoration:
              const BoxDecoration(
                color:
                Colors.white,
                border:
                Border(
                  bottom:
                  BorderSide(
                    color:
                    AppColors.cardBorder,
                  ),
                ),
              ),
              child:
              Row(
                children: [
                  IconButton(
                    onPressed:
                        () => Navigator.pop(
                      context,
                    ),
                    icon:
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color:
                      AppColors.navy,
                      size:
                      18,
                    ),
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Forward message',
                          style:
                          TextStyle(
                            color:
                            AppColors.navy,
                            fontSize:
                            15,
                            fontWeight:
                            FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height:
                          2,
                        ),

                        Text(
                          widget.message.previewText,
                          maxLines:
                          1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            color:
                            AppColors.grey,
                            fontSize:
                            10.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                10,
              ),
              child:
              TextField(
                controller:
                _searchController,
                onChanged:
                    (value) {
                  setState(() {
                    _query =
                        value.trim().toLowerCase();
                  });
                },
                decoration:
                InputDecoration(
                  hintText:
                  'Search conversations',
                  prefixIcon:
                  const Icon(
                    Icons.search_rounded,
                    color:
                    AppColors.grey,
                  ),
                  filled:
                  true,
                  fillColor:
                  Colors.white,
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
                    ),
                  ),
                ),
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
                  widget.currentUserId,
                ),
                builder:
                    (
                    context,
                    snapshot,
                    ) {
                  if (snapshot
                      .hasError) {
                    return const Center(
                      child:
                      Text(
                        'Could not load conversations.',
                        style:
                        TextStyle(
                          color:
                          AppColors.grey,
                        ),
                      ),
                    );
                  }

                  final conversations =
                      snapshot.data ??
                          const <
                              ChatConversation>[];

                  final visible =
                  _query.isEmpty
                      ? conversations
                      : conversations
                      .where(
                        (
                        item,
                        ) =>
                        item.partnerName
                            .toLowerCase()
                            .contains(
                          _query,
                        ),
                  )
                      .toList();

                  if (visible
                      .isEmpty) {
                    return const Center(
                      child:
                      Text(
                        'No conversations found.',
                        style:
                        TextStyle(
                          color:
                          AppColors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      24,
                    ),
                    itemCount:
                    visible.length,
                    separatorBuilder:
                        (_, __) =>
                    const Divider(
                      height:
                      1,
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

                      final sending =
                      _sendingTo.contains(
                        chat.id,
                      );

                      return ListTile(
                        contentPadding:
                        const EdgeInsets.symmetric(
                          horizontal:
                          2,
                          vertical:
                          6,
                        ),
                        leading:
                        _ForwardAvatar(
                          name:
                          chat.partnerName,
                          photoUrl:
                          chat.partnerPhotoUrl,
                        ),
                        title:
                        Text(
                          chat.partnerName,
                          style:
                          const TextStyle(
                            color:
                            AppColors.navy,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        subtitle:
                        Text(
                          chat.lastMessage,
                          maxLines:
                          1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            color:
                            AppColors.grey,
                            fontSize:
                            11,
                          ),
                        ),
                        trailing:
                        sending
                            ? const SizedBox(
                          width:
                          20,
                          height:
                          20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            AppColors.logoTurquoiseDark,
                          ),
                        )
                            : const Icon(
                          Icons.send_rounded,
                          color:
                          AppColors.logoTurquoiseDark,
                          size:
                          19,
                        ),
                        onTap:
                        sending
                            ? null
                            : () => _forward(
                          chat,
                        ),
                      );
                    },
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

class _ForwardAvatar
    extends StatelessWidget {
  const _ForwardAvatar({
    required this.name,
    required this.photoUrl,
  });

  final String name;
  final String photoUrl;

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

    return ClipOval(
      child:
      SizedBox(
        width:
        46,
        height:
        46,
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
              _ForwardAvatarFallback(
                initial:
                initial,
              ),
        )
            : _ForwardAvatarFallback(
          initial:
          initial,
        ),
      ),
    );
  }
}

class _ForwardAvatarFallback
    extends StatelessWidget {
  const _ForwardAvatarFallback({
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
          fontWeight:
          FontWeight.w900,
        ),
      ),
    );
  }
}
