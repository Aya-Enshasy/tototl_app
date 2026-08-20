import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/navigation/bottom_navbar.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../company/company_shell_screen.dart';

import '../../controllers/auth_controller.dart';

import '../chooseAccount/choose_account.dart';
import '../forgot_password/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final AuthController authController;

  const LoginScreen({
    super.key,
    required this.authController,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {

  // ============================================================
  // Controllers
  // ============================================================

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _loginSuccess = false;
  bool _buttonPressed = false;

  // ============================================================
  // Animations
  // ============================================================

  late final AnimationController _entranceController;
  late final AnimationController _logoController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _logoFloatAnimation;

  @override
  void initState() {
    super.initState();

    // دخول الشاشة
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutBack,
      ),
    );

    // حركة اللوجو العائمة
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoFloatAnimation = Tween<double>(
      begin: -4,
      end: 4,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeInOut,
      ),
    );

    _entranceController.forward();
    _logoController.repeat(reverse: true);

    _emailFocus.addListener(_refresh);
    _passwordFocus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    _emailFocus.dispose();
    _passwordFocus.dispose();

    _entranceController.dispose();
    _logoController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN BACKEND
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validation
    if (email.isEmpty) {
      _showMessage(
        'Please enter your email.',
        isError: true,
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
        isError: true,
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please enter your password.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loginSuccess = false;
    });

    final result = await widget.authController.login(
      email: email,
      password: password,
    );

    if (!mounted) return;

    if (result == null || result.data == null) {
      setState(() {
        _isLoading = false;
      });

      _showMessage(
        widget.authController.errorMessage ??
            'Login failed. Please check your credentials.',
        isError: true,
      );

      return;
    }

    // ==========================================================
    // LOGIN SUCCESS
    // ==========================================================

    final role = result.data!.role;
    final user = result.data!.user;

    debugPrint('================ LOGIN SUCCESS ================');
    debugPrint('User: ${user.name}');
    debugPrint('Email: ${user.email}');
    debugPrint('Role: $role');
    debugPrint('Status: ${user.status}');
    debugPrint('================================================');

    setState(() {
      _isLoading = false;
      _loginSuccess = true;
    });

    // نخلي المستخدم يشوف حركة النجاح للحظة بسيطة
    await Future.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) return;

    // ==========================================================
    // ROLE NAVIGATION
    // ==========================================================

    if (role.toLowerCase() == 'company') {
      Navigator.pushReplacement(
        context,
        _beautifulRoute(
          const CompanyShellScreen(),
        ),
      );

      return;
    }

    if (role.toLowerCase() == 'pilot') {
      Navigator.pushReplacement(
        context,
        _beautifulRoute(
          const MyScreen(),
        ),
      );

      return;
    }

    setState(() {
      _loginSuccess = false;
    });

    _showMessage(
      'Unknown account role: $role',
      isError: true,
    );
  }

  // ============================================================
  // BEAUTIFUL PAGE TRANSITION
  // ============================================================

  PageRouteBuilder _beautifulRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(
        milliseconds: 550,
      ),
      reverseTransitionDuration: const Duration(
        milliseconds: 350,
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
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          elevation: 8,
          backgroundColor: isError
              ? const Color(0xFFEC5C5C)
              : AppColors.logoTurquoiseDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_outline_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required bool obscureText,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
  }) {
    final focused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: focused
            ? [
          BoxShadow(
            color: AppColors.logoTurquoise.withOpacity(
              0.14,
            ),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        textInputAction: textInputAction,
        enabled: !_isLoading,
        autofillHints: keyboardType ==
            TextInputType.emailAddress
            ? const [AutofillHints.email]
            : const [AutofillHints.password],
        onSubmitted: (_) {
          onSubmitted?.call();
        },
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.lightGrey,
            fontSize: 13.5,
          ),
          prefixIcon: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 200,
            ),
            child: Icon(
              icon,
              key: ValueKey(focused),
              color: focused
                  ? AppColors.logoTurquoiseDark
                  : AppColors.grey,
              size: focused ? 21 : 20,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: focused
              ? AppColors.logoTurquoise.withOpacity(0.035)
              : Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.logoTurquoise,
              width: 1.5,
            ),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.border,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final size = MediaQuery.of(context).size;
    final keyboardHeight =
        MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [

          // ====================================================
          // BACKGROUND IMAGE
          // ====================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child: Image.asset(
              'assets/images/login_background.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ====================================================
          // DARK GRADIENT
          // ====================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.logoNavy.withOpacity(0.35),
                    AppColors.logoNavy.withOpacity(0.72),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // HEADER
          // ====================================================

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: size.height * 0.65,
            child: SafeArea(
              bottom: false,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // Floating Logo
                      AnimatedBuilder(
                        animation: _logoFloatAnimation,
                        builder: (
                            context,
                            child,
                            ) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              _logoFloatAnimation.value,
                            ),
                            child: child,
                          );
                        },
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 130,
                          height: 130,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Text(
                        'TOTOTL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1.1,
                        ),
                      ),

                      const Text(
                        'I N T G R X',
                        style: TextStyle(
                          color:
                          AppColors.logoTurquoiseLight,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5.5,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 45,
                            height: 1,
                            color: Colors.white38,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            child: Text(
                              'DRONE PILOT & COMPANY PLATFORM',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            width: 45,
                            height: 1,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ====================================================
          // WHITE SHEET
          // ====================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.65,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    const BorderRadius.only(
                      topLeft: Radius.circular(48),
                      topRight: Radius.circular(48),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.08,
                        ),
                        blurRadius: 25,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics:
                    const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      28,
                      32,
                      28,
                      32 + keyboardHeight,
                    ),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                        children: [

                          // ====================================
                          // TITLE
                          // ====================================

                          const Center(
                            child: Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
                                color: AppColors.text,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          const Center(
                            child: Text(
                              'Sign in to continue your journey',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: AppColors.grey,
                                fontWeight:
                                FontWeight.w400,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ====================================
                          // EMAIL
                          // ====================================

                          const Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                              FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),

                          const SizedBox(height: 8),

                          _buildAnimatedTextField(
                            controller:
                            _emailController,
                            focusNode: _emailFocus,
                            hint:
                            'Enter your email',
                            icon:
                            Icons.email_outlined,
                            keyboardType:
                            TextInputType
                                .emailAddress,
                            obscureText: false,
                            textInputAction:
                            TextInputAction.next,
                            onSubmitted: () {
                              _passwordFocus
                                  .requestFocus();
                            },
                          ),

                          const SizedBox(height: 18),

                          // ====================================
                          // PASSWORD
                          // ====================================

                          const Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                              FontWeight.w600,
                              color: AppColors.text,
                            ),
                          ),

                          const SizedBox(height: 8),

                          _buildAnimatedTextField(
                            controller:
                            _passwordController,
                            focusNode:
                            _passwordFocus,
                            hint:
                            'Enter your password',
                            icon:
                            Icons.lock_outline,
                            keyboardType:
                            TextInputType
                                .visiblePassword,
                            obscureText:
                            !_isPasswordVisible,
                            textInputAction:
                            TextInputAction.done,
                            onSubmitted: _login,
                            suffixIcon: IconButton(
                              splashRadius: 20,
                              icon: AnimatedSwitcher(
                                duration:
                                const Duration(
                                  milliseconds: 180,
                                ),
                                child: Icon(
                                  _isPasswordVisible
                                      ? Icons
                                      .visibility_outlined
                                      : Icons
                                      .visibility_off_outlined,
                                  key: ValueKey(
                                    _isPasswordVisible,
                                  ),
                                  color:
                                  AppColors.grey,
                                  size: 20,
                                ),
                              ),
                              onPressed: () {
                                HapticFeedback
                                    .selectionClick();

                                setState(() {
                                  _isPasswordVisible =
                                  !_isPasswordVisible;
                                });
                              },
                            ),
                          ),

                          // ====================================
                          // FORGOT PASSWORD
                          // ====================================

                          Align(
                            alignment:
                            Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              style:
                              TextButton.styleFrom(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  vertical: 8,
                                ),
                                minimumSize:
                                Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize
                                    .shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(
                                    0xFF0EC0BC,
                                  ),
                                  fontWeight:
                                  FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ====================================
                          // LOGIN BUTTON
                          // ====================================

                          Listener(
                            onPointerDown: (_) {
                              if (!_isLoading) {
                                setState(() {
                                  _buttonPressed =
                                  true;
                                });
                              }
                            },
                            onPointerUp: (_) {
                              if (mounted) {
                                setState(() {
                                  _buttonPressed =
                                  false;
                                });
                              }
                            },
                            onPointerCancel: (_) {
                              if (mounted) {
                                setState(() {
                                  _buttonPressed =
                                  false;
                                });
                              }
                            },
                            child: AnimatedScale(
                              duration:
                              const Duration(
                                milliseconds: 120,
                              ),
                              scale: _buttonPressed
                                  ? 0.97
                                  : 1,
                              child:
                              AnimatedContainer(
                                duration:
                                const Duration(
                                  milliseconds: 300,
                                ),
                                height: 54,
                                decoration:
                                BoxDecoration(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    28,
                                  ),
                                  gradient:
                                  LinearGradient(
                                    colors:
                                    _loginSuccess
                                        ? const [
                                      Color(
                                        0xFF3CCF91,
                                      ),
                                      Color(
                                        0xFF23A76F,
                                      ),
                                    ]
                                        : const [
                                      AppColors
                                          .logoTurquoise,
                                      AppColors
                                          .logoTurquoiseDark,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_loginSuccess
                                          ? const Color(
                                        0xFF23A76F,
                                      )
                                          : AppColors
                                          .logoTurquoiseDark)
                                          .withOpacity(
                                        0.35,
                                      ),
                                      blurRadius: 18,
                                      offset:
                                      const Offset(
                                        0,
                                        6,
                                      ),
                                    ),
                                  ],
                                ),
                                child:
                                ElevatedButton(
                                  onPressed:
                                  _isLoading ||
                                      _loginSuccess
                                      ? null
                                      : () {
                                    HapticFeedback
                                        .lightImpact();
                                    _login();
                                  },
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    Colors
                                        .transparent,
                                    disabledBackgroundColor:
                                    Colors
                                        .transparent,
                                    shadowColor:
                                    Colors
                                        .transparent,
                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        28,
                                      ),
                                    ),
                                  ),
                                  child:
                                  AnimatedSwitcher(
                                    duration:
                                    const Duration(
                                      milliseconds:
                                      250,
                                    ),
                                    transitionBuilder:
                                        (
                                        child,
                                        animation,
                                        ) {
                                      return FadeTransition(
                                        opacity:
                                        animation,
                                        child:
                                        ScaleTransition(
                                          scale:
                                          animation,
                                          child:
                                          child,
                                        ),
                                      );
                                    },
                                    child:
                                    _loginSuccess
                                        ? const Row(
                                      key: ValueKey(
                                        'success',
                                      ),
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        Icon(
                                          Icons
                                              .check_circle_rounded,
                                          color: Colors
                                              .white,
                                          size:
                                          21,
                                        ),
                                        SizedBox(
                                          width:
                                          9,
                                        ),
                                        Text(
                                          'Welcome!',
                                          style:
                                          TextStyle(
                                            color:
                                            Colors.white,
                                            fontSize:
                                            15.5,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                        : _isLoading
                                        ? const SizedBox(
                                      key:
                                      ValueKey(
                                        'loading',
                                      ),
                                      width:
                                      22,
                                      height:
                                      22,
                                      child:
                                      CircularProgressIndicator(
                                        strokeWidth:
                                        2.3,
                                        valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                        : const Row(
                                      key:
                                      ValueKey(
                                        'normal',
                                      ),
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          'Sign In',
                                          style:
                                          TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          // ====================================
                          // OR
                          // ====================================

                          const Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color:
                                  AppColors.border,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    color:
                                    AppColors.grey,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color:
                                  AppColors.border,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ====================================
                          // CREATE ACCOUNT
                          // ====================================

                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color:
                                  AppColors.grey,
                                  fontSize: 13.5,
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading
                                    ? null
                                    : () {
                                  HapticFeedback
                                      .selectionClick();

                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      opaque:
                                      false,
                                      barrierDismissible:
                                      true,
                                      pageBuilder:
                                          (
                                          context,
                                          _,
                                          __,
                                          ) =>
                                              ChooseAccountTypeScreen(
                                                authController: widget.authController,
                                              ),
                                      transitionsBuilder:
                                          (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                          child,
                                          ) {
                                        return FadeTransition(
                                          opacity:
                                          CurvedAnimation(
                                            parent:
                                            animation,
                                            curve:
                                            Curves.easeOut,
                                          ),
                                          child:
                                          ScaleTransition(
                                            scale:
                                            Tween<double>(
                                              begin:
                                              0.97,
                                              end:
                                              1,
                                            ).animate(
                                              CurvedAnimation(
                                                parent:
                                                animation,
                                                curve:
                                                Curves.easeOutBack,
                                              ),
                                            ),
                                            child:
                                            child,
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    color: AppColors
                                        .primary,
                                    fontWeight:
                                    FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}