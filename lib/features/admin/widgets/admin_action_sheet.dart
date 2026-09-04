import 'package:flutter/material.dart';

import 'admin_design.dart';

Future<String?> showAdminReasonSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String actionLabel,
  required bool destructive,
}) async {
  final controller = TextEditingController();

  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: StatefulBuilder(
              builder: (
                context,
                setSheetState,
              ) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AdminColors.border,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: destructive
                            ? AdminColors.dangerSoft
                            : AdminColors.warningSoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        destructive
                            ? Icons.gpp_bad_rounded
                            : Icons.pause_circle_outline_rounded,
                        color: destructive
                            ? AdminColors.danger
                            : AdminColors.warning,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: controller,
                      minLines: 3,
                      maxLines: 5,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Write the reason...',
                        filled: true,
                        fillColor: AdminColors.bg,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: AdminColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(17),
                          borderSide: const BorderSide(
                            color: AdminColors.teal,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.ink,
                              side: const BorderSide(
                                color: AdminColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: controller.text.trim().isEmpty
                                ? null
                                : () => Navigator.pop(
                                      sheetContext,
                                      controller.text.trim(),
                                    ),
                            style: FilledButton.styleFrom(
                              backgroundColor: destructive
                                  ? AdminColors.danger
                                  : AdminColors.warning,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AdminColors.border,
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              actionLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    },
  );

  controller.dispose();

  return result;
}

Future<bool> showAdminConfirmSheet({
  required BuildContext context,
  required String title,
  required String subtitle,
  required String actionLabel,
  Color actionColor = AdminColors.success,
  IconData icon = Icons.verified_rounded,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AdminColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: actionColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: actionColor,
                  size: 27,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AdminColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 19),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AdminColors.ink,
                        side: const BorderSide(
                          color: AdminColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: actionColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        actionLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
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

  return result == true;
}
