import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/logic/auth/auth_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/presentation/screens/history_screen.dart';
import 'package:taxrefine/presentation/screens/home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [HomeScreen(), HistoryScreen()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<AuthCubit>().signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(AppStrings.logout),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            context.read<HistoryCubit>().loadHistory();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.swipe_right_alt_rounded),
            label: AppStrings.tabSwipe,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            label: AppStrings.tabHistory,
          ),
        ],
      ),
    );
  }
}
