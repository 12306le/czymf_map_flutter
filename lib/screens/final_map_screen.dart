import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../widgets/category_selector.dart';
import '../widgets/search_bar_widget.dart';

/// 最终版地图 - 显示游戏世界地图背景，支持点击显示坐标
class FinalMapScreen extends StatefulWidget {
  const FinalMapScreen({super.key});

  @override
  State<FinalMapScreen> createState() => _FinalMapScreenState();
}

class _FinalMapScreenState extends State<FinalMapScreen> {
  final TransformationController _transformationController = 
      TransformationController();
  
  static const double mapSize = 20000.0;
  String? _tappedCoordinate;
  bool _backgroundLoaded = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.of(context).size;
      _transformationController.value = Matrix4.identity()
        ..translate(
          screenSize.width / 2 - mapSize * 0.2 / 2,
          screenSize.height / 2 - mapSize * 0.2 / 2,
        )
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
      backgroundColor: const Color(0xFF1A1A2E),
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    '加载中...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // 地图主体
              GestureDetector(
                onTapUp: (details) => _handleMapTap(details),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.1,
                  maxScale: 4.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  constrained: false,
                  child: SizedBox(
                    width: mapSize,
                    height: mapSize,
                    child: Stack(
                      children: [
                        // 备用背景（深色）
                        Positioned.fill(
                          child: Container(
                            color: const Color(0xFF0F3460),
                          ),
                        ),
                        
                        // 游戏世界地图背景 (4张图片拼接)
                        Positioned.fill(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/1.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(color: const Color(0xFF0F3460));
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/3.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(color: const Color(0xFF0F3460));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/2.jpg',
                                        fit: BoxFit.cover,
                                        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                          if (frame != null && !_backgroundLoaded) {
                                            WidgetsBinding.instance.addPostFrameCallback((_) {
                                              if (mounted) {
                                                setState(() {
                                                  _backgroundLoaded = true;
                                                });
                                              }
                                            });
                                          }
                                          return child;
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(color: const Color(0xFF0F3460));
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Image.asset(
                                        'assets/images/4.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(color: const Color(0xFF0F3460));
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                                        color: const Color(0xFF00D9FF),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.6),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
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
                                    painter: ArrowPainter(),
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
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildToolButton(
                        icon: Icons.filter_list,
                        tooltip: '筛选资源',
                        onPressed: () => _showCategorySelector(context),
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
                      _buildToolButton(
                        icon: Icons.center_focus_strong,
                        tooltip: '重置视图',
                        onPressed: _resetView,
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
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF00D9FF).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _backgroundLoaded ? Icons.check_circle : Icons.location_on,
                          color: _backgroundLoaded ? Colors.green : const Color(0xFF00D9FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tappedCoordinate ?? 
                          (_backgroundLoaded 
                            ? '地图已加载 · ${provider.visiblePoints.length} 个点位'
                            : '已显示 ${provider.visiblePoints.length} 个点位'),
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

  Widget _buildToolButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  void _handleMapTap(TapUpDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final offset = box.globalToLocal(details.globalPosition);
    
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    
    final mapX = (offset.dx - matrix.getTranslation().x) / scale;
    final mapY = (offset.dy - matrix.getTranslation().y) / scale;
    
    final gameX = mapX.round();
    final gameY = (mapSize - mapY).round();
    
    setState(() {
      _tappedCoordinate = '点击坐标: ($gameX, $gameY)';
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _tappedCoordinate = null;
        });
      }
    });
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
    final screenSize = MediaQuery.of(context).size;
    final targetX = screenSize.width / 2 - x;
    final targetY = screenSize.height / 2 - (mapSize - y);
    
    _transformationController.value = Matrix4.identity()
      ..translate(targetX, targetY)
      ..scale(1.0);
  }

  void _resetView() {
    final screenSize = MediaQuery.of(context).size;
    _transformationController.value = Matrix4.identity()
      ..translate(
        screenSize.width / 2 - mapSize * 0.2 / 2,
        screenSize.height / 2 - mapSize * 0.2 / 2,
      )
      ..scale(0.2);
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;
    
    for (double i = 0; i <= size.width; i += 1000) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i <= size.height; i += 1000) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00D9FF)
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
