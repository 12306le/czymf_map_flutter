#!/bin/bash
# 复制资源文件脚本

SOURCE_DIR="/sdcard/kkkk/map-tool/map-tool"
TARGET_DIR="/sdcard/kkkk/czymf_map_flutter"

echo "开始复制资源文件..."

# 复制数据文件
echo "复制数据文件..."
cp "$SOURCE_DIR/data/data.json" "$TARGET_DIR/assets/data/"

# 复制图标文件
echo "复制图标文件..."
cp -r "$SOURCE_DIR/img/icons/"*.png "$TARGET_DIR/assets/icons/"

# 复制地图背景图片
echo "复制地图背景图片..."
cp "$SOURCE_DIR/img/1.jpg" "$TARGET_DIR/assets/images/background.png"

echo "资源文件复制完成！"
echo ""
echo "注意：地图瓦片需要手动生成"
echo "原始地图图片位于: $SOURCE_DIR/img/"
echo "需要使用工具将4张图片合并并切割成瓦片"
