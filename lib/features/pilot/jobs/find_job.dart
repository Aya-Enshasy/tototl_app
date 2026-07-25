import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'job_details.dart';

// ---------------------------------------------------------------------------
// Job model
// ---------------------------------------------------------------------------
class DroneJob {
  final String title;
  final String company;
  final String location;
  final String dateRange;
  final String pay;
  final List<String> tags;
  final String match;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const DroneJob({
    required this.title,
    required this.company,
    required this.location,
    required this.dateRange,
    required this.pay,
    required this.tags,
    required this.match,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });
}

final List<DroneJob> jobs = [
  const DroneJob(
    title: 'Precision Mapping Project',
    company: 'GeoVision Solutions',
    location: 'Dubai, UAE',
    dateRange: 'May 28 – Jun 2, 2025',
    pay: '\$850 / day',
    tags: ['DJI Mavic 3E', 'LiDAR'],
    match: '96% Match',
    icon: Icons.change_history_rounded,
    iconBg: Color(0xFFE9F1FB),
    iconColor: Color(0xFF2952E3),
  ),
  const DroneJob(
    title: 'Construction Site Survey',
    company: 'BuildCorp',
    location: 'Riyadh, KSA',
    dateRange: 'Jun 1 – Jun 6, 2025',
    pay: '\$700 / day',
    tags: ['DJI Mavic 3', 'RTK'],
    match: '92% Match',
    icon: Icons.home_work_rounded,
    iconBg: Color(0xFFE9EDFB),
    iconColor: Color(0xFF17223B),
  ),
  const DroneJob(
    title: 'Oil & Gas Inspection',
    company: 'PetroScan Global',
    location: 'Doha, Qatar',
    dateRange: 'May 30 – Jun 3, 2025',
    pay: '\$900 / day',
    tags: ['DJI Mavic 3T', 'Thermal'],
    match: '95% Match',
    icon: Icons.bar_chart_rounded,
    iconBg: Color(0xFFFCE9EC),
    iconColor: Color(0xFFE0455A),
  ),
  const DroneJob(
    title: 'Agriculture Field Analysis',
    company: 'AgriTech Solutions',
    location: 'Abu Dhabi, UAE',
    dateRange: 'May 25 – May 29, 2025',
    pay: '\$650 / day',
    tags: ['DJI Mavic 3M', 'Multispectral'],
    match: '90% Match',
    icon: Icons.eco_rounded,
    iconBg: Color(0xFFE7F7EE),
    iconColor: Color(0xFF12B76A),
  ),
];


class FindDroneJobsScreen extends StatefulWidget {
  const FindDroneJobsScreen({super.key});

  @override
  State<FindDroneJobsScreen> createState() => _FindDroneJobsScreenState();
}

class _FindDroneJobsScreenState extends State<FindDroneJobsScreen> {
  bool isListSelected = true;
  int currentNavIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildTopBar(),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFiltersRow1(),
            const SizedBox(height: 10),
            _buildFiltersRow2(),
            const SizedBox(height: 14),
            _buildListMapToggle(),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '25 jobs found',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                itemCount: jobs.length,
                itemBuilder: (context, index) => _buildJobCard(jobs[index]),
              ),
            ),

          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          // _iconCircleButton(Icons.arrow_back, () {}),
          Expanded(
            child: Text(
              'Find Drone Jobs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
         ],
      ),
    );
  }

  Widget _iconCircleButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.chipBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.navy),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.chipBorder),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: AppColors.grey, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search jobs, company, location...',
                    style: TextStyle(color: AppColors.grey, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.chipBorder),
            ),
            child: Icon(Icons.tune, size: 20, color: AppColors.navy),
          ),
        ],
      ),
    );
  }

  Widget _dropdownChip(String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.navy),
        ],
      ),
    );
  }

  Widget _dateChip(String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 15, color: AppColors.navy),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 18, color: AppColors.navy),
        ],
      ),
    );
  }

  Widget _buildFiltersRow1() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _dropdownChip('Country'),
          const SizedBox(width: 10),
          _dropdownChip('State'),
          const SizedBox(width: 10),
          _dropdownChip('City'),
          const SizedBox(width: 10),
          _dropdownChip('Drone Type'),
        ],
      ),
    );
  }

  Widget _buildFiltersRow2() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _dropdownChip('Pay Range'),
          const SizedBox(width: 10),
          _dateChip('May 20 – Jun 5'),
        ],
      ),
    );
  }

  Widget _buildListMapToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: AppColors.chipBorder),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isListSelected = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isListSelected ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune,
                          size: 17,
                          color: isListSelected ? Colors.white : AppColors.navy),
                      const SizedBox(width: 6),
                      Text(
                        'List',
                        style: TextStyle(
                          color: isListSelected ? Colors.white : AppColors.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => isListSelected = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: !isListSelected ? AppColors.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 17,
                          color: !isListSelected ? Colors.white : AppColors.navy),
                      const SizedBox(width: 6),
                      Text(
                        'Map',
                        style: TextStyle(
                          color: !isListSelected ? Colors.white : AppColors.navy,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(DroneJob job) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JobDetailsScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: job.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    job.icon,
                    color: job.iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        job.company,
                        style: TextStyle(
                          color: AppColors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.bookmark_border_rounded,
                  color: AppColors.grey,
                  size: 22,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 15,
                  color: AppColors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  job.location,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(
                  Icons.calendar_today_outlined,
                  size: 13,
                  color: AppColors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  job.dateRange,
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  job.pay,
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                ...job.tags.map(
                      (t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _tagChip(t),
                  ),
                ),
                const Spacer(),
                _matchBadge(job.match),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.tagBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.navy,
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _matchBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.greenBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.green,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.home_outlined, 'label': 'Home'},
      {'icon': Icons.work_outline_rounded, 'label': 'Jobs'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Messages'},
      {'icon': Icons.notifications_none_rounded, 'label': 'Notifications'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.chipBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final selected = i == currentNavIndex;
          final isJobs = i == 1;
          return GestureDetector(
            onTap: () => setState(() => currentNavIndex = i),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    isJobs
                        ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        items[i]['icon'] as IconData,
                        size: 20,
                        color: selected ? Colors.white : AppColors.grey,
                      ),
                    )
                        : Icon(
                      items[i]['icon'] as IconData,
                      size: 22,
                      color: selected ? AppColors.blue : AppColors.grey,
                    ),
                    if (i == 3)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints:
                          const BoxConstraints(minWidth: 15, minHeight: 15),
                          child: const Text(
                            '3',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  items[i]['label'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? AppColors.blue : AppColors.grey,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
