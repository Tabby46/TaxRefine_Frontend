import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/theme/app_theme.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/providers/google_drive_provider.dart';
import 'package:taxrefine/data/providers/transaction_api_provider.dart';
import 'package:taxrefine/data/repositories/transaction_repository.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/logic/transactions/transaction_cubit.dart';
import 'package:taxrefine/presentation/screens/app_shell.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: kDebugMode,
      builder: (context) => const TaxRefineApp(),
    ),
  );
}

class TaxRefineApp extends StatelessWidget {
  const TaxRefineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dioClient = DioClient();
    final apiProvider = TransactionApiProvider(dioClient);
    final googleDriveProvider = GoogleDriveProvider();
    final repository = TransactionRepositoryImpl(apiProvider);

    return MaterialApp(
      title: AppStrings.appTitle,
      theme: AppTheme.light(),
      builder: DevicePreview.appBuilder,
      locale: DevicePreview.locale(context),
      home: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                TransactionCubit(repository, googleDriveProvider)
                  ..loadPendingTransactions(),
          ),
          BlocProvider(create: (_) => HistoryCubit(repository)),
        ],
        child: const AppShell(),
      ),
    );
  }
}
