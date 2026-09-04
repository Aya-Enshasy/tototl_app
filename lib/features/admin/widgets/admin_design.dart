import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  static const bg = Color(0xFFF4F7F9);
  static const surface = Colors.white;
  static const ink = Color(0xFF071A35);
  static const muted = Color(0xFF66788C);
  static const muted2 = Color(0xFF98A5B5);
  static const border = Color(0xFFE3EAF0);

  static const navy = Color(0xFF092D43);
  static const navy2 = Color(0xFF0A5868);
  static const teal = Color(0xFF16C6C7);
  static const tealDark = Color(0xFF0D8AA5);
  static const tealSoft = Color(0xFFEAF9FA);

  static const pilot = Color(0xFF246BCE);
  static const pilotSoft = Color(0xFFECF4FF);

  static const company = Color(0xFF6B57D4);
  static const companySoft = Color(0xFFF2EFFF);

  static const success = Color(0xFF1D9E72);
  static const successSoft = Color(0xFFE9F8F1);

  static const warning = Color(0xFFB97800);
  static const warningSoft = Color(0xFFFFF6DF);

  static const danger = Color(0xFFE45252);
  static const dangerSoft = Color(0xFFFFEEEE);
}

String adminDate(DateTime? date) {
  if (date == null) return 'Not available';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String adminInitials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();

  if (words.isEmpty) return 'AD';

  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
  }

  return '${words.first[0]}${words.last[0]}'.toUpperCase();
}

String prettyStatus(String value) {
  final clean = value.trim().toLowerCase();

  switch (clean) {
    case 'pending':
      return 'Pending Review';
    case 'approved':
    case 'active':
    case 'verified':
      return 'Active';
    case 'rejected':
      return 'Rejected';
    case 'suspended':
      return 'Suspended';
    default:
      if (clean.isEmpty) return 'Unknown';
      return clean
          .split(RegExp(r'[_\s-]+'))
          .map(
            (e) => e.isEmpty
                ? e
                : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
          )
          .join(' ');
  }
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final clean = status.trim().toLowerCase();

    Color fg = AdminColors.warning;
    Color bg = AdminColors.warningSoft;
    IconData icon = Icons.schedule_rounded;

    if (clean == 'active' ||
        clean == 'approved' ||
        clean == 'verified') {
      fg = AdminColors.success;
      bg = AdminColors.successSoft;
      icon = Icons.verified_rounded;
    } else if (clean == 'rejected') {
      fg = AdminColors.danger;
      bg = AdminColors.dangerSoft;
      icon = Icons.cancel_rounded;
    } else if (clean == 'suspended') {
      fg = const Color(0xFF9A4B14);
      bg = const Color(0xFFFFF0E3);
      icon = Icons.pause_circle_filled_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: fg,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            prettyStatus(status),
            style: TextStyle(
              color: fg,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminInitialAvatar extends StatelessWidget {
  const AdminInitialAvatar({
    super.key,
    required this.name,
    this.isCompany = false,
    this.size = 54,
  });

  final String name;
  final bool isCompany;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isCompany
            ? AdminColors.companySoft
            : AdminColors.pilotSoft,
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: Text(
        adminInitials(name),
        style: TextStyle(
          color: isCompany
              ? AdminColors.company
              : AdminColors.pilot,
          fontSize: size * 0.31,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class AdminPageTitle extends StatelessWidget {
  const AdminPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        10,
        18,
        10,
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class AdminRoundButton extends StatelessWidget {
  const AdminRoundButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icon,
            color: AdminColors.ink,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AdminColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.ink.withOpacity(0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AdminColors.tealSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AdminColors.tealDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AdminColors.muted,
                          fontSize: 9.8,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.last = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final clean = value.trim().isEmpty
        ? 'Not provided'
        : value.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: AdminColors.tealDark,
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AdminColors.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                flex: 2,
                child: Text(
                  clean,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!last)
          const Divider(
            height: 1,
            color: AdminColors.border,
          ),
      ],
    );
  }
}

class AdminSearchField extends StatefulWidget {
  const AdminSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<AdminSearchField> createState() =>
      _AdminSearchFieldState();
}

class _AdminSearchFieldState
    extends State<AdminSearchField> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: (value) {
        widget.onChanged(value);
        setState(() {});
      },
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: AdminColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: AdminColors.muted2,
          fontSize: 11.5,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AdminColors.tealDark,
          size: 19,
        ),
        suffixIcon: widget.controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 17,
                ),
              ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AdminColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(
            color: AdminColors.teal,
            width: 1.2,
          ),
        ),
      ),
    );
  }
}

class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        72,
        28,
        32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 78,
            height: 78,
            decoration: const BoxDecoration(
              color: AdminColors.tealSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AdminColors.tealDark,
              size: 33,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.tealDark,
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
