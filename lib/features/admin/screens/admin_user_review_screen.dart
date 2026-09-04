import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_user_model.dart';
import '../widgets/admin_action_sheet.dart';
import '../widgets/admin_design.dart';
import 'verification_history_screen.dart';

class AdminUserReviewScreen extends StatefulWidget {
  const AdminUserReviewScreen({
    super.key,
    required this.controller,
    required this.initialUser,
    required this.typeLabel,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroIcon,
    required this.heroColors,
    required this.details,
    this.isCompany = false,
  });

  final AdminController controller;
  final AdminUserModel initialUser;

  final String typeLabel;
  final String heroTitle;
  final String heroSubtitle;
  final IconData heroIcon;
  final List<Color> heroColors;
  final List<Widget> details;
  final bool isCompany;

  @override
  State<AdminUserReviewScreen> createState() =>
      _AdminUserReviewScreenState();
}

class _AdminUserReviewScreenState
    extends State<AdminUserReviewScreen> {
  late AdminUserModel _user;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
  }

  Future<void> _approve() async {
    final confirmed = await showAdminConfirmSheet(
      context: context,
      title: 'Approve this ${widget.typeLabel}?',
      subtitle:
          'The account will be approved and can continue using the platform.',
      actionLabel: 'Approve',
      actionColor: AdminColors.success,
      icon: Icons.verified_rounded,
    );

    if (!confirmed || !mounted) return;

    await _runAction(
      () => widget.controller.approve(_user.id),
      successFallback: 'Account approved successfully.',
    );
  }

  Future<void> _reject() async {
    final reason = await showAdminReasonSheet(
      context: context,
      title: 'Reject this ${widget.typeLabel}?',
      subtitle:
          'Add a clear reason. This action will be stored in the verification history.',
      actionLabel: 'Reject',
      destructive: true,
    );

    if (reason == null || !mounted) return;

    await _runAction(
      () => widget.controller.reject(
        userId: _user.id,
        reason: reason,
      ),
      successFallback: 'Account rejected.',
    );
  }

  Future<void> _suspend() async {
    final reason = await showAdminReasonSheet(
      context: context,
      title: 'Suspend this account?',
      subtitle:
          'The user will lose active access until an admin reactivates the account.',
      actionLabel: 'Suspend',
      destructive: false,
    );

    if (reason == null || !mounted) return;

    await _runAction(
      () => widget.controller.suspend(
        userId: _user.id,
        reason: reason,
      ),
      successFallback: 'Account suspended.',
    );
  }

  Future<void> _reactivate() async {
    final confirmed = await showAdminConfirmSheet(
      context: context,
      title: 'Reactivate this account?',
      subtitle:
          'The account will return to active status and regain platform access.',
      actionLabel: 'Reactivate',
      actionColor: AdminColors.tealDark,
      icon: Icons.restart_alt_rounded,
    );

    if (!confirmed || !mounted) return;

    await _runAction(
      () => widget.controller.reactivate(_user.id),
      successFallback: 'Account reactivated.',
    );
  }

  Future<void> _runAction(
    Future<AdminUserModel?> Function() call, {
    required String successFallback,
  }) async {
    if (_busy) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _busy = true;
    });

    final result = await call();

    if (!mounted) return;

    setState(() {
      _busy = false;

      if (result != null) {
        _user = result;
      }
    });

    if (result == null) {
      _showSnack(
        widget.controller.errorMessage ??
            'Unable to complete this action.',
        error: true,
      );
      return;
    }

    _showSnack(successFallback);
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerificationHistoryScreen(
          controller: widget.controller,
          user: _user,
        ),
      ),
    );
  }

  void _showSnack(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
              error ? AdminColors.danger : AdminColors.navy,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                AdminPageTitle(
                  title: '${widget.typeLabel} Review',
                  subtitle: 'Account verification & lifecycle controls',
                  leading: AdminRoundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(
                      context,
                      _user,
                    ),
                  ),
                  trailing: AdminRoundButton(
                    icon: Icons.history_rounded,
                    onTap: _openHistory,
                  ),
                ),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      4,
                      18,
                      122,
                    ),
                    children: [
                      _PremiumHero(
                        user: _user,
                        title: widget.heroTitle,
                        subtitle: widget.heroSubtitle,
                        icon: widget.heroIcon,
                        colors: widget.heroColors,
                        isCompany: widget.isCompany,
                      ),
                      const SizedBox(height: 14),
                      AdminSectionCard(
                        icon: Icons.manage_accounts_outlined,
                        title: 'Account Information',
                        subtitle:
                            'Core identity and contact details',
                        child: Column(
                          children: [
                            AdminInfoRow(
                              label: 'Full name',
                              value: _user.name,
                              icon: Icons.person_outline_rounded,
                            ),
                            AdminInfoRow(
                              label: 'Username',
                              value: _user.displayUsername,
                              icon: Icons.alternate_email_rounded,
                            ),
                            AdminInfoRow(
                              label: 'Email',
                              value: _user.email,
                              icon: Icons.mail_outline_rounded,
                            ),
                            AdminInfoRow(
                              label: 'Phone',
                              value: _user.displayPhone,
                              icon: Icons.phone_outlined,
                            ),
                            AdminInfoRow(
                              label: 'Email verified',
                              value: _user.emailVerifiedAt == null
                                  ? 'No'
                                  : 'Yes',
                              icon:
                                  Icons.mark_email_read_outlined,
                            ),
                            AdminInfoRow(
                              label: 'Created',
                              value: adminDate(_user.createdAt),
                              icon: Icons.event_outlined,
                              last: true,
                            ),
                          ],
                        ),
                      ),
                      ...widget.details,
                      const SizedBox(height: 14),
                      _HistoryShortcut(
                        onTap: _openHistory,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 10,
              child: _ActionDock(
                user: _user,
                busy: _busy,
                onApprove: _approve,
                onReject: _reject,
                onSuspend: _suspend,
                onReactivate: _reactivate,
              ),
            ),
            if (_busy)
              const Positioned.fill(
                child: _BusyOverlay(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({
    required this.user,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.isCompany,
  });

  final AdminUserModel user;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final bool isCompany;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 170,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -35,
            child: Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Container(
                    width: 70,
                    height: 70,
                    alignment: Alignment.center,
                    color: isCompany
                        ? AdminColors.companySoft
                        : AdminColors.pilotSoft,
                    child: Text(
                      adminInitials(user.displayName),
                      style: TextStyle(
                        color: isCompany
                            ? AdminColors.company
                            : AdminColors.pilot,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.68),
                        fontSize: 10.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminStatusBadge(
                      status: user.status,
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 21,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.user,
    required this.busy,
    required this.onApprove,
    required this.onReject,
    required this.onSuspend,
    required this.onReactivate,
  });

  final AdminUserModel user;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onSuspend;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];

    if (user.isPending) {
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: busy ? null : onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.danger,
              side: const BorderSide(
                color: Color(0xFFFFCACA),
              ),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(
              Icons.close_rounded,
              size: 17,
            ),
            label: const Text(
              'Reject',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );

      buttons.add(const SizedBox(width: 10));

      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onApprove,
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(
              Icons.verified_rounded,
              size: 17,
            ),
            label: const Text(
              'Approve',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    } else if (user.isSuspended) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onReactivate,
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.tealDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(
              Icons.restart_alt_rounded,
              size: 18,
            ),
            label: const Text(
              'Reactivate Account',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    } else if (user.isActive) {
      buttons.add(
        Expanded(
          child: FilledButton.icon(
            onPressed: busy ? null : onSuspend,
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            icon: const Icon(
              Icons.pause_circle_outline_rounded,
              size: 18,
            ),
            label: const Text(
              'Suspend Account',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: AdminColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.ink.withOpacity(0.09),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: buttons,
      ),
    );
  }
}

class _HistoryShortcut extends StatelessWidget {
  const _HistoryShortcut({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: AdminColors.border,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: AdminColors.tealDark,
                size: 20,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verification History',
                      style: TextStyle(
                        color: AdminColors.ink,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'View every admin action on this account',
                      style: TextStyle(
                        color: AdminColors.muted,
                        fontSize: 9.8,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black12,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AdminColors.tealDark,
                ),
              ),
              SizedBox(width: 11),
              Text(
                'Updating account...',
                style: TextStyle(
                  color: AdminColors.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
