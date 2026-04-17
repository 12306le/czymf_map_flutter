# 快速开始指南

## 1. 环境检查

```bash
# 检查Flutter版本
flutter doctor

# 确保输出显示：
# ✓ Flutter (Channel stable, 3.x.x)
# ✓ Android toolchain
# ✓ Connected device
```

## 2. 安装依赖

```bash
cd /sdcard/kkkk/czymf_map_flutter
flutter pub get
```

## 3. 生成代码

```bash
# 生成JSON序列化代码
flutter pub run build_runner build --delete-conflicting-outputs
```

## 4. 运行应用

```bash
# 连接Android设备或启动模拟器
flutter devices

# 运行应用
flutter run

# 或者直接构建APK
flutter build apk --release
```

## 5. 安装APK

构建完成后，APK位于：
```
build/app/outputs/flutter-apk/app-release.apk
```

直接安装到设备：
```bash
flutter install
```

## 常见问题解决

### 问题1: 找不到Flutter命令
```bash
# 添加Flutter到PATH
export PATH="$PATH:/path/to/flutter/bin"
```

### 问题2: 依赖下载失败
```bash
# 使用国内镜像
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
flutter pub get
```

### 问题3: build_runner失败
```bash
# 清理后重新生成
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题4: 资源文件未找到
```bash
# 重新复制资源
bash copy_assets.sh

# 检查assets目录
ls -la assets/data/
ls -la assets/icons/ | wc -l  # 应该显示327+
```

## 开发模式

### 热重载
运行应用后，修改代码按 `r` 键即可热重载

### 调试
```bash
# 启用调试模式
flutter run --debug

# 查看日志
flutter logs
```

## 性能优化建议

1. **首次运行较慢是正常的**
   - Flutter需要编译Dart代码
   - 后续启动会快很多

2. **减少同时显示的点位**
   - 不要一次选择所有类别
   - 按需选择2-3个类别即可

3. **使用Release模式**
   - Debug模式性能较差
   - Release模式可达60fps

## 下一步

- 阅读 [README.md](README.md) 了解完整功能
- 查看 [lib/](lib/) 目录了解代码结构
- 尝试修改UI样式和功能

## 技术支持

遇到问题？
1. 检查 `flutter doctor` 输出
2. 查看控制台错误信息
3. 确认资源文件完整性
4. 尝试 `flutter clean` 后重新构建
