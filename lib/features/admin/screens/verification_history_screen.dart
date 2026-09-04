import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_user_model.dart';
import '../models/admin_verification_history_model.dart';
import '../widgets/admin_design.dart';

class VerificationHistoryScreen extends StatefulWidget {
  const VerificationHistoryScreen({
    super.key,
    required this.controller,
    required this.user,
  });

  final AdminController controller;
  final AdminUserModel user;

  @override
  State<VerificationHistoryScreen> createState() =>
      _VerificationHistoryScreenState();
}

class _VerificationHistoryScreenState
    extends State<VerificationHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<AdminVerificationHistoryModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await widget.controller
        .verificationHistory(widget.user.id);

    if (!mounted) return;

    setState(() {
      _loading = false;

      if (result == null) {
        _error = widget.controller.errorMessage ??
            'Unable to load verification history.';
      } else {
        _items = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            AdminPageTitle(
              title: 'Verification History',
              subtitle: widget.user.displayName,
              leading: AdminRoundButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AdminColors.tealDark,
                onRefresh: _load,
                child: _loading
                    ? ListView(
                        children: const [
                          SizedBox(height: 140),
                          Center(
                            child: CircularProgressIndicator(
                              color: AdminColors.tealDark,
                              strokeWidth: 2.4,
                            ),
                          ),
                        ],
                      )
                    : _error != null
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [
                              AdminEmptyState(
                                icon: Icons.cloud_off_rounded,
                                title: 'History unavailable',
                                message: _error!,
                                actionLabel: 'Retry',
                                onAction: _load,
                              ),
                            ],
                          )
                        : _items.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  AdminEmptyState(
                                    icon: Icons.history_toggle_off_rounded,
                                    title: 'No actions yet',
                                    message:
                                        'Verification actions for this account will appear here.',
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(
                                  parent: BouncingScrollPhysics(),
                                ),
                                padding:
                                    const EdgeInsets.fromLTRB(
                                  18,
                                  6,
                                  18,
                                  34,
                                ),
                                itemCount: _items.length,
                                itemBuilder: (
                                  context,
                                  index,
                                ) {
                                  return _HistoryItem(
                                    item: _items[index],
                                    last:
                                        index == _items.length - 1,
                                  );
                                },
                              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.item,
    required this.last,
  });

  final AdminVerificationHistoryModel item;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final design = _designFor(item.normalizedAction);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: design.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  design.icon,
                  color: design.foreground,
                  size: 18,
                ),
              ),
              if (!last)
                Container(
                  width: 2,
                  height: item.reason.trim().isEmpty ? 70 : 96,
                  color: AdminColors.border,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 14,
            ),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: AdminColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _prettyAction(item.action),
                        style: const TextStyle(
                          color: AdminColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      adminDate(item.createdAt),
                      style: const TextStyle(
                        color: AdminColors.muted2,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Admin #${item.adminId}',
                  style: const TextStyle(
                    color: AdminColors.tealDark,
                    fontSize: 9.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.reason.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: AdminColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      item.reason,
                      style: const TextStyle(
                        color: AdminColors.muted,
                        fontSize: 10.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionDesign {
  final Color foreground;
  final Color background;
  final IconData icon;

  const _ActionDesign(
    this.foreground,
    this.background,
    this.icon,
  );
}

_ActionDesign _designFor(String action) {
  switch (action) {
    case 'approved':
      return const _ActionDesign(
        AdminColors.success,
        AdminColors.successSoft,
        Icons.verified_rounded,
      );
    case 'rejected':
      return const _ActionDesign(
        AdminColors.danger,
        AdminColors.dangerSoft,
        Icons.cancel_rounded,
      );
    case 'suspended':
      return const _ActionDesign(
        AdminColors.warning,
        AdminColors.warningSoft,
        Icons.pause_circle_filled_rounded,
      );
    case 'reactivated':
      return const _ActionDesign(
        AdminColors.tealDark,
        AdminColors.tealSoft,
        Icons.restart_alt_rounded,
      );
    default:
      return const _ActionDesign(
        AdminColors.muted,
        AdminColors.bg,
        Icons.history_rounded,
      );
  }
}

String _prettyAction(String value) {
  final clean = value.trim();

  if (clean.isEmpty) return 'Unknown Action';

  return clean
      .split(RegExp(r'[_\s-]+'))
      .map(
        (e) => e.isEmpty
            ? e
            : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
      )
      .join(' ');
}
