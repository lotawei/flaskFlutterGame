/// 应用环境配置。
class AppConfig {
  AppConfig({
    required this.serviceName,
    required this.apiBaseUrl,
    required this.logLevel,
    required this.enableNetworkLog,
  });

  final String serviceName;
  final String apiBaseUrl;
  final String logLevel;
  final bool enableNetworkLog;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      serviceName: 'meme-game-app',
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:5000',
      ),
      logLevel: const String.fromEnvironment(
        'LOG_LEVEL',
        defaultValue: 'INFO',
      ),
      enableNetworkLog: const bool.fromEnvironment(
        'ENABLE_NETWORK_LOG',
        defaultValue: true,
      ),
    );
  }
}
