import 'package:flutter/material.dart';

import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';

// ============================================================================
// ADMIN PALETTE
// ============================================================================

class AdminPalette {
  AdminPalette._();

  static const Color bg =
      Color(0xFFF5F7FA);

  static const Color surface =
      Colors.white;

  static const Color ink =
      Color(0xFF071A35);

  static const Color navy =
      Color(0xFF0B2F46);

  static const Color navy2 =
      Color(0xFF0B5365);

  static const Color teal =
      Color(0xFF0FA6B4);

  static const Color tealDark =
      Color(0xFF078B98);

  static const Color tealSoft =
      Color(0xFFEAF9FA);

  static const Color muted =
      Color(0xFF66778C);

  static const Color muted2 =
      Color(0xFF98A6B4);

  static const Color border =
      Color(0xFFE4EAF0);

  static const Color warning =
      Color(0xFFB97800);

  static const Color warningSoft =
      Color(0xFFFFF6DF);

  static const Color danger =
      Color(0xFFE45252);

  static const Color dangerSoft =
      Color(0xFFFFEEEE);

  static const Color pilot =
      Color(0xFF1777D2);

  static const Color pilotSoft =
      Color(0xFFEAF4FE);

  static const Color company =
      Color(0xFF6B56CF);

  static const Color companySoft =
      Color(0xFFF2EFFF);
}

// ============================================================================
// FORMAT
// ============================================================================

class AdminFormat {
  AdminFormat._();

  static String date(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Not available';
    }

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static String initials(
    String value, {
    String fallback = 'A',
  }) {
    final words = value
        .trim()
        .split(
          RegExp(r'\s+'),
        )
        .where(
          (item) => item.isNotEmpty,
        )
        .toList();

    if (words.isEmpty) {
      return fallback;
    }

    if (words.length == 1) {
      final word = words.first;
      return word
          .substring(
            0,
            word.length >= 2 ? 2 : 1,
          )
          .toUpperCase();
    }

    return '${words.first[0]}${words.last[0]}'
        .toUpperCase();
  }

  static String clean(
    String value, {
    String fallback = 'Not provided',
  }) {
    final text = value.trim();
    return text.isEmpty ? fallback : text;
  }

  static String status(
    String value,
  ) {
    final clean =
        value.trim().toLowerCase();

    switch (clean) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
      case 'verified':
      case 'active':
        return 'Verified';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return clean.isEmpty
            ? 'Unknown'
            : value.trim();
    }
  }
}

// ============================================================================
// PAGE TITLE
// ============================================================================

class AdminPageHeader
    extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        10,
      ),
      child:
          Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.ink,
                    fontSize:
                        21,
                    height:
                        1,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.muted,
                    fontSize:
                        10.5,
                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// ROUND ICON BUTTON
// ============================================================================

