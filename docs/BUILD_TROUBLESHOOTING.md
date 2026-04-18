# 构建故障排查指南

## 问题：BUILD FAILED in Gradle

### 症状
```
BUILD FAILED in 1m 43s
Gradle task assembleRelease failed with exit code 1
Error: Process completed with exit code 1
```

### 根本原因分析

1. **缺少Gradle Wrapper配置**
   - 文件：`android/gradle/wrapper/gradle-wrapper.properties`
   - 导致：Gradle无法确定使用哪个版本

2. **签名配置问题**
   - key.properties路径错误
   - 密钥文件不存在
   - build.gradle配置不完整

3. **依赖版本不兼容**
   - Gradle版本与AGP不匹配
   - Flutter版本与依赖包不兼容
   - Java版本不符合要求

### 解决方案

#### 方案1：完整的Gradle配置

**android/gradle/wrapper/gradle-wrapper.properties**
```properties
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

**android/build.gradle**
```gradle
buildscript {
    ext.kotlin_version = '1.9.0'
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.1.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

#### 方案2：签名配置检查清单

- [ ] `android/key.properties` 存在
- [ ] `android/app/upload-keystore.jks` 在构建时生成
- [ ] `android/app/build.gradle` 包含 keystoreProperties 读取
- [ ] `android/app/build.gradle` 包含 signingConfigs.release
- [ ] storeFile 路径正确（相对于android/目录）

#### 方案3：GitHub Actions优化

```yaml
- name: Setup Gradle
  uses: gradle/actions/setup-gradle@v3
  
- name: Build APK
  run: flutter build apk --release --verbose
```

### 版本兼容性矩阵

| Flutter | Gradle | AGP   | Kotlin | Java |
|---------|--------|-------|--------|------|
| 3.24.0  | 8.0+   | 8.1.0 | 1.9.0  | 17   |
| 3.22.0  | 7.6+   | 8.0.0 | 1.8.0  | 17   |
| 3.19.0  | 7.5+   | 7.4.0 | 1.7.0  | 11   |

### 调试命令

**本地测试构建**
```bash
cd android
./gradlew assembleRelease --stacktrace --info
```

**检查配置**
```bash
bash scripts/check_android_config.sh
```

**查看Gradle版本**
```bash
cd android
./gradlew --version
```

### 常见错误及解决

**错误1：Could not find keystore**
```
解决：检查 key.properties 中的 storeFile 路径
正确：storeFile=app/upload-keystore.jks
错误：storeFile=upload-keystore.jks
```

**错误2：Unsupported class file major version**
```
解决：Java版本不匹配
检查：java-version: '17' 在 GitHub Actions
```

**错误3：Execution failed for task ':app:lintVitalAnalyzeRelease'**
```
解决：在 android/app/build.gradle 添加：
lintOptions {
    checkReleaseBuilds false
    abortOnError false
}
```

**错误4：Duplicate class found**
```
解决：依赖冲突，在 pubspec.yaml 中固定版本
或在 android/app/build.gradle 添加：
configurations.all {
    resolutionStrategy {
        force 'com.google.code.gson:gson:2.10.1'
    }
}
```

### 最佳实践

1. **始终使用Gradle Wrapper**
   - 不要依赖系统安装的Gradle
   - 在项目中包含wrapper配置

2. **版本锁定**
   - 在pubspec.yaml中锁定依赖版本
   - 定期更新但测试后再推送

3. **本地先测试**
   ```bash
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

4. **使用缓存**
   - GitHub Actions中启用Gradle和Flutter缓存
   - 加速构建，减少失败概率

5. **详细日志**
   - 构建时使用 --verbose 或 --stacktrace
   - 便于快速定位问题
