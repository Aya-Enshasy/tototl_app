import 'package:flutter/material.dart';
import 'package:tototl_app/features/pilot/home/widgets/job_card.dart';
import '../widgets/drone_hero_image.dart';
import '../widgets/home_header.dart';
import '../widgets/match_card.dart';
import '../widgets/my_drone_card.dart';
import '../widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 👈 خلفية الصورة تغطي الشاشة كاملة
          Positioned.fill(
            child: Image.asset(
              "assets/images/home_bac.png", // ضع مسار الصورة هنا
              fit: BoxFit.fill,
            ),
          ),

          // 👈 المحتوى فوق الخلفية
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HomeHeader(),
                  const SizedBox(height: 18),
                  const SizedBox(height: 18),
                  const SizedBox(height: 18),
                  // DroneHero(),
                  const SizedBox(height: 18),
                  MyDroneCard(),
                  const SizedBox(height: 16),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: WeatherCard()),
                        const SizedBox(width: 14),
                        Expanded(child: MatchCard()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Recommended Jobs for You',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                      Text(
                        'See all',
                        style: TextStyle(
                          color: Color(0xFF3B6BF5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  JobCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
