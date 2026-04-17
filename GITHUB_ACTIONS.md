# GitHub Actions 配置指南

本项目已配置完整的GitHub Actions自动构建流程。

## 工作流说明

### 1. Build Flutter APK (`build.yml`)
**触发条件**：
- 推送到 main/master/develop 分支
- 创建 Pull Request
- 手动触发

**功能**：
- 自动构建 APK 和 AAB
- 运行代码分析和测试
- 上传构建产物

**产物下载**：
在 Actions 页面的工作流运行记录中下载 `release-apk` 和 `release-aab`

### 2. Release Build (`release.yml`)
**触发条件**：
- 推送 tag（如 `v1.0.0`）
- 手动触发并指定版本号

**功能**：
- 构建多架构 APK（arm64-v8a, armeabi-v7a, x86_64）
- 构建 App Bundle
- 自动创建 GitHub Release
- 上传所有构建产物到 Release

**使用方法**：
```bash
# 创建并推送 tag
git tag v1.0.0
git push origin v1.0.0

# 或在 GitHub Actions 页面手动触发
```

### 3. PR Check (`pr-check.yml`)
**触发条件**：
- 创建或更新 Pull Request

**功能**：
- 代码格式检查
- 静态分析
- 运行测试并生成覆盖率报告
- 上传覆盖率到 Codecov（可选）

## 首次配置步骤

### 1. 推送代码到 GitHub
```bash
cd /sdcard/kkkk/czymf_map_flutter
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/czymf_map_flutter.git
git push -u origin main
```

### 2. 启用 GitHub Actions
1. 进入仓库的 Settings → Actions → General
2. 确保 "Allow all actions and reusable workflows" 已启用
3. 保存设置

### 3. 配置 Secrets（可选）
如果需要签名 APK，在 Settings → Secrets and variables → Actions 中添加：
- `KEYSTORE_BASE64`: Base64 编码的 keystore 文件
- `KEYSTORE_PASSWORD`: Keystore 密码
- `KEY_ALIAS`: Key 别名
- `KEY_PASSWORD`: Key 密码

### 4. 更新 README 徽章
将 README.md 中的 `YOUR_USERNAME` 替换为你的 GitHub 用户名。

## 构建产物说明

### APK 文件
- **app-arm64-v8a-release.apk**: 64位ARM架构（推荐，适用于大多数现代设备）
- **app-armeabi-v7a-release.apk**: 32位ARM架构（适用于较老设备）
- **app-x86_64-release.apk**: x86架构（适用于模拟器）

### AAB 文件
- **app-release.aab**: Google Play 上传包（包含所有架构）

## 本地测试工作流

可以使用 [act](https://github.com/nektos/act) 在本地测试 GitHub Actions：

```bash
# 安装 act
# macOS: brew install act
# Linux: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# 测试 build 工作流
act push -W .github/workflows/build.yml

# 测试 PR 检查
act pull_request -W .github/workflows/pr-check.yml
```

## 常见问题

### Q: 构建失败，提示找不到 Flutter
A: 检查 `flutter-version` 是否正确，建议使用稳定版本号。

### Q: 构建超时
A: GitHub Actions 免费版有时间限制（6小时），通常 Flutter 构建不会超时。如果超时，检查是否有死循环或网络问题。

### Q: 如何加速构建
A: 工作流已配置缓存（Gradle、Flutter、Pub），首次构建较慢，后续会快很多。

### Q: 如何签名 APK
A: 需要配置 Secrets 并修改 `android/app/build.gradle`，添加签名配置。

## 进阶配置

### 添加签名配置
1. 生成 keystore：
```bash
keytool -genkey -v -keystore release.keystore -alias release -keyalg RSA -keysize 2048 -validity 10000
```

2. 转换为 Base64：
```bash
base64 release.keystore > keystore.base64
```

3. 在 GitHub Secrets 中添加 `KEYSTORE_BASE64` 和相关密码

4. 修改 `build.yml`，在构建前添加：
```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/release.keystore
    
- name: Create key.properties
  run: |
    echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
    echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
    echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
    echo "storeFile=release.keystore" >> android/key.properties
```

### 添加自动版本号
在 `pubspec.yaml` 中使用环境变量：
```yaml
version: 1.0.0+${{ github.run_number }}
```

## 监控构建状态

在 GitHub 仓库页面可以看到：
- Actions 标签页：所有工作流运行记录
- Releases 标签页：所有发布版本
- README 徽章：实时构建状态

## 相关链接

- [Flutter CI/CD 官方文档](https://docs.flutter.dev/deployment/cd)
- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
