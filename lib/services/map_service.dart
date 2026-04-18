import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lpinyin/lpinyin.dart';
import '../models/map_data.dart';

class MapService {
  MapData? _mapData;
  final Map<int, ItemInfo> _itemMap = {};
  final Map<int, List<MapPoint>> _pointsByCategory = {};

  // 搜索索引
  final Map<String, List<ItemInfo>> _searchIndex = {};

  // 过期活动 / 需要隐藏的 cat_id 黑名单（阿狸去哪儿等）
  static const Set<int> _excludedCatIds = {
    40001, 50006, 50007, 50008, 50009, 50010,
  };

  Future<void> loadData() async {
    try {
      print('🔄 开始加载地图数据...');
      final jsonString = await rootBundle.loadString('assets/data/data.json');
      print('✅ JSON文件加载成功，大小: ${jsonString.length} 字符');
      
      final jsonData = json.decode(jsonString);
      print('✅ JSON解析成功');
      
      _mapData = MapData.fromJson(jsonData);
      print('✅ MapData对象创建成功');
      
      _buildIndexes();
      print('✅ 索引构建完成');
      print('📊 数据统计: ${_mapData!.data.itemList.length} 个物品, ${_mapData!.data.xys.length} 个坐标点');
    } catch (e, stackTrace) {
      print('❌ 加载地图数据失败: $e');
      print('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  void _buildIndexes() {
    if (_mapData == null) return;

    // 构建物品映射
    for (var item in _mapData!.data.itemList) {
      if (_excludedCatIds.contains(item.catId)) continue;
      _itemMap[item.catId] = item;
    }

    // 按类别分组坐标点
    for (var point in _mapData!.data.xys) {
      if (_excludedCatIds.contains(point.catId)) continue;
      _pointsByCategory.putIfAbsent(point.catId, () => []).add(point);
    }

    // 构建搜索索引
    for (var item in _mapData!.data.itemList) {
      if (_excludedCatIds.contains(item.catId)) continue;
      // 中文名称
      final name = item.name.toLowerCase();
      _addToSearchIndex(name, item);

      // 拼音全拼
      final pinyin = PinyinHelper.getPinyinE(item.name, separator: '').toLowerCase();
      _addToSearchIndex(pinyin, item);

      // 拼音首字母
      final pinyinShort = PinyinHelper.getShortPinyin(item.name).toLowerCase();
      _addToSearchIndex(pinyinShort, item);
    }
  }

  void _addToSearchIndex(String key, ItemInfo item) {
    _searchIndex.putIfAbsent(key, () => []).add(item);
  }

  List<ItemInfo> search(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    final results = <ItemInfo>{};
    
    // 精确匹配
    for (var entry in _searchIndex.entries) {
      if (entry.key == lowerQuery) {
        results.addAll(entry.value);
      }
    }
    
    // 前缀匹配
    for (var entry in _searchIndex.entries) {
      if (entry.key.startsWith(lowerQuery)) {
        results.addAll(entry.value);
      }
    }
    
    // 包含匹配
    for (var entry in _searchIndex.entries) {
      if (entry.key.contains(lowerQuery)) {
        results.addAll(entry.value);
      }
    }
    
    return results.toList();
  }

  List<String> getCategories() {
    return _mapData?.data.itemType ?? [];
  }

  List<ItemInfo> getItemsByType(String typeIndex) {
    if (_mapData == null) return [];
    return _mapData!.data.itemList
        .where((item) => item.type.split('').contains(typeIndex))
        .toList();
  }

  List<MapPoint> getPointsByCategoryId(int catId) {
    return _pointsByCategory[catId] ?? [];
  }

  ItemInfo? getItemByCategoryId(int catId) {
    return _itemMap[catId];
  }

  List<MapPoint> getAllPoints() {
    return _mapData?.data.xys
            .where((p) => !_excludedCatIds.contains(p.catId))
            .toList() ??
        [];
  }
}
