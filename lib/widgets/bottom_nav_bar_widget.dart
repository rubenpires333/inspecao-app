import 'package:flutter/material.dart';

/// Item do menu de navegação inferior
class BottomNavItem {
  final String label;
  final IconData icon;
  final IconData? activeIcon;
  final String screen;

  const BottomNavItem({
    required this.label,
    required this.icon,
    this.activeIcon,
    required this.screen,
  });
}

/// Widget reutilizável para BottomNavigationBar padrão do aplicativo
/// Garante consistência de design e facilita manutenção
class BottomNavBarWidget extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? backgroundColor;

  const BottomNavBarWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.selectedColor,
    this.unselectedColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: selectedColor ?? const Color(0xFF18778A),
        unselectedItemColor: unselectedColor ?? 
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        items: items.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.activeIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}
