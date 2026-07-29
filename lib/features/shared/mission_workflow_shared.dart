// mission_workflow_shared.dart
//
// Shared building blocks for the mission workflow screens
// (pilot side + company side). Keeping them in one file avoids
// duplicating the timeline/card visuals between the two screens.
//
// Import this file from both mission_tracking_pilot_screen.dart
// and mission_tracking_company_screen.dart.

import 'package:flutter/material.dart' hide StepState;
import '../../core/theme/app_colors.dart';

/// What kind of interaction a step needs from the user.
/// Driving the visuals (icon / color / body layout) off this
/// enum is what makes every step "read" correctly at a glance:
/// upload steps look like upload steps, decisions look like
/// decisions, plain confirmations look like confirmations.
enum StepKind { document, signature, confirm, choice, proof, rating }

extension StepKindStyle on StepKind {
  String get label => switch (this) {
    StepKind.document => 'Upload',
    StepKind.signature => 'Sign',
    StepKind.confirm => 'Confirm',
    StepKind.choice => 'Choose',
    StepKind.proof => 'Attach proof',
    StepKind.rating => 'Rate',
  };

  IconData get badgeIcon => switch (this) {
    StepKind.document => Icons.upload_file_rounded,
    StepKind.signature => Icons.draw_rounded,
    StepKind.confirm => Icons.touch_app_rounded,
    StepKind.choice => Icons.tune_rounded,
    StepKind.proof => Icons.image_rounded,
    StepKind.rating => Icons.star_rounded,
  };

  Color get tint => switch (this) {
    StepKind.document => AppColors.blue,
    StepKind.signature => AppColors.orange,
    StepKind.confirm => AppColors.green,
    StepKind.choice => AppColors.gold,
    StepKind.proof => AppColors.blue,
    StepKind.rating => AppColors.gold,
  };

  /// Whether this kind renders as an "attachment tile" (drop-zone
  /// style box) instead of a plain button.
  bool get isAttachmentStyle =>
      this == StepKind.document ||
      this == StepKind.signature ||
      this == StepKind.proof;
}

/// The visual/behavioral state of a step, independent of its kind.
enum StepState { done, current, waitingOnOther, upcoming }

extension StepStateStyle on StepState {
  String get label => switch (this) {
    StepState.done => 'Done',
    StepState.current => 'Your turn',
    StepState.waitingOnOther => 'Waiting on other party',
    StepState.upcoming => 'Upcoming',
  };

  Color get color => switch (this) {
    StepState.done => AppColors.green,
    StepState.current => AppColors.blue,
    StepState.waitingOnOther => AppColors.orange,
    StepState.upcoming => AppColors.lightGrey,
  };

  IconData get icon => switch (this) {
    StepState.done => Icons.check_rounded,
    StepState.current => Icons.play_arrow_rounded,
    StepState.waitingOnOther => Icons.hourglass_top_rounded,
    StepState.upcoming => Icons.lock_outline_rounded,
  };
}

/// One row of the workflow timeline.
class WorkflowStep {
  const WorkflowStep({
    required this.kind,
    required this.icon,
    required this.title,
    required this.description,
    required this.state,
    this.attachmentName,
    this.actionLabel,
    this.action,
    this.helper,
  });

  /// What this step is asking for (upload / sign / confirm / choose / rate).
  final StepKind kind;

  /// Icon shown inside the timeline circle when the step is
  /// current or upcoming (done steps always show a check mark).
  final IconData icon;

  final String title;
  final String description;
  final StepState state;

  /// File name to show once something has been attached/uploaded.
  final String? attachmentName;

  /// Label + callback for the primary call-to-action of this step.
  /// Null/null means the step has no action right now (e.g. it's
  /// waiting on the other party, or it's already done).
  final String? actionLabel;
  final VoidCallback? action;

  /// Small secondary note under the description, e.g.
  /// "سيتم إشعارك فور توقيع الطيار".
  final String? helper;
}

/// Slim progress bar + "x من y" label shown above the timeline.
class WorkflowProgressHeader extends StatelessWidget {
  const WorkflowProgressHeader({
    super.key,
    required this.completedCount,
    required this.totalCount,
  });

