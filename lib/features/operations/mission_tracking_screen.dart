// mission_tracking_screen.dart
//
// Backward-compatible router. Every existing call site in the app
// (mission_details_screen.dart, application_details_screen.dart,
// company_application_detail_screen.dart, company_job_detail_screen.dart)
// calls:
//
//   MissionTrackingScreen(mission: mission, isCompany: true/false)
//
// so this file keeps that exact name + constructor and simply
// delegates to the dedicated pilot / company screens — no other
// file in the app needs to change.

import 'package:flutter/material.dart';
import '../company/MissionTrackingCompanyScreen.dart';
import '../pilot/MissionTrackingPilotScreen.dart';

import 'operation_store.dart';

class MissionTrackingScreen extends StatelessWidget {
  const MissionTrackingScreen({
    super.key,
    required this.mission,
    required this.isCompany,
  });

  final Mission mission;
  final bool isCompany;

  @override
  Widget build(BuildContext context) => isCompany
      ? MissionTrackingCompanyScreen(mission: mission)
      : MissionTrackingPilotScreen(mission: mission);
}
