import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tototl_app/features/auth/widgets/choose_account.dart';

import '../../core/navigation/bottom_navbar.dart';

// تأكد من عمل import لملف شاشة اختيار نوع الحساب إذا كانت في ملف منفصل
// import 'choose_account_type_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;

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
          // ==========================================
          // الطبقة 1: صورة الخلفية تمتد للقسم العلوي والجزء الخلفي للـ Sheet
          // ==========================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.52, // تمتد لتظهر الجبال خلف انحناء الـ Bottom Sheet
            child: Image.asset(
              'assets/images/drone_login.png', // صورة الخلفية الحاوية على الدرون والجبال
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // ==========================================
          // الطبقة 2: הـ Gradient Overlay الداكن المخصص
          // ==========================================
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
                    const Color(0xFF163A69).withOpacity(0.35),
                    const Color(0xFF0B1731).withOpacity(0.70),
                  ],
                ),
              ),
            ),
          ),

          // ==========================================
          // الطبقة 3: عناصر الهيدر (اللوجو والنصوص العلوية)
          // ==========================================
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            height: size.height * 0.42,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // اللوجو بحجم 70px
                  Image.asset(
                    'assets/images/logo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),

                  // اسم TOTOTL ببنط 42 ووزن ExtraBold و LetterSpacing -1
                  const Text(
                    'TOTOTL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.1,
                    ),
                  ),

                  // كلمة INTGRX باللون #3E63F4 وتباعد 4.5
                  const Text(
                    'I N T G R X',
                    style: TextStyle(
                      color: Color(0xFF3E63F4),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 5.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // النص السفلي مع خطين بعرض 45px
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 45, height: 1, color: Colors.white38),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                      Container(width: 45, height: 1, color: Colors.white38),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ==========================================
          // الطبقة 4: الـ Bottom Sheet الأبيض يطفو فوق الخلفية
          // ==========================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.65, // تغطي 60% من الشاشة وتبدأ أسفل الدرون والجبال
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
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome Back
                    const Center(
                      child: Text(
                        'Welcome Back',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
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
                          color: Color(0xFF8F93A3),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // حقل الإيميل ارتفاع 56px
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextField(
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 13.5),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF9E9E9E), size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF3F6DFB)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // حقل كلمة المرور
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 56,
                      child: TextField(
                        obscureText: !_isPasswordVisible,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: const TextStyle(color: Color(0xFFC0C0C0), fontSize: 13.5),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF9E9E9E), size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF9E9E9E),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFF3F6DFB)),
                          ),
                        ),
                      ),
                    ),

                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF3F6DFB),
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // زر Sign In بالتدرج اللوني والارتفاع المظبوط 54px و Radius 28
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF3F6DFB), // أزرق مخصص
                            Color(0xFF8E63FF), // بنفسجي مخصص
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3F6DFB).withOpacity(0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.send_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // فاصل or continue with
                    Row(
                      children: const [
                        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12.5),
                          ),
                        ),
                        Expanded(child: Divider(color: Color(0xFFE5E7EB), thickness: 1)),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // روابط إنشاء الحساب و Guest
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Color(0xFF757575), fontSize: 13.5),
                        ),
              GestureDetector(
                onTap: () {
                  // الانتقال باستخدام شاشة شفافة لتظل شاشة اللوجن ظاهرة بالخلفية
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      opaque: false, // هاد السطر بخلي الشاشة اللي تحتها ما تختفي
                      barrierDismissible: true,
                      pageBuilder: (context, _, __) => const ChooseAccountTypeScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        // تأثير ظهور ناعم جداً للطبقة الشفافة
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                child: const Text(
                  'Create Account',
                  style: TextStyle(
                    color: Color(0xFF3F6DFB),
                    fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}