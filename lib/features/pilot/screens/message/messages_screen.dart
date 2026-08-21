import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مسافة ثابتة من فوق
              const SizedBox(height: 24),
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
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _MessageGroupCard(items: _messages),
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

/// كرت أبيض واحد يحتوي كل المحادثات ورا بعض، مفصولة بخط رفيع (Divider).
class _MessageGroupCard extends StatelessWidget {
  final List<_MessageData> items;
  const _MessageGroupCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Container(
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : const Border(
                bottom: BorderSide(color: AppColors.cardBorder),
              ),
            ),
            child: _MessageTile(data: item),
          );
        }),
      ),
    );
  }
}

/// صف محادثة واحد داخل قائمة الرسائل.
class _MessageTile extends StatelessWidget {
  final _MessageData data;
  const _MessageTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final bool unread = data.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.all(14),
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