class AdminRoundButton
    extends StatelessWidget {
  const AdminRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor =
        AdminPalette.ink,
    this.backgroundColor =
        Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final Color backgroundColor;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          backgroundColor,
      shape:
          const CircleBorder(),
      child:
          InkWell(
        onTap:
            onTap,
        customBorder:
            const CircleBorder(),
        child:
            SizedBox(
          width:
              42,
          height:
              42,
          child:
              Icon(
            icon,
            color:
                iconColor,
            size:
                18,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class AdminStatusBadge
    extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(
    BuildContext context,
  ) {
    final clean =
        status.trim().toLowerCase();

    Color foreground =
        AdminPalette.warning;

    Color background =
        AdminPalette.warningSoft;

    IconData icon =
        Icons.schedule_rounded;

    if (clean == 'approved' ||
        clean == 'verified' ||
        clean == 'active') {
      foreground =
          AdminPalette.tealDark;
      background =
          AdminPalette.tealSoft;
      icon =
          Icons.verified_rounded;
    } else if (clean == 'rejected' ||
        clean == 'suspended') {
      foreground =
          AdminPalette.danger;
      background =
          AdminPalette.dangerSoft;
      icon =
          Icons.cancel_outlined;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            9,
        vertical:
            6,
      ),
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
      ),
      child:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                foreground,
            size:
                13,
          ),
          const SizedBox(width: 5),
          Text(
            AdminFormat.status(
              status,
            ),
            style:
                TextStyle(
              color:
                  foreground,
              fontSize:
                  9.5,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INITIAL AVATAR
// ============================================================================

class AdminInitialAvatar
    extends StatelessWidget {
  const AdminInitialAvatar({
    super.key,
    required this.text,
    this.isCompany = false,
    this.size = 50,
  });

  final String text;
  final bool isCompany;
  final double size;

  @override
  Widget build(
    BuildContext context,
  ) {
    final foreground =
        isCompany
            ? AdminPalette.company
            : AdminPalette.pilot;

    final background =
        isCompany
            ? AdminPalette.companySoft
            : AdminPalette.pilotSoft;

    return Container(
      width:
          size,
      height:
          size,
      alignment:
          Alignment.center,
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          size * 0.34,
        ),
      ),
      child:
          Text(
        AdminFormat.initials(
          text,
          fallback:
              isCompany ? 'CO' : 'P',
        ),
        style:
            TextStyle(
          color:
              foreground,
          fontSize:
              size * 0.32,
          fontWeight:
              FontWeight.w900,
          letterSpacing:
              -0.6,
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class AdminStatCard
    extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.foreground,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child:
            Container(
          constraints:
              const BoxConstraints(
            minHeight:
                120,
          ),
          padding:
              const EdgeInsets.fromLTRB(
            12,
            14,
            12,
            13,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  AdminPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    AdminPalette.ink
                        .withOpacity(0.035),
                blurRadius:
                    18,
                offset:
                    const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width:
                    38,
                height:
                    38,
                decoration:
                    BoxDecoration(
                  color:
                      background,
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      foreground,
                  size:
                      19,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style:
                    const TextStyle(
                  color:
                      AdminPalette.ink,
                  fontSize:
                      24,
                  height:
                      1,
                  fontWeight:
                      FontWeight.w900,
                  letterSpacing:
                      -0.8,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines:
                    1,
                overflow:
                    TextOverflow.ellipsis,
                style:
                    const TextStyle(
                  color:
                      AdminPalette.muted,
                  fontSize:
                      9.5,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION CARD
// ============================================================================

class AdminSectionCard
    extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        16,
      ),
      decoration:
          BoxDecoration(
        color:
            Colors.white,
        borderRadius:
            BorderRadius.circular(
          24,
        ),
        border:
            Border.all(
          color:
              AdminPalette.border,
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminPalette.ink
                    .withOpacity(
              0.035,
            ),
            blurRadius:
                18,
            offset:
                const Offset(
              0,
              7,
            ),
          ),
        ],
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width:
                    42,
                height:
                    42,
                decoration:
                    BoxDecoration(
                  color:
                      AdminPalette.tealSoft,
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child:
                    Icon(
                  icon,
                  color:
                      AdminPalette.tealDark,
                  size:
                      19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color:
                            AdminPalette.ink,
                        fontSize:
                            14.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style:
                            const TextStyle(
                          color:
                              AdminPalette.muted,
                          fontSize:
                              9.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class AdminInfoRow
    extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.last = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool last;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                10,
          ),
          child:
              Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color:
                      AdminPalette.tealDark,
                  size:
                      16,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child:
                    Text(
                  label,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.muted,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                flex:
                    2,
                child:
                    Text(
                  AdminFormat.clean(
                    value,
                  ),
                  textAlign:
                      TextAlign.right,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.ink,
                    fontSize:
                        11.5,
                    height:
                        1.35,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(
            height:
                1,
            color:
                AdminPalette.border,
          ),
      ],
    );
  }
}

// ============================================================================
// SEARCH FIELD
// ============================================================================

class AdminSearchField
    extends StatelessWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller:
          controller,
      onChanged:
          onChanged,
      textInputAction:
          TextInputAction.search,
      style:
          const TextStyle(
        color:
            AdminPalette.ink,
        fontSize:
            12,
        fontWeight:
            FontWeight.w600,
      ),
      decoration:
          InputDecoration(
        hintText:
            hint,
        hintStyle:
            const TextStyle(
          color:
              AdminPalette.muted2,
          fontSize:
              11.5,
        ),
        prefixIcon:
            const Icon(
          Icons.search_rounded,
          color:
              AdminPalette.tealDark,
          size:
              19,
        ),
        suffixIcon:
            controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                    icon:
                        const Icon(
                      Icons.close_rounded,
                      size:
                          17,
                    ),
                  ),
        filled:
            true,
        fillColor:
            Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          vertical:
              13,
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
                AdminPalette.border,
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
                AdminPalette.teal,
            width:
                1.2,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// PILOT QUEUE CARD
// ============================================================================

class AdminPilotQueueCard
    extends StatelessWidget {
  const AdminPilotQueueCard({
    super.key,
    required this.pilot,
    required this.onTap,
    this.compact = false,
  });

  final AdminPendingPilotModel pilot;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _QueueCardShell(
      onTap:
          onTap,
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          AdminInitialAvatar(
            text:
                pilot.displayName,
            size:
                compact ? 46 : 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(
                        pilot.displayName,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AdminPalette.ink,
                          fontSize:
                              13.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    AdminStatusBadge(
                      status:
                          pilot.status,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pilot.displayUsername,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.tealDark,
                    fontSize:
                        10.2,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                _QueueMeta(
                  icon:
                      Icons.badge_outlined,
                  text:
                      pilot.profile.experienceLabel,
                ),
                const SizedBox(height: 5),
                _QueueMeta(
                  icon:
                      Icons.location_on_outlined,
                  text:
                      pilot.profile.locationLabel,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding:
                EdgeInsets.only(
              top:
                  32,
            ),
            child:
                Icon(
              Icons.chevron_right_rounded,
              color:
                  AdminPalette.muted2,
              size:
                  21,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPANY QUEUE CARD
// ============================================================================

class AdminCompanyQueueCard
    extends StatelessWidget {
  const AdminCompanyQueueCard({
    super.key,
    required this.company,
    required this.onTap,
    this.compact = false,
  });

  final AdminPendingCompanyModel company;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _QueueCardShell(
      onTap:
          onTap,
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          AdminInitialAvatar(
            text:
                company.displayCompanyName,
            isCompany:
                true,
            size:
                compact ? 46 : 52,
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          Text(
                        company.displayCompanyName,
                        maxLines:
                            1,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          color:
                              AdminPalette.ink,
                          fontSize:
                              13.5,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    AdminStatusBadge(
                      status:
                          company.status,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  company.profile.industryLabel,
                  maxLines:
                      1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    color:
                        AdminPalette.company,
                    fontSize:
                        10.2,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                _QueueMeta(
                  icon:
                      Icons.person_outline_rounded,
                  text:
                      company.name.trim().isEmpty
                          ? 'Account owner not provided'
                          : company.name,
                ),
                const SizedBox(height: 5),
                _QueueMeta(
                  icon:
                      Icons.location_on_outlined,
                  text:
                      company.profile.locationLabel,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Padding(
            padding:
                EdgeInsets.only(
              top:
                  32,
            ),
            child:
                Icon(
              Icons.chevron_right_rounded,
              color:
                  AdminPalette.muted2,
              size:
                  21,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueCardShell
    extends StatelessWidget {
  const _QueueCardShell({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          Colors.white,
      borderRadius:
          BorderRadius.circular(
        22,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            borderRadius:
                BorderRadius.circular(
              22,
            ),
            border:
                Border.all(
              color:
                  AdminPalette.border,
            ),
          ),
          child:
              child,
        ),
      ),
    );
  }
}

class _QueueMeta
    extends StatelessWidget {
  const _QueueMeta({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color:
              AdminPalette.muted2,
          size:
              13,
        ),
        const SizedBox(width: 5),
        Expanded(
          child:
              Text(
            text,
            maxLines:
                1,
            overflow:
                TextOverflow.ellipsis,
            style:
                const TextStyle(
              color:
                  AdminPalette.muted,
              fontSize:
                  9.7,
              fontWeight:
                  FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// EMPTY / ERROR
// ============================================================================

class AdminEmptyState
    extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        26,
        70,
        26,
        30,
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width:
                76,
            height:
                76,
            decoration:
                const BoxDecoration(
              color:
                  AdminPalette.tealSoft,
              shape:
                  BoxShape.circle,
            ),
            child:
                Icon(
              icon,
              color:
                  AdminPalette.tealDark,
              size:
                  32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AdminPalette.ink,
              fontSize:
                  18,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AdminPalette.muted,
              fontSize:
                  11.5,
              height:
                  1.5,
            ),
          ),
          if (actionLabel != null &&
              onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed:
                  onAction,
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    AdminPalette.tealDark,
                foregroundColor:
                    Colors.white,
              ),
              icon:
                  const Icon(
                Icons.refresh_rounded,
                size:
                    17,
              ),
              label:
                  Text(
                actionLabel!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminListSkeleton
    extends StatelessWidget {
  const AdminListSkeleton({
    super.key,
    this.items = 5,
  });

  final int items;

  @override
  Widget build(
    BuildContext context,
  ) {
    return ListView.separated(
      physics:
          const NeverScrollableScrollPhysics(),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        30,
      ),
      itemCount:
          items,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height:
            12,
      ),
      itemBuilder:
          (_, __) =>
              Container(
        height:
            112,
        decoration:
            BoxDecoration(
          color:
              const Color(
            0xFFEDF2F5,
          ),
          borderRadius:
              BorderRadius.circular(
            22,
          ),
        ),
      ),
    );
  }
}
