# Android签名配置指南

## 问题说明
Flutter Android release构建需要签名配置，否则会出现 `Process completed with exit code 1` 错误。

## 必需文件

### 1. android/key.properties
```properties
storePassword=android
keyPassword=android
keyAlias=upload
storeFile=upload-keystore.jks
```

### 2. android/app/build.gradle
在 `android {}` 块前添加：
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

在 `android {}` 块内添加：
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        // ... 其他配置
    }
}
```

### 3. .github/workflows/build.yml
在构建前生成密钥：
```yaml
- name: Generate keystore
  run: |
    keytool -genkey -v -keystore android/app/upload-keystore.jks \
      -alias upload -keyalg RSA -keysize 2048 -validity 10000 \
      -storepass android -keypass android \
      -dname "CN=GitHub Actions, OU=CI, O=GitHub, L=Cloud, ST=Cloud, C=US"
```

## 快速检查清单
- [ ] android/key.properties 存在
- [ ] android/app/build.gradle 包含 keystoreProperties 读取逻辑
- [ ] android/app/build.gradle 包含 signingConfigs.release
- [ ] buildTypes.release 使用 signingConfig signingConfigs.release
- [ ] GitHub Actions 包含密钥生成步骤

## 自动化工具
```bash
# 检查配置完整性
bash scripts/check_android_config.sh

# 初始化签名配置
bash scripts/init_android_signing.sh
```

## 注意事项
1. **不要提交密钥文件**：将 `*.jks` 添加到 .gitignore
2. **GitHub Actions自动生成**：CI环境会自动生成临时密钥
3. **生产环境**：使用 GitHub Secrets 管理真实密钥
4. **密码安全**：示例使用简单密码，生产环境应使用强密码

## 故障排查
如果构建失败：
1. 运行 `bash scripts/check_android_config.sh` 检查配置
2. 查看 GitHub Actions 日志中的具体错误信息
3. 确认 keytool 命令是否成功执行
4. 检查 build.gradle 语法是否正确
