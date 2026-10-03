import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/user_session_storage.dart';
import '../models/chat_conversation.dart';
import '../services/cloudinary_chat_media_service.dart';
import '../services/firebase_chat_service.dart';
import 'forward_message_screen.dart';

String _ui(String source) => AppLanguage.text(source);

class ChatScreen extends StatefulWidget {
  ChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.partnerId,
    required this.partnerName,
    this.currentUserPhotoUrl = '',
    this.partnerPhotoUrl = '',
  });

  final String currentUserId;
  final String currentUserName;

  final String partnerId;
  final String partnerName;

  final String currentUserPhotoUrl;
  final String partnerPhotoUrl;

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {
  final TextEditingController
  _controller =
  TextEditingController();

  final FocusNode _focusNode =
  FocusNode();

  final ScrollController
  _scrollController =
  ScrollController();

  final ImagePicker _imagePicker =
  ImagePicker();

  bool _sendingText = false;
  bool _uploadingMedia = false;

  ChatMessage? _replyTo;

  String _currentUserPhotoUrl = '';

  int _lastMessageCount = 0;

  String get _conversationId =>
      FirebaseChatService.instance
          .conversationIdFor(
        widget.currentUserId,
        widget.partnerId,
      );

  @override
  void initState() {
    super.initState();

    _currentUserPhotoUrl =
        widget.currentUserPhotoUrl.trim();

    _loadCurrentUserPhoto();
  }

  Future<void>
  _loadCurrentUserPhoto() async {
    if (_currentUserPhotoUrl.isNotEmpty) {
      return;
    }

    final url =
    await UserSessionStorage
        .getProfilePhotoUrl();

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUserPhotoUrl =
          url?.trim() ?? '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========================================================================
  // TEXT
  // ========================================================================

  Future<void> _sendText() async {
    final text =
    _controller.text.trim();

    if (text.isEmpty ||
        _sendingText ||
        _uploadingMedia) {
      return;
    }

    setState(() {
      _sendingText = true;
    });

    try {
      await FirebaseChatService.instance
          .sendMessage(
        senderId:
        widget.currentUserId,
        senderName:
        widget.currentUserName,
        senderPhotoUrl:
        _currentUserPhotoUrl,
        receiverId:
        widget.partnerId,
        receiverName:
        widget.partnerName,
        receiverPhotoUrl:
        widget.partnerPhotoUrl,
        text:
        text,
        replyTo:
        _replyTo,
      );

      if (!mounted) {
        return;
      }

      _controller.clear();

      setState(() {
        _replyTo = null;
      });

      _focusNode.requestFocus();

      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        _showSnack(
          _ui('Message could not be sent.'),
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sendingText = false;
        });
      }
    }
  }

  // ========================================================================
  // IMAGE
  // ========================================================================

  Future<void>
  _showImageSourceSheet() async {
    if (_uploadingMedia) {
      return;
    }

    FocusScope.of(context).unfocus();

    final source =
    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor:
      Colors.transparent,
      builder:
          (sheetContext) {
        return SafeArea(
          top:
          false,
          child:
          Container(
            margin:
            EdgeInsets.all(
              12,
            ),
            padding:
            EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                28,
              ),
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width:
                  42,
                  height:
                  4,
                  decoration:
                  BoxDecoration(
                    color:
                    AppColors.cardBorder,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                  18,
                ),

                Text(
                  _ui('Send a photo'),
                  style:
                  TextStyle(
                    color:
                    AppColors.navy,
                    fontSize:
                    17,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                SizedBox(
                  height:
                  14,
                ),

                _MediaSourceTile(
                  icon:
                  Icons.photo_library_outlined,
                  title:
                  _ui('Photo library'),
                  subtitle:
                  _ui('Choose an image from your device'),
                  onTap:
                      () => Navigator.pop(
                    sheetContext,
                    ImageSource.gallery,
                  ),
                ),

                SizedBox(
                  height:
                  8,
                ),

                _MediaSourceTile(
                  icon:
                  Icons.photo_camera_outlined,
                  title:
                  _ui('Camera'),
                  subtitle:
                  _ui('Take a new photo'),
                  onTap:
                      () => Navigator.pop(
                    sheetContext,
                    ImageSource.camera,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null ||
        !mounted) {
      return;
    }

    await _pickAndSendImage(
      source,
    );
  }

  Future<void> _pickAndSendImage(
      ImageSource source,
      ) async {
    try {
      final image =
      await _imagePicker.pickImage(
        source:
        source,
        imageQuality:
        84,
        maxWidth:
        1800,
        requestFullMetadata:
        false,
      );

      if (image == null ||
          !mounted) {
        return;
      }

      final approved =
      await _showImagePreview(
        image,
      );

      if (approved != true ||
          !mounted) {
        return;
      }

      setState(() {
        _uploadingMedia = true;
      });

      final uploaded =
      await CloudinaryChatMediaService
          .instance
          .uploadImage(
        image.path,
      );

      await FirebaseChatService.instance
          .sendMediaMessage(
        senderId:
        widget.currentUserId,
        senderName:
        widget.currentUserName,
        senderPhotoUrl:
        _currentUserPhotoUrl,
        receiverId:
        widget.partnerId,
        receiverName:
        widget.partnerName,
        receiverPhotoUrl:
        widget.partnerPhotoUrl,
        type:
        ChatMessageType.image,
        mediaUrl:
        uploaded.secureUrl,
        mimeType:
        uploaded.format.isEmpty
            ? 'image'
            : 'image/${uploaded.format}',
        replyTo:
        _replyTo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _replyTo = null;
      });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showSnack(
          _ui('Photo upload failed.'),
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingMedia = false;
        });
      }
    }
  }

  Future<bool?> _showImagePreview(
      XFile image,
      ) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (sheetContext) {
        final height =
            MediaQuery.of(
              sheetContext,
            ).size.height *
                .68;

        return SafeArea(
          top:
          false,
          child:
          Container(
            margin:
            EdgeInsets.all(
              12,
            ),
            constraints:
            BoxConstraints(
              maxHeight:
              height,
            ),
            padding:
            EdgeInsets.fromLTRB(
              14,
              10,
              14,
              14,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                28,
              ),
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width:
                  42,
                  height:
                  4,
                  decoration:
                  BoxDecoration(
                    color:
                    AppColors.cardBorder,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                  12,
                ),

                Expanded(
                  child:
                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                    child:
                    Image.file(
                      File(
                        image.path,
                      ),
                      width:
                      double.infinity,
                      fit:
                      BoxFit.contain,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                  12,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          false,
                        ),
                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          AppColors.navy,
                          side:
                          BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          EdgeInsets.symmetric(
                            vertical:
                            14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                        Text(
                          _ui('Cancel'),
                        ),
                      ),
                    ),

                    SizedBox(
                      width:
                      10,
                    ),

                    Expanded(
                      child:
                      FilledButton.icon(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          true,
                        ),
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          AppColors.logoTurquoiseDark,
                          foregroundColor:
                          Colors.white,
                          padding:
                          EdgeInsets.symmetric(
                            vertical:
                            14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        icon:
                        Icon(
                          Icons.send_rounded,
                          size:
                          17,
                        ),
                        label:
                        Text(
                          _ui('Send photo'),
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========================================================================
  // REACTIONS / ACTIONS
  // ========================================================================

  Future<void> _setReaction(
      ChatMessage message,
      String reactionCode,
      ) async {
    if (message.deleted) {
      return;
    }

    try {
      await FirebaseChatService.instance
          .setSingleReaction(
        conversationId:
        _conversationId,
        message:
        message,
        userId:
        widget.currentUserId,
        reactionCode:
        reactionCode,
      );
    } catch (_) {
      if (mounted) {
        _showSnack(
          _ui('Reaction could not be updated.'),
          error: true,
        );
      }
    }
  }

  Future<void> _showMessageActions(
      ChatMessage message,
      ) async {
    if (message.deleted) {
      return;
    }

    HapticFeedback.selectionClick();

    final action =
    await showModalBottomSheet<String>(
      context:
      context,
      isScrollControlled:
      true,
      backgroundColor:
      Colors.transparent,
      builder:
          (sheetContext) {
        return _MessageActionsSheet(
          message:
          message,
          currentUserId:
          widget.currentUserId,
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    if (action.startsWith(
      'reaction:',
    )) {
      final code =
      action.substring(
        'reaction:'.length,
      );

      await _setReaction(
        message,
        code,
      );

      return;
    }

    switch (action) {
      case 'copy':
        if (message.isText &&
            message.text.trim().isNotEmpty) {
          await Clipboard.setData(
            ClipboardData(
              text:
              message.text,
            ),
          );

          if (mounted) {
            _showSnack(
              _ui('Message copied.'),
            );
          }
        }

        break;

      case 'reply':
        setState(() {
          _replyTo =
              message;
        });

        _focusNode.requestFocus();

        break;

      case 'forward':
        await Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder:
                (_) =>
                ForwardMessageScreen(
                  currentUserId:
                  widget.currentUserId,
                  currentUserName:
                  widget.currentUserName,
                  currentUserPhotoUrl:
                  _currentUserPhotoUrl,
                  message:
                  message,
                ),
          ),
        );

        break;

      case 'delete':
        if (message.senderId ==
            widget.currentUserId) {
          await _confirmDelete(
            message,
          );
        }

        break;
    }
  }

  Future<void> _confirmDelete(
      ChatMessage message,
      ) async {
    final confirmed =
    await showModalBottomSheet<bool>(
      context:
      context,
      backgroundColor:
      Colors.transparent,
      builder:
          (sheetContext) {
        return SafeArea(
          top:
          false,
          child:
          Container(
            margin:
            EdgeInsets.all(
              12,
            ),
            padding:
            EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            decoration:
            BoxDecoration(
              color:
              Colors.white,
              borderRadius:
              BorderRadius.circular(
                28,
              ),
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width:
                  42,
                  height:
                  4,
                  decoration:
                  BoxDecoration(
                    color:
                    AppColors.cardBorder,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                ),

                SizedBox(
                  height:
                  20,
                ),

                Container(
                  width:
                  58,
                  height:
                  58,
                  decoration:
                  BoxDecoration(
                    color:
                    AppColors.red.withValues(
                      alpha:
                      .09,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child:
                  Icon(
                    Icons.delete_outline_rounded,
                    color:
                    AppColors.red,
                    size:
                    26,
                  ),
                ),

                SizedBox(
                  height:
                  14,
                ),

                Text(
                  _ui('Delete message?'),
                  style:
                  TextStyle(
                    color:
                    AppColors.navy,
                    fontSize:
                    18,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                SizedBox(
                  height:
                  6,
                ),

                Text(
                  _ui('It will be replaced with “Message deleted” for both users.'),
                  textAlign:
                  TextAlign.center,
                  style:
                  TextStyle(
                    color:
                    AppColors.grey,
                    fontSize:
                    11.5,
                    height:
                    1.45,
                  ),
                ),

                SizedBox(
                  height:
                  18,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          false,
                        ),
                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          AppColors.navy,
                          side:
                          BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          EdgeInsets.symmetric(
                            vertical:
                            14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                        Text(
                          _ui('Cancel'),
                        ),
                      ),
                    ),

                    SizedBox(
                      width:
                      10,
                    ),

                    Expanded(
                      child:
                      FilledButton(
                        onPressed:
                            () => Navigator.pop(
                          sheetContext,
                          true,
                        ),
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          AppColors.red,
                          foregroundColor:
                          Colors.white,
                          padding:
                          EdgeInsets.symmetric(
                            vertical:
                            14,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child:
                        Text(
                          _ui('Delete'),
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseChatService.instance
          .deleteMessage(
        conversationId:
        _conversationId,
        message:
        message,
      );
    } catch (_) {
      if (mounted) {
        _showSnack(
          _ui('Message could not be deleted.'),
          error: true,
        );
      }
    }
  }

  // ========================================================================
  // UI HELPERS
  // ========================================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
              .position
              .maxScrollExtent,
          duration:
          Duration(
            milliseconds:
            240,
          ),
          curve:
          Curves.easeOut,
        );
      },
    );
  }

  void _handleNewMessageCount(
      int count,
      ) {
    if (count ==
        _lastMessageCount) {
      return;
    }

    final wasEmpty =
        _lastMessageCount == 0;

    _lastMessageCount =
        count;

    if (wasEmpty ||
        _isNearBottom()) {
      _scrollToBottom();
    }
  }

  bool _isNearBottom() {
    if (!_scrollController
        .hasClients) {
      return true;
    }

    final position =
        _scrollController.position;

    return position.maxScrollExtent -
        position.pixels <
        180;
  }

  void _showSnack(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          error
              ? AppColors.red
              : AppColors.navy,
          margin:
          EdgeInsets.all(
            16,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),
          content:
          Text(
            message,
          ),
        ),
      );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body:
      SafeArea(
        child:
        Stack(
          children: [
            Column(
              children: [
                _ChatHeader(
                  name:
                  widget.partnerName,
                  photoUrl:
                  widget.partnerPhotoUrl,
                ),

                Expanded(
                  child:
                  StreamBuilder<
                      List<
                          ChatMessage>>(
                    stream:
                    FirebaseChatService
                        .instance
                        .messagesFor(
                      _conversationId,
                    ),
                    builder:
                        (
                        context,
                        snapshot,
                        ) {
                      if (snapshot
                          .hasError) {
                        return const _MessagesError();
                      }

                      final messages =
                          snapshot.data ??
                              <
                                  ChatMessage>[];

                      WidgetsBinding
                          .instance
                          .addPostFrameCallback(
                            (_) =>
                            _handleNewMessageCount(
                              messages.length,
                            ),
                      );

                      if (messages
                          .isEmpty) {
                        return _EmptyConversation(
                          partnerName:
                          widget.partnerName,
                        );
                      }

                      return ListView.builder(
                        controller:
                        _scrollController,
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,
                        physics:
                        BouncingScrollPhysics(),
                        padding:
                        EdgeInsets.fromLTRB(
                          16,
                          18,
                          16,
                          12,
                        ),
                        itemCount:
                        messages.length,
                        itemBuilder:
                            (
                            context,
                            index,
                            ) {
                          final message =
                          messages[
                          index];

                          final mine =
                              message.senderId ==
                                  widget.currentUserId;

                          final showAvatar =
                              !mine &&
                                  _shouldShowAvatar(
                                    messages,
                                    index,
                                  );

                          final showDate =
                              index == 0 ||
                                  !_sameDay(
                                    messages[index - 1].sentAt,
                                    message.sentAt,
                                  );

                          return Column(
                            children: [
                              if (showDate)
                                _ConversationDateDivider(
                                  sentAt: message.sentAt,
                                ),
                              _MessageBubble(
                                message: message,
                                mine: mine,
                                currentUserId: widget.currentUserId,
                                partnerName: widget.partnerName,
                                partnerPhotoUrl: widget.partnerPhotoUrl,
                                showAvatar: showAvatar,
                                onLongPress: () =>
                                    _showMessageActions(message),
                                onDoubleTap: () =>
                                    _setReaction(message, 'heart'),
                                onReactionTap: (reactionCode) =>
                                    _setReaction(
                                      message,
                                      reactionCode,
                                    ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),

                _Composer(
                  controller: _controller,
                  focusNode: _focusNode,
                  sending: _sendingText,
                  uploadingMedia: _uploadingMedia,
                  replyTo: _replyTo,
                  currentUserId: widget.currentUserId,
                  partnerName: widget.partnerName,
                  onCancelReply: () {
                    setState(() {
                      _replyTo = null;
                    });
                  },
                  onSend: _sendText,
                  onAttachment: _showImageSourceSheet,
                ),
              ],
            ),

            if (_uploadingMedia)
              Positioned.fill(
                child:
                _MediaUploadingOverlay(),
              ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(int first, int second) {
    if (first == 0 || second == 0) return false;

    final a = DateTime.fromMillisecondsSinceEpoch(first);
    final b = DateTime.fromMillisecondsSinceEpoch(second);

    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  bool _shouldShowAvatar(
      List<ChatMessage> messages,
      int index,
      ) {
    if (index ==
        messages.length - 1) {
      return true;
    }

    return messages[index + 1]
        .senderId !=
        messages[index]
            .senderId;
  }
}

class _ConversationDateDivider extends StatelessWidget {
  const _ConversationDateDivider({
    required this.sentAt,
  });

  final int sentAt;

  @override
  Widget build(BuildContext context) {
    if (sentAt == 0) return const SizedBox.shrink();

    final date = DateTime.fromMillisecondsSinceEpoch(sentAt);
    final now = DateTime.now();

    final today = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    final label = today
        ? '${_ui('Today')}, ${DateFormat('MMM d').format(date)}'
        : DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 13),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.lightGrey,
          fontSize: 9.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ==========================================================================
// HEADER
// ==========================================================================

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.name,
    required this.photoUrl,
  });

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 6, 10, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 17,
            ),
          ),
          _ChatAvatar(
            name: name,
            photoUrl: photoUrl,
            size: 43,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty
                      ? _ui('Conversation')
                      : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
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
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.navy,
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================================================
// BUBBLE
// ==========================================================================

class _MessageBubble
    extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.mine,
    required this.currentUserId,
    required this.partnerName,
    required this.partnerPhotoUrl,
    required this.showAvatar,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onReactionTap,
  });

  final ChatMessage message;
  final bool mine;

  final String currentUserId;
  final String partnerName;
  final String partnerPhotoUrl;

  final bool showAvatar;

  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  final ValueChanged<String>
  onReactionTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final time =
    message.sentAt == 0
        ? ''
        : DateFormat(
      'h:mm a',
    ).format(
      DateTime
          .fromMillisecondsSinceEpoch(
        message.sentAt,
      ),
    );

    return Padding(
      padding:
      EdgeInsets.only(
        bottom:
        9,
      ),
      child:
      Row(
        mainAxisAlignment:
        mine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment:
        CrossAxisAlignment.end,
        children: [
          if (!mine) ...[
            SizedBox(
              width:
              30,
              child:
              showAvatar
                  ? _ChatAvatar(
                name:
                partnerName,
                photoUrl:
                partnerPhotoUrl,
                size:
                27,
              )
                  : null,
            ),
            SizedBox(
              width:
              6,
            ),
          ],

          Flexible(
            child:
            Column(
              crossAxisAlignment:
              mine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior:
                  HitTestBehavior.opaque,
                  onLongPress:
                  message.deleted
                      ? null
                      : onLongPress,
                  onDoubleTap:
                  message.deleted
                      ? null
                      : onDoubleTap,
                  child:
                  Container(
                    constraints:
                    BoxConstraints(
                      maxWidth:
                      MediaQuery.of(
                        context,
                      ).size.width *
                          .74,
                    ),
                    padding:
                    EdgeInsets.fromLTRB(
                      message.isImage &&
                          !message.deleted
                          ? 5
                          : 13,
                      message.isImage &&
                          !message.deleted
                          ? 5
                          : 10,
                      message.isImage &&
                          !message.deleted
                          ? 5
                          : 13,
                      8,
                    ),
                    decoration:
                    BoxDecoration(
                      gradient:
                      mine &&
                          !message.deleted
                          ? LinearGradient(
                        begin:
                        Alignment.topLeft,
                        end:
                        Alignment.bottomRight,
                        colors: [
                          AppColors.logoTurquoiseDark,
                          AppColors.logoTurquoise,
                        ],
                      )
                          : null,
                      color:
                      mine &&
                          !message.deleted
                          ? null
                          : message.deleted
                          ? Color(
                        0xFFF1F3F5,
                      )
                          : Colors.white,
                      borderRadius:
                      BorderRadius.only(
                        topLeft:
                        Radius.circular(
                          19,
                        ),
                        topRight:
                        Radius.circular(
                          19,
                        ),
                        bottomLeft:
                        Radius.circular(
                          mine
                              ? 19
                              : 5,
                        ),
                        bottomRight:
                        Radius.circular(
                          mine
                              ? 5
                              : 19,
                        ),
                      ),
                      border:
                      mine
                          ? null
                          : Border.all(
                        color:
                        AppColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                          AppColors.navy.withValues(
                            alpha:
                            .045,
                          ),
                          blurRadius:
                          12,
                          offset:
                          Offset(
                            0,
                            4,
                          ),
                        ),
                      ],
                    ),
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        if (message
                            .hasReply)
                          _ReplyPreview(
                            message:
                            message,
                            mine:
                            mine,
                            currentUserId:
                            currentUserId,
                            partnerName:
                            partnerName,
                          ),

                        if (message
                            .hasReply)
                          SizedBox(
                            height:
                            7,
                          ),

                        if (message.deleted)
                          Text(
                            _ui('Message deleted'),
                            style:
                            TextStyle(
                              color:
                              AppColors.grey,
                              fontSize:
                              12.8,
                              fontStyle:
                              FontStyle.italic,
                            ),
                          )
                        else if (message
                            .isImage)
                          _ImageMessageContent(
                            message:
                            message,
                          )
                        else if (message.isVoice)
                            _LegacyAudioMessage(mine: mine)
                          else
                            Text(
                              message.text,
                              style:
                              TextStyle(
                                color:
                                mine
                                    ? Colors.white
                                    : AppColors.navy,
                                fontSize:
                                13.2,
                                height:
                                1.35,
                              ),
                            ),

                        if (time
                            .isNotEmpty) ...[
                          SizedBox(
                            height:
                            5,
                          ),
                          Row(
                            mainAxisSize:
                            MainAxisSize.min,
                            mainAxisAlignment:
                            MainAxisAlignment.end,
                            children: [
                              Text(
                                time,
                                style:
                                TextStyle(
                                  color:
                                  mine &&
                                      !message.deleted
                                      ? Colors.white.withValues(
                                    alpha:
                                    .70,
                                  )
                                      : AppColors.lightGrey,
                                  fontSize:
                                  8.4,
                                ),
                              ),

                              if (mine &&
                                  !message.deleted) ...[
                                SizedBox(
                                  width:
                                  3,
                                ),
                                Icon(
                                  Icons.done_rounded,
                                  color:
                                  Colors.white.withValues(
                                    alpha:
                                    .72,
                                  ),
                                  size:
                                  12,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                if (message.reactions
                    .isNotEmpty)
                  Padding(
                    padding:
                    EdgeInsets.only(
                      top:
                      4,
                    ),
                    child:
                    Wrap(
                      spacing:
                      4,
                      runSpacing:
                      4,
                      children:
                      message.reactions.entries
                          .map(
                            (
                            entry,
                            ) {
                          final selected =
                          entry.value.contains(
                            currentUserId,
                          );

                          return _ReactionChip(
                            code:
                            entry.key,
                            count:
                            entry.value.length,
                            selected:
                            selected,
                            onTap:
                                () => onReactionTap(
                              entry.key,
                            ),
                          );
                        },
                      ).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageMessageContent
    extends StatelessWidget {
  const _ImageMessageContent({
    required this.message,
  });

  final ChatMessage message;

  @override
  Widget build(
      BuildContext context,
      ) {
    return GestureDetector(
      onTap:
          () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (_) =>
                _FullImageScreen(
                  imageUrl:
                  message.mediaUrl,
                ),
          ),
        );
      },
      child:
      ClipRRect(
        borderRadius:
        BorderRadius.circular(
          15,
        ),
        child:
        Container(
          constraints:
          BoxConstraints(
            minWidth:
            180,
            maxWidth:
            250,
            minHeight:
            150,
            maxHeight:
            300,
          ),
          color:
          Color(
            0xFFF0F3F5,
          ),
          child:
          Image.network(
            message.mediaUrl,
            fit:
            BoxFit.cover,
            loadingBuilder:
                (
                context,
                child,
                progress,
                ) {
              if (progress ==
                  null) {
                return child;
              }

              return SizedBox(
                width:
                220,
                height:
                180,
                child:
                Center(
                  child:
                  CircularProgressIndicator(
                    strokeWidth:
                    2,
                    color:
                    AppColors.logoTurquoiseDark,
                  ),
                ),
              );
            },
            errorBuilder:
                (
                context,
                error,
                stackTrace,
                ) {
              return SizedBox(
                width:
                220,
                height:
                170,
                child:
                Center(
                  child:
                  Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color:
                        AppColors.grey,
                      ),
                      SizedBox(
                        height:
                        6,
                      ),
                      Text(
                        _ui('Photo unavailable'),
                        style:
                        TextStyle(
                          color:
                          AppColors.grey,
                          fontSize:
                          10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FullImageScreen
    extends StatelessWidget {
  const _FullImageScreen({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      Colors.black,
      appBar:
      AppBar(
        backgroundColor:
        Colors.black,
        foregroundColor:
        Colors.white,
      ),
      body:
      Center(
        child:
        InteractiveViewer(
          minScale:
          .8,
          maxScale:
          4,
          child:
          Image.network(
            imageUrl,
            fit:
            BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _LegacyAudioMessage extends StatelessWidget {
  const _LegacyAudioMessage({
    required this.mine,
  });

  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.audio_file_outlined,
          size: 17,
          color: mine
              ? Colors.white.withOpacity(.88)
              : AppColors.logoTurquoiseDark,
        ),
        const SizedBox(width: 7),
        Text(
          _ui('Audio message'),
          style: TextStyle(
            color: mine ? Colors.white : AppColors.navy,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReplyPreview
    extends StatelessWidget {
  const _ReplyPreview({
    required this.message,
    required this.mine,
    required this.currentUserId,
    required this.partnerName,
  });

  final ChatMessage message;
  final bool mine;
  final String currentUserId;
  final String partnerName;

  @override
  Widget build(
      BuildContext context,
      ) {
    final replyMine =
        message.replyToSenderId ==
            currentUserId;

    return Container(
      width:
      double.infinity,
      padding:
      EdgeInsets.fromLTRB(
        9,
        7,
        9,
        7,
      ),
      decoration:
      BoxDecoration(
        color:
        mine
            ? Colors.white.withValues(
          alpha:
          .14,
        )
            : Color(
          0xFFF4F7F8,
        ),
        borderRadius:
        BorderRadius.circular(
          11,
        ),
        border:
        Border(
          left:
          BorderSide(
            color:
            mine
                ? Colors.white.withValues(
              alpha:
              .75,
            )
                : AppColors.logoTurquoiseDark,
            width:
            2.5,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            replyMine
                ? _ui('You')
                : partnerName,
            style:
            TextStyle(
              color:
              mine
                  ? Colors.white
                  : AppColors.logoTurquoiseDark,
              fontSize:
              9.2,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          SizedBox(
            height:
            2,
          ),

          Text(
            message.replyToText,
            maxLines:
            1,
            overflow:
            TextOverflow.ellipsis,
            style:
            TextStyle(
              color:
              mine
                  ? Colors.white.withValues(
                alpha:
                .78,
              )
                  : AppColors.grey,
              fontSize:
              9.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip
    extends StatelessWidget {
  const _ReactionChip({
    required this.code,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      selected
          ? AppColors.blueBg
          : Colors.white,
      borderRadius:
      BorderRadius.circular(
        30,
      ),
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          30,
        ),
        child:
        Container(
          padding:
          EdgeInsets.symmetric(
            horizontal:
            7,
            vertical:
            4,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              30,
            ),
            border:
            Border.all(
              color:
              selected
                  ? AppColors.logoTurquoise
                  : AppColors.cardBorder,
            ),
          ),
          child:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Text(
                emojiForReaction(
                  code,
                ),
                style:
                TextStyle(
                  fontSize:
                  13,
                ),
              ),

              if (count >
                  1) ...[
                SizedBox(
                  width:
                  3,
                ),
                Text(
                  '$count',
                  style:
                  TextStyle(
                    color:
                    AppColors.grey,
                    fontSize:
                    8.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageActionsSheet
    extends StatelessWidget {
  const _MessageActionsSheet({
    required this.message,
    required this.currentUserId,
  });

  final ChatMessage message;
  final String currentUserId;

  @override
  Widget build(
      BuildContext context,
      ) {
    final mine =
        message.senderId ==
            currentUserId;

    final currentReaction =
    message.reactionByUser(
      currentUserId,
    );

    return SafeArea(
      top:
      false,
      child:
      Container(
        margin:
        EdgeInsets.all(
          12,
        ),
        padding:
        EdgeInsets.fromLTRB(
          16,
          9,
          16,
          14,
        ),
        decoration:
        BoxDecoration(
          color:
          Colors.white,
          borderRadius:
          BorderRadius.circular(
            28,
          ),
          boxShadow: [
            BoxShadow(
              color:
              AppColors.navy.withValues(
                alpha:
                .12,
              ),
              blurRadius:
              30,
              offset:
              Offset(
                0,
                12,
              ),
            ),
          ],
        ),
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Center(
              child:
              Container(
                width:
                40,
                height:
                4,
                decoration:
                BoxDecoration(
                  color:
                  AppColors.cardBorder,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                ),
              ),
            ),

            SizedBox(
              height:
              14,
            ),

            Container(
              width:
              double.infinity,
              padding:
              EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color:
                Color(
                  0xFFF6F8FA,
                ),
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
              child:
              Text(
                message.previewText,
                maxLines:
                3,
                overflow:
                TextOverflow.ellipsis,
                style:
                TextStyle(
                  color:
                  AppColors.navy,
                  fontSize:
                  11.5,
                  height:
                  1.4,
                ),
              ),
            ),

            SizedBox(
              height:
              14,
            ),

            Text(
              _ui('React'),
              style:
              TextStyle(
                color:
                AppColors.navy,
                fontSize:
                12.5,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            SizedBox(
              height:
              10,
            ),

            SingleChildScrollView(
              scrollDirection:
              Axis.horizontal,
              child:
              Row(
                children:
                chatReactions.map(
                      (
                      reaction,
                      ) {
                    final selected =
                        currentReaction ==
                            reaction.code;

                    return Padding(
                      padding:
                      EdgeInsets.only(
                        right:
                        8,
                      ),
                      child:
                      Material(
                        color:
                        selected
                            ? AppColors.blueBg
                            : Color(
                          0xFFF7F8FA,
                        ),
                        shape:
                        CircleBorder(),
                        child:
                        InkWell(
                          onTap:
                              () => Navigator.pop(
                            context,
                            'reaction:${reaction.code}',
                          ),
                          customBorder:
                          CircleBorder(),
                          child:
                          Container(
                            width:
                            46,
                            height:
                            46,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              border:
                              selected
                                  ? Border.all(
                                color:
                                AppColors.logoTurquoise,
                                width:
                                1.4,
                              )
                                  : null,
                            ),
                            child:
                            Center(
                              child:
                              Text(
                                reaction.emoji,
                                style:
                                TextStyle(
                                  fontSize:
                                  23,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),

            if (currentReaction !=
                null) ...[
              SizedBox(
                height:
                7,
              ),
              Text(
                _ui('Choose another reaction to replace the current one, or tap the same reaction to remove it.'),
                style:
                TextStyle(
                  color:
                  AppColors.lightGrey,
                  fontSize:
                  8.8,
                  height:
                  1.35,
                ),
              ),
            ],

            SizedBox(
              height:
              10,
            ),

            Divider(
              color:
              AppColors.cardBorder,
              height:
              1,
            ),

            if (message.isText)
              _ActionRow(
                icon:
                Icons.copy_rounded,
                label:
                _ui('Copy'),
                onTap:
                    () => Navigator.pop(
                  context,
                  'copy',
                ),
              ),

            _ActionRow(
              icon:
              Icons.reply_rounded,
              label:
              _ui('Reply'),
              onTap:
                  () => Navigator.pop(
                context,
                'reply',
              ),
            ),

            _ActionRow(
              icon:
              Icons.forward_rounded,
              label:
              _ui('Forward'),
              onTap:
                  () => Navigator.pop(
                context,
                'forward',
              ),
            ),

            if (mine)
              _ActionRow(
                icon:
                Icons.delete_outline_rounded,
                label:
                _ui('Delete'),
                danger:
                true,
                onTap:
                    () => Navigator.pop(
                  context,
                  'delete',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionRow
    extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.transparent,
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        child:
        Padding(
          padding:
          EdgeInsets.symmetric(
            horizontal:
            3,
            vertical:
            13,
          ),
          child:
          Row(
            children: [
              Expanded(
                child:
                Text(
                  label,
                  style:
                  TextStyle(
                    color:
                    danger
                        ? AppColors.red
                        : AppColors.navy,
                    fontSize:
                    12.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),

              Icon(
                icon,
                color:
                danger
                    ? AppColors.red
                    : AppColors.grey,
                size:
                19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// COMPOSER
// ==========================================================================

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.uploadingMedia,
    required this.replyTo,
    required this.currentUserId,
    required this.partnerName,
    required this.onCancelReply,
    required this.onSend,
    required this.onAttachment,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool uploadingMedia;
  final ChatMessage? replyTo;
  final String currentUserId;
  final String partnerName;
  final VoidCallback onCancelReply;
  final Future<void> Function() onSend;
  final Future<void> Function() onAttachment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyTo != null)
                _ComposerReplyBar(
                  message: replyTo!,
                  currentUserId: currentUserId,
                  partnerName: partnerName,
                  onClose: onCancelReply,
                ),
              if (replyTo != null)
                const SizedBox(height: 7),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ComposerCircleButton(
                    icon: Icons.attach_file_rounded,
                    onTap: uploadingMedia ? null : onAttachment,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !uploadingMedia,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization:
                      TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 12.2,
                      ),
                      decoration: InputDecoration(
                        hintText: _ui('Type a message...'),
                        hintStyle: const TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 11.8,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFB),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: AppColors.cardBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: AppColors.logoTurquoise,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  SizedBox(
                    width: 43,
                    height: 43,
                    child: FilledButton(
                      onPressed:
                      sending || uploadingMedia ? null : onSend,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor:
                        AppColors.logoTurquoiseDark,
                        disabledBackgroundColor:
                        AppColors.logoTurquoiseDark
                            .withOpacity(.52),
                        shape: const CircleBorder(),
                      ),
                      child: sending
                          ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerReplyBar
    extends StatelessWidget {
  const _ComposerReplyBar({
    required this.message,
    required this.currentUserId,
    required this.partnerName,
    required this.onClose,
  });

  final ChatMessage message;
  final String currentUserId;
  final String partnerName;
  final VoidCallback onClose;

  @override
  Widget build(
      BuildContext context,
      ) {
    final mine =
        message.senderId ==
            currentUserId;

    return Container(
      padding:
      EdgeInsets.fromLTRB(
        11,
        8,
        7,
        8,
      ),
      decoration:
      BoxDecoration(
        color:
        AppColors.blueBg,
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border:
        Border(
          left:
          BorderSide(
            color:
            AppColors.logoTurquoiseDark,
            width:
            3,
          ),
        ),
      ),
      child:
      Row(
        children: [
          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  mine
                      ? _ui('Replying to yourself')
                      : _ui('Replying to {name}').replaceFirst('{name}', partnerName),
                  style:
                  TextStyle(
                    color:
                    AppColors.logoTurquoiseDark,
                    fontSize:
                    9.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height:
                  2,
                ),

                Text(
                  message.previewText,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  TextStyle(
                    color:
                    AppColors.grey,
                    fontSize:
                    9.8,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed:
            onClose,
            visualDensity:
            VisualDensity.compact,
            icon:
            Icon(
              Icons.close_rounded,
              color:
              AppColors.grey,
              size:
              17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerCircleButton
    extends StatelessWidget {
  const _ComposerCircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;

  final Future<void> Function()?
  onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Color(
        0xFFF4F6F8,
      ),
      shape:
      CircleBorder(),
      child:
      InkWell(
        onTap:
        onTap == null
            ? null
            : () {
          onTap!();
        },
        customBorder:
        CircleBorder(),
        child:
        SizedBox(
          width:
          42,
          height:
          42,
          child:
          Icon(
            icon,
            color:
            onTap == null
                ? AppColors.lightGrey
                : AppColors.grey,
            size:
            20,
          ),
        ),
      ),
    );
  }
}

// ==========================================================================
// SMALL HELPERS
// ==========================================================================

class _MediaSourceTile
    extends StatelessWidget {
  const _MediaSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Color(
        0xFFF7F9FA,
      ),
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child:
      InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child:
        Padding(
          padding:
          EdgeInsets.all(
            14,
          ),
          child:
          Row(
            children: [
              Container(
                width:
                43,
                height:
                43,
                decoration:
                BoxDecoration(
                  color:
                  AppColors.blueBg,
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                Icon(
                  icon,
                  color:
                  AppColors.logoTurquoiseDark,
                  size:
                  20,
                ),
              ),

              SizedBox(
                width:
                11,
              ),

              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      TextStyle(
                        color:
                        AppColors.navy,
                        fontSize:
                        12.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height:
                      3,
                    ),
                    Text(
                      subtitle,
                      style:
                      TextStyle(
                        color:
                        AppColors.grey,
                        fontSize:
                        9.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                color:
                AppColors.lightGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaUploadingOverlay
    extends StatelessWidget {
  const _MediaUploadingOverlay();

  @override
  Widget build(
      BuildContext context,
      ) {
    return IgnorePointer(
      child:
      Container(
        color:
        Colors.black.withValues(
          alpha:
          .10,
        ),
        alignment:
        Alignment.center,
        child:
        Container(
          constraints:
          BoxConstraints(
            maxWidth:
            230,
          ),
          padding:
          EdgeInsets.symmetric(
            horizontal:
            18,
            vertical:
            15,
          ),
          decoration:
          BoxDecoration(
            color:
            Colors.white,
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            boxShadow: [
              BoxShadow(
                color:
                AppColors.navy.withValues(
                  alpha:
                  .10,
                ),
                blurRadius:
                24,
                offset:
                Offset(
                  0,
                  9,
                ),
              ),
            ],
          ),
          child:
          Row(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              SizedBox(
                width:
                20,
                height:
                20,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.2,
                  color:
                  AppColors.logoTurquoiseDark,
                ),
              ),
              SizedBox(
                width:
                11,
              ),
              Flexible(
                child:
                Text(
                  _ui('Uploading media...'),
                  style:
                  TextStyle(
                    color:
                    AppColors.navy,
                    fontSize:
                    11.5,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatAvatar
    extends StatelessWidget {
  const _ChatAvatar({
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
    final cleanUrl =
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
              cleanUrl.isNotEmpty
                  ? Image.network(
                cleanUrl,
                fit:
                BoxFit.cover,
                errorBuilder:
                    (
                    context,
                    error,
                    stackTrace,
                    ) =>
                    _AvatarFallback(
                      initial:
                      initial,
                    ),
              )
                  : _AvatarFallback(
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
                size * .25,
                height:
                size * .25,
                decoration:
                BoxDecoration(
                  color:
                  Color(
                    0xFF25C76F,
                  ),
                  shape:
                  BoxShape.circle,
                  border:
                  Border.all(
                    color:
                    Colors.white,
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

class _AvatarFallback
    extends StatelessWidget {
  const _AvatarFallback({
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
      BoxDecoration(
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
        TextStyle(
          color:
          Colors.white,
          fontWeight:
          FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyConversation
    extends StatelessWidget {
  const _EmptyConversation({
    required this.partnerName,
  });

  final String partnerName;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child:
      Padding(
        padding:
        EdgeInsets.all(
          34,
        ),
        child:
        Column(
          mainAxisSize:
          MainAxisSize.min,
          children: [
            Container(
              width:
              74,
              height:
              74,
              decoration:
              BoxDecoration(
                color:
                AppColors.blueBg,
                shape:
                BoxShape.circle,
              ),
              child:
              Icon(
                Icons.chat_bubble_outline_rounded,
                color:
                AppColors.logoTurquoiseDark,
                size:
                32,
              ),
            ),

            SizedBox(
              height:
              16,
            ),

            Text(
              _ui('Start a conversation'),
              style:
              TextStyle(
                color:
                AppColors.navy,
                fontSize:
                16,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            SizedBox(
              height:
              6,
            ),

            Text(
              _ui('Send your first message to {name}.').replaceFirst('{name}', partnerName),
              textAlign:
              TextAlign.center,
              style:
              TextStyle(
                color:
                AppColors.grey,
                fontSize:
                11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesError
    extends StatelessWidget {
  const _MessagesError();

  @override
  Widget build(
      BuildContext context,
      ) {
    return Center(
      child:
      Padding(
        padding:
        EdgeInsets.all(
          24,
        ),
        child:
        Text(
          _ui('Could not load messages.'),
          style:
          TextStyle(
            color:
            AppColors.grey,
            fontSize:
            12,
          ),
        ),
      ),
    );
  }
}

