import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _filters = [
    _ContactFilter(label: 'All', isAll: true, selected: true),
    _ContactFilter(
      label: 'GeoVision',
      imageUrl:
      'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?auto=format&fit=crop&w=150&q=80',
    ),
    _ContactFilter(
      label: 'BuildCore',
      imageUrl:
      'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?auto=format&fit=crop&w=150&q=80',
    ),
    _ContactFilter(
      label: 'SunPeak',
      imageUrl:
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=150&q=80',
    ),
    _ContactFilter(
      label: 'VoltEdge',
      imageUrl:
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
    ),
  ];

  static const _messages = [
    _MessageData(
      name: 'GeoVision Solutions',
      preview: 'Hi Aya! We would like to confir...',
      time: '9:41 AM',
      unreadCount: 2,
      imageUrl:
      'https://images.unsplash.com/photo-1614064641938-3bbee52942c7?auto=format&fit=crop&w=150&q=80',
    ),
    _MessageData(
      name: 'BuildCore Team',
      preview: 'Project site has been updated',
      time: '8:20 AM',
      unreadCount: 1,
      imageUrl:
      'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?auto=format&fit=crop&w=150&q=80',
    ),
    _MessageData(
      name: 'Michael Brown',
      preview: 'Thanks for your quick response!',
      time: 'Yesterday',
      unreadCount: 0,
      imageUrl:
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=150&q=80',
    ),
    _MessageData(
      name: 'SunPeak Energy',
      preview: 'When are you available?',
      time: 'Yesterday',
      unreadCount: 0,
      imageUrl:
      'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&w=150&q=80',
    ),
    _MessageData(
      name: 'VoltEdge Utilities',
      preview: 'The job has been accepted',
      time: 'May 24',
      unreadCount: 0,
      imageUrl:
      'https://images.unsplash.com/photo-1602524818485-11f9d1470af0?auto=format&fit=crop&w=150&q=80',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Messages',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _buildSearchBar(),
              const SizedBox(height: 16),
              _buildFilterRow(),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: _messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) =>
                _MessageTile(data: _messages[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.grey, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Search messages...',
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
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(Icons.tune, size: 20, color: AppColors.navy),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _ContactFilterChip(data: _filters[index]),
      ),
    );
  }
}

class _ContactFilter {
  final String label;
  final String? imageUrl;
  final bool isAll;
  final bool selected;

  const _ContactFilter({
    required this.label,
    this.imageUrl,
    this.isAll = false,
    this.selected = false,
  });
}

/// دائرة فلترة جهة اتصال واحدة أعلى شاشة الرسائل (All / اسم الشركة).
class _ContactFilterChip extends StatelessWidget {
  final _ContactFilter data;
  const _ContactFilterChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: data.selected ? AppColors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: data.isAll
              ? Container(
            decoration: const BoxDecoration(
              color: AppColors.blue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.apps_rounded,
                color: Colors.white, size: 20),
          )
              : ClipOval(
            child: Image.network(
              data.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.tagBg,
                child: const Icon(Icons.business,
                    color: AppColors.grey, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.label,
          style: TextStyle(
            fontSize: 11,
            color: data.selected ? AppColors.blue : AppColors.grey,
            fontWeight: data.selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _MessageData {
  final String name;
  final String preview;
  final String time;
  final int unreadCount;
  final String imageUrl;

  const _MessageData({
    required this.name,
    required this.preview,
    required this.time,
    required this.unreadCount,
    required this.imageUrl,
  });
}

/// صف محادثة واحد داخل قائمة الرسائل.
class _MessageTile extends StatelessWidget {
  final _MessageData data;
  const _MessageTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool unread = data.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          ClipOval(
            child: Image.network(
              data.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 52,
                height: 52,
                color: AppColors.tagBg,
                child: const Icon(Icons.person, color: AppColors.grey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.time,
                style: const TextStyle(color: AppColors.grey, fontSize: 11),
              ),
              const SizedBox(height: 8),
              if (unread)
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${data.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}
