import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  final ApiClient _client;

  AuthBloc(this._repository, this._client) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (!_client.hasToken) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      final user = await _repository.getMe();
      emit(AuthAuthenticated(user));
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.login(
        LoginRequest(email: event.email, password: event.password),
      );
      final user = await _repository.getMe();
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(_extractError(e)));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repository.logout();
    emit(AuthUnauthenticated());
  }

  String _extractError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('401')) {
      return '邮箱或密码错误';
    }
    if (msg.contains('connection') || msg.contains('SocketException') || msg.contains('Connection')) {
      return '无法连接服务器 (${ApiConfig.baseUrl})';
    }
    return '登录失败: $msg';
  }
}
