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

  /// 聚类后同时渲染的最大 Marker 数
  static const int _maxRenderedMarkers = 800;

  String? _tappedCoordinate;
  bool _backgroundLoaded = false;

  // 屏幕中心准星对应的游戏坐标
  double _crosshairX = mapSize / 2;
  double _crosshairY = mapSize / 2;

  // 当前缩放，用于聚类降采样 & 图标补偿
  double _currentScale = 0.2;

  // 上一次消费的联动请求 cat_id（避免重复触发）
  int? _lastHandledFocusCatId;

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

  /// 按 catId + 网格 聚类，返回代表点 + 成员列表
  List<_MarkerCluster> _clusterPoints(List<MapPoint> points) {
    if (points.isEmpty) return const [];
    if (points.length <= _maxRenderedMarkers) {
      return points.map((p) => _MarkerCluster(point: p, members: [p])).toList();
    }
    final gridSize = (300.0 / _currentScale).clamp(200.0, 2500.0);
    final grouped = <String, List<MapPoint>>{};
    for (final p in points) {
      final key =
          '${p.catId}_${(p.x / gridSize).floor()}_${(p.y / gridSize).floor()}';
      grouped.putIfAbsent(key, () => []).add(p);
    }
    final result = <_MarkerCluster>[];
    for (final list in grouped.values) {
      result.add(_MarkerCluster(point: list.first, members: list));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          // 处理食谱→地图联动：切换到此 tab 后，移动地图到第一个点
          final focusCatId = provider.focusRequestCatId;
          if (focusCatId != null && focusCatId != _lastHandledFocusCatId) {
            _lastHandledFocusCatId = focusCatId;
            final points = provider.getPointsByCategoryId(focusCatId);
            if (points.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _moveToPoint(
                  points.first.x.toDouble(),
                  points.first.y.toDouble(),
                );
              });
            }
            // 清除请求
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.consumeFocusRequest();
            });
          }

          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('加载中...', style: TextStyle(color: Colors.white)),
                ],
              ),
            );
          }

          final clusters = _clusterPoints(provider.visiblePoints);
          final iconScale = provider.iconScale;
          final pointCount = provider.visiblePoints.length;

          return Stack(
            children: [
              // 地图主体
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.1,
                maxScale: 4.0,
                // Bug1：限制地图边界
                boundaryMargin: EdgeInsets.zero,
                constrained: false,
                child: SizedBox(
                  width: mapSize,
                  height: mapSize,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(color: const Color(0xFF0F3460)),
                      ),
                      Positioned.fill(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(child: _bgImage('assets/images/1.jpg')),
                                  Expanded(child: _bgImage('assets/images/3.jpg')),
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
                                  Expanded(child: _bgImage('assets/images/4.jpg')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 标记点
                      ...clusters.map((cluster) {
                        final point = cluster.point;
                        final item = provider.getItemByCategoryId(point.catId);
                        final markerSize = 48.0 * iconScale;
                        final totalHeight = markerSize + 16.0;
                        return Positioned(
                          left: point.x.toDouble() - markerSize / 2,
                          top: mapSize -
                              point.y.toDouble() -
                              totalHeight +
                              4.0,
                          width: markerSize,
                          height: totalHeight,
                          child: GestureDetector(
                            onTap: () {
                              if (cluster.members.length > 1) {
                                _showClusterSheet(
                                    context, cluster, provider);
                              } else {
                                _showPointInfo(context, point, item);
                              }
                            },
                            child: _MarkerIcon(
                              catId: point.catId,
                              count: cluster.members.length,
                              size: markerSize,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bug6：屏幕中心准星 + 坐标气泡
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
                      _toolButton(
                        icon: Icons.filter_list,
                        tooltip: '筛选资源',
                        onPressed: () => _showCategorySelector(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SearchBarWidget(
                          onSearch: (q) => provider.search(q),
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
                      _toolButton(
                        icon: Icons.tune,
                        tooltip: '图标大小',
                        onPressed: () => _showIconSettings(context, provider),
                      ),
                      const SizedBox(width: 8),
                      _toolButton(
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
                              _buildStatusText(pointCount, clusters.length),
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

  String _buildStatusText(int total, int clusterCount) {
    if (total == 0) return '暂无点位，请选择分类';
    if (clusterCount < total) {
      return '$total 个点位已聚合为 $clusterCount（点击簇查看详情）';
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

  Widget _toolButton({
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

  void _showIconSettings(BuildContext context, MapProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                '图标大小',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '缩放范围 0.5x ~ 2.5x',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              StatefulBuilder(builder: (ctx, setInner) {
                final current = provider.iconScale;
                return Row(
                  children: [
                    Text('${current.toStringAsFixed(1)}x'),
                    Expanded(
                      child: Slider(
                        value: current,
                        min: 0.5,
                        max: 2.5,
                        divisions: 20,
                        label: '${current.toStringAsFixed(1)}x',
                        onChanged: (v) {
                          provider.setIconScale(v);
                          setInner(() {});
                        },
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        );
      },
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

  void _showClusterSheet(
    BuildContext context,
    _MarkerCluster cluster,
    MapProvider provider,
  ) {
    final item = provider.getItemByCategoryId(cluster.point.catId);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.5,
          child: Column(
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: AssetImage(
                        'assets/icons/${cluster.point.catId}.png',
                      ),
                      onBackgroundImageError: (_, __) {},
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${item?.name ?? '未知'} · ${cluster.members.length} 个点位',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: cluster.members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = cluster.members[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade100,
                        child: Text('${index + 1}',
                            style: const TextStyle(fontSize: 12)),
                      ),
                      title: Text('X: ${p.x}  Y: ${p.y}'),
                      subtitle:
                          p.txt != null && p.txt!.isNotEmpty ? Text(p.txt!) : null,
                      trailing: const Icon(Icons.my_location, size: 20),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _moveToPoint(p.x.toDouble(), p.y.toDouble());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _moveToPoint(double gameX, double gameY) {
    if (!mounted) return;
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
    if (!mounted) return;
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

class _MarkerCluster {
  final MapPoint point;
  final List<MapPoint> members;
  _MarkerCluster({required this.point, required this.members});
}

/// 地图 Marker 图标
class _MarkerIcon extends StatelessWidget {
  final int catId;
  final int count;
  final double size;
  const _MarkerIcon({
    required this.catId,
    required this.count,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final triangleSize = size * 0.25;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border:
                    Border.all(color: const Color(0xFF00D9FF), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/$catId.png',
                  fit: BoxFit.cover,
                  cacheWidth: (size * 2).toInt(),
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: size * 0.6,
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: Size(triangleSize, triangleSize * 0.7),
              painter: _TrianglePainter(color: Colors.white),
            ),
          ],
        ),
        if (count > 1)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
