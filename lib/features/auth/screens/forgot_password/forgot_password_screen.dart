import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _emailSent = true);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.48,
            child: Image.asset(
              'assets/images/login_background.jpeg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.48,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.logoNavy.withOpacity(0.18),
                    AppColors.logoNavy.withOpacity(0.80),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8),
              child: _BackButton(onTap: () => Navigator.pop(context)),
            ),
          ),
          Positioned(
            top: size.height * 0.12,
            left: 24,
            right: 24,
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 86,
                  height: 86,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'TOTOTL',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
                const Text(
                  'I N T G R X',
                  style: TextStyle(
                    color: AppColors.logoTurquoiseLight,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.60,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(48),
                  topRight: Radius.circular(48),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _emailSent ? _successContent() : _formContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formContent() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: _IconCircle(icon: Icons.lock_reset_rounded),
          ),
          const SizedBox(height: 18),
          const Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No worries. Enter your email address and we’ll send you a link to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.grey),
          ),
          const SizedBox(height: 30),
          const Text(
            'Email',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Please enter your email address';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            decoration: _inputDecoration(),
          ),
          const SizedBox(height: 26),
          _PrimaryButton(label: 'Send Reset Link', icon: Icons.send_rounded, onPressed: _sendResetLink),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Back to Sign In',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _successContent() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _IconCircle(icon: Icons.mark_email_read_outlined)),
        const SizedBox(height: 18),
        const Text(
          'Check Your Inbox',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: AppColors.text),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent a password reset link to\n${_emailController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, height: 1.5, color: AppColors.grey),
        ),
        const SizedBox(height: 30),
        _PrimaryButton(label: 'Back to Sign In', icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => setState(() => _emailSent = false),
          child: const Text(
            'Use a different email',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() => InputDecoration(
        hintText: 'Enter your email',
        hintStyle: const TextStyle(color: AppColors.lightGrey, fontSize: 13.5),
        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.grey, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary)),
      );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),
      );
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 66,
        height: 66,
        decoration: const BoxDecoration(color: AppColors.blueBg, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.logoTurquoiseDark, size: 30),
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(colors: [AppColors.logoTurquoise, AppColors.logoTurquoiseDark]),
          boxShadow: [BoxShadow(color: AppColors.logoTurquoiseDark.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 18),
          label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          ),
        ),
      );
}
