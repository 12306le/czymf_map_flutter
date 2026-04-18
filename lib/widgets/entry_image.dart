import 'package:flutter/material.dart';
import '../models/game_entry.dart';

/// 通用条目图片组件：优先本地图，其次网络图，最后占位图标
class EntryImage extends StatelessWidget {
  final GameEntry entry;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData fallbackIcon;

  const EntryImage({
    super.key,
    required this.entry,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image,
  });

  @override
  Widget build(BuildContext context) {
    final local = entry.localImagePath;
    final network = entry.networkImageUrl;

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: Icon(fallbackIcon, color: Colors.grey.shade400, size: 36),
          ),
        );

    if (local != null) {
      return Image.asset(
        local,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width != null ? (width! * 2).toInt() : null,
        errorBuilder: (_, __, ___) {
          if (network != null) {
            return Image.network(
              network,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (_, __, ___) => placeholder(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder(),
            );
          }
          return placeholder();
        },
      );
    }
    if (network != null) {
      return Image.network(
        network,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder(),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : placeholder(),
      );
    }
    return placeholder();
  }
}
