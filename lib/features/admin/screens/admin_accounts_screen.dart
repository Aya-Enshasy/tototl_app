import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
 import '../models/admin_directory_entry.dart';
import '../widgets/admin_design.dart';
import 'company_review_screen.dart';
import 'pilot_review_screen.dart';

class AdminAccountsScreen extends StatefulWidget {
  const AdminAccountsScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;

  @override
  State<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState
    extends State<AdminAccountsScreen> {
  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';
  String _role = 'all';
  String _status = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminDirectoryEntry>
      get _visible {
    return widget.controller.knownAccounts
        .where(
          (entry) {
            if (_role == 'pilot' &&
                !entry.isPilot) {
              return false;
            }

            if (_role == 'company' &&
                !entry.isCompany) {
              return false;
            }

            if (_status != 'all') {
              if (_status == 'active') {
                if (!entry.user.isActive) {
                  return false;
                }
              } else if (
                  entry.user.normalizedStatus !=
                      _status) {
                return false;
              }
            }

            final query =
                _query.trim().toLowerCase();

            if (query.isEmpty) {
              return true;
            }

            return entry.searchableText.contains(
              query,
            );
          },
        )
        .toList();
  }

  Future<void> _open(
    AdminDirectoryEntry entry,
  ) async {
    if (entry.isPilot) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              PilotReviewScreen(
            controller:
                widget.controller,
            pilot:
                entry.pilot!,
          ),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CompanyReviewScreen(
            controller:
                widget.controller,
            company:
                entry.company!,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        const AdminPageTitle(
          title:
              'Accounts Directory',
          subtitle:
              'Browse pilots and companies by account status',
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
              _ScopeBanner(
            complete:
                widget.controller
                    .hasCompleteDirectoryApi,
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            0,
            18,
            9,
          ),
          child:
              AdminSearchField(
            controller:
                _searchController,
            hint:
                'Search account, email, username or location',
            onChanged:
                (value) {
              setState(() {
                _query =
                    value;
              });
            },
          ),
        ),

        SizedBox(
          height:
              42,
          child:
              ListView(
            scrollDirection:
                Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  18,
            ),
            children: [
              _FilterChip(
                label:
                    'All',
                selected:
                    _role == 'all',
                onTap:
                    () => setState(
                  () => _role = 'all',
                ),
              ),
              _FilterChip(
                label:
                    'Pilots',
                selected:
                    _role == 'pilot',
                onTap:
                    () => setState(
                  () => _role = 'pilot',
                ),
              ),
              _FilterChip(
                label:
                    'Companies',
                selected:
                    _role == 'company',
                onTap:
                    () => setState(
                  () => _role = 'company',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height:
              7,
        ),

        SizedBox(
          height:
              42,
          child:
              ListView(
            scrollDirection:
                Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  18,
            ),
            children: [
              _StatusChip(
                label:
                    'All Status',
                value:
                    'all',
                selected:
                    _status == 'all',
                onTap:
                    _setStatus,
              ),
              _StatusChip(
                label:
                    'Pending',
                value:
                    'pending',
                selected:
                    _status == 'pending',
                onTap:
                    _setStatus,
              ),
              _StatusChip(
                label:
                    'Active',
                value:
                    'active',
                selected:
                    _status == 'active',
                onTap:
                    _setStatus,
              ),
              _StatusChip(
                label:
                    'Suspended',
                value:
                    'suspended',
                selected:
                    _status == 'suspended',
                onTap:
                    _setStatus,
              ),
              _StatusChip(
                label:
                    'Rejected',
                value:
                    'rejected',
                selected:
                    _status == 'rejected',
                onTap:
                    _setStatus,
              ),
            ],
          ),
        ),

        const SizedBox(
          height:
              6,
        ),

        Expanded(
          child:
              RefreshIndicator(
            color:
                AdminColors.tealDark,
            onRefresh:
                widget.onRefresh,
            child:
                _visible.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          AdminEmptyState(
                            icon:
                                Icons.manage_search_rounded,
                            title:
                                'No accounts in this view',
                            message:
                                'Change the filters or search text to see other accounts.',
                          ),
                        ],
                      )
                    : ListView.separated(
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
                            _visible.length,
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
                          final entry =
                              _visible[index];

                          return _AccountCard(
                            entry:
                                entry,
                            onTap:
                                () => _open(
                              entry,
                            ),
                          );
                        },
                      ),
          ),
        ),
      ],
    );
  }

  void _setStatus(
    String value,
  ) {
    setState(() {
      _status =
          value;
    });
  }
}

