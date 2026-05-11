import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/map_provider.dart';

class CategorySelector extends StatelessWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '资源筛选',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: '关闭',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: Consumer<MapProvider>(
                builder: (context, provider, child) {
                  final categories = provider.getCategories();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final categoryName = categories[index];
                      final typeIndex = index.toString();
                      final items = provider.getItemsByType(typeIndex);
                      if (items.isEmpty) return const SizedBox.shrink();
                      final selectedCount = items
                          .where((item) =>
                              provider.selectedCategories.contains(item.catId))
                          .length;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ExpansionTile(
                          tilePadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(14, 0, 14, 14),
                          title: Text(
                            categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text('已选 $selectedCount / ${items.length}'),
                          trailing: Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                tooltip: '全选',
                                icon: const Icon(Icons.done_all_rounded),
                                onPressed: () =>
                                    provider.selectAllInType(typeIndex),
                              ),
                              IconButton(
                                tooltip: '清空本组',
                                icon: const Icon(Icons.remove_done_rounded),
                                onPressed: () =>
                                    provider.deselectAllInType(typeIndex),
                              ),
                            ],
                          ),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: items.map((item) {
                                  final isSelected = provider
                                      .selectedCategories
                                      .contains(item.catId);
                                  return FilterChip(
                                    avatar: Image.asset(
                                      'assets/icons/${item.catId}.png',
                                      width: 20,
                                      height: 20,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.location_on),
                                    ),
                                    label: Text(item.name),
                                    selected: isSelected,
                                    onSelected: (_) =>
                                        provider.toggleCategory(item.catId),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Divider(height: 1, color: colorScheme.outlineVariant),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: context.read<MapProvider>().clearSelection,
                      icon: const Icon(Icons.delete_sweep_rounded),
                      label: const Text('清空所有'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('完成'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
