import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar_widget.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  
  // 地图坐标转换：游戏坐标 (0-20000) -> 经纬度
  LatLng _gameToLatLng(int x, int y) {
    // 将游戏坐标映射到经纬度范围
    final lat = (20000 - y) / 200.0; // 反转Y轴，范围 0-100
    final lng = x / 200.0; // 范围 0-100
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              // 地图主体
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _gameToLatLng(10000, 10000),
                  initialZoom: 13.0,
                  minZoom: 11.0,
                  maxZoom: 18.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // 地图背景图层
                  TileLayer(
                    tileProvider: AssetTileProvider(),
                    urlTemplate: 'assets/images/tiles/{z}/{x}/{y}.png',
                    fallbackUrl: 'assets/images/background.png',
                    backgroundColor: const Color(0xFF2E5252),
                  ),
                  
                  // 标记点图层
                  MarkerLayer(
                    markers: provider.visiblePoints.map((point) {
                      final item = provider.getItemByCategoryId(point.catId);
                      return Marker(
                        point: _gameToLatLng(point.x, point.y),
                        width: 40,
                        height: 46,
                        child: GestureDetector(
                          onTap: () => _showPointInfo(context, point, item),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/${point.catId}.png',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.location_on,
                                        color: Colors.red,
                                        size: 24,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Container(
                                width: 0,
                                height: 0,
                                decoration: const BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      width: 4,
                                      color: Colors.transparent,
                                    ),
                                    right: BorderSide(
                                      width: 4,
                                      color: Colors.transparent,
                                    ),
                                    bottom: BorderSide(
                                      width: 8,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              
              // 顶部工具栏
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      // 分类选择按钮
                      IconButton(
                        icon: const Icon(Icons.filter_list),
                        onPressed: () => _showCategorySelector(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 搜索栏
                      Expanded(
                        child: SearchBarWidget(
                          onSearch: (query) {
                            provider.search(query);
                          },
                          onResultSelected: (item) {
                            provider.selectSearchResult(item);
                            // 移动到第一个点
                            final points = provider.getPointsByCategoryId(item.catId);
                            if (points.isNotEmpty) {
                              _mapController.move(
                                _gameToLatLng(points.first.x, points.first.y),
                                16.0,
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 当前坐标显示
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '已显示 ${provider.visiblePoints.length} 个点位',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategorySelector(),
    );
  }

  void _showPointInfo(BuildContext context, point, item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item?.name ?? '未知'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('坐标: (${point.x}, ${point.y})'),
            if (point.txt != null && point.txt!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('备注: ${point.txt}'),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mapController.move(
                _gameToLatLng(point.x, point.y),
                16.0,
              );
            },
            child: const Text('定位'),
          ),
        ],
      ),
    );
  }
}

class AssetTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return AssetImage(
      'assets/images/tiles/${coordinates.z}/${coordinates.x}/${coordinates.y}.png',
    );
  }
}
