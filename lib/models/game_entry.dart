/// 通用游戏条目数据模型（兼容 items/pets/builds 三种数据格式）
class GameEntry {
  final String name;
  final String? cover;
  final String? keyBase;
  final String? key;
  final String? pinyin;
  final String? filter; // 分类/标签
  final String? nameExif; // 饲料信息（宠物）
  final String html;

  GameEntry({
    required this.name,
    required this.html,
    this.cover,
    this.keyBase,
    this.key,
    this.pinyin,
    this.filter,
    this.nameExif,
  });

  factory GameEntry.fromJson(Map<String, dynamic> json) {
    return GameEntry(
      name: json['name']?.toString() ?? '',
      html: json['html']?.toString() ?? '',
      cover: json['cover']?.toString(),
      keyBase: json['key_base']?.toString(),
      key: json['key']?.toString(),
      pinyin: json['pinyin']?.toString(),
      filter: json['filter']?.toString(),
      nameExif: json['name_exif']?.toString(),
    );
  }

  /// 本地 asset 图片路径（pets/builds 用 key 命名，items 可能没有）
  String? get localImagePath {
    if (key != null && key!.isNotEmpty) {
      return 'assets/game_img/$key.jpg';
    }
    if (keyBase != null && keyBase!.isNotEmpty) {
      return 'assets/game_img/m$keyBase.jpg';
    }
    return null;
  }

  /// 远程图片 URL（主要是 items 用）
  String? get networkImageUrl {
    if (cover == null) return null;
    if (cover!.startsWith('http')) return cover;
    return null;
  }

  /// 从 HTML 提取简要描述（去标签、截取前 120 字符）
  String get summary {
    final stripped = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (stripped.length <= 120) return stripped;
    return '${stripped.substring(0, 120)}…';
  }

  /// HTML 清理：转换 <br> 为换行、去除其他标签，方便显示
  String get cleanedText {
    var text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
    // 折叠多余空行
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}

class GameEntryData {
  final List<GameEntry> items;
  final String? version;
  final List<String> filters;

  GameEntryData({
    required this.items,
    this.version,
    this.filters = const [],
  });

  factory GameEntryData.fromJson(Map<String, dynamic> json) {
    final rawFilters = json['filter'];
    final filters = <String>[];
    if (rawFilters is List) {
      filters.addAll(rawFilters.map((e) => e.toString()));
    }
    return GameEntryData(
      items: (json['items'] as List?)
              ?.map((e) => GameEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      version: json['version']?.toString(),
      filters: filters,
    );
  }
}
