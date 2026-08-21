import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tototl_app/core/theme/app_colors.dart';
import 'package:tototl_app/features/auth/controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  // ============================================================
  // FORM
  // ============================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _emailController =
  TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _emailSent = false;
  bool _isLoading = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND RESET LINK / CODE
  // ============================================================

  Future<void> _sendResetLink() async {
    if (_isLoading) return;

    final valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) {
      HapticFeedback.heavyImpact();
      return;
    }

    FocusScope.of(context).unfocus();

    HapticFeedback.selectionClick();

    setState(() {
      _isLoading = true;
    });

    try {
      final success =
      await widget.authController
          .forgotPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        HapticFeedback.mediumImpact();

        setState(() {
          _emailSent = true;
        });

        return;
      }

      HapticFeedback.heavyImpact();

      _showSnack(
        widget.authController.errorMessage ??
            'Unable to send reset email. Please try again.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;

      HapticFeedback.heavyImpact();

      _showSnack(
        'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // USE DIFFERENT EMAIL
  // ============================================================

  void _useDifferentEmail() {
    HapticFeedback.selectionClick();

    setState(() {
      _emailSent = false;
    });
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          elevation: 8,

          margin:
          const EdgeInsets.all(18),

          backgroundColor:
          isError
              ? const Color(0xFFE95C67)
              : const Color(0xFF168F8A),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(16),
          ),

          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color:
                  Colors.white.withOpacity(
                    0.15,
                  ),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  isError
                      ? Icons
                      .error_outline_rounded
                      : Icons
                      .check_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Text(
                  message,
                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight:
                    FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
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
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [

          // ============================================================
          // BACKGROUND
          // ============================================================

          Positioned.fill(
            child: Container(
              color: AppColors.logoNavy,
            ),
          ),

          // ============================================================
          // PAGE
          // ============================================================

          SafeArea(
            bottom: false,
            child: Column(
              children: [

                // ========================================================
                // TOP SECTION
                // ========================================================

                SizedBox(
                  height: 285,
                  width: double.infinity,

                  child: Stack(
                    fit: StackFit.expand,
                    children: [

                      Image.asset(
                        'assets/images/login_background.jpeg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),

                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.logoNavy.withOpacity(0.20),
                              AppColors.logoNavy.withOpacity(0.88),
                            ],
                          ),
                        ),
                      ),

                      // BACK BUTTON

                      Positioned(
                        top: 8,
                        left: 16,
                        child: _BackButton(
                          onTap: _isLoading
                              ? null
                              : () {
                            Navigator.pop(context);
                          },
                        ),
                      ),

                      // LOGO

                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 5),

                            Image.asset(
                              'assets/images/logo.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'TOTOTL',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),

                            const SizedBox(height: 1),

                            const Text(
                              'I N T G R X',
                              style: TextStyle(
                                color:
                                AppColors.logoTurquoiseLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ========================================================
                // WHITE CONTENT
                // ========================================================

                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -32),

                    child: Container(
                      width: double.infinity,

                      decoration: const BoxDecoration(
                        color: Colors.white,

                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(42),
                          topRight: Radius.circular(42),
                        ),
                      ),

                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior
                            .onDrag,

                        physics:
                        const BouncingScrollPhysics(),

                        padding:
                        const EdgeInsets.fromLTRB(
                          28,
                          34,
                          28,
                          40,
                        ),

                        child: AnimatedSwitcher(
                          duration:
                          const Duration(
                            milliseconds: 300,
                          ),

                          switchInCurve:
                          Curves.easeOutCubic,

                          switchOutCurve:
                          Curves.easeIn,

                          transitionBuilder:
                              (
                              child,
                              animation,
                              ) {
                            return FadeTransition(
                              opacity: animation,
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
                                  animation,
                                ),
                                child: child,
                              ),
                            );
                          },

                          child: _emailSent
                              ? _successContent()
                              : _formContent(),
                        ),
                      ),
                    ),
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
  // FORM CONTENT
  // ============================================================

  Widget _formContent() {
    return Form(
      key: _formKey,

      child: Column(
        key:
        const ValueKey(
          'forgot-form',
        ),

        crossAxisAlignment:
        CrossAxisAlignment.stretch,

        children: [

          // ICON

          const Center(
            child: _IconCircle(
              icon:
              Icons.lock_reset_rounded,
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // TITLE

          const Text(
            'Forgot Password?',
            textAlign:
            TextAlign.center,

            style: TextStyle(
              fontSize: 23,
              fontWeight:
              FontWeight.w800,
              color:
              AppColors.text,
              letterSpacing:
              -0.3,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // DESCRIPTION

          const Text(
            'Enter the email address linked to your account. We’ll send you instructions to securely reset your password.',
            textAlign:
            TextAlign.center,

            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color:
              AppColors.grey,
            ),
          ),

          const SizedBox(
            height: 30,
          ),

          // EMAIL LABEL

          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight:
              FontWeight.w600,
              color:
              AppColors.text,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // EMAIL FIELD

          TextFormField(
            controller:
            _emailController,

            enabled:
            !_isLoading,

            keyboardType:
            TextInputType
                .emailAddress,

            textInputAction:
            TextInputAction.done,

            autocorrect: false,

            enableSuggestions:
            false,

            autovalidateMode:
            AutovalidateMode
                .onUserInteraction,

            onFieldSubmitted:
                (_) {
              if (!_isLoading) {
                _sendResetLink();
              }
            },

            validator:
                (value) {
              final email =
                  value
                      ?.trim() ??
                      '';

              if (email.isEmpty) {
                return 'Please enter your email address';
              }

              final emailRegex =
              RegExp(
                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
              );

              if (!emailRegex
                  .hasMatch(
                email,
              )) {
                return 'Please enter a valid email address';
              }

              return null;
            },

            decoration:
            _inputDecoration(),
          ),

          const SizedBox(
            height: 26,
          ),

          // BUTTON

          _PrimaryButton(
            label:
            'Send Reset Link',

            icon:
            Icons.send_rounded,

            isLoading:
            _isLoading,

            onPressed:
            _isLoading
                ? null
                : _sendResetLink,
          ),

          const SizedBox(
            height: 20,
          ),

          // BACK LOGIN

          TextButton(
            onPressed:
            _isLoading
                ? null
                : () {
              Navigator.pop(
                context,
              );
            },

            child: const Text(
              'Back to Sign In',

              style: TextStyle(
                color:
                AppColors.primary,
                fontWeight:
                FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS CONTENT
  // ============================================================

  Widget _successContent() {
    return Column(
      key:
      const ValueKey(
        'forgot-success',
      ),

      crossAxisAlignment:
      CrossAxisAlignment.stretch,

      children: [

        // ICON

        const Center(
          child: _IconCircle(
            icon:
            Icons
                .mark_email_read_outlined,
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        // TITLE

        const Text(
          'Check Your Inbox',
          textAlign:
          TextAlign.center,

          style: TextStyle(
            fontSize: 23,
            fontWeight:
            FontWeight.w800,
            color:
            AppColors.text,
            letterSpacing:
            -0.3,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // EMAIL MESSAGE

        Text(
          'If an account exists for\n${_emailController.text.trim()}\nwe’ve sent password reset instructions.',
          textAlign:
          TextAlign.center,

          style:
          const TextStyle(
            fontSize: 13.5,
            height: 1.55,
            color:
            AppColors.grey,
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        // INFO BOX

        Container(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          decoration:
          BoxDecoration(
            color:
            AppColors.blueBg,

            borderRadius:
            BorderRadius
                .circular(
              15,
            ),

            border:
            Border.all(
              color:
              AppColors.primary
                  .withOpacity(
                0.10,
              ),
            ),
          ),

          child: const Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Icon(
                Icons
                    .info_outline_rounded,
                size: 18,
                color:
                AppColors.primary,
              ),

              SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Open the email and follow the reset instructions. Check your spam folder if you don’t see it.',
                  style:
                  TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color:
                    AppColors.text,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 26,
        ),

        // BACK LOGIN

        _PrimaryButton(
          label:
          'Back to Sign In',

          icon:
          Icons
              .arrow_back_rounded,

          isLoading:
          false,

          onPressed:
              () {
            Navigator.pop(
              context,
            );
          },
        ),

        const SizedBox(
          height: 14,
        ),

        // DIFFERENT EMAIL

        TextButton(
          onPressed:
          _useDifferentEmail,

          child: const Text(
            'Use a different email',

            style: TextStyle(
              color:
              AppColors.primary,
              fontWeight:
              FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        // RESEND

        TextButton.icon(
          onPressed:
          _isLoading
              ? null
              : () {
            setState(() {
              _emailSent =
              false;
            });

            Future.delayed(
              const Duration(
                milliseconds:
                180,
              ),
                  () {
                if (mounted) {
                  _sendResetLink();
                }
              },
            );
          },

          icon: const Icon(
            Icons
                .refresh_rounded,
            size: 17,
          ),

          label: const Text(
            'Resend Reset Email',
          ),

          style:
          TextButton.styleFrom(
            foregroundColor:
            AppColors.grey,
            textStyle:
            const TextStyle(
              fontSize: 12.5,
              fontWeight:
              FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration
  _inputDecoration() {
    return InputDecoration(
      hintText:
      'Enter your email',

      hintStyle:
      const TextStyle(
        color:
        AppColors.lightGrey,
        fontSize: 13.5,
      ),

      prefixIcon:
      const Icon(
        Icons.email_outlined,
        color:
        AppColors.grey,
        size: 20,
      ),

      filled: true,

      fillColor:
      const Color(
        0xFFFBFCFD,
      ),

      contentPadding:
      const EdgeInsets
          .symmetric(
        horizontal: 16,
        vertical: 18,
      ),

      errorStyle:
      const TextStyle(
        fontSize: 11,
      ),

      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          AppColors.border,
        ),
      ),

      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          AppColors.border,
        ),
      ),

      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          AppColors.primary,
          width: 1.3,
        ),
      ),

      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(
            0xFFE95C67,
          ),
        ),
      ),

      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius
            .circular(
          16,
        ),

        borderSide:
        const BorderSide(
          color:
          Color(
            0xFFE95C67,
          ),
          width: 1.3,
        ),
      ),
    );
  }
}

// ============================================================
// BACK BUTTON
// ============================================================

class _BackButton
    extends StatelessWidget {
  const _BackButton({
    required this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Material(
      color:
      Colors.white.withOpacity(
        0.18,
      ),

      borderRadius:
      BorderRadius.circular(
        14,
      ),

      child: InkWell(
        onTap:
        onTap,

        borderRadius:
        BorderRadius.circular(
          14,
        ),

        child: const SizedBox(
          width: 42,
          height: 42,

          child: Icon(
            Icons
                .arrow_back_ios_new_rounded,
            color:
            Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ICON CIRCLE
// ============================================================

class _IconCircle
    extends StatelessWidget {
  const _IconCircle({
    required this.icon,
  });

  final IconData icon;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: 68,
      height: 68,

      decoration:
      BoxDecoration(
        color:
        AppColors.blueBg,

        shape:
        BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color:
            AppColors.primary
                .withOpacity(
              0.08,
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

      child: Icon(
        icon,
        color:
        AppColors
            .logoTurquoiseDark,
        size: 30,
      ),
    );
  }
}

// ============================================================
// PRIMARY BUTTON
// ============================================================

class _PrimaryButton
    extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.isLoading,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(
      BuildContext context,
      ) {
    return AnimatedContainer(
      duration:
      const Duration(
        milliseconds: 220,
      ),

      height: 54,

      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          28,
        ),

        gradient:
        const LinearGradient(
          begin:
          Alignment.centerLeft,
          end:
          Alignment.centerRight,

          colors: [
            AppColors
                .logoTurquoise,
            AppColors
                .logoTurquoiseDark,
          ],
        ),

        boxShadow:
        onPressed != null
            ? [
          BoxShadow(
            color:
            AppColors
                .logoTurquoiseDark
                .withOpacity(
              0.30,
            ),
            blurRadius:
            18,
            offset:
            const Offset(
              0,
              6,
            ),
          ),
        ]
            : [],
      ),

      child:
      ElevatedButton(
        onPressed:
        onPressed,

        style:
        ElevatedButton.styleFrom(
          backgroundColor:
          Colors.transparent,

          disabledBackgroundColor:
          Colors.transparent,

          shadowColor:
          Colors.transparent,

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
            milliseconds: 180,
          ),

          child: isLoading
              ? const SizedBox(
            key:
            ValueKey(
              'loading',
            ),

            width: 22,
            height: 22,

            child:
            CircularProgressIndicator(
              strokeWidth: 2.3,
              color:
              Colors.white,
            ),
          )
              : Row(
            key:
            const ValueKey(
              'normal',
            ),

            mainAxisAlignment:
            MainAxisAlignment
                .center,

            children: [
              Icon(
                icon,
                color:
                Colors.white,
                size: 18,
              ),

              const SizedBox(
                width: 8,
              ),

              Text(
                label,

                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize:
                  15.5,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}