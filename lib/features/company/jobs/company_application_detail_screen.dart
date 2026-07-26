import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../operations/company_offer_screen.dart';
import '../../operations/conversation_screen.dart';
import '../../operations/mission_tracking_screen.dart';
import '../../operations/operation_store.dart';
import '../../pilot/shared/pilot_data.dart';
import '../../pilot/shared/pilot_public_profile_screen.dart';

class CompanyApplicationDetailScreen extends StatelessWidget {
  const CompanyApplicationDetailScreen({super.key, required this.application});
  final PilotApplication application;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OperationStore.instance,
    builder: (_, _) {
      final mission = OperationStore.instance.missionFor(application.id);
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
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Applicant Detail',
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
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PilotPublicProfileScreen(pilot: application.pilot),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.blueBg,
                          child: Text(
                            application.pilot.name.substring(0, 1),
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                application.pilot.name,
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${application.pilot.location} · ${application.pilot.experience} exp',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${application.pilot.rating} rating · ${application.drone.name}',
                                style: const TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.lightGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Application',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      application.job.title,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      application.coverNote ?? 'No cover note added.',
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConversationScreen(
                        application: application,
                        isCompany: true,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                  label: const Text('Message Pilot'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => mission == null
                          ? CompanyOfferScreen(application: application)
                          : MissionTrackingScreen(
                              mission: mission,
                              isCompany: true,
                            ),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    mission == null ? 'Create Offer' : 'Open Mission',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
