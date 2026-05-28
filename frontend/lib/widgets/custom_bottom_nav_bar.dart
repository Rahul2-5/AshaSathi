import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/widgets/common/common_widgets.dart';
import 'package:frontend/constants/app_colors.dart';

class CustomBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int>? onDestinationSelected;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 6, top: 4),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(30),
        blur: 24,
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            indicatorColor: isDark
                ? AppColors.teal.withValues(alpha: 0.25)
                : AppColors.teal.withValues(alpha: 0.15),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.accentCyan : AppColors.teal,
                );
              }
              return TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFF9AA7B3)
                    : const Color(0xFF6A7480),
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: isDark ? AppColors.accentCyan : AppColors.teal,
                  size: 26,
                );
              }
              return IconThemeData(
                color: isDark
                    ? const Color(0xFF8B99A6)
                    : const Color(0xFF808B96),
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) async {
              if (currentIndex == index) return;
              
              if (onDestinationSelected != null) {
                onDestinationSelected!(index);
              } else {
                // Default behavior when used outside MainNavigation
                // Push and remove until /main with initialIndex
                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                  '/main',
                  (route) => false,
                  arguments: index,
                );
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: l10n.tr('nav.dashboard'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_add_alt_1_outlined),
                selectedIcon: const Icon(Icons.person_add_alt_1),
                label: l10n.tr('nav.addPatient'),
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(Icons.groups_rounded),
                label: 'Family',
              ),
              NavigationDestination(
                icon: const Icon(Icons.insert_chart_outlined_rounded),
                selectedIcon: const Icon(Icons.insert_chart_rounded),
                label: l10n.tr('nav.phcPortal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
