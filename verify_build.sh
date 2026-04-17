#!/bin/bash

echo "========================================="
echo "Flutter项目构建配置验证"
echo "========================================="
echo ""

# 检查必需文件
echo "📋 检查必需文件..."
files=(
    "android/build.gradle"
    "android/settings.gradle"
    "android/gradle.properties"
    "android/app/build.gradle"
    "android/app/src/main/AndroidManifest.xml"
    "android/app/src/main/kotlin/com/czymf/map/MainActivity.kt"
    "android/app/src/main/res/values/styles.xml"
    "android/app/src/main/res/drawable/launch_background.xml"
    "pubspec.yaml"
    "lib/main.dart"
)

missing=0
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file - 缺失"
        missing=$((missing + 1))
    fi
done

echo ""
echo "📦 检查资源文件..."
if [ -d "assets/data" ]; then
    data_count=$(find assets/data -type f | wc -l)
    echo "  ✅ assets/data/ ($data_count 个文件)"
else
    echo "  ❌ assets/data/ - 缺失"
    missing=$((missing + 1))
fi

if [ -d "assets/images" ]; then
    img_count=$(find assets/images -type f | wc -l)
    echo "  ✅ assets/images/ ($img_count 个文件)"
else
    echo "  ❌ assets/images/ - 缺失"
    missing=$((missing + 1))
fi

if [ -d "assets/icons" ]; then
    icon_count=$(find assets/icons -type f -name "*.png" | wc -l)
    echo "  ✅ assets/icons/ ($icon_count 个图标)"
else
    echo "  ❌ assets/icons/ - 缺失"
    missing=$((missing + 1))
fi

echo ""
echo "🔍 检查配置内容..."

# 检查AndroidManifest
if grep -q "flutterEmbedding" android/app/src/main/AndroidManifest.xml; then
    if grep -q 'android:value="2"' android/app/src/main/AndroidManifest.xml; then
        echo "  ✅ Flutter v2 embedding 已启用"
    else
        echo "  ⚠️  Flutter embedding 版本不正确"
    fi
else
    echo "  ❌ 缺少 flutterEmbedding 配置"
    missing=$((missing + 1))
fi

# 检查styles.xml
if [ -f "android/app/src/main/res/values/styles.xml" ]; then
    if grep -q "LaunchTheme" android/app/src/main/res/values/styles.xml; then
        echo "  ✅ LaunchTheme 已定义"
    else
        echo "  ❌ 缺少 LaunchTheme"
        missing=$((missing + 1))
    fi
fi

echo ""
echo "========================================="
if [ $missing -eq 0 ]; then
    echo "✅ 所有检查通过！项目配置正确。"
    echo "========================================="
    exit 0
else
    echo "❌ 发现 $missing 个问题，请修复后再构建。"
    echo "========================================="
    exit 1
fi
