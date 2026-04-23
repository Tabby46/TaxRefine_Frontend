import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/theme/app_theme.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/providers/auth_api_provider.dart';
import 'package:taxrefine/data/providers/google_drive_provider.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';
import 'package:taxrefine/data/repositories/auth_repository.dart';
import 'package:taxrefine/data/repositories/transaction_repository.dart';
import 'package:taxrefine/logic/auth/auth_cubit.dart';
import 'package:taxrefine/logic/auth/auth_state.dart';
import 'package:taxrefine/logic/dashboard/dashboard_summary_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_cubit.dart';
import 'package:taxrefine/features/profile/cubit/bank_connection_cubit.dart';
import 'package:taxrefine/core/network/api_service.dart';
import 'package:taxrefine/presentation/screens/app_shell.dart';
import 'package:taxrefine/presentation/screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env').catchError((_) {
    // Optional for local/dev environments where .env may not exist.
  });

  runApp(const TaxRefineApp());
}

class TaxRefineApp extends StatelessWidget {
  const TaxRefineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authApiProvider = AuthApiProvider();
    final authRepository = AuthRepository(authApiProvider);
    final dioClient = DioClient();
    final apiProvider = TransactionApiProvider(dioClient);
    final googleDriveProvider = GoogleDriveProvider();
    final repository = TransactionRepositoryImpl(apiProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: BlocProvider(
        create: (_) => AuthCubit(authRepository)..restoreSession(),
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            if (authState is AuthLoading || authState is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (authState is Authenticated) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(
                    create: (_) =>
                        TransactionCubit(repository, googleDriveProvider)
                          ..loadPendingTransactions(),
                  ),
                  BlocProvider(
                    create: (_) =>
                        HistoryCubit(repository, googleDriveProvider),
                  ),
                  BlocProvider(
                    create: (_) => BankConnectionCubit(
                      apiService: ApiService(client: http.Client()),
                    ),
                  ),
                  BlocProvider(
                    create: (_) => DashboardSummaryCubit(apiProvider),
                  ),
                ],
                child: const AppShell(),
              );
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
