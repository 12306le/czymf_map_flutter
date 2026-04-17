import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class AssetTestScreen extends StatefulWidget {
  const AssetTestScreen({super.key});

  @override
  State<AssetTestScreen> createState() => _AssetTestScreenState();
}

class _AssetTestScreenState extends State<AssetTestScreen> {
  String testResult = '正在测试资源加载...';
  bool backgroundLoaded = false;
  bool dataLoaded = false;
  int iconsLoaded = 0;
  int iconsFailed = 0;

  @override
  void initState() {
    super.initState();
    testAssets();
  }

  Future<void> testAssets() async {
    final results = <String>[];

    // 测试背景图片
    try {
      await rootBundle.load('assets/images/background.png');
      backgroundLoaded = true;
      results.add('✅ 背景图片加载成功');
    } catch (e) {
      results.add('❌ 背景图片加载失败: $e');
    }

    // 测试数据文件
    try {
      final data = await rootBundle.loadString('assets/data/data.json');
      final json = jsonDecode(data);
      dataLoaded = true;
      results.add('✅ 数据文件加载成功 (${json['data']['item_list'].length} 个物品)');
    } catch (e) {
      results.add('❌ 数据文件加载失败: $e');
    }

    // 测试图标文件
    final testIcons = [1, 2, 3, 47, 48, 50, 100, 200, 300, 400, 500];
    for (final id in testIcons) {
      try {
        await rootBundle.load('assets/icons/$id.png');
        iconsLoaded++;
      } catch (e) {
        iconsFailed++;
        results.add('❌ 图标 $id.png 加载失败');
      }
    }
    results.add('✅ 图标测试: $iconsLoaded 成功, $iconsFailed 失败');

    setState(() {
      testResult = results.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('资源加载测试'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '资源加载状态',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      testResult,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '图标预览',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [1, 2, 3, 47, 48, 50, 100, 200, 300]
                          .map((id) => Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Image.asset(
                                  'assets/icons/$id.png',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 24,
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '背景图片预览',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Image.asset(
                        'assets/images/background.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.red[100],
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error, color: Colors.red, size: 48),
                                  SizedBox(height: 8),
                                  Text('背景图片加载失败'),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
