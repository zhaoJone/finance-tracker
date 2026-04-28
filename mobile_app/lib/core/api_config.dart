/// API 常量与配置
class ApiConfig {
  /// 后端 API 地址（Android 模拟器访问宿主机用 10.0.2.2）
  static const String baseUrl = 'http://10.0.2.2:8000';

  /// API 前缀
  static const String apiPrefix = '/api';

  static String get apiBase => '$baseUrl$apiPrefix';

  /// 认证相关
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

  /// 交易相关
  static const String transactionsEndpoint = '/transactions';
  static const String importEndpoint = '/transactions/import';
  static const String categoriesEndpoint = '/categories';
}
