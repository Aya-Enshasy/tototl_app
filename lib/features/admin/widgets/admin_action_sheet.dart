import 'package:flutter/material.dart';

import 'admin_design.dart';

// ============================================================================
// REASON SHEET
//
// IMPORTANT:
// The TextEditingController is owned by the sheet State itself.
// This prevents:
// "A TextEditingController was used after being disposed."
// while the modal route / keyboard is still animating out.
// ============================================================================

Future<String?> showAdminReasonSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String actionLabel,
  required bool destructive,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _AdminReasonSheet(
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
        destructive: destructive,
      );
    },
  );
}

class _AdminReasonSheet extends StatefulWidget {
  const _AdminReasonSheet({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.destructive,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final bool destructive;

  @override
  State<_AdminReasonSheet> createState() =>
      _AdminReasonSheetState();
}

class _AdminReasonSheetState
    extends State<_AdminReasonSheet> {
  late final TextEditingController
  _reasonController;

  late final FocusNode
  _reasonFocusNode;

  @override
  void initState() {
    super.initState();

    _reasonController =
        TextEditingController();

    _reasonFocusNode =
        FocusNode();
  }

  @override
  void dispose() {
    _reasonFocusNode.dispose();
    _reasonController.dispose();

    super.dispose();
  }

  bool get _canSubmit =>
      _reasonController.text.trim().isNotEmpty;

  void _cancel() {
    FocusScope.of(context).unfocus();

    Navigator.of(context).pop();
  }

  void _submit() {
    final reason =
    _reasonController.text.trim();

    if (reason.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    Navigator.of(context).pop(
      reason,
    );
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final media =
    MediaQuery.of(context);

    final bottomInset =
        media.viewInsets.bottom;

    final actionColor =
    widget.destructive
        ? AdminColors.danger
        : AdminColors.warning;

    final actionSoftColor =
    widget.destructive
        ? AdminColors.dangerSoft
        : AdminColors.warningSoft;

    final actionIcon =
    widget.destructive
        ? Icons.gpp_bad_rounded
        : Icons.pause_circle_outline_rounded;

    return AnimatedPadding(
      duration:
      const Duration(
        milliseconds:
        180,
      ),
      curve:
      Curves.easeOut,
      padding:
      EdgeInsets.only(
        bottom:
        bottomInset,
      ),
      child:
      SafeArea(
        top:
        false,
        child:
        SingleChildScrollView(
          physics:
          const BouncingScrollPhysics(),
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
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
              boxShadow: [
                BoxShadow(
                  color:
                  Colors.black
                      .withOpacity(
                    0.08,
                  ),
                  blurRadius:
                  28,
                  offset:
                  const Offset(
                    0,
                    10,
                  ),
                ),
              ],
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
                    AdminColors.border,
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
                    actionSoftColor,
                    borderRadius:
                    BorderRadius.circular(
                      18,
                    ),
                  ),
                  child:
                  Icon(
                    actionIcon,
                    color:
                    actionColor,
                    size:
                    26,
                  ),
                ),

                const SizedBox(
                  height:
                  14,
                ),

                Text(
                  widget.title,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    AdminColors.ink,
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

                Text(
                  widget.subtitle,
                  textAlign:
                  TextAlign.center,
                  style:
                  const TextStyle(
                    color:
                    AdminColors.muted,
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

                TextField(
                  controller:
                  _reasonController,
                  focusNode:
                  _reasonFocusNode,
                  minLines:
                  3,
                  maxLines:
                  5,
                  maxLength:
                  500,
                  textCapitalization:
                  TextCapitalization.sentences,
                  keyboardType:
                  TextInputType.multiline,
                  textInputAction:
                  TextInputAction.newline,
                  onChanged:
                      (_) {
                    setState(() {});
                  },
                  decoration:
                  InputDecoration(
                    hintText:
                    'Write the reason...',
                    counterText:
                    '',
                    filled:
                    true,
                    fillColor:
                    AdminColors.bg,
                    contentPadding:
                    const EdgeInsets.all(
                      14,
                    ),
                    enabledBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        17,
                      ),
                      borderSide:
                      const BorderSide(
                        color:
                        AdminColors.border,
                      ),
                    ),
                    focusedBorder:
                    OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(
                        17,
                      ),
                      borderSide:
                      const BorderSide(
                        color:
                        AdminColors.teal,
                        width:
                        1.2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height:
                  16,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed:
                        _cancel,
                        style:
                        OutlinedButton.styleFrom(
                          foregroundColor:
                          AdminColors.ink,
                          side:
                          const BorderSide(
                            color:
                            AdminColors.border,
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
                          style:
                          TextStyle(
                            fontWeight:
                            FontWeight.w700,
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
                      FilledButton(
                        onPressed:
                        _canSubmit
                            ? _submit
                            : null,
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          actionColor,
                          foregroundColor:
                          Colors.white,
                          disabledBackgroundColor:
                          AdminColors.border,
                          disabledForegroundColor:
                          AdminColors.muted2,
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
                        Text(
                          widget.actionLabel,
                          style:
                          const TextStyle(
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
        ),
      ),
    );
  }
}

// ============================================================================
// CONFIRMATION SHEET
// ============================================================================

Future<bool> showAdminConfirmSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String actionLabel,
  Color actionColor = AdminColors.success,
  IconData icon = Icons.verified_rounded,
}) async {
  final result =
  await showModalBottomSheet<bool>(
    context:
    context,
    isScrollControlled:
    true,
    useSafeArea:
    false,
    backgroundColor:
    Colors.transparent,
    builder:
        (sheetContext) {
      final media =
      MediaQuery.of(
        sheetContext,
      );

      return AnimatedPadding(
        duration:
        const Duration(
          milliseconds:
          180,
        ),
        curve:
        Curves.easeOut,
        padding:
        EdgeInsets.only(
          bottom:
          media.viewInsets.bottom,
        ),
        child:
        SafeArea(
          top:
          false,
          child:
          SingleChildScrollView(
            physics:
            const BouncingScrollPhysics(),
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
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.black
                        .withOpacity(
                      0.08,
                    ),
                    blurRadius:
                    28,
                    offset:
                    const Offset(
                      0,
                      10,
                    ),
                  ),
                ],
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
                      AdminColors.border,
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
                      actionColor
                          .withOpacity(
                        0.10,
                      ),
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                    child:
                    Icon(
                      icon,
                      color:
                      actionColor,
                      size:
                      27,
                    ),
                  ),

                  const SizedBox(
                    height:
                    14,
                  ),

                  Text(
                    title,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color:
                      AdminColors.ink,
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

                  Text(
                    subtitle,
                    textAlign:
                    TextAlign.center,
                    style:
                    const TextStyle(
                      color:
                      AdminColors.muted,
                      fontSize:
                      11.5,
                      height:
                      1.45,
                    ),
                  ),

                  const SizedBox(
                    height:
                    19,
                  ),

                  Row(
                    children: [
                      Expanded(
                        child:
                        OutlinedButton(
                          onPressed:
                              () {
                            Navigator.of(
                              sheetContext,
                            ).pop(
                              false,
                            );
                          },
                          style:
                          OutlinedButton.styleFrom(
                            foregroundColor:
                            AdminColors.ink,
                            side:
                            const BorderSide(
                              color:
                              AdminColors.border,
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
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight.w700,
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
                        FilledButton(
                          onPressed:
                              () {
                            Navigator.of(
                              sheetContext,
                            ).pop(
                              true,
                            );
                          },
                          style:
                          FilledButton.styleFrom(
                            backgroundColor:
                            actionColor,
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
                          Text(
                            actionLabel,
                            style:
                            const TextStyle(
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
          ),
        ),
      );
    },
  );

  return result ==
      true;
}
