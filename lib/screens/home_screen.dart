import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import 'final_map_screen.dart';
import 'recipes_screen.dart';
import 'items_screen.dart';
import 'pets_screen.dart';
import 'builds_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _screens = [
    FinalMapScreen(),
    RecipesScreen(),
    ItemsScreen(),
    PetsScreen(),
    BuildsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, provider, _) {
        final index = provider.tabIndex.clamp(0, _screens.length - 1);
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => provider.switchTab(i),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.map),
                label: '地图',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.restaurant_menu),
                label: '食谱',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: '物品',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                label: '宠物',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.home_work),
                label: '图纸',
              ),
            ],
          ),
        );
      },
    );
  }
}
