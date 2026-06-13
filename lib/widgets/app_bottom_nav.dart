import 'package:flutter/material.dart';

enum AppNavItem { home, game, scan, settings }

class AppBottomNav extends StatelessWidget {
  final AppNavItem? currentItem;
  final ValueChanged<AppNavItem> onItemSelected;

  const AppBottomNav({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
  });

  static const _items = [
    _NavItemData(AppNavItem.home, Icons.home_rounded, 'Home'),
    _NavItemData(AppNavItem.game, Icons.sports_esports_rounded, 'Game'),
    _NavItemData(AppNavItem.scan, Icons.document_scanner_rounded, 'Pindai'),
    _NavItemData(AppNavItem.settings, Icons.settings_rounded, 'Pengaturan'),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(36, 0, 36, 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final item in _items)
              _BottomNavButton(
                item: item,
                selected: item.value == currentItem,
                onTap: () => onItemSelected(item.value),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? Colors.white : scheme.primary;
    return Expanded(
      child: Tooltip(
        message: item.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 34 : 30,
                  height: selected ? 34 : 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? scheme.primary
                        : scheme.primaryContainer.withValues(alpha: 0.7),
                  ),
                  child: Icon(item.icon, color: color, size: 20),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scheme.primary,
                    fontSize: 9,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final AppNavItem value;
  final IconData icon;
  final String label;

  const _NavItemData(this.value, this.icon, this.label);
}
