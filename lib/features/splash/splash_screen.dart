import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/core/navigation/bottom_navbar.dart';
import 'package:tototl_app/core/navigation/company_shell_screen.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';
import '../../core/theme/app_colors.dart';
import '../auth/controllers/auth_controller.dart';
import '../auth/controllers/user_session_storage.dart';
import '../auth/screens/login/login_screen.dart';
import '../auth/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final AnimationController _introController;
  late final AnimationController _logoFloatController;
  late final AnimationController _dotsController;
  late final AnimationController _readyController;

  // ============================================================
  // BACKGROUND
  // ============================================================

  late final Animation<double> _backgroundFade;
  late final Animation<double> _backgroundScale;

  // ============================================================
  // LOGO
  // ============================================================

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;
  late final Animation<double> _logoFloat;

  // ============================================================
  // TEXT
  // ============================================================

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _subTitleFade;
  late final Animation<Offset> _subTitleSlide;

  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  // ============================================================
  // READY TO FLY
  // ============================================================

  late final Animation<double> _readyOpacity;
  late final Animation<double> _readyScale;

  Timer? _splashTimer;

  // ============================================================
  // AUTH
  // ============================================================

  late final ApiClient _apiClient;
  late final AuthService _authService;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // SYSTEM UI
    // ==========================================================

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        Brightness.light,
        statusBarBrightness:
        Brightness.dark,
      ),
    );

    // ==========================================================
    // AUTH INITIALIZATION
    // ==========================================================

    _apiClient = ApiClient();

    _authService = AuthService(
      _apiClient,
    );

    _authController = AuthController(
      _authService,
    );

    // ==========================================================
    // MAIN INTRO CONTROLLER
    // ==========================================================

    _introController = AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 1800),
    );

    // Background
    _backgroundFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.0,
        0.40,
        curve: Curves.easeOut,
      ),
    );

    _backgroundScale = Tween<double>(
      begin: 1.08,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.0,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ==========================================================
    // LOGO
    // ==========================================================

    _logoFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.05,
        0.45,
        curve: Curves.easeOut,
      ),
    );

    _logoScale = Tween<double>(
      begin: 0.72,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.05,
          0.52,
          curve: Curves.easeOutBack,
        ),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.05,
          0.50,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ==========================================================
    // TOTOTL
    // ==========================================================

    _titleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.28,
        0.63,
        curve: Curves.easeOut,
      ),
    );

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.30),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.28,
          0.63,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ==========================================================
    // INTGRX
    // ==========================================================

    _subTitleFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.43,
        0.75,
        curve: Curves.easeOut,
      ),
    );

    _subTitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.43,
          0.75,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ==========================================================
    // TAGLINE
    // ==========================================================

    _taglineFade = CurvedAnimation(
      parent: _introController,
      curve: const Interval(
        0.58,
        0.95,
        curve: Curves.easeOut,
      ),
    );

    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(
          0.58,
          0.95,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // ==========================================================
    // LOGO FLOATING
    // ==========================================================

    _logoFloatController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(milliseconds: 2100),
        );

    _logoFloat = Tween<double>(
      begin: -4,
      end: 4,
    ).animate(
      CurvedAnimation(
        parent: _logoFloatController,
        curve: Curves.easeInOut,
      ),
    );

    // ==========================================================
    // DOTS
    // ==========================================================

    _dotsController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(milliseconds: 1200),
        );

    // ==========================================================
    // READY TO FLY
    // ==========================================================

    _readyController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(milliseconds: 1300),
        );

    _readyOpacity = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _readyController,
        curve: Curves.easeInOut,
      ),
    );

    _readyScale = Tween<double>(
      begin: 0.98,
      end: 1.035,
    ).animate(
      CurvedAnimation(
        parent: _readyController,
        curve: Curves.easeInOut,
      ),
    );

    // ==========================================================
    // START ANIMATIONS
    // ==========================================================

    _introController.forward();

    Future.delayed(
      const Duration(milliseconds: 700),
          () {
        if (!mounted) return;

        _logoFloatController.repeat(
          reverse: true,
        );

        _dotsController.repeat();

        _readyController.repeat(
          reverse: true,
        );
      },
    );

    _startSplash();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Preload splash image
    precacheImage(
      const AssetImage(
        'assets/images/splash.jpeg',
      ),
      context,
    );

    // Preload logo too
    precacheImage(
      const AssetImage(
        'assets/images/logo.png',
      ),
      context,
    );
  }

  // ============================================================
  // SPLASH TIMER
  // ============================================================

  void _startSplash() {
    _splashTimer = Timer(
      const Duration(seconds: 4),
          () {
        _checkSessionAndNavigate();
      },
    );
  }
