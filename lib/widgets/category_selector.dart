import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '选择资源类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // 分类列表
          Expanded(
            child: Consumer<MapProvider>(
              builder: (context, provider, child) {
                final categories = provider.getCategories();
                
                return ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final categoryName = categories[index];
                    final typeIndex = index.toString();
                    final items = provider.getItemsByType(typeIndex);
                    
                    if (items.isEmpty) return const SizedBox.shrink();
                    
                    final selectedCount = items
                        .where((item) => provider.selectedCategories.contains(item.catId))
                        .length;
                    
                    return ExpansionTile(
                      title: Text(
                        categoryName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        '已选 $selectedCount / ${items.length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () => provider.selectAllInType(typeIndex),
                            child: const Text('全选'),
                          ),
                          TextButton(
                            onPressed: () => provider.deselectAllInType(typeIndex),
                            child: const Text('清空'),
                          ),
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: items.map((item) {
                              final isSelected = provider.selectedCategories
                                  .contains(item.catId);
                              
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/icons/${item.catId}.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.image_not_supported,
                                          size: 20,
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 4),
                                    Text(item.name),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  provider.toggleCategory(item.catId);
                                },
                                selectedColor: Colors.blue.shade100,
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // 底部操作栏
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<MapProvider>().clearSelection();
                    },
                    child: const Text('清空所有'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
