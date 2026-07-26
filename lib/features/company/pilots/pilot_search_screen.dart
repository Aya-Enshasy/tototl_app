import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../pilot/shared/pilot_data.dart';
import '../../pilot/shared/pilot_public_profile_screen.dart';

class PilotSearchScreen extends StatefulWidget {
  const PilotSearchScreen({super.key});

  @override
  State<PilotSearchScreen> createState() => _PilotSearchScreenState();
}

class _PilotSearchScreenState extends State<PilotSearchScreen> {
  final _search = TextEditingController();
  String? _skill;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<PilotProfile> get _pilots {
    final query = _search.text.trim().toLowerCase();
    return pilotProfiles.where((pilot) {
      final queryMatches =
          query.isEmpty ||
          '${pilot.name} ${pilot.location} ${pilot.skills.join(' ')}'
              .toLowerCase()
              .contains(query);
      final skillMatches = _skill == null || pilot.skills.contains(_skill);
      return queryMatches && skillMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pilots = _pilots;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 6),
              child: Text(
                'Find Pilots',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Search verified pilots by experience and capability.',
                style: TextStyle(color: AppColors.grey, fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 17),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search pilots, skills, location...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.grey,
                  ),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _search.clear,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.grey,
                          ),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: AppColors.blue),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _Filter(
                    label: 'All',
                    active: _skill == null,
                    onTap: () => setState(() => _skill = null),
                  ),
                  const SizedBox(width: 8),
                  ...['Thermal', 'Imaging', 'LiDAR', 'Night Vision'].map(
                    (skill) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Filter(
                        label: skill,
                        active: _skill == skill,
                        onTap: () => setState(() => _skill = skill),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${pilots.length} pilots available',
                style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: pilots.isEmpty
                  ? const Center(
                      child: Text(
                        'No pilots match these filters',
                        style: TextStyle(color: AppColors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: pilots.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 11),
                      itemBuilder: (_, index) =>
                          _PilotCard(pilot: pilots[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PilotCard extends StatelessWidget {
  const _PilotCard({required this.pilot});
  final PilotProfile pilot;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PilotPublicProfileScreen(pilot: pilot),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.blueBg,
                  child: Text(
                    pilot.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            pilot.name,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.green,
                            size: 15,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${pilot.location} · ${pilot.experience} exp',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12.5,
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
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 17),
                const SizedBox(width: 4),
                Text(
                  '${pilot.rating} (${pilot.reviewCount})',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(
                  Icons.flight_takeoff_rounded,
                  color: AppColors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pilot.missions} missions',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: pilot.skills
                  .take(3)
                  .map(
                    (skill) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        skill,
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: active,
    onSelected: (_) => onTap(),
    selectedColor: AppColors.blue,
    labelStyle: TextStyle(
      color: active ? Colors.white : AppColors.navy,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    ),
    side: BorderSide(color: active ? AppColors.blue : AppColors.cardBorder),
  );
}
