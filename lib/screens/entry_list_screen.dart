import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../services/game_entry_service.dart';
import '../theme/app_theme.dart';
import '../widgets/entry_image.dart';

/// 通用的游戏条目网格页（物品 / 宠物 / 建筑共用 UI）
class EntryListScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final IconData emptyIcon;
  final bool showFilter;
  final String searchHint;

  /// 自定义每个条目的副标题（卡片上显示）。可选。
  final String Function(GameEntry entry)? subtitleBuilder;

  const EntryListScreen({
    super.key,
    required this.title,
    required this.assetPath,
    this.emptyIcon = Icons.inventory_2,
    this.showFilter = true,
    this.searchHint = '搜索名称...',
    this.subtitleBuilder,
  });

  @override
  State<EntryListScreen> createState() => _EntryListScreenState();
}

class _EntryListScreenState extends State<EntryListScreen> {
  late final GameEntryService _service;
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  String? _selectedFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _service = GameEntryService(widget.assetPath);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _service.load();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '加载失败: $e';
      });
    }
  }

  List<GameEntry> get _entries {
    Iterable<GameEntry> list = _service.all();
    if (_selectedFilter != null && _selectedFilter!.isNotEmpty) {
      list = list.where((e) => e.filter == _selectedFilter);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((e) =>
          e.name.toLowerCase().contains(q) ||
          (e.pinyin?.toLowerCase().contains(q) ?? false) ||
          (e.nameExif?.toLowerCase().contains(q) ?? false) ||
          (e.keyBase?.toLowerCase().contains(q) ?? false));
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.showFilter ? _service.filters() : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(filters.isNotEmpty ? 120 : 64),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
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
              if (filters.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    scrollDirection: Axis.horizontal,
                    itemCount: filters.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final selected = _selectedFilter == null;
                        return _FilterChip(
                          label: '全部',
                          selected: selected,
                          onTap: () => setState(() => _selectedFilter = null),
                        );
                      }
                      final filter = filters[index - 1];
                      final selected = _selectedFilter == filter;
                      return _FilterChip(
                        label: filter,
                        selected: selected,
                        onTap: () =>
                            setState(() => _selectedFilter = filter),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!),
        ),
      );
    }
    final list = _entries;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.emptyIcon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('没有匹配的结果',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 190,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        return _EntryCard(
          entry: entry,
          subtitle: widget.subtitleBuilder?.call(entry),
          emptyIcon: widget.emptyIcon,
          onTap: () => _showDetail(entry),
        );
      },
    );
  }

  void _showDetail(GameEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EntryDetailScreen(
          entry: entry,
          emptyIcon: widget.emptyIcon,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final GameEntry entry;
  final String? subtitle;
  final IconData emptyIcon;
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.emptyIcon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: EntryImage(
                      entry: entry,
                      fit: BoxFit.cover,
                      fallbackIcon: emptyIcon,
                    ),
                  ),
                  if (entry.filter != null && entry.filter!.isNotEmpty)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          entry.filter!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
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

class _EntryDetailScreen extends StatelessWidget {
  final GameEntry entry;
  final IconData emptyIcon;
  const _EntryDetailScreen({
    required this.entry,
    required this.emptyIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: Colors.black12,
              child: EntryImage(
                entry: entry,
                fit: BoxFit.contain,
                fallbackIcon: emptyIcon,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (entry.filter != null && entry.filter!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          entry.filter!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                      ),
                  ],
                ),
                if (entry.nameExif != null && entry.nameExif!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.restaurant,
                            size: 18, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.nameExif!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SelectableText(
                  entry.cleanedText.isNotEmpty
                      ? entry.cleanedText
                      : '暂无详细描述',
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
