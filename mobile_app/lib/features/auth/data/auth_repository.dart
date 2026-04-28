import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import 'auth_models.dart';

/// Auth 数据仓库
class AuthRepository {
  final ApiClient _client;

  AuthRepository(this._client);

  /// 登录，返回 access_token
  Future<String> login(LoginRequest request) async {
    final response = await _client.dio.post(
      ApiConfig.loginEndpoint,
      data: request.toFormData(),
      options: Options(
        contentType: 'application/x-www-form-urlencoded',
      ),
    );
    final token = TokenResponse.fromJson(response.data as Map<String, dynamic>);
    await _client.saveToken(token.accessToken);
    return token.accessToken;
  }

  /// 获取当前用户信息
  Future<User> getMe() async {
    final response = await _client.dio.get(ApiConfig.meEndpoint);
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// 登出
  Future<void> logout() async {
    await _client.clearToken();
  }
}
