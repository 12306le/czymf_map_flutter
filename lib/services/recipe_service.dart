import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/recipe.dart';

class RecipeService {
  RecipeData? _recipeData;
  Map<String, List<Recipe>> _ingredientIndex = {};

  Future<void> loadData() async {
    try {
      print('🔄 开始加载食谱数据...');
      final jsonString = await rootBundle.loadString('assets/data/cook_decoded.json');
      print('✅ 食谱JSON文件加载成功');
      
      final jsonData = json.decode(jsonString);
      _recipeData = RecipeData.fromJson(jsonData);
      print('✅ 食谱数据解析成功: ${_recipeData!.items.length} 个食谱');
      
      _buildIngredientIndex();
      print('✅ 材料索引构建完成');
    } catch (e, stackTrace) {
      print('❌ 加载食谱数据失败: $e');
      print('堆栈跟踪: $stackTrace');
      rethrow;
    }
  }

  void _buildIngredientIndex() {
    _ingredientIndex.clear();
    if (_recipeData == null) return;

    for (var recipe in _recipeData!.items) {
      for (var ingredient in recipe.ingredients) {
        _ingredientIndex.putIfAbsent(ingredient, () => []).add(recipe);
      }
    }
  }

  List<Recipe> getAllRecipes() {
    return _recipeData?.items ?? [];
  }

  List<Recipe> getRecipesByIngredient(String ingredient) {
    return _ingredientIndex[ingredient] ?? [];
  }

  List<String> getAllIngredients() {
    return _ingredientIndex.keys.toList()..sort();
  }

  List<Recipe> searchRecipes(String query) {
    if (query.isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return _recipeData?.items.where((recipe) {
      return recipe.name.toLowerCase().contains(lowerQuery) ||
             recipe.pinyin.toLowerCase().contains(lowerQuery) ||
             recipe.nameExif.toLowerCase().contains(lowerQuery);
    }).toList() ?? [];
  }
}