class _ScopeBanner
    extends StatelessWidget {
  const _ScopeBanner({
    required this.complete,
  });

  final bool complete;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (complete) {
      return const SizedBox.shrink();
    }

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        13,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(
          0xFFFFF9E8,
        ),
        borderRadius:
            BorderRadius.circular(
          17,
        ),
        border:
            Border.all(
          color:
              const Color(
            0xFFFFE6A3,
          ),
        ),
      ),
      child:
          const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color:
                AdminColors.warning,
            size:
                18,
          ),
          SizedBox(
            width:
                9,
          ),
          Expanded(
            child:
                Text(
              'The supplied API currently lists pending accounts only. This directory also keeps accounts updated by this admin during the current session. Add the backend “all pilots / all companies” list endpoints to make this directory fully historical.',
              style:
                  TextStyle(
                color:
                    Color(
                  0xFF80621D,
                ),
                fontSize:
                    9.8,
                height:
                    1.45,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip
    extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        right:
            8,
      ),
      child:
          Material(
        color:
            selected
                ? AdminColors.navy
                : Colors.white,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        child:
            InkWell(
          onTap:
              onTap,
          borderRadius:
              BorderRadius.circular(
            30,
          ),
          child:
              Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  14,
              vertical:
                  9,
            ),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
              border:
                  Border.all(
                color:
                    selected
                        ? AdminColors.navy
                        : AdminColors.border,
              ),
            ),
            child:
                Text(
              label,
              style:
                  TextStyle(
                color:
                    selected
                        ? Colors.white
                        : AdminColors.muted,
                fontSize:
                    9.8,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip
    extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    Color color =
        AdminColors.tealDark;

    if (value == 'suspended') {
      color =
          AdminColors.warning;
    } else if (value == 'rejected') {
      color =
          AdminColors.danger;
    } else if (value == 'active') {
      color =
          AdminColors.success;
    }

    return Padding(
      padding:
          const EdgeInsets.only(
        right:
            8,
      ),
      child:
          Material(
        color:
            selected
                ? color.withOpacity(
                    0.10,
                  )
                : Colors.white,
        borderRadius:
            BorderRadius.circular(
          30,
        ),
        child:
            InkWell(
          onTap:
              () => onTap(
            value,
          ),
          borderRadius:
              BorderRadius.circular(
            30,
          ),
          child:
              Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal:
                  13,
              vertical:
                  9,
            ),
            decoration:
                BoxDecoration(
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
              border:
                  Border.all(
                color:
                    selected
                        ? color.withOpacity(
                            0.28,
                          )
                        : AdminColors.border,
              ),
            ),
            child:
                Text(
              label,
              style:
                  TextStyle(
                color:
                    selected
                        ? color
                        : AdminColors.muted,
                fontSize:
                    9.5,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountCard
    extends StatelessWidget {
  const _AccountCard({
    required this.entry,
    required this.onTap,
  });

  final AdminDirectoryEntry entry;
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
            borderRadius:
                BorderRadius.circular(
              23,
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
              AdminInitialAvatar(
                name:
                    entry.title,
                isCompany:
                    entry.isCompany,
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
                            entry.title,
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
                              entry.user.status,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                          5,
                    ),
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                8,
                            vertical:
                                4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                entry.isCompany
                                    ? AdminColors.companySoft
                                    : AdminColors.pilotSoft,
                            borderRadius:
                                BorderRadius.circular(
                              30,
                            ),
                          ),
                          child:
                              Text(
                            entry.roleLabel,
                            style:
                                TextStyle(
                              color:
                                  entry.isCompany
                                      ? AdminColors.company
                                      : AdminColors.pilot,
                              fontSize:
                                  8.5,
                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(
                          width:
                              7,
                        ),
                        Expanded(
                          child:
                              Text(
                            entry.user.displayUsername,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                const TextStyle(
                              color:
                                  AdminColors.muted,
                              fontSize:
                                  9.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height:
                          8,
                    ),
                    Text(
                      entry.subtitle,
                      maxLines:
                          1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        color:
                            AdminColors.muted2,
                        fontSize:
                            9.5,
                      ),
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
