import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// Dio HTTP 客户端单例
class ApiClient {
  late final Dio _dio;
  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';

  ApiClient(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBase,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 请求拦截器：注入 Bearer Token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString(_tokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          // 401 → 清除 token（后续可扩展为自动刷新）
          if (error.response?.statusCode == 401) {
            _prefs.remove(_tokenKey);
          }
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  /// 保存 Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// 清除 Token（登出）
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// 是否有 Token
  bool get hasToken => _prefs.getString(_tokenKey) != null;
}
