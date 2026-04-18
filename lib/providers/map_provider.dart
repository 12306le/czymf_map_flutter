import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_data.dart';
import '../services/map_service.dart';

class MapProvider with ChangeNotifier {
  final MapService _mapService = MapService();

  bool _isLoading = true;
  final Set<int> _selectedCategories = {};
  List<MapPoint> _visiblePoints = [];
  String _searchQuery = '';
  List<ItemInfo> _searchResults = [];

  // 图标缩放（0.5 ~ 2.5）
  double _iconScale = 1.0;

  // 跨 tab 导航
  int _tabIndex = 0;
  int? _focusRequestCatId;

  bool get isLoading => _isLoading;
  Set<int> get selectedCategories => _selectedCategories;
  List<MapPoint> get visiblePoints => _visiblePoints;
  String get searchQuery => _searchQuery;
  List<ItemInfo> get searchResults => _searchResults;
  double get iconScale => _iconScale;
  int get tabIndex => _tabIndex;
  int? get focusRequestCatId => _focusRequestCatId;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _mapService.loadData();
      await _loadPreferences();
      _updateVisiblePoints();
    } catch (e, stackTrace) {
      print('❌ MapProvider初始化失败: $e');
      print('堆栈跟踪: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = prefs.getStringList('selected_categories');
    if (savedCategories != null) {
      _selectedCategories
        ..clear()
        ..addAll(savedCategories.map((e) => int.parse(e)));
    }
    final savedScale = prefs.getDouble('icon_scale');
    if (savedScale != null) {
      _iconScale = savedScale.clamp(0.5, 2.5);
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_categories',
      _selectedCategories.map((e) => e.toString()).toList(),
    );
  }

  Future<void> setIconScale(double value) async {
    _iconScale = value.clamp(0.5, 2.5);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('icon_scale', _iconScale);
    notifyListeners();
  }

  /// 切到指定 tab，可选 focus 到某个 cat_id（用于食谱→地图联动）
  void switchTab(int index, {int? focusCatId}) {
    _tabIndex = index;
    if (focusCatId != null) {
      _selectedCategories.add(focusCatId);
      _updateVisiblePoints();
      _savePreferences();
      _focusRequestCatId = focusCatId;
    }
    notifyListeners();
  }

  void consumeFocusRequest() {
    _focusRequestCatId = null;
  }

  /// 通过物品名称（如"胡萝卜"）查找 cat_id，查到则返回
  int? findCatIdByName(String name) {
    final results = _mapService.search(name);
    for (final item in results) {
      if (item.name == name) return item.catId;
    }
    if (results.isNotEmpty) return results.first.catId;
    return null;
  }

  void toggleCategory(int catId) {
    if (_selectedCategories.contains(catId)) {
      _selectedCategories.remove(catId);
    } else {
      _selectedCategories.add(catId);
    }
    _updateVisiblePoints();
    _savePreferences();
    notifyListeners();
  }

  void selectAllInType(String typeIndex) {
    final items = _mapService.getItemsByType(typeIndex);
    for (var item in items) {
      _selectedCategories.add(item.catId);
    }
    _updateVisiblePoints();
    _savePreferences();
    notifyListeners();
  }

  void deselectAllInType(String typeIndex) {
    final items = _mapService.getItemsByType(typeIndex);
    for (var item in items) {
      _selectedCategories.remove(item.catId);
    }
    _updateVisiblePoints();
    _savePreferences();
    notifyListeners();
  }

  void clearSelection() {
    _selectedCategories.clear();
    _updateVisiblePoints();
    _savePreferences();
    notifyListeners();
  }

  void _updateVisiblePoints() {
    _visiblePoints = _mapService
        .getAllPoints()
        .where((point) => _selectedCategories.contains(point.catId))
        .toList();
  }

  void search(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _mapService.search(query);
    }
    notifyListeners();
  }

  void selectSearchResult(ItemInfo item) {
    _selectedCategories.add(item.catId);
    _updateVisiblePoints();
    _savePreferences();
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }

  List<String> getCategories() => _mapService.getCategories();

  List<ItemInfo> getItemsByType(String typeIndex) =>
      _mapService.getItemsByType(typeIndex);

  ItemInfo? getItemByCategoryId(int catId) =>
      _mapService.getItemByCategoryId(catId);

  List<MapPoint> getPointsByCategoryId(int catId) =>
      _mapService.getPointsByCategoryId(catId);
}
