import 'package:flutter/material.dart';
import 'final_map_screen.dart';
import 'recipes_screen.dart';
import 'items_screen.dart';
import 'pets_screen.dart';
import 'builds_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    FinalMapScreen(),
    RecipesScreen(),
    ItemsScreen(),
    PetsScreen(),
    BuildsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
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
  }
}
