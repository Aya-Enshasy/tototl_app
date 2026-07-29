import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'operation_store.dart';

class MissionDetailsScreen extends StatefulWidget {
  const MissionDetailsScreen({
    super.key,
    required this.mission,
    required this.isCompany,
  });
  final Mission mission;
  final bool isCompany;
  @override
  State<MissionDetailsScreen> createState() => _MissionDetailsScreenState();
}

class _MissionDetailsScreenState extends State<MissionDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final job = widget.mission.application.job;
    final pilot = widget.mission.application.pilot;
    return Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
              ),
              const Expanded(
                child: Text(
                  'Mission Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 20),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.title,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    )),
                const SizedBox(height: 6),
                Text(
                  widget.isCompany
                      ? 'Pilot: ${pilot.name}'
                      : 'Company: ${job.company}',
                  style: const TextStyle(color: AppColors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: job.date,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        icon: Icons.payments_outlined,
                        label: 'Rate',
                        value: job.pay,
                      ),
                    ),
                    Expanded(
                      child: _Metric(
                        icon: Icons.flight_rounded,
                        label: 'Drone',
                        value: widget.mission.application.drone.name,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site location',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 144,
                  decoration: BoxDecoration(
                    color: AppColors.blueBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _MapGridPainter()),
                      ),
                      const Center(
                        child: Icon(
                          Icons.location_on_rounded,
                          color: AppColors.blue,
                          size: 38,
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            job.location,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  job.address == null || job.address!.isEmpty
                      ? 'Exact address is shared after approval.'
                      : job.address!,
                  style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Description',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  job.description,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Requirements',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...job.requirements.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.green,
                          size: 18,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Site files & attachments',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _FileRow(
                  icon: Icons.description_outlined,
                  title: widget.mission.contractFileName ?? 'Service contract',
                  detail: widget.mission.contractFileName == null
                      ? 'Not uploaded yet'
                      : 'Available',
                ),
                _FileRow(
                  icon: Icons.assignment_return_outlined,
                  title: widget.mission.terminationFileName ??
                      'Termination agreement',
                  detail: widget.mission.terminationFileName == null
                      ? 'Not uploaded yet'
                      : 'Available',
                ),
                _FileRow(
                  icon: Icons.image_outlined,
                  title: 'Site reference images',
                  detail: 'Available after approval',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openRequestSheet(context),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: const Text('Request schedule or rate change'),
          ),
          TextButton.icon(
            onPressed: () => _showCancelDialog(
              context,
            ),
            icon: const Icon(Icons.cancel_outlined, color: AppColors.red),
            label: const Text(
              'Cancel Job',
              style: TextStyle(color: AppColors.red),
            ),
          ),
          TextButton.icon(
            onPressed: () => _showActionDialog(
              context,
              'Open a dispute',
              'Tell us what happened and keep all mission evidence in the conversation.',
            ),
            icon: const Icon(Icons.flag_outlined, color: AppColors.orange),
            label: const Text(
              'Open a dispute',
              style: TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    ),
  );
  }
  void _openRequestSheet(BuildContext context) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request a change',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          const TextField(
            decoration: InputDecoration(
              labelText: 'New date, hours, or rate',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Reason',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change request sent for review.'),
                  ),
                );
              },
              child: const Text('Send Request'),
            ),
          ),
        ],
      ),
    ),
  );
  void _showActionDialog(BuildContext context, String title, String detail) =>
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$title request sent.')));
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );

  void _showCancelDialog(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancel Job'),
          content: const Text(
            'This will cancel the job workflow for both sides.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                OperationStore.instance.cancelMission(widget.mission);
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Job cancelled.')),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('Cancel Job'),
            ),
          ],
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.cardBorder),
    ),
    child: child,
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.blue, size: 18),
      const SizedBox(height: 6),
      Text(
        label,
        style: const TextStyle(color: AppColors.grey, fontSize: 10.5),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.navy,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.blueBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.blue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              Text(
                detail,
                style: const TextStyle(color: AppColors.grey, fontSize: 11.5),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.download_outlined,
          color: AppColors.lightGrey,
          size: 19,
        ),
      ],
    ),
  );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.11)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
