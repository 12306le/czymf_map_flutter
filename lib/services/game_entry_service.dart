import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_entry.dart';

/// 通用游戏条目数据服务（物品 / 宠物 / 建筑共用）
class GameEntryService {
  final String assetPath;
  GameEntryData? _data;

  GameEntryService(this.assetPath);

  Future<void> load() async {
    if (_data != null) return;
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    _data = GameEntryData.fromJson(jsonData);
  }

  List<GameEntry> all() => _data?.items ?? [];

  List<String> filters() {
    if (_data == null) return [];
    if (_data!.filters.isNotEmpty) return _data!.filters;
    final set = <String>{};
    for (final item in _data!.items) {
      final f = item.filter;
      if (f != null && f.isNotEmpty) set.add(f);
    }
    return set.toList()..sort();
  }

  List<GameEntry> search(String query) {
    final items = all();
    if (query.isEmpty) return items;
    final q = query.toLowerCase();
    return items.where((e) {
      return e.name.toLowerCase().contains(q) ||
          (e.pinyin?.toLowerCase().contains(q) ?? false) ||
          (e.nameExif?.toLowerCase().contains(q) ?? false) ||
          (e.keyBase?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  List<GameEntry> byFilter(String? filter) {
    final items = all();
    if (filter == null || filter.isEmpty) return items;
    return items.where((e) => e.filter == filter).toList();
  }
}
