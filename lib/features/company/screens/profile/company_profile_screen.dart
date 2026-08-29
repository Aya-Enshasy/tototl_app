import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../shared/screens/profile/account_settings_screen.dart';
import '../../../shared/settings_detail_screens.dart';
import '../../controllers/company_profile_controller.dart';
import '../../models/company_profile_model.dart';
import '../../services/company_profile_service.dart';
import 'company_edit_profile_screen.dart';



// ============================================================================
// COMPANY PROFILE SCREEN
// ============================================================================

class CompanyProfileScreen
    extends StatefulWidget {
  const CompanyProfileScreen({
    super.key,
  });

  @override
  State<CompanyProfileScreen>
  createState() =>
      _CompanyProfileScreenState();
}

class _CompanyProfileScreenState
    extends State<CompanyProfileScreen> {
  // ==========================================================================
  // CONTROLLER
  // ==========================================================================

  late final CompanyProfileController
  _controller;

  // ==========================================================================
  // STATE
  // ==========================================================================

  CompanyProfileViewData? _data;

  bool _loading =
  true;

  bool _refreshing =
  false;

  String? _errorMessage;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    _controller =
        CompanyProfileController(
          CompanyProfileService(
            ApiClient(),
          ),
        );

    _loadProfile();
  }

  // ==========================================================================
  // INITIAL LOAD
  //
  // 1. Show local data immediately.
  // 2. Refresh API silently in background.
  // ==========================================================================

  Future<void> _loadProfile() async {
    final local =
    await _controller
        .loadLocalProfile();

    if (!mounted) {
      return;
    }

    if (local != null) {
      setState(() {
        _data =
            local;

        _loading =
        false;
      });

      // Do not await.
      // API refresh happens in background.
      _refreshInBackground();

      return;
    }

    // No local profile available.
    // In this case we need API data.
    final fresh =
    await _controller
        .loadFreshProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _data =
          fresh;

      _loading =
      false;

      _errorMessage =
      fresh == null
          ? _controller
          .errorMessage
          : null;
    });
  }

  // ==========================================================================
  // BACKGROUND REFRESH
  // ==========================================================================

  Future<void>
  _refreshInBackground() async {
    if (_refreshing) {
      return;
    }

    _refreshing =
    true;

    final fresh =
    await _controller
        .refreshSilently();

    if (!mounted) {
      return;
    }

    _refreshing =
    false;

    if (fresh == null) {
      // Silent refresh:
      // keep showing cached information.
      return;
    }

    setState(() {
      _data =
          fresh;

      _errorMessage =
      null;
    });
  }

  // ==========================================================================
  // MANUAL REFRESH
  // ==========================================================================

  Future<void> _handleRefresh() async {
    final fresh =
    await _controller
        .refreshSilently();

    if (!mounted) {
      return;
    }

    if (fresh != null) {
      setState(() {
        _data =
            fresh;

        _errorMessage =
        null;
      });
    }
  }

  // ==========================================================================
  // EDIT COMPANY PROFILE
  // ==========================================================================

  Future<void> _openEditProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const CompanyEditProfileScreen(),
      ),
    );

    if (!mounted || changed != true) {
      return;
    }

    await _handleRefresh();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (_loading) {
      return const Scaffold(
        backgroundColor:
        AppColors.bg,
        body:
        SafeArea(
          child:
          Center(
            child:
            CircularProgressIndicator(
              color:
              AppColors.blue,
            ),
          ),
        ),
      );
    }

    if (_data == null) {
      return _ErrorView(
        message:
        _errorMessage ??
            'Unable to load company profile.',
        onRetry:
        _loadProfile,
      );
    }

    final data =
    _data!;

    final profile =
        data.profile;

    final account =
        data.account;

    return Scaffold(
      backgroundColor:
      AppColors.bg,

      body:
      SafeArea(
        child:
        RefreshIndicator(
          color:
          AppColors.blue,

          onRefresh:
          _handleRefresh,

          child:
          ListView(
            physics:
            const AlwaysScrollableScrollPhysics(),

            padding:
            const EdgeInsets
                .fromLTRB(
              20,
              24,
              20,
              110,
            ),

            children: [
              // ==============================================================
              // HEADER
              // ==============================================================

              Row(
                children: [
                  const Expanded(
                    child:
                    Text(
                      'Company Profile',
                      style:
                      TextStyle(
                        color:
                        AppColors.navy,
                        fontSize:
                        25,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),
                  ),

                  IconButton(
                    onPressed:
                        () {
                      Navigator.of(
                        context,
                      ).push(
                        MaterialPageRoute(
                          builder:
                              (_) =>
                          const AccountSettingsScreen(
                            isCompany:
                            true,
                          ),
                        ),
                      );
                    },

                    icon:
                    const Icon(
                      Icons.settings_outlined,
                      color:
                      AppColors.navy,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height:
                18,
              ),

              // ==============================================================
              // PROFILE HERO
              // ==============================================================

              _ProfileCard(
                account:
                account,

                profile:
                profile,

                profilePhotoUrl:
                data.profilePhotoUrl,
              ),

              const SizedBox(
                height:
                14,
              ),

              // ==============================================================
              // ABOUT
              // ==============================================================

              _Section(
                title:
                'About',

                child:
                Text(
                  profile.description
                      .trim()
                      .isEmpty
                      ? 'No company description added yet.'
                      : profile.description,

                  style:
                  const TextStyle(
                    color:
                    AppColors.text,
                    fontSize:
                    13.5,
                    height:
                    1.5,
                  ),
                ),
              ),

              const SizedBox(
                height:
                14,
              ),

              // ==============================================================
              // COMPANY INFORMATION
              // ==============================================================

              _Section(
                title:
                'Company Information',

                child:
                Column(
                  children: [
                    _InfoRow(
                      icon:
                      Icons
                          .business_outlined,
                      label:
                      'Industry',
                      value:
                      _display(
                        profile.industryType,
                      ),
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .location_on_outlined,
                      label:
                      'Location',
                      value:
                      profile.locationLabel,
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .home_work_outlined,
                      label:
                      'Address',
                      value:
                      _display(
                        profile.address,
                      ),
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .language_rounded,
                      label:
                      'Website',
                      value:
                      _display(
                        profile.website,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                14,
              ),

              // ==============================================================
              // OPERATING REGIONS
              // ==============================================================

              _Section(
                title:
                'Operating Regions',

                child:
                profile
                    .workRegions
                    .isEmpty
                    ? const Text(
                  'No operating regions added yet.',
                  style:
                  TextStyle(
                    color:
                    AppColors.grey,
                    fontSize:
                    12.5,
                  ),
                )
                    : Wrap(
                  spacing:
                  8,
                  runSpacing:
                  8,
                  children:
                  profile
                      .workRegions
                      .map(
                        (
                        region,
                        ) {
                      return Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal:
                          11,
                          vertical:
                          7,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          AppColors.blue.withOpacity(
                            0.07,
                          ),
                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                          border:
                          Border.all(
                            color:
                            AppColors.blue.withOpacity(
                              0.15,
                            ),
                          ),
                        ),
                        child:
                        Row(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons
                                  .location_on_outlined,
                              size:
                              14,
                              color:
                              AppColors.blue,
                            ),
                            const SizedBox(
                              width:
                              5,
                            ),
                            Text(
                              region.displayLabel,
                              style:
                              const TextStyle(
                                color:
                                AppColors.navy,
                                fontSize:
                                11,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),

              const SizedBox(
                height:
                14,
              ),

              // ==============================================================
              // ACCOUNT DATA
              // ==============================================================

              _Section(
                title:
                'Account',

                child:
                Column(
                  children: [
                    _InfoRow(
                      icon:
                      Icons
                          .person_outline_rounded,
                      label:
                      'Account name',
                      value:
                      _display(
                        account.name,
                      ),
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .alternate_email_rounded,
                      label:
                      'Username',
                      value:
                      _display(
                        account.displayUsername,
                      ),
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .email_outlined,
                      label:
                      'Email',
                      value:
                      _display(
                        account.email,
                      ),
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _InfoRow(
                      icon:
                      Icons
                          .phone_outlined,
                      label:
                      'Phone',
                      value:
                      _display(
                        account.phone,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height:
                14,
              ),

              // ==============================================================
              // SETTINGS
              // ==============================================================

              _Section(
                title:
                'Settings',

                child:
                Column(
                  children: [
                    _Tile(
                      icon:
                      Icons
                          .business_outlined,

                      title:
                      'Company details',

                      subtitle:
                      'Industry, address, website and operating regions',

                      onTap: _openEditProfile,
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _Tile(
                      icon:
                      Icons
                          .credit_card_outlined,

                      title:
                      'Subscription plan',

                      subtitle:
                      'Manage your subscription',

                      onTap:
                          () {},
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _Tile(
                      icon:
                      Icons
                          .notifications_none_rounded,

                      title:
                      'Notifications',

                      subtitle:
                      'Job and application activity',

                      onTap:
                          () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                            const AccountSettingsScreen(
                              isCompany:
                              true,
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(
                      color:
                      AppColors.cardBorder,
                    ),

                    _Tile(
                      icon:
                      Icons
                          .security_outlined,

                      title:
                      'Security & privacy',

                      subtitle:
                      'Account access and data controls',

                      onTap:
                          () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder:
                                (_) =>
                            const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),
                  ],
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
// PROFILE CARD
// ============================================================================

class _ProfileCard
    extends StatelessWidget {
  const _ProfileCard({
    required this.account,
    required this.profile,
    required this.profilePhotoUrl,
  });

  final CompanyAccountModel account;
  final CompanyProfileModel profile;
  final String profilePhotoUrl;

  @override
  Widget build(
      BuildContext context,
      ) {
    final verified =
        account.isVerified;

    return Container(
      padding:
      const EdgeInsets.all(
        20,
      ),

      decoration:
      BoxDecoration(
        color:
        Colors.white,

        borderRadius:
        BorderRadius.circular(
          20,
        ),

        border:
        Border.all(
          color:
          AppColors.cardBorder,
        ),
      ),

      child:
      Column(
        children: [
          // ================================================================
          // PHOTO / LOGO
          // ================================================================

          Container(
            width:
            78,
            height:
            78,

            decoration:
            BoxDecoration(
              color:
              AppColors.blue,

              borderRadius:
              BorderRadius.circular(
                23,
              ),
            ),

            clipBehavior:
            Clip.antiAlias,

            child:
            profilePhotoUrl
                .trim()
                .isNotEmpty
                ? Image.network(
              profilePhotoUrl,
              fit:
              BoxFit.cover,
              errorBuilder:
                  (
                  context,
                  error,
                  stackTrace,
                  ) {
                return const Icon(
                  Icons
                      .business_rounded,
                  color:
                  Colors.white,
                  size:
                  38,
                );
              },
            )
                : const Icon(
              Icons
                  .business_rounded,
              color:
              Colors.white,
              size:
              38,
            ),
          ),

          const SizedBox(
            height:
            13,
          ),

          // ================================================================
          // COMPANY NAME
          // ================================================================

          Text(
            profile.displayCompanyName,

            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              color:
              AppColors.navy,

              fontSize:
              21,

              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            5,
          ),

          Text(
            profile.industryAndLocationLabel,

            textAlign:
            TextAlign.center,

            style:
            const TextStyle(
              color:
              AppColors.grey,

              fontSize:
              13,
            ),
          ),

          const SizedBox(
            height:
            10,
          ),

          // ================================================================
          // STATUS
          // ================================================================

          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              10,
              vertical:
              5,
            ),

            decoration:
            BoxDecoration(
              color:
              verified
                  ? AppColors.greenBg
                  : const Color(
                0xFFFFF5DF,
              ),

              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),

            child:
            Row(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                Icon(
                  verified
                      ? Icons
                      .verified_rounded
                      : Icons
                      .schedule_rounded,

                  color:
                  verified
                      ? AppColors.green
                      : const Color(
                    0xFFC38315,
                  ),

                  size:
                  14,
                ),

                const SizedBox(
                  width:
                  5,
                ),

                Text(
                  account.statusLabel,

                  style:
                  TextStyle(
                    color:
                    verified
                        ? AppColors.green
                        : const Color(
                      0xFFC38315,
                    ),

                    fontSize:
                    11.5,

                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height:
            17,
          ),

          // ================================================================
          // METRICS
          //
          // Not returned by GET /company/profile yet.
          // ================================================================

          const Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceAround,

            children: [
              _Metric(
                value:
                '0',
                label:
                'Jobs posted',
              ),

              _Metric(
                value:
                '0',
                label:
                'Pilots hired',
              ),

              _Metric(
                value:
                '0',
                label:
                'Company rating',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// METRIC
// ============================================================================

class _Metric
    extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      children: [
        Text(
          value,

          style:
          const TextStyle(
            color:
            AppColors.navy,

            fontSize:
            17,

            fontWeight:
            FontWeight.w800,
          ),
        ),

        const SizedBox(
          height:
          3,
        ),

        Text(
          label,

          style:
          const TextStyle(
            color:
            AppColors.grey,

            fontSize:
            10.5,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SECTION
// ============================================================================

class _Section
    extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(
        17,
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
          AppColors.cardBorder,
        ),
      ),

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
              AppColors.navy,

              fontSize:
              16,

              fontWeight:
              FontWeight.w800,
            ),
          ),

          const SizedBox(
            height:
            13,
          ),

          child,
        ],
      ),
    );
  }
}

// ============================================================================
// INFO ROW
// ============================================================================

class _InfoRow
    extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(
        vertical:
        8,
      ),

      child:
      Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            icon,

            color:
            AppColors.blue,

            size:
            19,
          ),

          const SizedBox(
            width:
            11,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  label,

                  style:
                  const TextStyle(
                    color:
                    AppColors.grey,

                    fontSize:
                    10.5,
                  ),
                ),

                const SizedBox(
                  height:
                  3,
                ),

                Text(
                  value,

                  style:
                  const TextStyle(
                    color:
                    AppColors.navy,

                    fontSize:
                    12.5,

                    fontWeight:
                    FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TILE
// ============================================================================

class _Tile
    extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return InkWell(
      onTap:
      onTap,

      borderRadius:
      BorderRadius.circular(
        12,
      ),

      child:
      Padding(
        padding:
        const EdgeInsets.symmetric(
          vertical:
          8,
        ),

        child:
        Row(
          children: [
            Icon(
              icon,

              color:
              AppColors.blue,

              size:
              20,
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
                  Text(
                    title,

                    style:
                    const TextStyle(
                      color:
                      AppColors.navy,

                      fontWeight:
                      FontWeight.w700,
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
                      AppColors.grey,

                      fontSize:
                      11.5,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons
                  .chevron_right_rounded,

              color:
              AppColors.lightGrey,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ERROR
// ============================================================================

class _ErrorView
    extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      AppColors.bg,

      body:
      SafeArea(
        child:
        Center(
          child:
          Padding(
            padding:
            const EdgeInsets.all(
              28,
            ),

            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,

              children: [
                const Icon(
                  Icons
                      .cloud_off_rounded,

                  color:
                  AppColors.grey,

                  size:
                  46,
                ),

                const SizedBox(
                  height:
                  14,
                ),

                Text(
                  message,

                  textAlign:
                  TextAlign.center,

                  style:
                  const TextStyle(
                    color:
                    AppColors.text,

                    fontSize:
                    13,
                  ),
                ),

                const SizedBox(
                  height:
                  18,
                ),

                FilledButton(
                  onPressed:
                  onRetry,

                  child:
                  const Text(
                    'Try Again',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DISPLAY
// ============================================================================

String _display(
    String value,
    ) {
  final clean =
  value.trim();

  if (clean.isEmpty) {
    return 'Not specified';
  }

  return clean;
}
