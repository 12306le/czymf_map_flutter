# 安装指南

## 方式一：直接安装APK（推荐）

如果已有构建好的APK文件：

```bash
# 使用adb安装
adb install app-release.apk

# 或者直接复制到手机安装
```

## 方式二：从源码构建

### 前置要求

1. **Flutter SDK** (3.0+)
   ```bash
   # 下载并安装Flutter
   # https://flutter.dev/docs/get-started/install
   
   # 验证安装
   flutter doctor
   ```

2. **Android SDK** (API 21+)
   - 通过Android Studio安装
   - 或使用命令行工具

3. **设备或模拟器**
   - Android设备（开启USB调试）
   - 或Android模拟器

### 构建步骤

#### 1. 准备项目
```bash
cd /sdcard/kkkk/czymf_map_flutter
```

#### 2. 复制资源文件
```bash
bash copy_assets.sh
```

#### 3. 安装依赖
```bash
flutter pub get
```

#### 4. 生成代码
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 5. 构建APK
```bash
# 使用构建脚本（推荐）
bash build.sh

# 或手动构建
flutter build apk --release
```

#### 6. 安装应用
```bash
# 方式1: 使用Flutter命令
flutter install

# 方式2: 使用adb
adb install build/app/outputs/flutter-apk/app-release.apk

# 方式3: 复制APK到手机手动安装
cp build/app/outputs/flutter-apk/app-release.apk /sdcard/Download/
```

## 常见问题

### Q1: Flutter命令找不到
```bash
# 添加Flutter到PATH
export PATH="$PATH:/path/to/flutter/bin"

# 或在 ~/.bashrc 中添加
echo 'export PATH="$PATH:/path/to/flutter/bin"' >> ~/.bashrc
source ~/.bashrc
```

### Q2: 依赖下载失败
```bash
# 使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

# 重新获取依赖
flutter pub get
```

### Q3: build_runner失败
```bash
# 清理后重试
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Q4: 资源文件未找到
```bash
# 检查资源文件
ls -la assets/data/
ls -la assets/images/
ls assets/icons/*.png | wc -l  # 应该显示327

# 重新复制
bash copy_assets.sh
```

### Q5: 构建APK失败
```bash
# 检查Flutter环境
flutter doctor -v

# 清理后重新构建
flutter clean
flutter pub get
flutter build apk --release
```

### Q6: 安装APK失败
```bash
# 检查设备连接
adb devices

# 卸载旧版本
adb uninstall com.czymf.map

# 重新安装
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

## 开发模式

### 运行调试版本
```bash
# 连接设备
flutter devices

# 运行应用
flutter run

# 热重载：按 r
# 热重启：按 R
# 退出：按 q
```

### 查看日志
```bash
# 实时日志
flutter logs

# 或使用adb
adb logcat | grep flutter
```

## 性能优化建议

### 首次运行
- 首次启动会较慢（需要编译）
- 后续启动会快很多
- Release版本性能最佳

### 使用建议
- 不要一次选择所有类别
- 按需选择2-3个类别即可
- 使用搜索功能快速定位

## 系统要求

### Android
- **最低版本**: Android 5.0 (API 21)
- **推荐版本**: Android 8.0+ (API 26+)
- **存储空间**: 至少50MB
- **内存**: 至少2GB RAM

### iOS（未测试）
- **最低版本**: iOS 11.0
- **需要**: Apple开发者账号

## 卸载

```bash
# 使用adb
adb uninstall com.czymf.map

# 或在设备上手动卸载
```

## 技术支持

遇到问题？

1. 查看 [README.md](README.md)
2. 查看 [QUICKSTART.md](QUICKSTART.md)
3. 检查 `flutter doctor` 输出
4. 查看构建日志

## 更新

### 更新应用
```bash
# 拉取最新代码
git pull

# 重新构建
bash build.sh

# 安装更新
flutter install
```

### 更新依赖
```bash
# 更新所有依赖到最新版本
flutter pub upgrade

# 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs
```

---

**提示**: 首次构建可能需要较长时间（10-30分钟），请耐心等待。
