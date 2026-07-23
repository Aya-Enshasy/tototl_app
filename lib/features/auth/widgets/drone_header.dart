import 'package:flutter/material.dart';

class DroneHeader extends StatelessWidget {
  const DroneHeader({super.key});

  @override
  Widget build(BuildContext context) {

    return Stack(
      fit: StackFit.expand,
      children: [

        /// Background
        Image.asset(
          "assets/images/drone_login.png",
          fit: BoxFit.cover,
        ),

        /// Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [

                Colors.black.withOpacity(.12),

                Colors.black.withOpacity(.18),

                Colors.black.withOpacity(.35),

              ],
            ),
          ),
        ),

        /// Safe Area
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              children: [

                const SizedBox(height: 10),

                /// Logo
                Image.asset(
                  "assets/images/logo.png",
                  width: 78,
                ),

                const SizedBox(height: 8),

                /// TOTOTL
                const Text(
                  "TOTOTL",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),

                const SizedBox(height: 2),

                /// INTGRX
                const Text(
                  "I N T G R X",
                  style: TextStyle(
                    color: Color(0xff3568FF),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 5,
                  ),
                ),

                const SizedBox(height: 16),

                /// Platform Text
                Row(
                  children: [

                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white38,
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Text(
                      "DRONE PILOT & COMPANY PLATFORM",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w300,
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.white38,
                      ),
                    ),
                  ],
                ),

                const Spacer(),


              ],
            ),
          ),
        ),
      ],
    );
  }
}