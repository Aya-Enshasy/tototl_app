import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_design.dart';
import 'pilot_review_screen.dart';

class PendingPilotsScreen extends StatefulWidget {
  const PendingPilotsScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;

  @override
  State<PendingPilotsScreen> createState() =>
      _PendingPilotsScreenState();
}

class _PendingPilotsScreenState
    extends State<PendingPilotsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPendingPilotModel> get _visible {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.pendingPilots;
    }

    return widget.controller.pendingPilots
        .where(
          (item) => item.searchableText.contains(query),
        )
        .toList();
  }

  Future<void> _open(
    AdminPendingPilotModel pilot,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PilotReviewScreen(
          controller: widget.controller,
          pilot: pilot,
        ),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminPageTitle(
          title: 'Pending Pilots',
          subtitle:
              '${widget.controller.pendingPilotCount} waiting for verification',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            18,
            2,
            18,
            8,
          ),
          child: AdminSearchField(
            controller: _searchController,
            hint:
                'Search name, username, email or location',
            onChanged: (value) {
              setState(() {
                _query = value;
              });
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AdminColors.tealDark,
            onRefresh: widget.onRefresh,
            child: _visible.isEmpty
                ? ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    children: [
                      AdminEmptyState(
                        icon: _query.isEmpty
                            ? Icons.verified_user_outlined
                            : Icons.search_off_rounded,
                        title: _query.isEmpty
                            ? 'No pilots waiting'
                            : 'No matching pilots',
                        message: _query.isEmpty
                            ? 'The pilot verification queue is clear.'
                            : 'Try a different name, username, email or location.',
                      ),
                    ],
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    physics:
                        const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      8,
                      18,
                      34,
                    ),
                    itemCount: _visible.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 11),
                    itemBuilder: (
                      context,
                      index,
                    ) {
                      final pilot = _visible[index];

                      return _PilotCard(
                        pilot: pilot,
                        onTap: () => _open(pilot),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _PilotCard extends StatelessWidget {
  const _PilotCard({
    required this.pilot,
    required this.onTap,
  });

  final AdminPendingPilotModel pilot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: AdminColors.border,
            ),
          ),
          child: Row(
            children: [
              AdminInitialAvatar(
                name: pilot.user.displayName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pilot.user.displayName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AdminColors.ink,
                              fontSize: 13.5,
                              fontWeight:
                                  FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        AdminStatusBadge(
                          status: pilot.user.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pilot.user.displayUsername,
                      style: const TextStyle(
                        color: AdminColors.tealDark,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _Meta(
                      icon:
                          Icons.workspace_premium_outlined,
                      text:
                          '${pilot.profile.experienceLabel} experience',
                    ),
                    const SizedBox(height: 5),
                    _Meta(
                      icon:
                          Icons.location_on_outlined,
                      text: pilot.profile.locationLabel,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: AdminColors.muted2,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 9.7,
            ),
          ),
        ),
      ],
    );
  }
}
