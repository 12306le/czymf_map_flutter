#!/bin/bash
# Flutter项目构建脚本

set -e

echo "======================================"
echo "创造与魔法地图工具 - Flutter构建脚本"
echo "======================================"
echo ""

# 检查Flutter环境
if ! command -v flutter &> /dev/null; then
    echo "❌ 错误: 未找到Flutter命令"
    echo "请先安装Flutter SDK: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ Flutter环境检查通过"
flutter --version
echo ""

# 清理旧构建
echo "🧹 清理旧构建..."
flutter clean

# 获取依赖
echo "📦 获取依赖..."
flutter pub get

# 生成代码
echo "🔨 生成JSON序列化代码..."
flutter pub run build_runner build --delete-conflicting-outputs

# 检查资源文件
echo "📁 检查资源文件..."
if [ ! -f "assets/data/data.json" ]; then
    echo "❌ 错误: 未找到 assets/data/data.json"
    echo "请运行: bash copy_assets.sh"
    exit 1
fi

if [ ! -f "assets/images/background.png" ]; then
    echo "❌ 错误: 未找到 assets/images/background.png"
    echo "请运行: bash copy_assets.sh"
    exit 1
fi

icon_count=$(ls assets/icons/*.png 2>/dev/null | wc -l)
if [ "$icon_count" -lt 300 ]; then
    echo "⚠️  警告: 图标文件数量不足 ($icon_count/327)"
    echo "请运行: bash copy_assets.sh"
fi

echo "✓ 资源文件检查完成"
echo ""

# 构建APK
echo "🚀 开始构建Release APK..."
flutter build apk --release

# 检查构建结果
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
    echo ""
    echo "======================================"
    echo "✅ 构建成功！"
    echo "======================================"
    echo ""
    echo "APK位置: build/app/outputs/flutter-apk/app-release.apk"
    
    # 显示APK大小
    apk_size=$(du -h build/app/outputs/flutter-apk/app-release.apk | cut -f1)
    echo "APK大小: $apk_size"
    echo ""
    
    echo "安装命令:"
    echo "  adb install build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "或使用Flutter命令:"
    echo "  flutter install"
else
    echo ""
    echo "❌ 构建失败"
    exit 1
fi
