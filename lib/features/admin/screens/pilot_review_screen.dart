import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_design.dart';
import 'admin_user_review_screen.dart';

class PilotReviewScreen extends StatelessWidget {
  const PilotReviewScreen({
    super.key,
    required this.controller,
    required this.pilot,
  });

  final AdminController controller;
  final AdminPendingPilotModel pilot;

  @override
  Widget build(BuildContext context) {
    final profile = pilot.profile;

    return AdminUserReviewScreen(
      controller: controller,
      initialUser: pilot.user,
      typeLabel: 'Pilot',
      heroTitle: pilot.user.displayName,
      heroSubtitle:
          '${pilot.user.displayUsername} • ${profile.experienceLabel} experience',
      heroIcon: Icons.flight_takeoff_rounded,
      heroColors: const [
        Color(0xFF092D43),
        Color(0xFF0A6070),
      ],
      details: [
        const SizedBox(height: 14),
        AdminSectionCard(
          icon: Icons.badge_outlined,
          title: 'Pilot Profile',
          subtitle: 'Professional details submitted by the pilot',
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Experience',
                value: profile.experienceLabel,
                icon: Icons.workspace_premium_outlined,
              ),
              AdminInfoRow(
                label: 'Nationality',
                value: profile.nationality,
                icon: Icons.flag_outlined,
              ),
              AdminInfoRow(
                label: 'Date of birth',
                value: adminDate(profile.dateOfBirth),
                icon: Icons.cake_outlined,
              ),
              AdminInfoRow(
                label: 'Languages',
                value: profile.languagesLabel,
                icon: Icons.language_rounded,
              ),
              AdminInfoRow(
                label: 'Previous company',
                value: profile.previousCompany,
                icon: Icons.business_outlined,
              ),
              AdminInfoRow(
                label: 'LinkedIn',
                value: profile.linkedinUrl,
                icon: Icons.link_rounded,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSectionCard(
          icon: Icons.location_on_outlined,
          title: 'Current Location',
          subtitle: profile.locationLabel,
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Country',
                value: profile.currentCountry,
              ),
              AdminInfoRow(
                label: 'State / Region',
                value: profile.currentState,
              ),
              AdminInfoRow(
                label: 'City',
                value: profile.currentCity,
                last: true,
              ),
            ],
          ),
        ),
        if (profile.bio.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          AdminSectionCard(
            icon: Icons.notes_rounded,
            title: 'Professional Summary',
            subtitle: 'Pilot-provided introduction',
            child: Text(
              profile.bio,
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 11.7,
                height: 1.65,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
