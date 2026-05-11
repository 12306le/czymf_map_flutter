import 'package:flutter/material.dart';

import '../models/game_entry.dart';
import '../services/game_entry_service.dart';
import '../utils/html_content_parser.dart';
import '../widgets/entry_image.dart';
import '../widgets/fluxdo_shell.dart';
import '../widgets/html_content_view.dart';

class EntryListScreen extends StatefulWidget {
  const EntryListScreen({
    super.key,
    required this.title,
    required this.assetPath,
    this.emptyIcon = Icons.inventory_2,
    this.showFilter = true,
    this.searchHint = '搜索名称...',
    this.maxCrossAxisExtent = 180,
    this.subtitleBuilder,
  });

  final String title;
  final String assetPath;
  final IconData emptyIcon;
  final bool showFilter;
  final String searchHint;
  final double maxCrossAxisExtent;
  final String Function(GameEntry entry)? subtitleBuilder;

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
        _error = '加载失败：$e';
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
      list = list.where(
        (e) =>
            e.name.toLowerCase().contains(q) ||
            (e.pinyin?.toLowerCase().contains(q) ?? false) ||
            (e.nameExif?.toLowerCase().contains(q) ?? false) ||
            (e.keyBase?.toLowerCase().contains(q) ?? false),
      );
    }
    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    final filters = widget.showFilter ? _service.filters() : <String>[];
    final list = _entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                _loading ? '' : '${list.length} 项',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _Toolbar(
            controller: _searchController,
            searchHint: widget.searchHint,
            query: _query,
            filters: filters,
            selectedFilter: _selectedFilter,
            onQueryChanged: (value) => setState(() => _query = value),
            onClearQuery: () {
              _searchController.clear();
              setState(() => _query = '');
            },
            onFilterChanged: (value) => setState(() => _selectedFilter = value),
          ),
          Expanded(child: _buildBody(list)),
        ],
      ),
    );
  }

  Widget _buildBody(List<GameEntry> list) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return FluxdoEmptyState(
        icon: Icons.error_outline_rounded,
        title: _error!,
        subtitle: '请检查资源文件是否完整。',
      );
    }
    if (list.isEmpty) {
      return FluxdoEmptyState(
        icon: widget.emptyIcon,
        title: '没有匹配结果',
        subtitle: '换个关键词或清空筛选后再试。',
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: widget.maxCrossAxisExtent,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final entry = list[index];
        return _EntryCard(
          entry: entry,
          subtitle: widget.subtitleBuilder?.call(entry),
          emptyIcon: widget.emptyIcon,
          compact: widget.maxCrossAxisExtent < 150,
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

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.controller,
    required this.searchHint,
    required this.query,
    required this.filters,
    required this.selectedFilter,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final String searchHint;
  final String query;
  final List<String> filters;
  final String? selectedFilter;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Column(
          children: [
            FluxdoSearchField(
              controller: controller,
              hintText: searchHint,
              onChanged: onQueryChanged,
              onClear: query.isEmpty ? null : onClearQuery,
            ),
            if (filters.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final value = index == 0 ? null : filters[index - 1];
                    return ChoiceChip(
                      label: Text(value ?? '全部'),
                      selected: selectedFilter == value,
                      onSelected: (_) => onFilterChanged(value),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.emptyIcon,
    this.subtitle,
    this.compact = false,
  });

  final GameEntry entry;
  final String? subtitle;
  final IconData emptyIcon;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
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
                  if (!compact && entry.filter?.isNotEmpty == true)
                    Positioned(
                      top: 6,
                      left: 6,
                      right: 6,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              entry.filter!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 9,
                vertical: compact ? 5 : 7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!compact && subtitle?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
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
  const _EntryDetailScreen({
    required this.entry,
    required this.emptyIcon,
  });

  final GameEntry entry;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context) {
    final sections = HtmlContentParser.parse(entry.html);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(entry.name)),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ColoredBox(
              color: colorScheme.surfaceContainerHighest,
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
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (entry.filter?.isNotEmpty == true)
                      Chip(label: Text(entry.filter!)),
                  ],
                ),
                if (entry.nameExif?.isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.nameExif!)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                HtmlContentView(sections: sections),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
