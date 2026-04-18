#!/bin/bash

# Android签名配置初始化脚本
# 自动配置Flutter项目的Android签名

echo "🚀 初始化Android签名配置..."

# 1. 创建key.properties
cat > android/key.properties << EOF
storePassword=android
keyPassword=android
keyAlias=upload
storeFile=upload-keystore.jks
EOF
echo "✅ 创建 android/key.properties"

# 2. 检查build.gradle是否已配置
if ! grep -q "keystoreProperties" android/app/build.gradle; then
    echo "⚠️  需要手动修改 android/app/build.gradle"
    echo "请在 android { } 块前添加："
    echo ""
    echo "def keystoreProperties = new Properties()"
    echo "def keystorePropertiesFile = rootProject.file('key.properties')"
    echo "if (keystorePropertiesFile.exists()) {"
    echo "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))"
    echo "}"
    echo ""
    echo "并在 buildTypes { } 中配置 signingConfigs"
else
    echo "✅ build.gradle 已配置签名"
fi

# 3. 生成本地测试密钥（可选）
if [ ! -f "android/app/upload-keystore.jks" ]; then
    echo "📝 生成本地测试密钥..."
    keytool -genkey -v -keystore android/app/upload-keystore.jks \
        -alias upload -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass android -keypass android \
        -dname "CN=Test, OU=Test, O=Test, L=Test, ST=Test, C=CN"
    echo "✅ 本地密钥已生成"
else
    echo "✅ 本地密钥已存在"
fi

echo ""
echo "✅ 初始化完成！"
echo "💡 提示：GitHub Actions会自动生成密钥，无需提交.jks文件"
