import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key, required this.isCompany});
  final bool isCompany;
  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool jobUpdates = true;
  bool applicationUpdates = true;
  bool emailUpdates = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Expanded(
                child: Text(
                  'Settings',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsCard(
            title: 'Notifications',
            child: Column(
              children: [
                _SwitchRow(
                  title: widget.isCompany
                      ? 'Job activity'
                      : 'Job recommendations',
                  value: jobUpdates,
                  onChanged: (value) => setState(() => jobUpdates = value),
                ),
                const Divider(color: AppColors.cardBorder),
                _SwitchRow(
                  title: 'Application updates',
                  value: applicationUpdates,
                  onChanged: (value) =>
                      setState(() => applicationUpdates = value),
                ),
                const Divider(color: AppColors.cardBorder),
                _SwitchRow(
                  title: 'Email updates',
                  value: emailUpdates,
                  onChanged: (value) => setState(() => emailUpdates = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _SettingsCard(
            title: 'Account',
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.lock_outline_rounded,
                  title: 'Password & security',
                ),
                Divider(color: AppColors.cardBorder),
                _SettingsRow(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy controls',
                ),
                Divider(color: AppColors.cardBorder),
                _SettingsRow(
                  icon: Icons.language_rounded,
                  title: 'Language & region',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        child,
      ],
    ),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: AppColors.blue,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title});
  final IconData icon;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: AppColors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.lightGrey),
      ],
    ),
  );
}
