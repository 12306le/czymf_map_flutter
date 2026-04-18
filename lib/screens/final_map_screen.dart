import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/map_provider.dart';
import '../models/map_data.dart';
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

  /// 同时渲染的最大 Marker 数，超过则按屏幕网格聚合降采样
  static const int _maxRenderedMarkers = 800;

  String? _tappedCoordinate;
  bool _backgroundLoaded = false;

  // 屏幕中心准星对应的游戏坐标
  double _crosshairX = mapSize / 2;
  double _crosshairY = mapSize / 2;

  // 当前缩放，用于聚类降采样
  double _currentScale = 0.2;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetView();
    });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final screenSize = MediaQuery.of(context).size;

    // 屏幕中心在地图坐标系中的位置
    final mapCenterX = (screenSize.width / 2 - matrix.getTranslation().x) / scale;
    final mapCenterY = (screenSize.height / 2 - matrix.getTranslation().y) / scale;

    final gameX = mapCenterX.clamp(0.0, mapSize);
    final gameY = (mapSize - mapCenterY).clamp(0.0, mapSize);

    if ((scale - _currentScale).abs() > 0.01 ||
        (gameX - _crosshairX).abs() > 5 ||
        (gameY - _crosshairY).abs() > 5) {
      setState(() {
        _currentScale = scale;
        _crosshairX = gameX.toDouble();
        _crosshairY = gameY.toDouble();
      });
    }
  }

  /// 按屏幕网格对大量点位降采样，避免一次构建过多 Widget
  List<MapPoint> _downsample(List<MapPoint> points) {
    if (points.length <= _maxRenderedMarkers) return points;

    // 根据当前缩放决定网格大小：缩放越小，网格越大，合并越激进
    final gridSize = (300.0 / _currentScale).clamp(150.0, 2000.0);
    final grouped = <String, MapPoint>{};
    for (final p in points) {
      final key =
          '${p.catId}_${(p.x / gridSize).floor()}_${(p.y / gridSize).floor()}';
      grouped.putIfAbsent(key, () => p);
    }
    return grouped.values.toList();
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

          final renderedPoints = _downsample(provider.visiblePoints);
          final pointCount = provider.visiblePoints.length;
          final clusteredCount = renderedPoints.length;

          return Stack(
            children: [
              // 地图主体
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 4.0,
                // ✅ Bug1：限制为 0 margin，防止拖出地图外的黑色区域
                boundaryMargin: EdgeInsets.zero,
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
                                    child: _bgImage('assets/images/1.jpg'),
                                  ),
                                  Expanded(
                                    child: _bgImage('assets/images/3.jpg'),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _bgImage(
                                      'assets/images/2.jpg',
                                      trackLoaded: true,
                                    ),
                                  ),
                                  Expanded(
                                    child: _bgImage('assets/images/4.jpg'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 标记点
                      ...renderedPoints.map((point) {
                        final item = provider.getItemByCategoryId(point.catId);
                        return Positioned(
                          left: point.x.toDouble() - 28,
                          top: mapSize - point.y.toDouble() - 60,
                          width: 56,
                          height: 64,
                          child: GestureDetector(
                            onTap: () => _showPointInfo(context, point, item),
                            child: _MarkerIcon(catId: point.catId),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // ✅ Bug6：屏幕中心准星 + 坐标气泡
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                          size: const Size(48, 48),
                          painter: _CrosshairPainter(),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'X: ${_crosshairX.toInt()}  Y: ${_crosshairY.toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
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
                            final points =
                                provider.getPointsByCategoryId(item.catId);
                            if (points.isNotEmpty) {
                              _moveToPoint(
                                points.first.x.toDouble(),
                                points.first.y.toDouble(),
                              );
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
                          _backgroundLoaded
                              ? Icons.check_circle
                              : Icons.location_on,
                          color: _backgroundLoaded
                              ? Colors.green
                              : const Color(0xFF00D9FF),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _tappedCoordinate ??
                              _buildStatusText(pointCount, clusteredCount),
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

  String _buildStatusText(int total, int rendered) {
    if (total == 0) return '暂无点位，请选择分类';
    if (rendered < total) {
      return '已聚合 $total → $rendered 个点位（放大查看更多）';
    }
    return '已显示 $total 个点位';
  }

  Widget _bgImage(String path, {bool trackLoaded = false}) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      frameBuilder: trackLoaded
          ? (context, child, frame, wasSynchronouslyLoaded) {
              if (frame != null && !_backgroundLoaded && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _backgroundLoaded = true);
                });
              }
              return child;
            }
          : null,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0F3460)),
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

  void _showCategorySelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CategorySelector(),
    );
  }

  void _showPointInfo(BuildContext context, MapPoint point, ItemInfo? item) {
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

  void _moveToPoint(double gameX, double gameY) {
    final screenSize = MediaQuery.of(context).size;
    const scale = 1.0;
    final mapY = mapSize - gameY;
    _transformationController.value = Matrix4.identity()
      ..translate(
        screenSize.width / 2 - gameX * scale,
        screenSize.height / 2 - mapY * scale,
      )
      ..scale(scale);
  }

  void _resetView() {
    final screenSize = MediaQuery.of(context).size;
    const scale = 0.2;
    _transformationController.value = Matrix4.identity()
      ..translate(
        screenSize.width / 2 - mapSize * scale / 2,
        screenSize.height / 2 - mapSize * scale / 2,
      )
      ..scale(scale);
  }
}

/// 地图 Marker 图标（圆图标 + 下方三角）
class _MarkerIcon extends StatelessWidget {
  final int catId;
  const _MarkerIcon({required this.catId});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00D9FF), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/icons/$catId.png',
              fit: BoxFit.cover,
              cacheWidth: 96,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.location_on, color: Colors.red, size: 28),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _TrianglePainter(color: Colors.white),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const gap = 6.0;
    const len = 14.0;

    for (final p in [shadowPaint, paint]) {
      canvas.drawLine(Offset(cx - len - gap, cy), Offset(cx - gap, cy), p);
      canvas.drawLine(Offset(cx + gap, cy), Offset(cx + len + gap, cy), p);
      canvas.drawLine(Offset(cx, cy - len - gap), Offset(cx, cy - gap), p);
      canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + len + gap), p);
    }

    canvas.drawCircle(Offset(cx, cy), 2.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      Offset(cx, cy),
      2.5,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) => false;
}
