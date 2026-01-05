/*
 * @Author: 轻语 243267674@qq.com
 * @Date: 2025-12-24 15:33:42
 * @LastEditors: 轻语
 * @LastEditTime: 2026-01-05 10:10:04
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/file_provider.dart';
import 'services/mock_service.dart';
import 'router.dart';
import 'config/environment_config.dart';
import 'config/app_flavor.dart';

void main() {
  const String environment = String.fromEnvironment(
    'FLUTTER_FLAVOR',
    defaultValue: EnvironmentConfig.dev,
  );

  AppFlavor.initialize(
    environment: environment.toUpperCase(),
    apiBaseUrl: EnvironmentConfig.getApiBaseUrl(environment),
    appName: EnvironmentConfig.getAppName(environment),
    enableDebugMode: EnvironmentConfig.isDebugMode(environment),
    logLevel: EnvironmentConfig.getLogLevel(environment),
    timeout: EnvironmentConfig.getTimeout(environment),
  );

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
        title: AppFlavor.appName,
        debugShowCheckedModeBanner: AppFlavor.enableDebugMode,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          useMaterial3: true,
        ),
        routerConfig: router,
      ),
    );
  }
}
