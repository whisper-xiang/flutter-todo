/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:33:42
 * @LastEditors: 轻语 243267674@qq.com
 * @LastEditTime: 2025-12-24 15:46:05
 * @FilePath: /flutter_cad/lib/main.dart
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/file_provider.dart';
import 'services/mock_service.dart';
import 'router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mockService = MockService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(mockService)),
        ChangeNotifierProvider(create: (_) => FileProvider(mockService)),
      ],
      child: MaterialApp.router(
        title: 'CAD Preview Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
