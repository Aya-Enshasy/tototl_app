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

            if (_status != 'all' &&
                entry.effectiveStatus !=
                    _status) {
              return false;
            }

            final query =
                _query.trim().toLowerCase();

            if (query.isEmpty) {
              return true;
            }

            final extraHistoryText =
                entry.verificationHistory
                    .map(
                      (item) =>
                          '${item.action} ${item.reason}',
                    )
                    .join(' ')
                    .toLowerCase();

            return entry.searchableText.contains(
                  query,
                ) ||
                extraHistoryText.contains(
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminPageTitle(
          title:
              'Accounts Directory',
          subtitle:
              '${widget.controller.knownAccounts.length} known account${widget.controller.knownAccounts.length == 1 ? '' : 's'} • classified by verification history',
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
              _StatusSummary(
            controller:
                widget.controller,
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
                'Search account, email, username, reason or location',
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
                    'Approved',
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
                () async {
              await widget.onRefresh();

              if (mounted) {
                setState(() {});
              }
            },
            child:
                _visible.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          AdminEmptyState(
                            icon:
                                Icons.manage_search_rounded,
                            title:
                                'No accounts in this status',
                            message:
                                _status == 'all'
                                    ? 'Change the role filter or search text.'
                                    : 'No known ${_status == 'active' ? 'approved' : _status} accounts match the current filters.',
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

class _StatusSummary
    extends StatelessWidget {
  const _StatusSummary({
    required this.controller,
  });

  final AdminController controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child:
              _SummaryMini(
            label:
                'Approved',
            value:
                controller.knownActiveCount,
            color:
                AdminColors.success,
            background:
                AdminColors.successSoft,
          ),
        ),
        const SizedBox(
          width:
              8,
        ),
        Expanded(
          child:
              _SummaryMini(
            label:
                'Suspended',
            value:
                controller.knownSuspendedCount,
            color:
                AdminColors.warning,
            background:
                const Color(
              0xFFFFF0E3,
            ),
          ),
        ),
        const SizedBox(
          width:
              8,
        ),
        Expanded(
          child:
              _SummaryMini(
            label:
                'Rejected',
            value:
                controller.knownRejectedCount,
            color:
                AdminColors.danger,
            background:
                AdminColors.dangerSoft,
          ),
        ),
      ],
    );
  }
}

class _SummaryMini
    extends StatelessWidget {
  const _SummaryMini({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final int value;
  final Color color;
  final Color background;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal:
            11,
        vertical:
            10,
      ),
      decoration:
          BoxDecoration(
        color:
            background,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
      ),
      child:
          Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style:
                TextStyle(
              color:
                  color,
              fontSize:
                  18,
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
          FittedBox(
            fit:
                BoxFit.scaleDown,
            alignment:
                Alignment.centerLeft,
            child:
                Text(
              label,
              style:
                  TextStyle(
                color:
                    color,
                fontSize:
                    8.8,
                fontWeight:
                    FontWeight.w800,
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
    final latest =
        entry.latestHistoryAction;

    final action =
        entry.latestAction;

    final actionLabel =
        action.isEmpty
            ? 'Current status'
            : _prettyAction(
                action,
              );

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
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                              entry.effectiveStatus,
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
                          9,
                    ),

                    Row(
                      children: [
                        Icon(
                          _actionIcon(
                            action,
                          ),
                          size:
                              13,
                          color:
                              _actionColor(
                            entry.effectiveStatus,
                          ),
                        ),
                        const SizedBox(
                          width:
                              5,
                        ),
                        Expanded(
                          child:
                              Text(
                            latest == null
                                ? '$actionLabel • ${_prettyAction(entry.effectiveStatus)}'
                                : '$actionLabel • ${adminDate(latest.createdAt)}',
                            maxLines:
                                1,
                            overflow:
                                TextOverflow.ellipsis,
                            style:
                                TextStyle(
                              color:
                                  _actionColor(
                                entry.effectiveStatus,
                              ),
                              fontSize:
                                  9.4,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (entry.latestReason.isNotEmpty) ...[
                      const SizedBox(
                        height:
                            7,
                      ),
                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              9,
                          vertical:
                              7,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AdminColors.bg,
                          borderRadius:
                              BorderRadius.circular(
                            11,
                          ),
                        ),
                        child:
                            Text(
                          entry.latestReason,
                          maxLines:
                              2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color:
                                AdminColors.muted,
                            fontSize:
                                8.9,
                            height:
                                1.35,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                width:
                    7,
              ),

              const Padding(
                padding:
                    EdgeInsets.only(
                  top:
                      28,
                ),
                child:
                    Icon(
                  Icons.chevron_right_rounded,
                  color:
                      AdminColors.muted2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _prettyAction(
  String value,
) {
  final clean =
      value.trim();

  if (clean.isEmpty) {
    return 'Unknown';
  }

  if (clean == 'active') {
    return 'Approved';
  }

  return clean
      .split(
        RegExp(
          r'[_\s-]+',
        ),
      )
      .map(
        (part) =>
            part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(
        ' ',
      );
}

Color _actionColor(
  String status,
) {
  switch (status) {
    case 'active':
    case 'approved':
    case 'verified':
      return AdminColors.success;

    case 'suspended':
      return AdminColors.warning;

    case 'rejected':
      return AdminColors.danger;

    default:
      return AdminColors.tealDark;
  }
}

IconData _actionIcon(
  String action,
) {
  switch (action) {
    case 'approved':
      return Icons.verified_rounded;

    case 'rejected':
      return Icons.cancel_rounded;

    case 'suspended':
      return Icons.pause_circle_filled_rounded;

    case 'reactivated':
    case 'reactivate':
      return Icons.restart_alt_rounded;

    default:
      return Icons.history_rounded;
  }
}
