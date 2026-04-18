import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/game_entry.dart';

/// 通用条目图片：优先本地 asset，失败回退到远程图（带缓存），再失败显示占位
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

    Widget remoteImage(String url) => CachedNetworkImage(
          imageUrl: url,
          width: width,
          height: height,
          fit: fit,
          placeholder: (_, __) => placeholder(),
          errorWidget: (_, __, ___) => placeholder(),
        );

    if (local != null) {
      return Image.asset(
        local,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width != null ? (width! * 2).toInt() : null,
        errorBuilder: (_, __, ___) =>
            network != null ? remoteImage(network) : placeholder(),
      );
    }
    if (network != null) return remoteImage(network);
    return placeholder();
  }
}
