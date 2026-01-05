class EnvironmentConfig {
  static const String dev = 'dev';
  static const String test = 'test';
  static const String prod = 'prod';

  static Map<String, Map<String, String>> configs = {
    dev: {
      'apiBaseUrl': 'https://dev-api.example.com',
      'appName': 'CAD Preview (Dev)',
      'enableDebugMode': 'true',
      'logLevel': 'debug',
      'timeout': '30000',
    },
    test: {
      'apiBaseUrl': 'https://test-api.example.com',
      'appName': 'CAD Preview (Test)',
      'enableDebugMode': 'true',
      'logLevel': 'info',
      'timeout': '25000',
    },
    prod: {
      'apiBaseUrl': 'https://api.example.com',
      'appName': 'CAD Preview',
      'enableDebugMode': 'false',
      'logLevel': 'error',
      'timeout': '20000',
    },
  };

  static String getConfig(String environment, String key) {
    return configs[environment]?[key] ?? configs[dev]![key] ?? '';
  }

  static bool isDebugMode(String environment) {
    return getConfig(environment, 'enableDebugMode') == 'true';
  }

  static String getApiBaseUrl(String environment) {
    return getConfig(environment, 'apiBaseUrl');
  }

  static String getAppName(String environment) {
    return getConfig(environment, 'appName');
  }

  static String getLogLevel(String environment) {
    return getConfig(environment, 'logLevel');
  }

  static int getTimeout(String environment) {
    return int.tryParse(getConfig(environment, 'timeout')) ?? 30000;
  }
}
