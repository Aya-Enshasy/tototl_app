import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_pilot_model.dart';
import '../widgets/admin_ui.dart';
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
  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPendingPilotModel>
  get _visible {
    final query =
        _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.pendingPilots;
    }

    return widget.controller.pendingPilots
        .where(
          (item) =>
              item.searchableText.contains(query),
        )
        .toList();
  }

  Future<void> _open(
    AdminPendingPilotModel pilot,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            PilotReviewScreen(
          pilot: pilot,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller =
        widget.controller;

    return Column(
      children: [
        AdminPageHeader(
          title:
              'Pending Pilots',
          subtitle:
              '${controller.pendingPilotCount} account${controller.pendingPilotCount == 1 ? '' : 's'} waiting for review',
        ),

        Padding(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            2,
            18,
            8,
          ),
          child:
              AdminSearchField(
            controller:
                _searchController,
            hint:
                'Search pilot, username, email or location',
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
                AdminPalette.tealDark,
            onRefresh:
                widget.onRefresh,
            child:
                controller.pilotsError != null &&
                        controller.pendingPilots.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          AdminEmptyState(
                            icon:
                                Icons.cloud_off_rounded,
                            title:
                                'Unable to load pilots',
                            message:
                                controller.pilotsError!,
                            actionLabel:
                                'Retry',
                            onAction:
                                () {
                              widget.onRefresh();
                            },
                          ),
                        ],
                      )
                    : _visible.isEmpty
                        ? ListView(
                            physics:
                                const AlwaysScrollableScrollPhysics(),
                            children: [
                              AdminEmptyState(
                                icon:
                                    _query.isEmpty
                                        ? Icons.verified_user_outlined
                                        : Icons.search_off_rounded,
                                title:
                                    _query.isEmpty
                                        ? 'No pilots waiting'
                                        : 'No matching pilots',
                                message:
                                    _query.isEmpty
                                        ? 'The pilot verification queue is currently clear.'
                                        : 'Try a different name, username, email or location.',
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
                              final pilot =
                                  _visible[index];

                              return AdminPilotQueueCard(
                                pilot:
                                    pilot,
                                onTap:
                                    () => _open(
                                  pilot,
                                ),
                              );
                            },
                          ),
          ),
        ),
      ],
    );
  }
}
