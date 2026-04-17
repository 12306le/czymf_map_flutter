import 'package:json_annotation/json_annotation.dart';

part 'map_data.g.dart';

@JsonSerializable()
class MapData {
  final int code;
  final String msg;
  final GameData data;

  MapData({
    required this.code,
    required this.msg,
    required this.data,
  });

  factory MapData.fromJson(Map<String, dynamic> json) =>
      _$MapDataFromJson(json);
  Map<String, dynamic> toJson() => _$MapDataToJson(this);
}

@JsonSerializable()
class GameData {
  @JsonKey(name: 'item_type')
  final List<String> itemType;
  
  @JsonKey(name: 'item_list')
  final List<ItemInfo> itemList;
  
  final List<MapPoint> xys;

  GameData({
    required this.itemType,
    required this.itemList,
    required this.xys,
  });

  factory GameData.fromJson(Map<String, dynamic> json) =>
      _$GameDataFromJson(json);
  Map<String, dynamic> toJson() => _$GameDataToJson(this);
}

@JsonSerializable()
class ItemInfo {
  @JsonKey(name: 'cat_id')
  final int catId;
  
  final String name;
  final String type;

  ItemInfo({
    required this.catId,
    required this.name,
    required this.type,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) =>
      _$ItemInfoFromJson(json);
  Map<String, dynamic> toJson() => _$ItemInfoToJson(this);
}

@JsonSerializable()
class MapPoint {
  final int id;
  
  @JsonKey(name: 'user_id')
  final int userId;
  
  @JsonKey(name: 'cat_id')
  final int catId;
  
  final int x;
  final int y;
  final String? img;
  final String? txt;

  MapPoint({
    required this.id,
    required this.userId,
    required this.catId,
    required this.x,
    required this.y,
    this.img,
    this.txt,
  });

  factory MapPoint.fromJson(Map<String, dynamic> json) =>
      _$MapPointFromJson(json);
  Map<String, dynamic> toJson() => _$MapPointToJson(this);
}
