import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_data.dart';
import '../services/map_service.dart';

class MapProvider with ChangeNotifier {
  final MapService _mapService = MapService();
  
  bool _isLoading = true;
  Set<int> _selectedCategories = {};
  List<MapPoint> _visiblePoints = [];
  String _searchQuery = '';
  List<ItemInfo> _searchResults = [];

  bool get isLoading => _isLoading;
  Set<int> get selectedCategories => _selectedCategories;
  List<MapPoint> get visiblePoints => _visiblePoints;
  String get searchQuery => _searchQuery;
  List<ItemInfo> get searchResults => _searchResults;

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
      _selectedCategories = savedCategories.map((e) => int.parse(e)).toSet();
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selected_categories',
      _selectedCategories.map((e) => e.toString()).toList(),
    );
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
