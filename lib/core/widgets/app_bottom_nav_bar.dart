import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 3,
      height: 62,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (idx) {
        if (idx == currentIndex) return;
        switch (idx) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/trips');
            break;
          case 2:
            context.go('/transport');
            break;
          case 3:
            context.go('/maps');
            break;
          case 4:
            context.go('/settings');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.map_outlined, size: 22),
          selectedIcon: Icon(Icons.map, size: 22),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined, size: 22),
          selectedIcon: Icon(Icons.list_alt, size: 22),
          label: 'Recorridos',
        ),
        NavigationDestination(
          icon: Icon(Icons.directions_bus_outlined, size: 22),
          selectedIcon: Icon(Icons.directions_bus, size: 22),
          label: 'Líneas',
        ),
        NavigationDestination(
          icon: Icon(Icons.download_for_offline_outlined, size: 22),
          selectedIcon: Icon(Icons.download_for_offline, size: 22),
          label: 'Mapas',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined, size: 22),
          selectedIcon: Icon(Icons.settings, size: 22),
          label: 'Ajustes',
        ),
      ],
    );
  }
}
