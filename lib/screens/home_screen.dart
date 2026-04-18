import 'package:flutter/material.dart';
import 'final_map_screen.dart';
import 'recipes_screen.dart';

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
    PlaceholderScreen(title: '物品'),
    PlaceholderScreen(title: '宠物'),
    PlaceholderScreen(title: '图纸'),
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

class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$title功能开发中...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
