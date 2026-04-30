/// API 常量与配置
///
/// baseUrl 通过 `--dart-define=API_BASE_URL=...` 编译时注入，
/// 不从源码硬编码读取，确保仓库安全。
/// 本地构建时，[build_apk.sh] 自动从 `.env` 文件读取并传入。
class ApiConfig {
  /// 后端 API 地址
  /// 编译时通过 --dart-define=API_BASE_URL=... 传入
  /// 默认值用于 CI / 本地无配置时的回退
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// API 前缀
  static const String apiPrefix = '/api';

  static String get apiBase => '$baseUrl$apiPrefix';

  /// 认证相关
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

  /// 统计相关
  static const String statsEndpoint = '/stats';

  /// 交易相关
  static const String transactionsEndpoint = '/transactions';
  static const String importEndpoint = '/transactions/import';
  static const String categoriesEndpoint = '/categories';
}
