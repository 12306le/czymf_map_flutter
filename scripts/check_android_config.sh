#!/bin/bash

# Android配置完整性检查脚本
# 用于验证Flutter项目的Android签名配置是否完整

echo "🔍 检查Android配置完整性..."

# 检查key.properties
if [ ! -f "android/key.properties" ]; then
    echo "❌ 缺少 android/key.properties"
    exit 1
else
    echo "✅ android/key.properties 存在"
fi

# 检查build.gradle中的签名配置
if ! grep -q "signingConfigs" android/app/build.gradle; then
    echo "❌ android/app/build.gradle 缺少 signingConfigs 配置"
    exit 1
else
    echo "✅ build.gradle 包含签名配置"
fi

# 检查GitHub Actions配置
if [ ! -f ".github/workflows/build.yml" ]; then
    echo "⚠️  缺少 GitHub Actions 配置"
else
    if ! grep -q "keytool" .github/workflows/build.yml; then
        echo "❌ GitHub Actions 缺少密钥生成步骤"
        exit 1
    else
        echo "✅ GitHub Actions 配置完整"
    fi
fi

echo ""
echo "✅ 所有配置检查通过！"
exit 0
