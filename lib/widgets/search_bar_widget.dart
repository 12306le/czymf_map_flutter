import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/map_data.dart';
import '../providers/map_provider.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  final Function(ItemInfo) onResultSelected;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    required this.onResultSelected,
  });

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
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '搜索资源（支持中文/拼音）',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        widget.onSearch('');
                        setState(() => _showResults = false);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              widget.onSearch(value);
              setState(() => _showResults = value.isNotEmpty);
            },
            onTap: () {
              if (_controller.text.isNotEmpty) {
                setState(() => _showResults = true);
              }
            },
          ),
        ),
        
        // 搜索结果
        if (_showResults)
          Consumer<MapProvider>(
            builder: (context, provider, child) {
              if (provider.searchResults.isEmpty) {
                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    '未找到相关资源',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              
              return Container(
                margin: const EdgeInsets.only(top: 8),
                constraints: const BoxConstraints(maxHeight: 300),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: provider.searchResults.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = provider.searchResults[index];
                    final points = provider.getPointsByCategoryId(item.catId);
                    
                    return ListTile(
                      leading: Image.asset(
                        'assets/icons/${item.catId}.png',
                        width: 32,
                        height: 32,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image_not_supported);
                        },
                      ),
                      title: Text(item.name),
                      subtitle: Text('${points.length} 个点位'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