  final int completedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final ratio = totalCount == 0 ? 0.0 : completedCount / totalCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Mission progress',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$completedCount of $totalCount',
                style: const TextStyle(
                  color: AppColors.grey,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.blueBg,
              valueColor: AlwaysStoppedAnimation(
                ratio >= 1 ? AppColors.green : AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One timeline row: circle + connector line on the leading edge,
/// full step card on the trailing edge.
class WorkflowStepTimelineTile extends StatelessWidget {
  const WorkflowStepTimelineTile({
    super.key,
    required this.step,
    required this.isLast,
    this.extra,
  });

  final WorkflowStep step;
  final bool isLast;

  /// Optional extra widget injected right above the action button
  /// (used by the company screen for the payment-method picker).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final state = step.state;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: state == StepState.done
                      ? AppColors.green
                      : state == StepState.current
                      ? Colors.white
                      : AppColors.blueBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: state == StepState.done
                        ? AppColors.green
                        : state == StepState.current
                        ? AppColors.blue
                        : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Icon(
                  state == StepState.done ? Icons.check_rounded : step.icon,
                  color: state == StepState.done
                      ? Colors.white
                      : state == StepState.current
                      ? AppColors.blue
                      : AppColors.lightGrey,
                  size: 19,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == StepState.done
                        ? AppColors.green.withValues(alpha: 0.5)
                        : AppColors.cardBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: _StepCard(step: step, extra: extra),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, this.extra});

  final WorkflowStep step;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final state = step.state;
    final highlighted = state == StepState.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.blueBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? AppColors.blue : AppColors.cardBorder,
          width: highlighted ? 1.3 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  step.title,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _KindBadge(kind: step.kind),
            ],
          ),
          const SizedBox(height: 8),
          _StateBadge(state: state),
          const SizedBox(height: 8),
          Text(
            step.description,
            style: const TextStyle(
              color: AppColors.grey,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          if (step.helper != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.blue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    step.helper!,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (state != StepState.upcoming && step.kind.isAttachmentStyle) ...[
            const SizedBox(height: 12),
            _AttachmentTile(step: step),
          ],
          if (extra != null && state == StepState.current) ...[
            const SizedBox(height: 12),
            extra!,
          ],
          if (step.actionLabel != null &&
              step.action != null &&
              !step.kind.isAttachmentStyle) ...[
            const SizedBox(height: 12),
            _ActionButton(step: step),
          ],
        ],
      ),
    );
  }
}

/// Drop-zone style tile for document / signature / proof steps.
/// Shows a dashed placeholder before something is attached and a
/// solid "attached" tile with a checkmark afterward.
class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.step});

  final WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    final attached = step.attachmentName != null;
    if (attached) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.greenBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.green,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                step.attachmentName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.download_outlined,
              color: AppColors.green,
              size: 18,
            ),
          ],
        ),
      );
    }

    final canAct = step.action != null && step.actionLabel != null;
    return DottedBorderBox(
      color: canAct ? step.kind.tint : AppColors.lightGrey,
      onTap: step.action,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: (canAct ? step.kind.tint : AppColors.lightGrey).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              step.kind.badgeIcon,
              size: 17,
              color: canAct ? step.kind.tint : AppColors.lightGrey,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              step.actionLabel ?? 'Waiting on other party',
              style: TextStyle(
                color: canAct ? AppColors.navy : AppColors.grey,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (canAct)
            Icon(Icons.chevron_left_rounded, color: step.kind.tint, size: 20),
        ],
      ),
    );
  }
}

/// Simple dashed-border container used as an upload/attach drop zone.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.onTap,
  });

  final Widget child;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          color: color.withValues(alpha: 0.05),
        ),
        child: child,
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.step});

  final WorkflowStep step;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 44,
    child: FilledButton.icon(
      onPressed: step.action,
      icon: Icon(step.kind.badgeIcon, size: 18),
      label: Text(
        step.actionLabel!,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: step.kind.tint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class _KindBadge extends StatelessWidget {
  const _KindBadge({required this.kind});

  final StepKind kind;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: kind.tint.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(kind.badgeIcon, size: 11.5, color: kind.tint),
        const SizedBox(width: 4),
        Text(
          kind.label,
          style: TextStyle(
            color: kind.tint,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state});

  final StepState state;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: state.color.withValues(alpha: 0.4)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(state.icon, size: 12, color: state.color),
        const SizedBox(width: 5),
        Text(
          state.label,
          style: TextStyle(
            color: state.color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

/// Reusable payment-method picker (bank transfer / cash / wallet),
/// used inside the company's "open secure payment" step.
class PaymentMethodPicker extends StatelessWidget {
  const PaymentMethodPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String? selected;
  final ValueChanged<String> onSelected;

  static const options = <String>['Bank transfer', 'E-wallet', 'Cash'];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Choose payment method',
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final isSelected = option == selected;
          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            selectedColor: AppColors.blue,
            backgroundColor: AppColors.blueBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          );
        }).toList(),
      ),
    ],
  );
}

/// Generic small hero card for the top of the workflow screen.
class MissionHeroCard extends StatelessWidget {
  const MissionHeroCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.chips,
  });

  final String title;
  final String statusLabel;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 9, runSpacing: 9, children: chips),
      ],
    ),
  );
}

class MissionMetricChip extends StatelessWidget {
  const MissionMetricChip({super.key, required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.blueBg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.blue),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
