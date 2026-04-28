/// 登录请求体
class LoginRequest {
  final String username; // email
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toFormData() => {
        'username': username,
        'password': password,
      };
}

/// Token 响应
class TokenResponse {
  final String accessToken;
  final String tokenType;

  TokenResponse({required this.accessToken, required this.tokenType});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String,
    );
  }
}

/// 用户信息
class User {
  final String id;
  final String email;

  User({required this.id, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }
}
