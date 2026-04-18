import 'package:flutter/material.dart';
import 'entry_list_screen.dart';

class BuildsScreen extends StatelessWidget {
  const BuildsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EntryListScreen(
      title: '建筑图纸',
      assetPath: 'assets/data/builds_decoded.json',
      emptyIcon: Icons.home_work,
      searchHint: '搜索建筑...',
      maxCrossAxisExtent: 170,
    );
  }
}
