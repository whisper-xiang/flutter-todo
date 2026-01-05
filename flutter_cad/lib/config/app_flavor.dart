import 'package:flutter/material.dart';
import 'package:flutter_flavor/flutter_flavor.dart';

class AppFlavor {
  static const String dev = 'DEV';
  static const String test = 'TEST';
  static const String prod = 'PROD';

  static void initialize({
    required String environment,
    required String apiBaseUrl,
    required String appName,
    required bool enableDebugMode,
    required String logLevel,
    required int timeout,
  }) {
    FlavorConfig(
      name: environment,
      color: _getEnvironmentColor(environment),
      location: BannerLocation.topStart,
      variables: {
        'apiBaseUrl': apiBaseUrl,
        'appName': appName,
        'enableDebugMode': enableDebugMode.toString(),
        'logLevel': logLevel,
        'timeout': timeout.toString(),
      },
    );
  }

  static String get apiBaseUrl =>
      FlavorConfig.instance.variables['apiBaseUrl'] ?? '';
  static String get appName => FlavorConfig.instance.variables['appName'] ?? '';
  static bool get enableDebugMode =>
      FlavorConfig.instance.variables['enableDebugMode'] == 'true';
  static String get logLevel =>
      FlavorConfig.instance.variables['logLevel'] ?? 'debug';
  static int get timeout =>
      int.tryParse(FlavorConfig.instance.variables['timeout'] ?? '30000') ??
      30000;

  static String get currentEnvironment => FlavorConfig.instance.name ?? dev;

  static bool get isDev => currentEnvironment == dev;
  static bool get isTest => currentEnvironment == test;
  static bool get isProd => currentEnvironment == prod;

  static Color _getEnvironmentColor(String environment) {
    switch (environment) {
      case dev:
        return Colors.blue;
      case test:
        return Colors.orange;
      case prod:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
