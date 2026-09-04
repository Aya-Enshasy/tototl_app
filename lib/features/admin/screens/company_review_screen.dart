import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../widgets/admin_design.dart';
import 'admin_user_review_screen.dart';

class CompanyReviewScreen extends StatelessWidget {
  const CompanyReviewScreen({
    super.key,
    required this.controller,
    required this.company,
  });

  final AdminController controller;
  final AdminPendingCompanyModel company;

  @override
  Widget build(BuildContext context) {
    final profile = company.profile;

    return AdminUserReviewScreen(
      controller: controller,
      initialUser: company.user,
      typeLabel: 'Company',
      heroTitle: company.displayCompanyName,
      heroSubtitle:
          '${profile.industryType.trim().isEmpty ? 'Industry not provided' : profile.industryType} • ${profile.locationLabel}',
      heroIcon: Icons.apartment_rounded,
      heroColors: const [
        Color(0xFF322A63),
        Color(0xFF6754B0),
      ],
      isCompany: true,
      details: [
        const SizedBox(height: 14),
        AdminSectionCard(
          icon: Icons.apartment_rounded,
          title: 'Company Profile',
          subtitle: 'Organization information submitted for review',
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Company name',
                value: profile.companyName,
                icon: Icons.business_outlined,
              ),
              AdminInfoRow(
                label: 'Industry',
                value: profile.industryType,
                icon: Icons.category_outlined,
              ),
              AdminInfoRow(
                label: 'Website',
                value: profile.website,
                icon: Icons.language_rounded,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AdminSectionCard(
          icon: Icons.location_on_outlined,
          title: 'Business Location',
          subtitle: profile.locationLabel,
          child: Column(
            children: [
              AdminInfoRow(
                label: 'Country',
                value: profile.country,
              ),
              AdminInfoRow(
                label: 'State / Region',
                value: profile.state,
              ),
              AdminInfoRow(
                label: 'City',
                value: profile.city,
              ),
              AdminInfoRow(
                label: 'Address',
                value: profile.address,
                last: true,
              ),
            ],
          ),
        ),
        if (profile.description.trim().isNotEmpty) ...[
          const SizedBox(height: 14),
          AdminSectionCard(
            icon: Icons.notes_rounded,
            title: 'Company Description',
            subtitle: 'Organization-provided summary',
            child: Text(
              profile.description,
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
