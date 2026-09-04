import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../widgets/admin_ui.dart';
import 'company_review_screen.dart';

class PendingCompaniesScreen
    extends StatefulWidget {
  const PendingCompaniesScreen({
    super.key,
    required this.controller,
    required this.onRefresh,
  });

  final AdminController controller;
  final Future<void> Function() onRefresh;

  @override
  State<PendingCompaniesScreen> createState() =>
      _PendingCompaniesScreenState();
}

class _PendingCompaniesScreenState
    extends State<PendingCompaniesScreen> {
  final TextEditingController
      _searchController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPendingCompanyModel>
  get _visible {
    final query =
        _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.pendingCompanies;
    }

    return widget.controller.pendingCompanies
        .where(
          (item) =>
              item.searchableText.contains(query),
        )
        .toList();
  }

  Future<void> _open(
    AdminPendingCompanyModel company,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            CompanyReviewScreen(
          company: company,
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
              'Pending Companies',
          subtitle:
              '${controller.pendingCompanyCount} account${controller.pendingCompanyCount == 1 ? '' : 's'} waiting for review',
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
                'Search company, owner, industry or location',
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
                controller.companiesError != null &&
                        controller.pendingCompanies.isEmpty
                    ? ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          AdminEmptyState(
                            icon:
                                Icons.cloud_off_rounded,
                            title:
                                'Unable to load companies',
                            message:
                                controller.companiesError!,
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
                                        ? Icons.domain_verification_outlined
                                        : Icons.search_off_rounded,
                                title:
                                    _query.isEmpty
                                        ? 'No companies waiting'
                                        : 'No matching companies',
                                message:
                                    _query.isEmpty
                                        ? 'The company verification queue is currently clear.'
                                        : 'Try a different company, owner, industry or location.',
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
                              final company =
                                  _visible[index];

                              return AdminCompanyQueueCard(
                                company:
                                    company,
                                onTap:
                                    () => _open(
                                  company,
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
