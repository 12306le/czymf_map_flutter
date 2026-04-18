/// 通用游戏条目数据模型（兼容 items/pets/builds 三种数据格式）
class GameEntry {
  final String name;
  final String? cover;
  final String? keyBase;
  final String? key;
  final String? pinyin;
  final String? filter; // 分类/标签（主要用于宠物）
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

  /// 从 HTML 提取简要描述（去标签、截取前 120 字符）
  String get summary {
    final stripped = html
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (stripped.length <= 120) return stripped;
    return '${stripped.substring(0, 120)}…';
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
