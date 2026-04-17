import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar_widget.dart';

/// 调试版地图 - 使用网格背景便于查看
class DebugMapScreen extends StatefulWidget {
  const DebugMapScreen({super.key});

  @override
  State<DebugMapScreen> createState() => _DebugMapScreenState();
}

class _DebugMapScreenState extends State<DebugMapScreen> {
  final TransformationController _transformationController = 
      TransformationController();
  
  static const double mapSize = 20000.0;
  static const double displaySize = 4000.0;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _transformationController.value = Matrix4.identity()
        ..translate(-mapSize / 2 + displaySize / 2, -mapSize / 2 + displaySize / 2)
        ..scale(0.2);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          return Stack(
            children: [
              // 地图主体
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                child: SizedBox(
                  width: mapSize,
                  height: mapSize,
                  child: Stack(
                    children: [
                      // 网格背景（便于调试）
                      Positioned.fill(
                        child: CustomPaint(
                          painter: GridPainter(),
                        ),
                      ),
                      
                      // 尝试加载背景图片
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.5,
                          child: Image.asset(
                            'assets/images/background.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.teal[700],
                                child: const Center(
                                  child: Text(
                                    '背景图片未加载\n使用网格代替',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 48,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // 标记点
                      ...provider.visiblePoints.map((point) {
                        final item = provider.getItemByCategoryId(point.catId);
                        return Positioned(
                          left: point.x.toDouble() - 20,
                          top: mapSize - point.y.toDouble() - 46,
                          child: GestureDetector(
                            onTap: () => _showPointInfo(context, point, item),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 8,
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
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      right: BorderSide(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      bottom: BorderSide(
                                        color: Colors.white,
                                        width: 6,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              
              // 顶部工具栏
              Positioned(
                top: MediaQuery.of(context).padding.top,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list),
                          tooltip: '筛选资源',
                          onPressed: () => _showCategorySelector(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SearchBarWidget(
                          onSearch: (query) => provider.search(query),
                          onResultSelected: (item) {
                            provider.selectSearchResult(item);
                            final points = provider.getPointsByCategoryId(item.catId);
                            if (points.isNotEmpty) {
                              _moveToPoint(points.first.x.toDouble(), points.first.y.toDouble());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.center_focus_strong),
                          tooltip: '重置视图',
                          onPressed: _resetView,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 底部信息栏
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '已显示 ${provider.visiblePoints.length} 个点位',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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
              _moveToPoint(point.x.toDouble(), point.y.toDouble());
            },
            child: const Text('定位'),
          ),
        ],
      ),
    );
  }

  void _moveToPoint(double x, double y) {
    final targetX = -x + displaySize / 2;
    final targetY = -(mapSize - y) + displaySize / 2;
    
    _transformationController.value = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(1.0);
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity()
      ..translate(-mapSize / 2 + displaySize / 2, -mapSize / 2 + displaySize / 2)
      ..scale(0.2);
  }
}

/// 绘制网格背景
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;

    // 绘制网格线（每1000单位一条线）
    for (double i = 0; i <= size.width; i += 1000) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    
    for (double i = 0; i <= size.height; i += 1000) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
    
    // 绘制中心十字线
    final centerPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..strokeWidth = 4;
    
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );
    
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
