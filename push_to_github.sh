#!/bin/bash

# GitHub推送脚本
# 使用方法：bash push_to_github.sh YOUR_GITHUB_TOKEN

set -e

if [ -z "$1" ]; then
    echo "错误：请提供GitHub Personal Access Token"
    echo "使用方法：bash push_to_github.sh YOUR_TOKEN"
    exit 1
fi

TOKEN="$1"
REPO_URL="https://12306le:${TOKEN}@github.com/12306le/czymf_map_flutter.git"

echo "=== 初始化Git仓库 ==="
git init
git config user.name "Kiro AI"
git config user.email "kiro@example.com"

echo "=== 添加所有文件 ==="
git add .

echo "=== 提交更改 ==="
git commit -m "Fix Android build configuration and add complete project"

echo "=== 设置主分支 ==="
git branch -M main

echo "=== 添加远程仓库 ==="
git remote add origin "$REPO_URL"

echo "=== 推送到GitHub ==="
git push -u origin main

echo "=== 清理敏感信息 ==="
git remote remove origin

echo ""
echo "✅ 推送成功！"
echo "查看仓库：https://github.com/12306le/czymf_map_flutter"
echo ""
echo "GitHub Actions会自动开始构建APK"
echo "查看构建状态：https://github.com/12306le/czymf_map_flutter/action