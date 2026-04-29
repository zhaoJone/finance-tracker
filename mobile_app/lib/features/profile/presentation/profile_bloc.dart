import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api_client.dart';
import '../../../core/api_config.dart';
import '../../auth/data/auth_models.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiClient _client;

  ProfileBloc(this._client) : super(ProfileInitial()) {
    on<ProfileLoad>(_onLoad);
    on<ProfileLogout>(_onLogout);
  }

  Future<void> _onLoad(ProfileLoad event, Emitter<ProfileState> emit) async {
    emit(ProfileLoading());
    try {
      final response = await _client.dio.get(ApiConfig.meEndpoint);
      final user = User.fromJson(response.data as Map<String, dynamic>);
      emit(ProfileLoaded(user: user));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> _onLogout(ProfileLogout event, Emitter<ProfileState> emit) async {
    await _client.clearToken();
    // After logout, auth state should be handled by AuthBloc
    // Just emit initial state
    emit(ProfileInitial());
  }
}
