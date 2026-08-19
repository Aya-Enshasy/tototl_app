import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

// ============================================================================
// BOTTOM NAV ITEM MODEL
// ============================================================================

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
}

// ============================================================================
// PREMIUM BOTTOM NAV BAR
// ============================================================================

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          10,
        ),
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFFAFCFD),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: AppColors.cardBorder.withValues(
                alpha: 0.85,
              ),
              width: 0.8,
            ),
            boxShadow: [
              // soft wide shadow
              BoxShadow(
                color: AppColors.navy.withValues(
                  alpha: 0.055,
                ),
                blurRadius: 28,
                offset: const Offset(
                  0,
                  10,
                ),
              ),

              // closer soft shadow
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.025,
                ),
                blurRadius: 8,
                offset: const Offset(
                  0,
                  2,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: Row(
              children: List.generate(
                items.length,
                    (index) {
                  return Expanded(
                    child: _BottomNavButton(
                      item: items[index],
                      selected: index == currentIndex,
                      onTap: () {
                        if (index == currentIndex) {
                          return;
                        }

                        HapticFeedback.selectionClick();

                        onTap(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SINGLE NAV BUTTON
// ============================================================================

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.blue.withValues(
          alpha: 0.04,
        ),
        highlightColor: AppColors.blue.withValues(
          alpha: 0.025,
        ),
        child: SizedBox(
          height: 74,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ============================================================
              // VERY SUBTLE ACTIVE BACKGROUND
              // ============================================================

              AnimatedPositioned(
                duration: const Duration(
                  milliseconds: 260,
                ),
                curve: Curves.easeOutCubic,
                top: selected ? 6 : 10,
                left: 7,
                right: 7,
                bottom: 6,
                child: AnimatedOpacity(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.blue.withValues(
                            alpha: 0.055,
                          ),
                          AppColors.blue.withValues(
                            alpha: 0.018,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),
              ),

              // ============================================================
              // CONTENT
              // ============================================================

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ======================================================
                    // ICON
                    // ======================================================

                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 260,
                          ),
                          curve: Curves.easeOutCubic,
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: selected
                                ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(
                                  0xFF19C6C5,
                                ),
                                Color(
                                  0xFF087F9D,
                                ),
                              ],
                            )
                                : null,
                            color: selected
                                ? null
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                              11,
                            ),
                            boxShadow: selected
                                ? [
                              BoxShadow(
                                color: AppColors.blue.withValues(
                                  alpha: 0.22,
                                ),
                                blurRadius: 10,
                                offset: const Offset(
                                  0,
                                  4,
                                ),
                              ),
                            ]
                                : [],
                          ),
                          child: AnimatedScale(
                            duration: const Duration(
                              milliseconds: 220,
                            ),
                            curve: Curves.easeOutBack,
                            scale: selected ? 1 : 0.94,
                            child: Icon(
                              selected
                                  ? item.activeIcon
                                  : item.icon,
                              size: selected ? 19 : 20,
                              color: selected
                                  ? Colors.white
                                  : AppColors.lightGrey,
                            ),
                          ),
                        ),

                        // ==================================================
                        // BADGE
                        // ==================================================

                        if (item.badge != null &&
                            item.badge! > 0)
                          Positioned(
                            top: -4,
                            right: -7,
                            child: Container(
                              constraints: const BoxConstraints(
                                minWidth: 17,
                                minHeight: 17,
                              ),
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.red,
                                borderRadius:
                                BorderRadius.circular(
                                  10,
                                ),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.red
                                        .withValues(
                                      alpha: 0.22,
                                    ),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Text(
                                item.badge! > 99
                                    ? '99+'
                                    : '${item.badge}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7.5,
                                  fontWeight:
                                  FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    // ======================================================
                    // LABEL - ALWAYS VISIBLE
                    // ======================================================

                    AnimatedDefaultTextStyle(
                      duration: const Duration(
                        milliseconds: 220,
                      ),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: selected
                            ? AppColors.logoTurquoiseDark
                            : AppColors.lightGrey,
                        fontSize: 9.5,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.1,
                      ),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}