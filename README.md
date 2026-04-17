# 创造与魔法地图工具 - Flutter版

[![Build Status](https://github.com/YOUR_USERNAME/czymf_map_flutter/workflows/Build%20Flutter%20APK/badge.svg)](https://github.com/YOUR_USERNAME/czymf_map_flutter/actions)
[![Release](https://img.shields.io/github/v/release/YOUR_USERNAME/czymf_map_flutter)](https://github.com/YOUR_USERNAME/czymf_map_flutter/releases)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

基于Web版本重构的Flutter移动应用，提供完整的离线地图浏览功能。

## 功能特性

### ✅ 已实现
- 🗺️ 交互式地图浏览（拖动、缩放）
- 📍 2725个资源点位显示
- 🏷️ 8大类别、317种物品分类筛选
- 🔍 智能搜索（支持中文、拼音全拼、拼音首字母）
- 💾 本地存储用户选择偏好
- 📱 完全离线可用
- ⚡ 60fps流畅性能

### 🎯 核心优势
1. **搜索功能增强**
   - 中文名称搜索：`铁矿`
   - 拼音全拼搜索：`tiekuang`
   - 拼音首字母：`tk`
   - 模糊匹配支持

2. **性能优化**
   - 使用flutter_map实现高性能地图渲染
   - 标记点按需加载
   - 流畅的60fps缩放体验

3. **用户体验**
   - Material Design 3设计
   - 直观的分类选择界面
   - 实时搜索结果展示
   - 点位详情弹窗

## 项目结构

```
czymf_map_flutter/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/
│   │   └── map_data.dart         # 数据模型
│   ├── services/
│   │   └── map_service.dart      # 数据服务
│   ├── providers/
│   │   └── map_provider.dart     # 状态管理
│   ├── screens/
│   │   └── map_screen.dart       # 地图主页面
│   └── widgets/
│       ├── category_selector.dart # 分类选择器
│       └── search_bar_widget.dart # 搜索栏
├── assets/
│   ├── data/
│   │   └── data.json             # 游戏数据
│   ├── images/
│   │   └── background.png        # 地图背景
│   └── icons/                    # 物品图标（327个）
├── pubspec.yaml                  # 依赖配置
└── README.md                     # 本文件
```

## 技术栈

- **Flutter**: 3.0+
- **flutter_map**: 地图渲染引擎
- **Provider**: 状态管理
- **lpinyin**: 拼音搜索支持
- **shared_preferences**: 本地存储

## 安装步骤

### 1. 环境准备
```bash
# 确保已安装Flutter SDK
flutter --version

# 克隆项目
cd /sdcard/kkkk/czymf_map_flutter
```

### 2. 复制资源文件
```bash
# 执行资源复制脚本
bash copy_assets.sh
```

### 3. 生成代码
```bash
# 生成JSON序列化代码
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. 运行应用
```bash
# 连接设备后运行
flutter run

# 或构建APK
flutter build apk --release
```

## 地图瓦片处理

由于原始地图是4张大图（每张2495x2495），需要转换为瓦片格式：

### 方案1：使用简化背景（推荐）
直接使用单张背景图，不切割瓦片：
```bash
# 已在copy_assets.sh中实现
cp img/1.jpg assets/images/background.png
```

### 方案2：生成完整瓦片（可选）
使用GDAL工具生成标准地图瓦片：
```bash
# 1. 合并4张图片
# 2. 使用gdal2tiles.py生成瓦片
gdal2tiles.py -z 11-18 merged_map.png assets/images/tiles/
```

## 数据说明

### 游戏数据统计
- **分类**: 8种（矿产、坐骑、宠物、采集物、宝箱、钓鱼、其他、结缘设施）
- **物品**: 317种
- **坐标点**: 2725个
- **地图范围**: 0-20000 游戏坐标

### 坐标转换
```dart
// 游戏坐标 -> 经纬度
LatLng gameToLatLng(int x, int y) {
  final lat = (20000 - y) / 200.0;  // 0-100
  final lng = x / 200.0;             // 0-100
  return LatLng(lat, lng);
}
```

## 使用说明

### 基本操作
1. **浏览地图**: 拖动地图查看不同区域
2. **缩放**: 双指捏合放大/缩小
3. **筛选资源**: 点击左上角筛选按钮选择要显示的资源类型
4. **搜索**: 在搜索框输入资源名称（支持拼音）
5. **查看详情**: 点击地图上的标记查看坐标和备注

### 搜索示例
- 搜索 `铁矿` 或 `tiekuang` 或 `tk`
- 搜索 `熔火龙` 或 `ronghuolong` or `rhl`
- 搜索 `草莓` 或 `caomei` 或 `cm`

## 性能优化

1. **标记点优化**
   - 仅渲染选中类别的点位
   - 使用AssetImage缓存图标
   - 避免重复构建Widget

2. **地图优化**
   - 限制缩放范围（11-18级）
   - 使用本地资源避免网络请求
   - 启用硬件加速

3. **搜索优化**
   - 预构建搜索索引
   - 分级匹配（精确 > 前缀 > 包含）
   - 结果去重

## 开发计划

### 待实现功能
- [ ] 路径规划
- [ ] 收藏点位
- [ ] 自定义标记
- [ ] 数据导入/导出
- [ ] 多语言支持
- [ ] 暗黑模式

## 常见问题

### Q: 地图显示空白？
A: 检查assets/images/目录是否有背景图片，确保pubspec.yaml中正确配置了assets路径。

### Q: 图标不显示？
A: 确保assets/icons/目录包含所有图标文件（327个PNG文件）。

### Q: 搜索不到结果？
A: 检查data.json是否正确加载，查看控制台是否有错误信息。

### Q: 性能卡顿？
A: 减少同时显示的点位数量，避免选择过多类别。

## 构建发布

### 本地构建
```bash
# 使用自动化脚本
bash build.sh

# 或手动构建
flutter build apk --release

# 输出位置
# build/app/outputs/flutter-apk/app-release.apk
```

### GitHub Actions 自动构建
项目已配置完整的CI/CD流程，支持：
- 推送代码自动构建APK
- 打tag自动发布Release
- PR代码质量检查

详见 [GITHUB_ACTIONS.md](GITHUB_ACTIONS.md)

**快速发布**：
```bash
git tag v1.0.0
git push origin v1.0.0
# 自动构建并发布到GitHub Releases
```

## 贡献指南

欢迎提交Issue和Pull Request！

## 许可证

本项目基于Web版本改编，仅供学习交流使用。

## 致谢

- 原始Web版本提供数据和设计参考
- Flutter社区提供优秀的开源库
- 创造与魔法游戏提供游戏数据

---

**版本**: 1.0.0  
**更新日期**: 2024-04-18  
**作者**: Kiro AI Assistant
