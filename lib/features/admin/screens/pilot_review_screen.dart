import 'package:flutter/material.dart';

import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_ui.dart';

class PilotReviewScreen
    extends StatelessWidget {
  const PilotReviewScreen({
    super.key,
    required this.pilot,
  });

  final AdminPendingPilotModel pilot;

  @override
  Widget build(
    BuildContext context,
  ) {
    final profile =
        pilot.profile;

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
                  'Pilot Review',
              subtitle:
                  'Review account and professional details',
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
                  _PilotHero(
                    pilot:
                        pilot,
                  ),

                  const SizedBox(height: 14),

                  AdminSectionCard(
                    icon:
                        Icons.manage_accounts_outlined,
                    title:
                        'Account Information',
                    subtitle:
                        'Core identity and contact details',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Full name',
                          value:
                              pilot.name,
                          icon:
                              Icons.person_outline_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Username',
                          value:
                              pilot.displayUsername,
                          icon:
                              Icons.alternate_email_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Email',
                          value:
                              pilot.email,
                          icon:
                              Icons.mail_outline_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Phone',
                          value:
                              pilot.displayPhone,
                          icon:
                              Icons.phone_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Email verified',
                          value:
                              pilot.emailVerifiedAt == null
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
                            pilot.createdAt,
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
                        Icons.badge_outlined,
                    title:
                        'Pilot Profile',
                    subtitle:
                        'Professional background submitted by the pilot',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Experience',
                          value:
                              profile.experienceLabel,
                          icon:
                              Icons.workspace_premium_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Nationality',
                          value:
                              profile.nationality,
                          icon:
                              Icons.flag_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Date of birth',
                          value:
                              AdminFormat.date(
                            profile.dateOfBirth,
                          ),
                          icon:
                              Icons.cake_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'Languages',
                          value:
                              profile.languagesLabel,
                          icon:
                              Icons.language_rounded,
                        ),
                        AdminInfoRow(
                          label:
                              'Previous company',
                          value:
                              profile.previousCompany,
                          icon:
                              Icons.business_outlined,
                        ),
                        AdminInfoRow(
                          label:
                              'LinkedIn',
                          value:
                              profile.linkedinUrl,
                          icon:
                              Icons.link_rounded,
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
                        'Current Location',
                    subtitle:
                        'Location registered on the pilot profile',
                    child:
                        Column(
                      children: [
                        AdminInfoRow(
                          label:
                              'Country',
                          value:
                              profile.currentCountry,
                        ),
                        AdminInfoRow(
                          label:
                              'State / Region',
                          value:
                              profile.currentState,
                        ),
                        AdminInfoRow(
                          label:
                              'City',
                          value:
                              profile.currentCity,
                          last:
                              true,
                        ),
                      ],
                    ),
                  ),

                  if (profile.bio.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),

                    AdminSectionCard(
                      icon:
                          Icons.notes_rounded,
                      title:
                          'Professional Summary',
                      subtitle:
                          'Pilot-provided introduction',
                      child:
                          Text(
                        profile.bio,
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

class _PilotHero extends StatelessWidget {
  const _PilotHero({
    required this.pilot,
  });

  final AdminPendingPilotModel pilot;

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
              0xFF0A3550,
            ),
            Color(
              0xFF0A6673,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminPalette.navy
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
                    AdminPalette.pilotSoft,
                child:
                    Text(
                  AdminFormat.initials(
                    pilot.displayName,
                    fallback:
                        'P',
                  ),
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.pilot,
                    fontSize:
                        21,
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
                  pilot.displayName,
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
                  pilot.displayUsername,
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
                      pilot.status,
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
              Icons.flight_takeoff_rounded,
              color:
                  Color(
                0xFF8DE9E8,
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
