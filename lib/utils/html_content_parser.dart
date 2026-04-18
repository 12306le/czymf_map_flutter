/// HTML 内容解析：把原始 HTML 字符串切分为结构化的 Section 列表
/// 支持 段落文本 / 标题 / 图片 / 表格 四种类型，并清理常见的广告/导航文案。
sealed class HtmlSection {
  const HtmlSection();
}

class HeadingSection extends HtmlSection {
  final String text;
  final int level; // 1=h1, 2=h2, 3=用 ▍ 标记的分段标题
  const HeadingSection(this.text, {this.level = 1});
}

class ParagraphSection extends HtmlSection {
  final String text;
  const ParagraphSection(this.text);
}

class ImageSection extends HtmlSection {
  final String url;
  const ImageSection(this.url);
}

/// 简单表格：rows[r][c] 为单元格文本
class TableSection extends HtmlSection {
  final List<List<String>> rows;
  const TableSection(this.rows);

  bool get isEmpty => rows.isEmpty || rows.every((r) => r.every((c) => c.isEmpty));
}

class HtmlContentParser {
  // 广告 / 导航 / 小编套话模板
  static final _adPatterns = <RegExp>[
    RegExp(r'推荐阅读[：:].*', dotAll: true),
    RegExp(r'地图攻略\s*\|.*?物品大全', dotAll: true),
    RegExp(r'今天小编.*?带来.*?[。！.!]'),
    RegExp(r'下面小编.*?带来.*?[。！.!]'),
    RegExp(r'想知道.*?那就.*?一起来看看吧[！。!.]?'),
    RegExp(r'下面就[^。！.!\n]*?看看[^。！.!\n]*?吧[！。!.]?'),
    RegExp(r'许多小伙伴不知道.*?下面就.*?[。！.!]'),
    RegExp(r'那么[^。！.!\n]*?怎么[^。！.!\n]*?[？?]', dotAll: false),
  ];

  /// 主入口：HTML -> sections
  static List<HtmlSection> parse(String html) {
    if (html.trim().isEmpty) return const [];

    final sections = <HtmlSection>[];
    var remaining = html;

    while (remaining.isNotEmpty) {
      // 找到下一个结构化元素（h1/h2/img/table）
      final nextTag = _findNextStructural(remaining);
      if (nextTag == null) {
        _appendParagraphs(sections, remaining);
        break;
      }
      // 先处理 tag 之前的文本
      if (nextTag.start > 0) {
        _appendParagraphs(sections, remaining.substring(0, nextTag.start));
      }
      // 处理 tag 本身
      if (nextTag.type == 'table') {
        final table = _parseTable(nextTag.fullMatch);
        if (!table.isEmpty) sections.add(table);
      } else if (nextTag.type == 'img') {
        final url = nextTag.attr ?? '';
        if (url.startsWith('http')) {
          sections.add(ImageSection(url));
        }
      } else if (nextTag.type == 'h1' || nextTag.type == 'h2') {
        final inner = _stripTags(nextTag.attr ?? '');
        if (inner.isNotEmpty) {
          sections.add(HeadingSection(
            inner,
            level: nextTag.type == 'h1' ? 1 : 2,
          ));
        }
      }
      remaining = remaining.substring(nextTag.end);
    }

    return _postProcess(sections);
  }

  static _TagMatch? _findNextStructural(String html) {
    final patterns = <String, RegExp>{
      'h1': RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true),
      'h2': RegExp(r'<h2[^>]*>(.*?)</h2>', caseSensitive: false, dotAll: true),
      'img': RegExp(
          r'''<img[^>]*src\s*=\s*["']?([^"'\s>]+)[^>]*/?>''',
          caseSensitive: false),
      'table': RegExp(r'<table[^>]*>.*?</table>',
          caseSensitive: false, dotAll: true),
    };
    _TagMatch? best;
    for (final entry in patterns.entries) {
      final m = entry.value.firstMatch(html);
      if (m != null) {
        if (best == null || m.start < best.start) {
          best = _TagMatch(
            type: entry.key,
            start: m.start,
            end: m.end,
            fullMatch: m.group(0)!,
            attr: m.groupCount >= 1 ? m.group(1) : null,
          );
        }
      }
    }
    return best;
  }

  /// 将纯文本片段切成段落（按 <br>、句号、换行），过滤广告
  static void _appendParagraphs(List<HtmlSection> out, String fragment) {
    // 先把 <br> 换行，然后去其他标签
    var text = fragment
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');

    // 清广告
    for (final pattern in _adPatterns) {
      text = text.replaceAll(pattern, '');
    }

    // 按换行分段
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final line in lines) {
      if (line.length < 2) continue;
      // 分段标题（▍ 开头）
      if (line.startsWith('▍')) {
        final title = line.replaceFirst('▍', '').trim();
        if (title.isNotEmpty) {
          out.add(HeadingSection(title, level: 3));
        }
      } else {
        out.add(ParagraphSection(line));
      }
    }
  }

  static TableSection _parseTable(String tableHtml) {
    final rows = <List<String>>[];
    final rowRegex = RegExp(r'<tr[^>]*>(.*?)</tr>',
        caseSensitive: false, dotAll: true);
    final cellRegex = RegExp(r'<t[dh][^>]*>(.*?)</t[dh]>',
        caseSensitive: false, dotAll: true);

    for (final rowMatch in rowRegex.allMatches(tableHtml)) {
      final cells = <String>[];
      for (final cellMatch in cellRegex.allMatches(rowMatch.group(1) ?? '')) {
        cells.add(_stripTags(cellMatch.group(1) ?? ''));
      }
      if (cells.any((c) => c.isNotEmpty)) {
        rows.add(cells);
      }
    }
    return TableSection(rows);
  }

  static String _stripTags(String s) {
    return s
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// 后处理：去连续重复段、去空段
  static List<HtmlSection> _postProcess(List<HtmlSection> sections) {
    final result = <HtmlSection>[];
    String? lastParagraph;
    for (final s in sections) {
      if (s is ParagraphSection) {
        if (s.text == lastParagraph) continue;
        lastParagraph = s.text;
      } else {
        lastParagraph = null;
      }
      result.add(s);
    }
    return result;
  }
}

class _TagMatch {
  final String type;
  final int start;
  final int end;
  final String fullMatch;
  final String? attr;
  _TagMatch({
    required this.type,
    required this.start,
    required this.end,
    required this.fullMatch,
    this.attr,
  });
}
