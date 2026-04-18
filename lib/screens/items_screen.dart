import 'package:flutter/material.dart';
import 'entry_list_screen.dart';

class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EntryListScreen(
      title: '物品资料',
      assetPath: 'assets/data/items_decoded.json',
      emptyIcon: Icons.inventory_2,
      searchHint: '搜索物品...',
      maxCrossAxisExtent: 110, // 4 列
    );
  }
}
