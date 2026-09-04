import 'package:flutter/material.dart';

import '../controllers/admin_controller.dart';
import '../models/admin_pending_company_model.dart';
import '../widgets/admin_design.dart';
import 'company_review_screen.dart';

class PendingCompaniesScreen extends StatefulWidget {
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
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminPendingCompanyModel> get _visible {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return widget.controller.pendingCompanies;
    }

    return widget.controller.pendingCompanies
        .where(
          (item) => item.searchableText.contains(query),
        )
        .toList();
  }

  Future<void> _open(
    AdminPendingCompanyModel company,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyReviewScreen(
          controller: widget.controller,
          company: company,
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
          title: 'Pending Companies',
          subtitle:
              '${widget.controller.pendingCompanyCount} waiting for verification',
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
                'Search company, owner, industry or location',
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
                            ? Icons.domain_verification_outlined
                            : Icons.search_off_rounded,
                        title: _query.isEmpty
                            ? 'No companies waiting'
                            : 'No matching companies',
                        message: _query.isEmpty
                            ? 'The company verification queue is clear.'
                            : 'Try a different company, owner, industry or location.',
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
                      final company = _visible[index];

                      return _CompanyCard(
                        company: company,
                        onTap: () => _open(company),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}

class _CompanyCard extends StatelessWidget {
  const _CompanyCard({
    required this.company,
    required this.onTap,
  });

  final AdminPendingCompanyModel company;
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
                name: company.displayCompanyName,
                isCompany: true,
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
                            company.displayCompanyName,
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
                          status: company.user.status,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      company.profile.industryType
                              .trim()
                              .isEmpty
                          ? 'Industry not provided'
                          : company.profile.industryType,
                      style: const TextStyle(
                        color: AdminColors.company,
                        fontSize: 10.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 9),
                    _Meta(
                      icon: Icons.person_outline_rounded,
                      text: company.user.displayName,
                    ),
                    const SizedBox(height: 5),
                    _Meta(
                      icon: Icons.location_on_outlined,
                      text: company.profile.locationLabel,
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
