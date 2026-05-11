import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/map_data.dart';
import '../providers/map_provider.dart';
import 'fluxdo_shell.dart';

class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onResultSelected,
  });

  final ValueChanged<String> onSearch;
  final ValueChanged<ItemInfo> onResultSelected;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showResults = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Material(
          color: colorScheme.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(8),
          child: FluxdoSearchField(
            controller: _controller,
            hintText: '搜索资源、拼音或首字母',
            onChanged: (value) {
              widget.onSearch(value);
              setState(() => _showResults = value.trim().isNotEmpty);
            },
            onClear: () {
              _controller.clear();
              widget.onSearch('');
              setState(() => _showResults = false);
            },
          ),
        ),
        if (_showResults)
          Consumer<MapProvider>(
            builder: (context, provider, child) {
              final results = provider.searchResults;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 320),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: results.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('没有找到相关资源'),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: results.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: colorScheme.outlineVariant,
                        ),
                        itemBuilder: (context, index) {
                          final item = results[index];
                          final points =
                              provider.getPointsByCategoryId(item.catId);
                          return ListTile(
                            dense: true,
                            leading: _IconThumb(catId: item.catId),
                            title: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text('${points.length} 个点位'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              widget.onResultSelected(item);
                              _controller.clear();
                              setState(() => _showResults = false);
                              _focusNode.unfocus();
                            },
                          );
                        },
                      ),
              );
            },
          ),
      ],
    );
  }
}

class _IconThumb extends StatelessWidget {
  const _IconThumb({required this.catId});

  final int catId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        'assets/icons/$catId.png',
        width: 34,
        height: 34,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
      ),
    );
  }
}
