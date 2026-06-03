import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationShell extends StatelessWidget {
  final Widget child;

  const NavigationShell({super.key, required this.child});

  static const _mainRoutes = [
    _NavItem('/', Icons.dashboard_outlined, Icons.dashboard, 'Главная'),
    _NavItem('/ports', Icons.anchor_outlined, Icons.anchor, 'Порты'),
    _NavItem('/fleet', Icons.directions_boat_outlined, Icons.directions_boat, 'Флот'),
    _NavItem('/market', Icons.store_outlined, Icons.store, 'Рынок'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;

    // Determine selected index for bottom nav
    int currentIndex = 0;
    for (int i = 0; i < _mainRoutes.length; i++) {
      if (currentLocation == _mainRoutes[i].route ||
          (i == 0 && currentLocation == '/') ||
          (i > 0 && currentLocation.startsWith(_mainRoutes[i].route))) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == 4) {
            _showMoreMenu(context);
          } else {
            context.go(_mainRoutes[index].route);
          }
        },
        items: [
          for (final item in _mainRoutes)
            BottomNavigationBarItem(
              icon: Icon(item.iconOutline),
              activeIcon: Icon(item.iconFilled),
              label: item.label,
            ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Ещё',
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF14213D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Color(0xFF2196F3).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  margin: const EdgeInsets.only(bottom: 16),
                ),
                _menuItem(ctx, Icons.route_outlined, 'Рейсы', '/voyages'),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                _menuItem(ctx, Icons.account_balance_outlined, 'Финансы', '/finance'),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                _menuItem(ctx, Icons.factory_outlined, 'Производство', '/production'),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                _menuItem(ctx, Icons.people_outlined, 'Персонал', '/personnel'),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                _menuItem(ctx, Icons.settings_outlined, 'Настройки', '/settings'),
                const Divider(height: 1, color: Color(0xFF1E3A5F)),
                _menuItem(ctx, Icons.business_outlined, 'Профиль', '/profile'),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF9E9E9E), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFBDBDBD),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}

class _NavItem {
  final String route;
  final IconData iconOutline;
  final IconData iconFilled;
  final String label;

  const _NavItem(
      this.route, this.iconOutline, this.iconFilled, this.label);
}
