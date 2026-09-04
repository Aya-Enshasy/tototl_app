import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_ui.dart';

// ============================================================================
// ADMIN DASHBOARD
// ============================================================================

class AdminDashboardScreen
    extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
    required this.onOpenPilots,
    required this.onOpenCompanies,
    required this.onOpenPilot,
    required this.onOpenCompany,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;
  final VoidCallback onOpenPilots;
  final VoidCallback onOpenCompanies;

  final ValueChanged<AdminPendingPilotModel>
      onOpenPilot;

  final ValueChanged<AdminPendingCompanyModel>
      onOpenCompany;

  @override
  Widget build(
    BuildContext context,
  ) {
    return RefreshIndicator(
      color:
          AdminPalette.tealDark,
      onRefresh:
          onRefresh,
      child:
          CustomScrollView(
        physics:
            const AlwaysScrollableScrollPhysics(
          parent:
              BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              0,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _DashboardHero(
                total:
                    controller.totalPending,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              0,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _Stats(
                controller:
                    controller,
                onOpenPilots:
                    onOpenPilots,
                onOpenCompanies:
                    onOpenCompanies,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              0,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _SectionTitle(
                title:
                    'Pilot Reviews',
                subtitle:
                    '${controller.pendingPilotCount} waiting',
                actionLabel:
                    controller.pendingPilotCount > 3
                        ? 'View all'
                        : null,
                onAction:
                    controller.pendingPilotCount > 3
                        ? onOpenPilots
                        : null,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              0,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _PilotPreview(
                controller:
                    controller,
                onOpen:
                    onOpenPilot,
                onRetry:
                    onRefresh,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              20,
              18,
              0,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _SectionTitle(
                title:
                    'Company Reviews',
                subtitle:
                    '${controller.pendingCompanyCount} waiting',
                actionLabel:
                    controller.pendingCompanyCount > 3
                        ? 'View all'
                        : null,
                onAction:
                    controller.pendingCompanyCount > 3
                        ? onOpenCompanies
                        : null,
              ),
            ),
          ),

          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              36,
            ),
            sliver:
                SliverToBoxAdapter(
              child:
                  _CompanyPreview(
                controller:
                    controller,
                onOpen:
                    onOpenCompany,
                onRetry:
                    onRefresh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HERO
// ============================================================================

class _DashboardHero
    extends StatelessWidget {
  const _DashboardHero({
    required this.total,
  });

  final int total;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      constraints:
          const BoxConstraints(
        minHeight:
            178,
      ),
      padding:
          const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          28,
        ),
        gradient:
            const LinearGradient(
          begin:
              Alignment.topLeft,
          end:
              Alignment.bottomRight,
          colors: [
            Color(
              0xFF092D43,
            ),
            Color(
              0xFF0A5365,
            ),
            Color(
              0xFF0C7180,
            ),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
                AdminPalette.navy
                    .withOpacity(
              0.18,
            ),
            blurRadius:
                30,
            offset:
                const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child:
          Stack(
        children: [
          Positioned(
            right:
                -20,
            top:
                -24,
            child:
                Container(
              width:
                  130,
              height:
                  130,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    Colors.white
                        .withOpacity(
                  0.055,
                ),
              ),
            ),
          ),

          Positioned(
            right:
                42,
            bottom:
                -50,
            child:
                Container(
              width:
                  120,
              height:
                  120,
              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,
                color:
                    AdminPalette.teal
                        .withOpacity(
                  0.10,
                ),
              ),
            ),
          ),

          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal:
                            10,
                        vertical:
                            6,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.white
                                .withOpacity(
                          0.11,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                      child:
                          const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_rounded,
                            color:
                                Color(
                              0xFF8DE9E8,
                            ),
                            size:
                                15,
                          ),
                          SizedBox(
                            width:
                                6,
                          ),
                          Text(
                            'ADMIN CONTROL CENTER',
                            style:
                                TextStyle(
                              color:
                                  Color(
                                0xFFC9FAF8,
                              ),
                              fontSize:
                                  8.5,
                              fontWeight:
                                  FontWeight.w900,
                              letterSpacing:
                                  0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height:
                          15,
                    ),

                    const Text(
                      'Review with confidence.',
                      style:
                          TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            23,
                        height:
                            1.05,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing:
                            -0.7,
                      ),
                    ),

                    const SizedBox(
                      height:
                          7,
                    ),

                    Text(
                      total == 0
                          ? 'Your verification queue is clear.'
                          : '$total account${total == 1 ? '' : 's'} waiting for review.',
                      style:
                          TextStyle(
                        color:
                            Colors.white
                                .withOpacity(
                          0.72,
                        ),
                        fontSize:
                            11,
                        height:
                            1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width:
                    72,
                height:
                    72,
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white
                          .withOpacity(
                    0.11,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    23,
                  ),
                  border:
                      Border.all(
                    color:
                        Colors.white
                            .withOpacity(
                      0.10,
                    ),
                  ),
                ),
                child:
                    Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            25,
                        height:
                            1,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height:
                          5,
                    ),
                    Text(
                      'Pending',
                      style:
                          TextStyle(
                        color:
                            Colors.white
                                .withOpacity(
                          0.62,
                        ),
                        fontSize:
                            8.5,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATS
// ============================================================================

class _Stats extends StatelessWidget {
  const _Stats({
    required this.controller,
    required this.onOpenPilots,
    required this.onOpenCompanies,
  });

  final AdminController controller;
  final VoidCallback onOpenPilots;
  final VoidCallback onOpenCompanies;

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final compact =
            constraints.maxWidth <
                350;

        final gap =
            compact ? 8.0 : 10.0;

        return SizedBox(
          height:
              compact ? 112 : 120,
          child:
              Row(
            children: [
              Expanded(
                child:
                    AdminStatCard(
                  icon:
                      Icons.flight_takeoff_rounded,
                  value:
                      '${controller.pendingPilotCount}',
                  label:
                      'Pending Pilots',
                  foreground:
                      AdminPalette.pilot,
                  background:
                      AdminPalette.pilotSoft,
                  onTap:
                      onOpenPilots,
                ),
              ),
              SizedBox(
                width:
                    gap,
              ),
              Expanded(
                child:
                    AdminStatCard(
                  icon:
                      Icons.apartment_rounded,
                  value:
                      '${controller.pendingCompanyCount}',
                  label:
                      'Companies',
                  foreground:
                      AdminPalette.company,
                  background:
                      AdminPalette.companySoft,
                  onTap:
                      onOpenCompanies,
                ),
              ),
              SizedBox(
                width:
                    gap,
              ),
              Expanded(
                child:
                    AdminStatCard(
                  icon:
                      Icons.fact_check_outlined,
                  value:
                      '${controller.totalPending}',
                  label:
                      'Total Reviews',
                  foreground:
                      AdminPalette.tealDark,
                  background:
                      AdminPalette.tealSoft,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// SECTION TITLE
// ============================================================================

class _SectionTitle
    extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
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
                      16,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(
                height:
                    2,
              ),
              Text(
                subtitle,
                style:
                    const TextStyle(
                  color:
                      AdminPalette.muted,
                  fontSize:
                      9.5,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null &&
            onAction != null)
          TextButton(
            onPressed:
                onAction,
            style:
                TextButton.styleFrom(
              foregroundColor:
                  AdminPalette.tealDark,
            ),
            child:
                Text(
              actionLabel!,
              style:
                  const TextStyle(
                fontSize:
                    10.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// PILOT PREVIEW
// ============================================================================

class _PilotPreview
    extends StatelessWidget {
  const _PilotPreview({
    required this.controller,
    required this.onOpen,
    required this.onRetry,
  });

  final AdminController controller;

  final ValueChanged<AdminPendingPilotModel>
      onOpen;

  final Future<void> Function() onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (controller.pilotsError != null &&
        controller.pendingPilots.isEmpty) {
      return AdminEmptyState(
        icon:
            Icons.cloud_off_rounded,
        title:
            'Pilots unavailable',
        message:
            controller.pilotsError!,
        actionLabel:
            'Retry',
        onAction:
            () {
          onRetry();
        },
      );
    }

    if (controller.pendingPilots.isEmpty) {
      return const AdminEmptyState(
        icon:
            Icons.verified_user_outlined,
        title:
            'No pilots waiting',
        message:
            'New pilot applications will appear here when they need admin review.',
      );
    }

    final visible =
        controller.pendingPilots
            .take(
              3,
            )
            .toList();

    return Column(
      children: [
        for (var i = 0;
            i < visible.length;
            i++) ...[
          AdminPilotQueueCard(
            pilot:
                visible[i],
            onTap:
                () => onOpen(
              visible[i],
            ),
            compact:
                true,
          ),
          if (i !=
              visible.length - 1)
            const SizedBox(
              height:
                  10,
            ),
        ],
      ],
    );
  }
}

// ============================================================================
// COMPANY PREVIEW
// ============================================================================

class _CompanyPreview
    extends StatelessWidget {
  const _CompanyPreview({
    required this.controller,
    required this.onOpen,
    required this.onRetry,
  });

  final AdminController controller;

  final ValueChanged<AdminPendingCompanyModel>
      onOpen;

  final Future<void> Function() onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (controller.companiesError != null &&
        controller.pendingCompanies.isEmpty) {
      return AdminEmptyState(
        icon:
            Icons.cloud_off_rounded,
        title:
            'Companies unavailable',
        message:
            controller.companiesError!,
        actionLabel:
            'Retry',
        onAction:
            () {
          onRetry();
        },
      );
    }

    if (controller.pendingCompanies.isEmpty) {
      return const AdminEmptyState(
        icon:
            Icons.domain_verification_outlined,
        title:
            'No companies waiting',
        message:
            'New company applications will appear here when they need admin review.',
      );
    }

    final visible =
        controller.pendingCompanies
            .take(
              3,
            )
            .toList();

    return Column(
      children: [
        for (var i = 0;
            i < visible.length;
            i++) ...[
          AdminCompanyQueueCard(
            company:
                visible[i],
            onTap:
                () => onOpen(
              visible[i],
            ),
            compact:
                true,
          ),
          if (i !=
              visible.length - 1)
            const SizedBox(
              height:
                  10,
            ),
        ],
      ],
    );
  }
}
