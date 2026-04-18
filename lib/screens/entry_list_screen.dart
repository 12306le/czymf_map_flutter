import 'package:flutter/material.dart';
import '../models/game_entry.dart';
import '../services/game_entry_service.dart';
import '../theme/app_theme.dart';

/// 通用的游戏条目列表页（物品 / 宠物 / 建筑共用 UI）
class EntryListScreen extends StatefulWidget {
  final String title;
  final String assetPath;
  final IconData emptyIcon;
  final bool showFilter;
  final String searchHint;

  /// 自定义每个条目的副标题。可选。
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
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        return _EntryCard(
          entry: entry,
          subtitle: widget.subtitleBuilder?.call(entry),
          onTap: () => _showDetail(entry),
        );
      },
    );
  }

  void _showDetail(GameEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EntryDetailScreen(entry: entry),
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
  final VoidCallback onTap;

  const _EntryCard({
    required this.entry,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  entry.filter == '坐骑'
                      ? Icons.directions_run
                      : Icons.auto_awesome,
                  color: AppTheme.primary,
                  size: 28,
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
                            entry.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (entry.filter != null && entry.filter!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              entry.filter!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ] else if (entry.summary.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryDetailScreen extends StatelessWidget {
  final GameEntry entry;
  const _EntryDetailScreen({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            if (entry.nameExif != null && entry.nameExif!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.nameExif!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              entry.summary.isNotEmpty ? entry.summary : '暂无详细描述',
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
