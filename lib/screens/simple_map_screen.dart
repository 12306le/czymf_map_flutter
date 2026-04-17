import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar_widget.dart';

/// 简化版地图实现 - 使用InteractiveViewer替代flutter_map
/// 适合快速开发和测试，性能更好
class SimpleMapScreen extends StatefulWidget {
  const SimpleMapScreen({super.key});

  @override
  State<SimpleMapScreen> createState() => _SimpleMapScreenState();
}

class _SimpleMapScreenState extends State<SimpleMapScreen> {
  final TransformationController _transformationController = 
      TransformationController();
  
  // 地图尺寸
  static const double mapSize = 20000.0;
  static const double displaySize = 4000.0; // 显示区域大小
  
  @override
  void initState() {
    super.initState();
    // 初始化到地图中心
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
      backgroundColor: const Color(0xFF2E5252),
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
                      // 背景图片
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/background.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('地图背景加载失败: $error');
                            return Container(
                              color: const Color(0xFF4A6B6B),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 64,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      '地图背景加载失败',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '错误: ${error.toString()}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                                CustomPaint(
                                  size: const Size(8, 6),
                                  painter: TrianglePainter(),
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
                  child: Row(
                    children: [
                      // 分类选择按钮
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () => _showCategorySelector(context),
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
                              _moveToPoint(points.first.x.toDouble(), points.first.y.toDouble());
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // 重置视图按钮
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.center_focus_strong),
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

/// 绘制标记点下方的三角形
class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
