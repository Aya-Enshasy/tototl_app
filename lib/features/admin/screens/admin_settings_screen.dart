import 'package:flutter/material.dart';

import '../../auth/controllers/user_session_storage.dart';
import '../widgets/admin_design.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({
    super.key,
  });

  @override
  State<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState
    extends State<AdminSettingsScreen> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = await UserSessionStorage.getUser();

    if (!mounted) return;

    setState(() {
      _user = user;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name =
        _user?['name']?.toString().trim() ?? '';

    final email =
        _user?['email']?.toString().trim() ?? '';

    final username =
        _user?['username']?.toString().trim() ?? '';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        34,
      ),
      children: [
        const AdminPageTitle(
          title: 'Admin Workspace',
          subtitle:
              'Administrative account and access information',
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF092D43),
                Color(0xFF0A6070),
              ],
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                ),
                child: Text(
                  adminInitials(
                    name.isEmpty ? 'Admin' : name,
                  ),
                  style: const TextStyle(
                    color: AdminColors.tealDark,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Administrator' : name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email.isEmpty ? username : email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color:
                            Colors.white.withOpacity(0.68),
                        fontSize: 10.5,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius:
                            BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'ADMINISTRATOR',
                        style: TextStyle(
                          color: Color(0xFFB9F5F2),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const AdminSectionCard(
          icon: Icons.shield_outlined,
          title: 'Admin Capabilities',
          subtitle:
              'Actions currently connected to the backend',
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Pending reviews',
                value: 'Pilots & Companies',
                icon: Icons.fact_check_outlined,
              ),
              AdminInfoRow(
                label: 'Verification',
                value: 'Approve / Reject',
                icon: Icons.verified_user_outlined,
              ),
              AdminInfoRow(
                label: 'Lifecycle',
                value: 'Suspend / Reactivate',
                icon: Icons.autorenew_rounded,
              ),
              AdminInfoRow(
                label: 'Audit history',
                value: 'Verification History',
                icon: Icons.history_rounded,
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
