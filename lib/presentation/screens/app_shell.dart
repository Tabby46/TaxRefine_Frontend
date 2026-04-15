import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/models/user_model.dart';
import 'package:taxrefine/logic/auth/auth_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/presentation/screens/history_screen.dart';
import 'package:taxrefine/presentation/screens/home_screen.dart';
import 'package:taxrefine/presentation/screens/profile_screen.dart';
import 'package:taxrefine/presentation/screens/transaction_dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final ValueNotifier<int> _dashboardRefreshNotifier = ValueNotifier<int>(0);

  UserModel _buildCurrentUser() {
    final userId = AuthSession.userId ?? '';
    final email = AuthSession.email ?? 'unknown@taxrefine.app';
    final name =
        (AuthSession.name != null && AuthSession.name!.trim().isNotEmpty)
        ? AuthSession.name!
        : (email.contains('@') ? email.split('@').first : 'User');

    return UserModel(
      id: userId,
      name: name,
      email: email,
      plaidLinkActive: false,
      institutionName: null,
    );
  }

  @override
  void dispose() {
    _dashboardRefreshNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _buildCurrentUser();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const HistoryScreen(),
          TransactionDashboardScreen(refreshNotifier: _dashboardRefreshNotifier),
          ProfileScreen(user: currentUser),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.read<AuthCubit>().signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(AppStrings.logout),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0B6E4F),
        unselectedItemColor: Colors.grey.shade700,
        showUnselectedLabels: true,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) {
            context.read<HistoryCubit>().loadHistory();
          }
          if (index == 2) {
            _dashboardRefreshNotifier.value++;
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
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: AppStrings.tabDashboard,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: AppStrings.tabProfile,
          ),
        ],
      ),
    );
  }
}