// ============================================================
// CHECK LOCAL SESSION
// ============================================================

  Future<void> _checkSessionAndNavigate() async {
    if (!mounted) return;

    try {
      // ==========================================================
      // TOKEN
      // ==========================================================

      final hasToken =
      await TokenStorage.hasToken();

      if (!hasToken) {
        debugPrint(
          'SPLASH: NO TOKEN -> LOGIN',
        );

        _navigateToLogin();
        return;
      }

      // ==========================================================
      // ROLE
      // ==========================================================

      final role =
      await UserSessionStorage.getRole();

      debugPrint(
        'SPLASH TOKEN EXISTS: $hasToken',
      );

      debugPrint(
        'SPLASH SAVED ROLE: $role',
      );

      if (!mounted) return;

      // ==========================================================
      // COMPANY
      // ==========================================================

      if (role != null &&
          role.toLowerCase() == 'company') {
        debugPrint(
          'SPLASH -> COMPANY',
        );

        _navigateToPage(
          const CompanyShellScreen(),
        );

        return;
      }

      // ==========================================================
      // PILOT
      // ==========================================================

      if (role != null &&
          role.toLowerCase() == 'pilot') {
        debugPrint(
          'SPLASH -> PILOT',
        );

        _navigateToPage(
          const MyScreen(),
        );

        return;
      }

      // ==========================================================
      // TOKEN EXISTS BUT ROLE IS MISSING / UNKNOWN
      // ==========================================================

      debugPrint(
        'SPLASH: TOKEN EXISTS BUT ROLE UNKNOWN -> LOGIN',
      );

      _navigateToLogin();
    } catch (e) {
      debugPrint(
        'SPLASH SESSION ERROR: $e',
      );

      if (!mounted) return;

      _navigateToLogin();
    }
  }

// ============================================================
// LOGIN NAVIGATION
// ============================================================

  void _navigateToLogin() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      _buildRoute(
        LoginScreen(
          authController:
          _authController,
        ),
      ),
    );
  }

// ============================================================
// AUTHENTICATED NAVIGATION
// ============================================================

  void _navigateToPage(
      Widget page,
      ) {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      _buildRoute(
        page,
      ),
    );
  }

