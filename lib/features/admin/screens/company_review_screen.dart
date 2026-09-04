import 'package:flutter/material.dart';

import '../models/admin_pending_company_model.dart';
import '../widgets/admin_ui.dart';

class CompanyReviewScreen
    extends StatelessWidget {
  const CompanyReviewScreen({
    super.key,
    required this.company,
  });

  final AdminPendingCompanyModel company;

  @override
  Widget build(
    BuildContext context,
  ) {
    final profile =
        company.profile;

    return Scaffold(
      backgroundColor:
          AdminPalette.bg,
      body:
          SafeArea(
        child:
            Column(
          children: [
            AdminPageHeader(
              title:
                  'Company Review',
              subtitle:
                  'Review account and organization details',
              leading:
                  AdminRoundButton(
                icon:
                    Icons.arrow_back_ios_new_rounded,
                onTap:
                    () => Navigator.pop(context),
              ),
            ),

            Expanded(
              child:
                  ListView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  4,
                  18,
                  34,
                ),
                children: [
                  _CompanyHero(
                    company:
                        company,
                  ),

                  const SizedBox(height: 14),

                  AdminSectionCard(
                    icon:
                        Icons.manage_accounts_outlined,
                    title:
                        'Account Information',
                    subtitle:
                        'Account owner and contact information',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Account name',
                          value:
                              company.name,
                          icon:
                              Icons.person_outline_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Username',
                          value:
                              company.displayUsername,
                          icon:
                              Icons.alternate_email_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Email',
                          value:
                              company.email,
                          icon:
                              Icons.mail_outline_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Phone',
                          value:
                              company.displayPhone,
                          icon:
                              Icons.phone_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Email verified',
                          value:
                              company.emailVerifiedAt == null
                                  ? 'No'
                                  : 'Yes',
                          icon:
                              Icons.mark_email_read_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Applied',
                          value:
                              AdminFormat.date(
                            company.createdAt,
                          ),
                          icon:
                              Icons.event_outlined,
                          last:
                              true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  AdminSectionCard(
                    icon:
                        Icons.apartment_rounded,
                    title:
                        'Company Profile',
                    subtitle:
                        'Organization information submitted for review',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Company name',
                          value:
                              profile.companyName,
                          icon:
                              Icons.business_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Industry',
                          value:
                              profile.industryType,
                          icon:
                              Icons.category_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Website',
                          value:
                              profile.website,
                          icon:
                              Icons.language_rounded,
                          last:
                              true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  AdminSectionCard(
                    icon:
                        Icons.location_on_outlined,
                    title:
                        'Business Location',
                    subtitle:
                        'Registered company address',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Country',
                          value:
                              profile.country,
                        ),
                        AdminInfoRow(
                          label:
                              'State / Region',
                          value:
                              profile.state,
                        ),
                        AdminInfoRow(
                          label:
                              'City',
                          value:
                              profile.city,
                        ),
                        AdminInfoRow(
                          label:
                              'Address',
                          value:
                              profile.address,
                          last:
                              true,
                        ),
                      ],
                    ),
                  ),

                  if (profile.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),

                    AdminSectionCard(
                      icon:
                          Icons.notes_rounded,
                      title:
                          'Company Description',
                      subtitle:
                          'Organization-provided summary',
                      child:
                          Text(
                        profile.description,
                        style:
                            const TextStyle(
                          color:
                              AdminPalette.muted,
                          fontSize:
                              11.7,
                          height:
                              1.65,
                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyHero extends StatelessWidget {
  const _CompanyHero({
    required this.company,
  });

  final AdminPendingCompanyModel company;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(
        18,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          27,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(
              0xFF322A63,
            ),
            Color(
              0xFF59489D,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminPalette.company
                    .withOpacity(
              0.16,
            ),
            blurRadius:
                26,
            offset:
                const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child:
          Row(
        children: [
          Container(
            padding:
                const EdgeInsets.all(
              3,
            ),
            decoration:
                const BoxDecoration(
              color:
                  Colors.white,
              shape:
                  BoxShape.circle,
            ),
            child:
                ClipOval(
              child:
                  Container(
                width:
                    68,
                height:
                    68,
                alignment:
                    Alignment.center,
                color:
                    AdminPalette.companySoft,
                child:
                    Text(
                  AdminFormat.initials(
                    company.displayCompanyName,
                    fallback:
                        'CO',
                  ),
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.company,
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  company.displayCompanyName,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        Colors.white,
                    fontSize:
                        18,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        -0.4,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  company.profile.industryLabel,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      TextStyle(
                    color:
                        Colors.white.withOpacity(
                      0.66,
                    ),
                    fontSize:
                        10.5,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 10),

                AdminStatusBadge(
                  status:
                      company.status,
                ),
              ],
            ),
          ),

          Container(
            width:
                42,
            height:
                42,
            decoration:
                BoxDecoration(
              color:
                  Colors.white.withOpacity(
                0.11,
              ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child:
                const Icon(
              Icons.apartment_rounded,
              color:
                  Color(
                0xFFD6CFFF,
              ),
              size:
                  20,
            ),
          ),
        ],
      ),
    );
  }
}
