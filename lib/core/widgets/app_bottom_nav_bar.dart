import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

enum AppTab { home, gallery, daily, shop }

class AppBottomNavBar extends StatelessWidget {
  final AppTab currentTab;

  const AppBottomNavBar({
    super.key,
    required this.currentTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D2D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: isDark
            ? Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.2,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.09),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              tab: AppTab.home,
              label: 'Home',
              icon: Icons.home_rounded,
              route: '/home',
              isDark: isDark,
            ),
            _buildNavItem(
              context: context,
              tab: AppTab.gallery,
              label: 'Gallery',
              icon: Icons.grid_view_rounded,
              route: '/gallery',
              isDark: isDark,
            ),
            _buildNavItem(
              context: context,
              tab: AppTab.daily,
              label: 'Daily',
              icon: Icons.calendar_today_rounded,
              route: '/daily',
              isDark: isDark,
            ),
            _buildNavItem(
              context: context,
              tab: AppTab.shop,
              label: 'Shop',
              icon: Icons.shopping_bag_outlined,
              route: '/shop',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required AppTab tab,
    required String label,
    required IconData icon,
    required String route,
    required bool isDark,
  }) {
    final isActive = currentTab == tab;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!isActive) {
          context.go(route);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFB300) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isActive
                  ? Border.all(color: Colors.white.withValues(alpha: 0.40), width: 1.2)
                  : null,
              boxShadow: isActive
                  ? [
                      const BoxShadow(
                        color: Color(0xFFD87C00),
                        offset: Offset(0, 2.5),
                        blurRadius: 0,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                        offset: const Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isActive
                  ? Colors.white
                  : (isDark ? const Color(0xFF8DA2B5) : const Color(0xFF718096)),
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? (isDark ? const Color(0xFFFFC107) : const Color(0xFFE65100))
                  : (isDark ? const Color(0xFF8DA2B5) : const Color(0xFF718096)),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
