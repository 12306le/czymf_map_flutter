import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';
import '../widgets/fluxdo_shell.dart';
import 'builds_screen.dart';
import 'final_map_screen.dart';
import 'items_screen.dart';
import 'pets_screen.dart';
import 'recipes_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _screens = [
    FinalMapScreen(),
    RecipesScreen(),
    ItemsScreen(),
    PetsScreen(),
    BuildsScreen(),
  ];

  static const List<NavigationDestination> _destinations = [
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map_rounded),
      label: '地图',
    ),
    NavigationDestination(
      icon: Icon(Icons.restaurant_menu_outlined),
      selectedIcon: Icon(Icons.restaurant_menu_rounded),
      label: '食谱',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: '物品',
    ),
    NavigationDestination(
      icon: Icon(Icons.pets_outlined),
      selectedIcon: Icon(Icons.pets_rounded),
      label: '宠物',
    ),
    NavigationDestination(
      icon: Icon(Icons.home_work_outlined),
      selectedIcon: Icon(Icons.home_work_rounded),
      label: '图纸',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final index = provider.tabIndex.clamp(0, _screens.length - 1);
        return FluxdoShell(
          selectedIndex: index,
          onDestinationSelected: provider.switchTab,
          destinations: _destinations,
          body: IndexedStack(
            index: index,
            children: _screens,
          ),
        );
      },
    );
  }
}