// ============================================================
// TRANSITION
// ============================================================

  PageRouteBuilder _buildRoute(
      Widget page,
      ) {
    return PageRouteBuilder(
      transitionDuration:
      const Duration(
        milliseconds: 700,
      ),
      reverseTransitionDuration:
      const Duration(
        milliseconds: 400,
      ),
      pageBuilder: (
          context,
          animation,
          secondaryAnimation,
          ) {
        return page;
      },
      transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved =
        CurvedAnimation(
          parent: animation,
          curve:
          Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position:
            Tween<Offset>(
              begin:
              const Offset(
                0,
                0.025,
              ),
              end:
              Offset.zero,
            ).animate(
              curved,
            ),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _splashTimer?.cancel();

    _introController.dispose();
    _logoFloatController.dispose();
    _dotsController.dispose();
    _readyController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenSize =
        MediaQuery.of(context).size;

    final logoSize =
    (screenSize.width * 0.70)
        .clamp(
      180.0,
      260.0,
    );

    return Scaffold(
      backgroundColor:
      AppColors.logoNavy,
      body: Stack(
        children: [
          // ====================================================
          // BACKGROUND
          // ====================================================

          Positioned.fill(
            child: AnimatedBuilder(
              animation:
              _introController,
              builder:
                  (
                  context,
                  child,
                  ) {
                return FadeTransition(
                  opacity:
                  _backgroundFade,
                  child: ScaleTransition(
                    scale:
                    _backgroundScale,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/splash.jpeg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ====================================================
          // SUBTLE DARK OVERLAY
          // ====================================================

          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration:
                BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,
                    end: Alignment
                        .bottomCenter,
                    colors: [
                      Colors.black
                          .withOpacity(
                        0.03,
                      ),
                      Colors.transparent,
                      AppColors.logoNavy
                          .withOpacity(
                        0.18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // =================================================
                // MAIN CONTENT
                // =================================================

                Positioned.fill(
                  child:
                  Transform.translate(
                    offset:
                    const Offset(
                      0,
                      -35,
                    ),
                    child: Center(
                      child:
                      SingleChildScrollView(
                        physics:
                        const NeverScrollableScrollPhysics(),
                        child: Column(
                          mainAxisSize:
                          MainAxisSize
                              .min,
                          children: [
                            // =====================================
                            // LOGO
                            // =====================================

                            AnimatedBuilder(
                              animation:
                              _logoFloatController,
                              builder:
                                  (
                                  context,
                                  child,
                                  ) {
                                return Transform
                                    .translate(
                                  offset:
                                  Offset(
                                    0,
                                    _logoFloat
                                        .value,
                                  ),
                                  child:
                                  child,
                                );
                              },
                              child:
                              FadeTransition(
                                opacity:
                                _logoFade,
                                child:
                                SlideTransition(
                                  position:
                                  _logoSlide,
                                  child:
                                  ScaleTransition(
                                    scale:
                                    _logoScale,
                                    child:
                                    Image.asset(
                                      'assets/images/logo.png',
                                      width:
                                      logoSize,
                                      height:
                                      logoSize,
                                      fit: BoxFit
                                          .contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 2,
                            ),

                            // =====================================
                            // TOTOTL
                            // =====================================

                            FadeTransition(
                              opacity:
                              _titleFade,
                              child:
                              SlideTransition(
                                position:
                                _titleSlide,
                                child:
                                const Text(
                                  'TOTOTL',
                                  style:
                                  TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize:
                                    42,
                                    fontWeight:
                                    FontWeight
                                        .w900,
                                    letterSpacing:
                                    -1,
                                    height:
                                    1.1,
                                  ),
                                ),
                              ),
                            ),

                            // =====================================
                            // INTGRX
                            // =====================================

                            FadeTransition(
                              opacity:
                              _subTitleFade,
                              child:
                              SlideTransition(
                                position:
                                _subTitleSlide,
                                child:
                                const Text(
                                  'I N T G R X',
                                  style:
                                  TextStyle(
                                    color:
                                    Color(
                                      0xFF16C6C7,
                                    ),
                                    fontSize:
                                    15,
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                    letterSpacing:
                                    5.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            // =====================================
                            // PLATFORM TAGLINE
                            // =====================================

                            FadeTransition(
                              opacity:
                              _taglineFade,
                              child:
                              SlideTransition(
                                position:
                                _taglineSlide,
                                child:
                                Padding(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    18,
                                  ),
                                  child:
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment
                                        .center,
                                    children: [
                                      Flexible(
                                        child:
                                        Container(
                                          constraints:
                                          const BoxConstraints(
                                            maxWidth:
                                            45,
                                          ),
                                          height:
                                          1,
                                          color: Colors
                                              .white38,
                                        ),
                                      ),

                                      const SizedBox(
                                        width:
                                        8,
                                      ),

                                      Flexible(
                                        flex:
                                        5,
                                        child:
                                        FittedBox(
                                          fit:
                                          BoxFit.scaleDown,
                                          child:
                                          const Text(
                                            'DRONE PILOT & COMPANY PLATFORM',
                                            maxLines:
                                            1,
                                            style:
                                            TextStyle(
                                              color:
                                              Colors.white70,
                                              fontSize:
                                              12,
                                              letterSpacing:
                                              0.8,
                                              fontWeight:
                                              FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width:
                                        8,
                                      ),

                                      Flexible(
                                        child:
                                        Container(
                                          constraints:
                                          const BoxConstraints(
                                            maxWidth:
                                            45,
                                          ),
                                          height:
                                          1,
                                          color: Colors
                                              .white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // =================================================
                // BOTTOM
                // =================================================

                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 45,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      // =============================================
                      // DOTS
                      // =============================================

                      AnimatedBuilder(
                        animation:
                        _dotsController,
                        builder:
                            (
                            context,
                            child,
                            ) {
                          return Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                            children: [
                              _buildDot(
                                index: 0,
                              ),

                              const SizedBox(
                                width: 9,
                              ),

                              _buildDot(
                                index: 1,
                              ),

                              const SizedBox(
                                width: 9,
                              ),

                              _buildDot(
                                index: 2,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      // =============================================
                      // READY TO FLY
                      // =============================================

                      AnimatedBuilder(
                        animation:
                        _readyController,
                        builder:
                            (
                            context,
                            child,
                            ) {
                          return Opacity(
                            opacity:
                            _readyOpacity
                                .value,
                            child:
                            Transform.scale(
                              scale:
                              _readyScale
                                  .value,
                              child:
                              child,
                            ),
                          );
                        },
                        child: const Text(
                          'READY TO FLY',
                          textAlign:
                          TextAlign.center,
                          style: TextStyle(
                            color:
                            Color(
                              0xFF21E6C1,
                            ),
                            fontSize:
                            11,
                            fontWeight:
                            FontWeight
                                .w700,
                            letterSpacing:
                            4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ANIMATED DOT
  // ============================================================

  Widget _buildDot({
    required int index,
  }) {
    final progress =
        _dotsController.value;

    final shifted =
        (progress - (index * 0.20)) % 1.0;

    final distance =
        (shifted - 0.5).abs() * 2;

    final intensity =
        1.0 - distance.clamp(
          0.0,
          1.0,
        );

    final scale =
        0.85 + (intensity * 0.45);

    final opacity =
        0.45 + (intensity * 0.55);

    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == 1
                ? Colors.white
                : const Color(
              0xFF21E6C1,
            ),
            boxShadow: [
              BoxShadow(
                color: (index == 1
                    ? Colors.white
                    : const Color(
                  0xFF21E6C1,
                ))
                    .withOpacity(
                  intensity * 0.45,
                ),
                blurRadius:
                7 * intensity,
                spreadRadius:
                intensity,
              ),
            ],
          ),
        ),
      ),
    );
  }
}