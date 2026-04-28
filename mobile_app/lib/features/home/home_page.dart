import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../auth/presentation/auth_bloc.dart';
import '../auth/presentation/auth_event.dart';
import '../auth/presentation/auth_state.dart';
import '../notifications/presentation/notification_import_bloc.dart';
import '../notifications/presentation/notification_import_page.dart';
import '../../injection.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationImportBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finance Tracker'),
          actions: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthAuthenticated) {
                  return Row(
                    children: [
                      Text(
                        state.user.email,
                        style: const TextStyle(fontSize: 14),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: '登出',
                        onPressed: () {
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                        },
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: const NotificationImportPage(),
      ),
    );
  }
}
