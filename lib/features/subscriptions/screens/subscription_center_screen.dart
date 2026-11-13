import 'package:flutter/material.dart';

import 'plan_selection_screen.dart';

/// Backwards-compatible entrypoint used by pilot, company, and quota dialogs.
/// All plan entrypoints now render the same premium design.
class SubscriptionCenterScreen extends StatelessWidget {
  const SubscriptionCenterScreen({super.key, this.upgradeOnly = false});

  final bool upgradeOnly;

  @override
  Widget build(BuildContext context) =>
      PlanSelectionScreen(upgradeOnly: upgradeOnly);
}
