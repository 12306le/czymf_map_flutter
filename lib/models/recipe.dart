class Recipe {
  final String name;
  final String nameExif; // 材料列表，用+分隔
  final List<RecipeProp> sortProp;
  final String pinyin;
  final String key;
  final String des;

  Recipe({
    required this.name,
    required this.nameExif,
    required this.sortProp,
    required this.pinyin,
    required this.key,
    required this.des,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? '',
      nameExif: json['name_exif'] ?? '',
      sortProp: (json['sort_prop'] as List?)
              ?.map((e) => RecipeProp.fromJson(e))
              .toList() ??
          [],
      pinyin: json['pinyin'] ?? '',
      key: json['key'] ?? '',
      des: json['des'] ?? '',
    );
  }

  // 获取材料列表
  List<String> get ingredients {
    return nameExif.split('+').map((e) => e.trim()).toList();
  }

  // 获取食物值
  String get foodValue {
    final foodProp = sortProp.firstWhere(
      (prop) => prop.name == '食物',
      orElse: () => RecipeProp(name: '食物', value: '0', cover: ''),
    );
    return foodProp.value;
  }

  // 获取水分值
  String get waterValue {
    final waterProp = sortProp.firstWhere(
      (prop) => prop.name == '水分',
      orElse: () => RecipeProp(name: '水分', value: '0', cover: ''),
    );
    return waterProp.value;
  }

  // 获取buff
  String get buff {
    final buffProp = sortProp.firstWhere(
      (prop) => prop.name == 'buff',
      orElse: () => RecipeProp(name: 'buff', value: '', cover: ''),
    );
    return buffProp.value;
  }
}

class RecipeProp {
  final String name;
  final String value;
  final String cover;

  RecipeProp({
    required this.name,
    required this.value,
    required this.cover,
  });

  factory RecipeProp.fromJson(Map<String, dynamic> json) {
    return RecipeProp(
      name: json['name'] ?? '',
      value: json['value']?.toString() ?? '',
      cover: json['cover'] ?? '',
    );
  }
}

class RecipeData {
  final List<Recipe> items;

  RecipeData({required this.items});

  factory RecipeData.fromJson(Map<String, dynamic> json) {
    return RecipeData(
      items: (json['items'] as List?)
              ?.map((e) => Recipe.fromJson(e))
              .toList() ??
          [],
    );
  }
}
