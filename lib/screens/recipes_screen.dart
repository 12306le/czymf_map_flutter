import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe.dart';
import '../providers/map_provider.dart';
import '../services/recipe_service.dart';
import '../theme/app_theme.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final RecipeService _recipeService = RecipeService();
  bool _isLoading = true;
  List<Recipe> _displayedRecipes = [];
  String? _selectedIngredient;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      await _recipeService.loadData();
      setState(() {
        _displayedRecipes = _recipeService.getAllRecipes();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  void _onIngredientTap(String ingredient) {
    setState(() {
      if (_selectedIngredient == ingredient) {
        _selectedIngredient = null;
        _displayedRecipes = _recipeService.getAllRecipes();
      } else {
        _selectedIngredient = ingredient;
        _displayedRecipes = _recipeService.getRecipesByIngredient(ingredient);
      }
      _searchController.clear();
    });
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _selectedIngredient = null;
        _displayedRecipes = _recipeService.getAllRecipes();
      } else {
        _selectedIngredient = null;
        _displayedRecipes = _recipeService.searchRecipes(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('食谱大全'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '搜索食谱或材料...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_selectedIngredient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: AppTheme.primaryLight.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          '筛选: $_selectedIngredient',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _onIngredientTap(_selectedIngredient!),
                          child: const Text('清除'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _displayedRecipes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '没有找到相关食谱',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _displayedRecipes.length,
                          itemBuilder: (context, index) {
                            return _RecipeCard(
                              recipe: _displayedRecipes[index],
                              onIngredientTap: _onIngredientTap,
                              selectedIngredient: _selectedIngredient,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Function(String) onIngredientTap;
  final String? selectedIngredient;

  const _RecipeCard({
    required this.recipe,
    required this.onIngredientTap,
    this.selectedIngredient,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    color: AppTheme.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              recipe.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: '在地图上查看材料',
                            icon: const Icon(
                              Icons.map_outlined,
                              color: AppTheme.primary,
                            ),
                            onPressed: () =>
                                _openIngredientsOnMap(context, recipe),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _PropertyChip(
                            icon: Icons.restaurant_menu,
                            label: '食物',
                            value: recipe.foodValue,
                          ),
                          const SizedBox(width: 8),
                          _PropertyChip(
                            icon: Icons.water_drop,
                            label: '水分',
                            value: recipe.waterValue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (recipe.buff.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 16, color: AppTheme.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Buff: ${recipe.buff}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Text(
              '材料（点击筛选 · 长按在地图上定位）:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recipe.ingredients.map((ingredient) {
                final isSelected = ingredient == selectedIngredient;
                return InkWell(
                  onTap: () => onIngredientTap(ingredient),
                  onLongPress: () =>
                      _openSingleIngredientOnMap(context, ingredient),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _openSingleIngredientOnMap(BuildContext context, String ingredient) {
    final provider = context.read<MapProvider>();
    final catId = provider.findCatIdByName(ingredient);
    if (catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('地图数据中未找到「$ingredient」')),
      );
      return;
    }
    provider.switchTab(0, focusCatId: catId);
  }

  void _openIngredientsOnMap(BuildContext context, Recipe recipe) {
    final provider = context.read<MapProvider>();
    int? firstFocus;
    final notFound = <String>[];
    for (final ingredient in recipe.ingredients) {
      final catId = provider.findCatIdByName(ingredient);
      if (catId != null) {
        firstFocus ??= catId;
        // 选中但不移动（只对第一个聚焦）
        if (!provider.selectedCategories.contains(catId)) {
          provider.toggleCategory(catId);
        }
      } else {
        notFound.add(ingredient);
      }
    }
    if (firstFocus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('地图中未找到该食谱的任何材料')),
      );
      return;
    }
    provider.switchTab(0, focusCatId: firstFocus);
    if (notFound.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('未找到：${notFound.join("、")}')),
      );
    }
  }
}

class _PropertyChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _PropertyChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
