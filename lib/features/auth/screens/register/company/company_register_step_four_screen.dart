import 'package:flutter/material.dart';
import 'package:tototl_app/features/subscriptions/screens/plan_selection_screen.dart';

/// Existing registration route preserved for all current navigation calls.
/// The shared subscription screen handles the onboarding-only dashboard exit.
class CompanyRegisterStepThreeScreen extends StatelessWidget {
  const CompanyRegisterStepThreeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlanSelectionScreen(onboarding: true);
}
