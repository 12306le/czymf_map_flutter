import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import 'entry_list_screen.dart';

class PetsScreen extends StatelessWidget {
  const PetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EntryListScreen(
      title: '宠物大全',
      assetPath: 'assets/data/creationmagic_pet_food_decoded.json',
      emptyIcon: Icons.pets,
      searchHint: '搜索宠物 / 饲料...',
      subtitleBuilder: (GameEntry entry) => entry.nameExif ?? '',
    );
  }
}
