import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_design.dart';
import 'company_review_screen.dart';
import 'pilot_review_screen.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;

  @override
  State<AdminReviewsScreen> createState() =>
      _AdminReviewsScreenState();
}

class _AdminReviewsScreenState
    extends State<AdminReviewsScreen> {
  final TextEditingController
      _searchController =
      TextEditingController();

  int _tab = 0;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPendingPilotModel>
      get _pilots {
    final query =
        _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.pendingPilots;
    }

    return widget.controller.pendingPilots
        .where(
          (item) =>
              item.searchableText.contains(
            query,
          ),
        )
        .toList();
  }

  List<AdminPendingCompanyModel>
      get _companies {
    final query =
        _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller
          .pendingCompanies;
    }

    return widget.controller.pendingCompanies
        .where(
          (item) =>
              item.searchableText.contains(
            query,
          ),
        )
        .toList();
  }

  Future<void> _openPilot(
    AdminPendingPilotModel pilot,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PilotReviewScreen(
          controller:
              widget.controller,
          pilot:
              pilot,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openCompany(
    AdminPendingCompanyModel company,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CompanyReviewScreen(
          controller:
              widget.controller,
          company:
              company,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final count =
        _tab == 0
            ? widget.controller
                .pendingPilotCount
            : widget.controller
                .pendingCompanyCount;

    return Column(
      children: [
        AdminPageTitle(
          title:
              'Review Center',
          subtitle:
              '$count pending ${_tab == 0 ? 'pilot' : 'company'} application${count == 1 ? '' : 's'}',
        ),

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            2,
            18,
            10,
          ),
          child:
              Container(
            padding:
                const EdgeInsets.all(
              5,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.white,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
              border:
                  Border.all(
                color:
                    AdminColors.border,
              ),
            ),
            child:
                Row(
              children: [
                Expanded(
                  child:
                      _Segment(
                    selected:
                        _tab == 0,
                    icon:
                        Icons.flight_takeoff_rounded,
                    label:
                        'Pilots',
                    badge:
                        widget.controller.pendingPilotCount,
                    onTap:
                        () {
                      setState(() {
                        _tab =
                            0;
                      });
                    },
                  ),
                ),
                const SizedBox(
                  width:
                      5,
                ),
                Expanded(
                  child:
                      _Segment(
                    selected:
                        _tab == 1,
                    icon:
                        Icons.apartment_rounded,
                    label:
                        'Companies',
                    badge:
                        widget.controller.pendingCompanyCount,
                    onTap:
                        () {
                      setState(() {
                        _tab =
                            1;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            8,
          ),
          child:
              AdminSearchField(
            controller:
                _searchController,
            hint:
                _tab == 0
                    ? 'Search pilot, email, username or location'
                    : 'Search company, owner, industry or location',
            onChanged:
                (value) {
              setState(() {
                _query =
                    value;
              });
            },
          ),
        ),

        Expanded(
          child:
              RefreshIndicator(
            color:
                AdminColors.tealDark,
            onRefresh:
                widget.onRefresh,
            child:
                _tab == 0
                    ? _PilotList(
                        items:
                            _pilots,
                        query:
                            _query,
                        onOpen:
                            _openPilot,
                      )
                    : _CompanyList(
                        items:
                            _companies,
                        query:
                            _query,
                        onOpen:
                            _openCompany,
                      ),
          ),
        ),
      ],
    );
  }
}

class _Segment
    extends StatelessWidget {
  const _Segment({
    required this.selected,
    required this.icon,
    required this.label,
    required this.badge,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color:
          selected
              ? AdminColors.tealSoft
              : Colors.transparent,
      borderRadius:
          BorderRadius.circular(
        14,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        child:
            Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical:
                10,
            horizontal:
                8,
          ),
          child:
              Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size:
                    16,
                color:
                    selected
                        ? AdminColors.tealDark
                        : AdminColors.muted,
              ),
              const SizedBox(
                width:
                    6,
              ),
              Text(
                label,
                style:
                    TextStyle(
                  color:
                      selected
                          ? AdminColors.tealDark
                          : AdminColors.muted,
                  fontSize:
                      10.5,
                  fontWeight:
                      selected
                          ? FontWeight.w900
                          : FontWeight.w700,
                ),
              ),
              const SizedBox(
                width:
                    6,
              ),
              Container(
                constraints:
                    const BoxConstraints(
                  minWidth:
                      20,
                  minHeight:
                      20,
                ),
                alignment:
                    Alignment.center,
                decoration:
                    BoxDecoration(
                  color:
                      selected
                          ? AdminColors.tealDark
                          : AdminColors.bg,
                  shape:
                      BoxShape.circle,
                ),
                child:
                    Text(
                  '$badge',
                  style:
                      TextStyle(
                    color:
                        selected
                            ? Colors.white
                            : AdminColors.muted,
                    fontSize:
                        8,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PilotList
    extends StatelessWidget {
  const _PilotList({
    required this.items,
    required this.query,
    required this.onOpen,
  });

  final List<AdminPendingPilotModel>
      items;

  final String query;

  final ValueChanged<
      AdminPendingPilotModel> onOpen;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (items.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          AdminEmptyState(
            icon:
                query.trim().isEmpty
                    ? Icons.verified_user_outlined
                    : Icons.search_off_rounded,
            title:
                query.trim().isEmpty
                    ? 'Pilot queue is clear'
                    : 'No matching pilots',
            message:
                query.trim().isEmpty
                    ? 'New pilot applications will appear here for admin review.'
                    : 'Try a different search.',
          ),
        ],
      );
    }

    return ListView.separated(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(
        parent:
            BouncingScrollPhysics(),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        34,
      ),
      itemCount:
          items.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height:
            11,
      ),
      itemBuilder:
          (
        context,
        index,
      ) {
        final pilot =
            items[index];

        return _ReviewCard(
          name:
              pilot.user.displayName,
          subtitle:
              pilot.user.displayUsername,
          meta:
              pilot.profile.locationLabel,
          status:
              pilot.user.status,
          isCompany:
              false,
          onTap:
              () => onOpen(
            pilot,
          ),
        );
      },
    );
  }
}

class _CompanyList
    extends StatelessWidget {
  const _CompanyList({
    required this.items,
    required this.query,
    required this.onOpen,
  });

  final List<AdminPendingCompanyModel>
      items;

  final String query;

  final ValueChanged<
      AdminPendingCompanyModel> onOpen;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (items.isEmpty) {
      return ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        children: [
          AdminEmptyState(
            icon:
                query.trim().isEmpty
                    ? Icons.domain_verification_outlined
                    : Icons.search_off_rounded,
            title:
                query.trim().isEmpty
                    ? 'Company queue is clear'
                    : 'No matching companies',
            message:
                query.trim().isEmpty
                    ? 'New company applications will appear here for admin review.'
                    : 'Try a different search.',
          ),
        ],
      );
    }

    return ListView.separated(
      keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
      physics:
          const AlwaysScrollableScrollPhysics(
        parent:
            BouncingScrollPhysics(),
      ),
      padding:
          const EdgeInsets.fromLTRB(
        18,
        8,
        18,
        34,
      ),
      itemCount:
          items.length,
      separatorBuilder:
          (_, __) =>
              const SizedBox(
        height:
            11,
      ),
      itemBuilder:
          (
        context,
        index,
      ) {
        final company =
            items[index];

        return _ReviewCard(
          name:
              company.displayCompanyName,
          subtitle:
              company.profile.industryType.trim().isEmpty
                  ? company.user.displayUsername
                  : company.profile.industryType,
          meta:
              company.profile.locationLabel,
          status:
              company.user.status,
          isCompany:
              true,
          onTap:
              () => onOpen(
            company,
          ),
        );
      },
    );
  }
}

class _ReviewCard
    extends StatelessWidget {
  const _ReviewCard({
    required this.name,
    required this.subtitle,
    required this.meta,
    required this.status,
    required this.isCompany,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String meta;
  final String status;
  final bool isCompany;
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
        23,
      ),
      child:
          InkWell(
        onTap:
            onTap,
        borderRadius:
            BorderRadius.circular(
          23,
        ),
        child:
            Container(
          padding:
              const EdgeInsets.all(
            14,
          ),
          decoration:
              BoxDecoration(
            border:
                Border.all(
              color:
                  AdminColors.border,
            ),
            borderRadius:
                BorderRadius.circular(
              23,
            ),
          ),
          child:
              Row(
            children: [
              AdminInitialAvatar(
                name:
                    name,
                isCompany:
                    isCompany,
              ),
              const SizedBox(
                width:
                    12,
              ),
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
                            name,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  AdminColors.ink,
                              fontSize:
                                  13.5,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width:
                              7,
                        ),
                        AdminStatusBadge(
                          status:
                              status,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                          5,
                    ),
                    Text(
                      subtitle,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          TextStyle(
                        color:
                            isCompany
                                ? AdminColors.company
                                : AdminColors.tealDark,
                        fontSize:
                            10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size:
                              13,
                          color:
                              AdminColors.muted2,
                        ),
                        const SizedBox(
                          width:
                              5,
                        ),
                        Expanded(
                          child:
                              Text(
                            meta,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  AdminColors.muted,
                              fontSize:
                                  9.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width:
                    7,
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color:
                    AdminColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
