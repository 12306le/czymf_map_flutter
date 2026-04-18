import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/html_content_parser.dart';

/// 把一组 HtmlSection 渲染为 Flutter widgets
class HtmlContentView extends StatelessWidget {
  final List<HtmlSection> sections;
  const HtmlContentView({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('暂无详细资料', style: TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < sections.length; i++)
          _buildSection(context, sections[i], i),
      ],
    );
  }

  Widget _buildSection(BuildContext context, HtmlSection section, int index) {
    if (section is HeadingSection) {
      final fontSize = section.level == 1
          ? 20.0
          : section.level == 2
              ? 17.0
              : 15.0;
      final padding = EdgeInsets.only(
        top: index == 0 ? 0 : 12,
        bottom: 6,
      );
      return Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (section.level == 3) ...[
              Container(
                width: 4,
                height: fontSize,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                section.text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  color: section.level == 1
                      ? AppTheme.primaryDark
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (section is ParagraphSection) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SelectableText(
          section.text,
          style: const TextStyle(fontSize: 15, height: 1.55),
        ),
      );
    }
    if (section is ImageSection) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: section.url,
            fit: BoxFit.contain,
            placeholder: (_, __) => Container(
              height: 160,
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              height: 120,
              color: Colors.grey.shade100,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image,
                        size: 32, color: Colors.grey.shade400),
                    const SizedBox(height: 4),
                    Text('图片加载失败',
                        style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (section is TableSection) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _TableView(rows: section.rows),
      );
    }
    return const SizedBox.shrink();
  }
}

class _TableView extends StatelessWidget {
  final List<List<String>> rows;
  const _TableView({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    // 如果是两列键值对表格（更常见），用键值对的样式展示
    final allTwoCols = rows.every((r) => r.length == 2);
    if (allTwoCols) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            for (int i = 0; i < rows.length; i++)
              Container(
                decoration: BoxDecoration(
                  color: i.isEven
                      ? AppTheme.primaryLight.withOpacity(0.08)
                      : Colors.white,
                  border: i == rows.length - 1
                      ? null
                      : Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade200,
                          ),
                        ),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          color: AppTheme.primary.withOpacity(0.08),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rows[i][0],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            rows[i][1],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // 多列表格：横向滚动 DataTable
    final maxCols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    final header = rows.first;
    final body = rows.skip(1).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(
          AppTheme.primary.withOpacity(0.1),
        ),
        columns: [
          for (int i = 0; i < maxCols; i++)
            DataColumn(
              label: Text(
                i < header.length ? header[i] : '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
        rows: [
          for (final row in body)
            DataRow(
              cells: [
                for (int i = 0; i < maxCols; i++)
                  DataCell(Text(i < row.length ? row[i] : '')),
              ],
            ),
        ],
      ),
    );
  }
}
