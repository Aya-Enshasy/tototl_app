import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/user_session_storage.dart';
import '../models/chat_conversation.dart';
import '../services/cloudinary_chat_media_service.dart';
import '../services/firebase_chat_service.dart';
import 'forward_message_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
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

  final AudioRecorder _recorder =
  AudioRecorder();

  bool _sendingText = false;
  bool _uploadingMedia = false;

  ChatMessage? _replyTo;

  String _currentUserPhotoUrl = '';

  int _lastMessageCount = 0;

  bool _isRecording = false;

  Duration _recordingDuration =
      Duration.zero;

  Timer? _recordingTimer;

  String? _recordingPath;

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
    _recordingTimer?.cancel();

    if (_isRecording) {
      unawaited(
        _recorder.cancel(),
      );
    }

    unawaited(
      _recorder.dispose(),
    );

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
        _uploadingMedia ||
        _isRecording) {
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
          'Message could not be sent.',
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
    if (_uploadingMedia ||
        _isRecording) {
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
            const EdgeInsets.all(
              12,
            ),
            padding:
            const EdgeInsets.fromLTRB(
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

                const SizedBox(
                  height:
                  18,
                ),

                const Text(
                  'Send a photo',
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

                const SizedBox(
                  height:
                  14,
                ),

                _MediaSourceTile(
                  icon:
                  Icons.photo_library_outlined,
                  title:
                  'Photo library',
                  subtitle:
                  'Choose an image from your device',
                  onTap:
                      () => Navigator.pop(
                    sheetContext,
                    ImageSource.gallery,
                  ),
                ),

                const SizedBox(
                  height:
                  8,
                ),

                _MediaSourceTile(
                  icon:
                  Icons.photo_camera_outlined,
                  title:
                  'Camera',
                  subtitle:
                  'Take a new photo',
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
          'Photo upload failed.',
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
            const EdgeInsets.all(
              12,
            ),
            constraints:
            BoxConstraints(
              maxHeight:
              height,
            ),
            padding:
            const EdgeInsets.fromLTRB(
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

                const SizedBox(
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

                const SizedBox(
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
                          const BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
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
                        const Text(
                          'Cancel',
                        ),
                      ),
                    ),

                    const SizedBox(
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
                          const EdgeInsets.symmetric(
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
                        const Icon(
                          Icons.send_rounded,
                          size:
                          17,
                        ),
                        label:
                        const Text(
                          'Send photo',
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
  // VOICE
  // ========================================================================

  Future<void> _startRecording() async {
    if (_isRecording ||
        _uploadingMedia ||
        _sendingText) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final allowed =
      await _recorder.hasPermission();

      if (!allowed) {
        if (mounted) {
          _showSnack(
            'Microphone permission is required.',
            error: true,
          );
        }

        return;
      }

      final tempDir =
      await getTemporaryDirectory();

      final path =
          '${tempDir.path}/'
          'tototl_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder:
          AudioEncoder.aacLc,
          bitRate:
          96000,
          sampleRate:
          44100,
          numChannels:
          1,
          echoCancel:
          true,
          noiseSuppress:
          true,
        ),
        path:
        path,
      );

      if (!mounted) {
        return;
      }

      _recordingTimer?.cancel();

      setState(() {
        _recordingPath =
            path;

        _recordingDuration =
            Duration.zero;

        _isRecording =
        true;
      });

      _recordingTimer =
          Timer.periodic(
            const Duration(
              seconds:
              1,
            ),
                (_) {
              if (!mounted ||
                  !_isRecording) {
                return;
              }

              setState(() {
                _recordingDuration +=
                const Duration(
                  seconds:
                  1,
                );
              });
            },
          );
    } catch (_) {
      if (mounted) {
        _showSnack(
          'Could not start voice recording.',
          error: true,
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();

    try {
      await _recorder.cancel();
    } catch (_) {}

    final path =
        _recordingPath;

    if (path != null) {
      final file =
      File(path);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording =
      false;

      _recordingPath =
      null;

      _recordingDuration =
          Duration.zero;
    });
  }

  Future<void> _sendRecording() async {
    if (!_isRecording ||
        _uploadingMedia) {
      return;
    }

    _recordingTimer?.cancel();

    final capturedDuration =
        _recordingDuration;

    String? path;

    try {
      path =
      await _recorder.stop();
    } catch (_) {
      path =
          _recordingPath;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording =
      false;

      _recordingPath =
      null;

      _recordingDuration =
          Duration.zero;
    });

    if (path == null ||
        path.trim().isEmpty) {
      _showSnack(
        'Voice recording was not saved.',
        error: true,
      );

      return;
    }

    final voicePath =
        path;

    if (capturedDuration <
        const Duration(
          seconds:
          1,
        )) {
      final file =
      File(voicePath);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      _showSnack(
        'Voice message is too short.',
      );

      return;
    }

    setState(() {
      _uploadingMedia =
      true;
    });

    try {
      final uploaded =
      await CloudinaryChatMediaService
          .instance
          .uploadVoice(
        voicePath,
      );

      final cloudDurationMs =
      uploaded.durationSeconds > 0
          ? (uploaded.durationSeconds *
          1000)
          .round()
          : capturedDuration
          .inMilliseconds;

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
        ChatMessageType.voice,
        mediaUrl:
        uploaded.secureUrl,
        mediaDurationMs:
        cloudDurationMs,
        mimeType:
        uploaded.format.isEmpty
            ? 'audio/mp4'
            : 'audio/${uploaded.format}',
        replyTo:
        _replyTo,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _replyTo =
        null;
      });

      _scrollToBottom();
    } catch (_) {
      if (mounted) {
        _showSnack(
          'Voice upload failed.',
          error: true,
        );
      }
    } finally {
      final file =
      File(voicePath);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _uploadingMedia =
          false;
        });
      }
    }
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
          'Reaction could not be updated.',
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
              'Message copied.',
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
            const EdgeInsets.all(
              12,
            ),
            padding:
            const EdgeInsets.fromLTRB(
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

                const SizedBox(
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
                  const Icon(
                    Icons.delete_outline_rounded,
                    color:
                    AppColors.red,
                    size:
                    26,
                  ),
                ),

                const SizedBox(
                  height:
                  14,
                ),

                const Text(
                  'Delete message?',
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

                const SizedBox(
                  height:
                  6,
                ),

                const Text(
                  'It will be replaced with “Message deleted” for both users.',
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

                const SizedBox(
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
                          const BorderSide(
                            color:
                            AppColors.cardBorder,
                          ),
                          padding:
                          const EdgeInsets.symmetric(
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
                        const Text(
                          'Cancel',
                        ),
                      ),
                    ),

                    const SizedBox(
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
                          const EdgeInsets.symmetric(
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
                        const Text(
                          'Delete',
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
          'Message could not be deleted.',
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
          const Duration(
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
          const EdgeInsets.all(
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
      backgroundColor:
      AppColors.bg,
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
                              const <
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
                        const BouncingScrollPhysics(),
                        padding:
                        const EdgeInsets.fromLTRB(
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

                          return _MessageBubble(
                            message:
                            message,
                            mine:
                            mine,
                            currentUserId:
                            widget.currentUserId,
                            partnerName:
                            widget.partnerName,
                            partnerPhotoUrl:
                            widget.partnerPhotoUrl,
                            showAvatar:
                            showAvatar,
                            onLongPress:
                                () =>
                                _showMessageActions(
                                  message,
                                ),
                            onDoubleTap:
                                () =>
                                _setReaction(
                                  message,
                                  'heart',
                                ),
                            onReactionTap:
                                (
                                reactionCode,
                                ) =>
                                _setReaction(
                                  message,
                                  reactionCode,
                                ),
                          );
                        },
                      );
                    },
                  ),
                ),

                _Composer(
                  controller:
                  _controller,
                  focusNode:
                  _focusNode,
                  sending:
                  _sendingText,
                  uploadingMedia:
                  _uploadingMedia,
                  isRecording:
                  _isRecording,
                  recordingDuration:
                  _recordingDuration,
                  replyTo:
                  _replyTo,
                  currentUserId:
                  widget.currentUserId,
                  partnerName:
                  widget.partnerName,
                  onCancelReply:
                      () {
                    setState(() {
                      _replyTo =
                      null;
                    });
                  },
                  onSend:
                  _sendText,
                  onAttachment:
                  _showImageSourceSheet,
                  onStartVoice:
                  _startRecording,
                  onCancelVoice:
                  _cancelRecording,
                  onSendVoice:
                  _sendRecording,
                ),
              ],
            ),

            if (_uploadingMedia)
              const Positioned.fill(
                child:
                _MediaUploadingOverlay(),
              ),
          ],
        ),
      ),
    );
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

// ==========================================================================
// HEADER
// ==========================================================================

class _ChatHeader
    extends StatelessWidget {
  const _ChatHeader({
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
                () => Navigator.of(
              context,
            ).pop(),
            icon:
            const Icon(
              Icons.arrow_back_ios_new_rounded,
              color:
              AppColors.navy,
              size:
              18,
            ),
          ),

          _ChatAvatar(
            name:
            name,
            photoUrl:
            photoUrl,
            size:
            43,
            online:
            true,
          ),

          const SizedBox(
            width:
            10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  name.trim().isEmpty
                      ? 'Conversation'
                      : name,
                  maxLines:
                  1,
                  overflow:
                  TextOverflow.ellipsis,
                  style:
                  const TextStyle(
                    color:
                    AppColors.navy,
                    fontSize:
                    14.5,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height:
                  2,
                ),

                const Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size:
                      11,
                      color:
                      AppColors.logoTurquoiseDark,
                    ),
                    SizedBox(
                      width:
                      4,
                    ),
                    Text(
                      'Private conversation',
                      style:
                      TextStyle(
                        color:
                        AppColors.grey,
                        fontSize:
                        10.2,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            width:
            38,
            height:
            38,
            decoration:
            const BoxDecoration(
              color:
              Color(
                0xFFF5F7F9,
              ),
              shape:
              BoxShape.circle,
            ),
            child:
            const Icon(
              Icons.more_horiz_rounded,
              color:
              AppColors.navy,
              size:
              19,
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
      const EdgeInsets.only(
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
            const SizedBox(
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
                          ? const LinearGradient(
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
                          ? const Color(
                        0xFFF1F3F5,
                      )
                          : Colors.white,
                      borderRadius:
                      BorderRadius.only(
                        topLeft:
                        const Radius.circular(
                          19,
                        ),
                        topRight:
                        const Radius.circular(
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
                          const Offset(
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
                          const SizedBox(
                            height:
                            7,
                          ),

                        if (message.deleted)
                          const Text(
                            'Message deleted',
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
                        else if (message
                              .isVoice)
                            _VoiceMessagePlayer(
                              url:
                              message.mediaUrl,
                              durationMs:
                              message.mediaDurationMs,
                              mine:
                              mine,
                            )
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
                          const SizedBox(
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
                                const SizedBox(
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
                    const EdgeInsets.only(
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
          const BoxConstraints(
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
          const Color(
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

              return const SizedBox(
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
              return const SizedBox(
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
                        'Photo unavailable',
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

// ==========================================================================
// VOICE PLAYER
// ==========================================================================

class _VoiceMessagePlayer
    extends StatefulWidget {
  const _VoiceMessagePlayer({
    required this.url,
    required this.durationMs,
    required this.mine,
  });

  final String url;
  final int durationMs;
  final bool mine;

  @override
  State<_VoiceMessagePlayer> createState() =>
      _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState
    extends State<_VoiceMessagePlayer> {
  late final AudioPlayer _player;

  StreamSubscription<Duration>?
  _positionSub;

  StreamSubscription<Duration>?
  _durationSub;

  StreamSubscription<PlayerState>?
  _stateSub;

  StreamSubscription<void>?
  _completeSub;

  Duration _position =
      Duration.zero;

  Duration _duration =
      Duration.zero;

  PlayerState _state =
      PlayerState.stopped;

  @override
  void initState() {
    super.initState();

    _duration =
        Duration(
          milliseconds:
          widget.durationMs,
        );

    _player =
        AudioPlayer();

    _positionSub =
        _player.onPositionChanged.listen(
              (value) {
            if (mounted) {
              setState(() {
                _position =
                    value;
              });
            }
          },
        );

    _durationSub =
        _player.onDurationChanged.listen(
              (value) {
            if (mounted) {
              setState(() {
                _duration =
                    value;
              });
            }
          },
        );

    _stateSub =
        _player.onPlayerStateChanged.listen(
              (value) {
            if (mounted) {
              setState(() {
                _state =
                    value;
              });
            }
          },
        );

    _completeSub =
        _player.onPlayerComplete.listen(
              (_) {
            if (mounted) {
              setState(() {
                _state =
                    PlayerState.stopped;

                _position =
                    Duration.zero;
              });
            }
          },
        );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();

    unawaited(
      _player.dispose(),
    );

    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state ==
        PlayerState.playing) {
      await _player.pause();

      return;
    }

    if (_state ==
        PlayerState.paused) {
      await _player.resume();

      return;
    }

    await _player.play(
      UrlSource(
        widget.url,
      ),
    );
  }

  Future<void> _seek(
      double ratio,
      ) async {
    if (_duration.inMilliseconds <=
        0) {
      return;
    }

    final target =
    Duration(
      milliseconds:
      (_duration.inMilliseconds *
          ratio.clamp(
            0.0,
            1.0,
          ))
          .round(),
    );

    await _player.seek(
      target,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final totalMs =
    _duration.inMilliseconds > 0
        ? _duration.inMilliseconds
        : widget.durationMs;

    final progress =
    totalMs <= 0
        ? 0.0
        : (_position.inMilliseconds /
        totalMs)
        .clamp(
      0.0,
      1.0,
    );

    final foreground =
    widget.mine
        ? Colors.white
        : AppColors.logoTurquoiseDark;

    final muted =
    widget.mine
        ? Colors.white.withValues(
      alpha:
      .62,
    )
        : AppColors.lightGrey;

    final shownDuration =
    _position > Duration.zero
        ? _position
        : Duration(
      milliseconds:
      totalMs,
    );

    return SizedBox(
      width:
      230,
      child:
      Row(
        children: [
          Material(
            color:
            widget.mine
                ? Colors.white
                : AppColors.blueBg,
            shape:
            const CircleBorder(),
            child:
            InkWell(
              onTap:
              _toggle,
              customBorder:
              const CircleBorder(),
              child:
              SizedBox(
                width:
                42,
                height:
                42,
                child:
                Icon(
                  _state ==
                      PlayerState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color:
                  widget.mine
                      ? AppColors.logoTurquoiseDark
                      : AppColors.logoTurquoiseDark,
                  size:
                  23,
                ),
              ),
            ),
          ),

          const SizedBox(
            width:
            10,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                _Waveform(
                  progress:
                  progress,
                  activeColor:
                  foreground,
                  inactiveColor:
                  muted,
                  onSeek:
                  _seek,
                ),

                const SizedBox(
                  height:
                  5,
                ),

                Text(
                  _formatDuration(
                    shownDuration,
                  ),
                  style:
                  TextStyle(
                    color:
                    muted,
                    fontSize:
                    8.8,
                    fontWeight:
                    FontWeight.w600,
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

class _Waveform
    extends StatelessWidget {
  const _Waveform({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.onSeek,
  });

  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  final Future<void> Function(
      double ratio,
      ) onSeek;

  static const _heights =
  <double>[
    9,
    16,
    11,
    22,
    15,
    26,
    13,
    19,
    10,
    24,
    17,
    12,
    27,
    15,
    21,
    9,
    18,
    25,
    13,
    20,
    11,
    24,
    15,
    19,
  ];

  @override
  Widget build(
      BuildContext context,
      ) {
    return LayoutBuilder(
      builder:
          (
          context,
          constraints,
          ) {
        return GestureDetector(
          behavior:
          HitTestBehavior.opaque,
          onTapDown:
              (details) {
            final width =
                constraints.maxWidth;

            if (width <= 0) {
              return;
            }

            onSeek(
              details.localPosition.dx /
                  width,
            );
          },
          child:
          SizedBox(
            height:
            30,
            child:
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children:
              List.generate(
                _heights.length,
                    (
                    index,
                    ) {
                  final barProgress =
                      (index + 1) /
                          _heights.length;

                  final active =
                      barProgress <=
                          progress;

                  return Expanded(
                    child:
                    Align(
                      child:
                      Container(
                        width:
                        2.2,
                        height:
                        _heights[index],
                        decoration:
                        BoxDecoration(
                          color:
                          active
                              ? activeColor
                              : inactiveColor,
                          borderRadius:
                          BorderRadius.circular(
                            3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

// ==========================================================================
// REPLY / REACTIONS
// ==========================================================================

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
      const EdgeInsets.fromLTRB(
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
            : const Color(
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
                ? 'You'
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

          const SizedBox(
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
          const EdgeInsets.symmetric(
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
                const TextStyle(
                  fontSize:
                  13,
                ),
              ),

              if (count >
                  1) ...[
                const SizedBox(
                  width:
                  3,
                ),
                Text(
                  '$count',
                  style:
                  const TextStyle(
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
        const EdgeInsets.all(
          12,
        ),
        padding:
        const EdgeInsets.fromLTRB(
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
              const Offset(
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

            const SizedBox(
              height:
              14,
            ),

            Container(
              width:
              double.infinity,
              padding:
              const EdgeInsets.all(
                12,
              ),
              decoration:
              BoxDecoration(
                color:
                const Color(
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
                const TextStyle(
                  color:
                  AppColors.navy,
                  fontSize:
                  11.5,
                  height:
                  1.4,
                ),
              ),
            ),

            const SizedBox(
              height:
              14,
            ),

            const Text(
              'React',
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

            const SizedBox(
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
                      const EdgeInsets.only(
                        right:
                        8,
                      ),
                      child:
                      Material(
                        color:
                        selected
                            ? AppColors.blueBg
                            : const Color(
                          0xFFF7F8FA,
                        ),
                        shape:
                        const CircleBorder(),
                        child:
                        InkWell(
                          onTap:
                              () => Navigator.pop(
                            context,
                            'reaction:${reaction.code}',
                          ),
                          customBorder:
                          const CircleBorder(),
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
                                const TextStyle(
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
              const SizedBox(
                height:
                7,
              ),
              const Text(
                'Choose another reaction to replace the current one, or tap the same reaction to remove it.',
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

            const SizedBox(
              height:
              10,
            ),

            const Divider(
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
                'Copy',
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
              'Reply',
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
              'Forward',
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
                'Delete',
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
          const EdgeInsets.symmetric(
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

class _Composer
    extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.uploadingMedia,
    required this.isRecording,
    required this.recordingDuration,
    required this.replyTo,
    required this.currentUserId,
    required this.partnerName,
    required this.onCancelReply,
    required this.onSend,
    required this.onAttachment,
    required this.onStartVoice,
    required this.onCancelVoice,
    required this.onSendVoice,
  });

  final TextEditingController
  controller;

  final FocusNode focusNode;

  final bool sending;
  final bool uploadingMedia;
  final bool isRecording;

  final Duration recordingDuration;

  final ChatMessage? replyTo;

  final String currentUserId;
  final String partnerName;

  final VoidCallback onCancelReply;

  final Future<void> Function()
  onSend;

  final Future<void> Function()
  onAttachment;

  final Future<void> Function()
  onStartVoice;

  final Future<void> Function()
  onCancelVoice;

  final Future<void> Function()
  onSendVoice;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      decoration:
      const BoxDecoration(
        color:
        Colors.white,
        border:
        Border(
          top:
          BorderSide(
            color:
            AppColors.cardBorder,
          ),
        ),
      ),
      child:
      SafeArea(
        top:
        false,
        child:
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            12,
            8,
            12,
            10,
          ),
          child:
          Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              if (replyTo !=
                  null)
                _ComposerReplyBar(
                  message:
                  replyTo!,
                  currentUserId:
                  currentUserId,
                  partnerName:
                  partnerName,
                  onClose:
                  onCancelReply,
                ),

              if (replyTo !=
                  null)
                const SizedBox(
                  height:
                  7,
                ),

              if (isRecording)
                _RecordingBar(
                  duration:
                  recordingDuration,
                  onCancel:
                  onCancelVoice,
                  onSend:
                  onSendVoice,
                )
              else
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    _ComposerCircleButton(
                      icon:
                      Icons.add_rounded,
                      onTap:
                      uploadingMedia
                          ? null
                          : onAttachment,
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    Expanded(
                      child:
                      TextField(
                        controller:
                        controller,
                        focusNode:
                        focusNode,
                        enabled:
                        !uploadingMedia,
                        minLines:
                        1,
                        maxLines:
                        4,
                        textCapitalization:
                        TextCapitalization.sentences,
                        textInputAction:
                        TextInputAction.newline,
                        style:
                        const TextStyle(
                          color:
                          AppColors.navy,
                          fontSize:
                          12.8,
                        ),
                        decoration:
                        InputDecoration(
                          hintText:
                          'Message...',
                          hintStyle:
                          const TextStyle(
                            color:
                            AppColors.lightGrey,
                            fontSize:
                            12.5,
                          ),
                          suffixIcon:
                          const Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color:
                            AppColors.grey,
                            size:
                            20,
                          ),
                          filled:
                          true,
                          fillColor:
                          const Color(
                            0xFFF4F6F8,
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(
                            horizontal:
                            14,
                            vertical:
                            11,
                          ),
                          border:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                              24,
                            ),
                            borderSide:
                            BorderSide.none,
                          ),
                          enabledBorder:
                          OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                              24,
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
                              24,
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
                      ),
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    _ComposerCircleButton(
                      icon:
                      Icons.mic_none_rounded,
                      onTap:
                      uploadingMedia
                          ? null
                          : onStartVoice,
                    ),

                    const SizedBox(
                      width:
                      7,
                    ),

                    SizedBox(
                      width:
                      46,
                      height:
                      46,
                      child:
                      FilledButton(
                        onPressed:
                        sending ||
                            uploadingMedia
                            ? null
                            : onSend,
                        style:
                        FilledButton.styleFrom(
                          padding:
                          EdgeInsets.zero,
                          backgroundColor:
                          AppColors.logoTurquoiseDark,
                          disabledBackgroundColor:
                          AppColors.logoTurquoiseDark.withValues(
                            alpha:
                            .55,
                          ),
                          shape:
                          const CircleBorder(),
                        ),
                        child:
                        sending
                            ? const SizedBox(
                          width:
                          18,
                          height:
                          18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth:
                            2,
                            color:
                            Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.send_rounded,
                          color:
                          Colors.white,
                          size:
                          20,
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

class _RecordingBar
    extends StatelessWidget {
  const _RecordingBar({
    required this.duration,
    required this.onCancel,
    required this.onSend,
  });

  final Duration duration;

  final Future<void> Function()
  onCancel;

  final Future<void> Function()
  onSend;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        11,
        7,
        7,
        7,
      ),
      decoration:
      BoxDecoration(
        color:
        const Color(
          0xFFF4F6F8,
        ),
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        border:
        Border.all(
          color:
          AppColors.cardBorder,
        ),
      ),
      child:
      Row(
        children: [
          Container(
            width:
            10,
            height:
            10,
            decoration:
            const BoxDecoration(
              color:
              AppColors.red,
              shape:
              BoxShape.circle,
            ),
          ),

          const SizedBox(
            width:
            8,
          ),

          Text(
            _formatDuration(
              duration,
            ),
            style:
            const TextStyle(
              color:
              AppColors.navy,
              fontSize:
              12,
              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            width:
            10,
          ),

          Expanded(
            child:
            Row(
              children:
              List.generate(
                18,
                    (
                    index,
                    ) {
                  final heights =
                  <double>[
                    7,
                    14,
                    10,
                    19,
                    12,
                    21,
                    9,
                    17,
                    11,
                    22,
                    13,
                    16,
                    8,
                    20,
                    12,
                    18,
                    9,
                    15,
                  ];

                  return Expanded(
                    child:
                    Align(
                      child:
                      Container(
                        width:
                        2,
                        height:
                        heights[index],
                        decoration:
                        BoxDecoration(
                          color:
                          AppColors.logoTurquoiseDark.withValues(
                            alpha:
                            .55,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            3,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(
            width:
            8,
          ),

          IconButton(
            onPressed:
            onCancel,
            style:
            IconButton.styleFrom(
              backgroundColor:
              AppColors.red.withValues(
                alpha:
                .08,
              ),
            ),
            icon:
            const Icon(
              Icons.delete_outline_rounded,
              color:
              AppColors.red,
              size:
              20,
            ),
          ),

          const SizedBox(
            width:
            3,
          ),

          IconButton(
            onPressed:
            onSend,
            style:
            IconButton.styleFrom(
              backgroundColor:
              AppColors.logoTurquoiseDark,
              foregroundColor:
              Colors.white,
            ),
            icon:
            const Icon(
              Icons.send_rounded,
              size:
              19,
            ),
          ),
        ],
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
      const EdgeInsets.fromLTRB(
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
        const Border(
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
                      ? 'Replying to yourself'
                      : 'Replying to $partnerName',
                  style:
                  const TextStyle(
                    color:
                    AppColors.logoTurquoiseDark,
                    fontSize:
                    9.5,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
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
                  const TextStyle(
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
            const Icon(
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
      const Color(
        0xFFF4F6F8,
      ),
      shape:
      const CircleBorder(),
      child:
      InkWell(
        onTap:
        onTap == null
            ? null
            : () {
          onTap!();
        },
        customBorder:
        const CircleBorder(),
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
      const Color(
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
          const EdgeInsets.all(
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
                    Text(
                      title,
                      style:
                      const TextStyle(
                        color:
                        AppColors.navy,
                        fontSize:
                        12.5,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                    const SizedBox(
                      height:
                      3,
                    ),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        color:
                        AppColors.grey,
                        fontSize:
                        9.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
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
          const BoxConstraints(
            maxWidth:
            230,
          ),
          padding:
          const EdgeInsets.symmetric(
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
                const Offset(
                  0,
                  9,
                ),
              ),
            ],
          ),
          child:
          const Row(
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
                  'Uploading media...',
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
                  const Color(
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
        const EdgeInsets.all(
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
              16,
            ),

            const Text(
              'Start a conversation',
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

            const SizedBox(
              height:
              6,
            ),

            Text(
              'Send your first message to $partnerName.',
              textAlign:
              TextAlign.center,
              style:
              const TextStyle(
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
    return const Center(
      child:
      Padding(
        padding:
        EdgeInsets.all(
          24,
        ),
        child:
        Text(
          'Could not load messages.',
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

String _formatDuration(
    Duration value,
    ) {
  final minutes =
      value.inMinutes;

  final seconds =
      value.inSeconds %
          60;

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
