import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/data/models/user_model.dart';
import 'package:taxrefine/logic/dashboard/dashboard_summary_cubit.dart';
import 'package:taxrefine/logic/history/history_cubit.dart';
import 'package:taxrefine/presentation/screens/history_screen.dart';
import 'package:taxrefine/presentation/screens/home_screen.dart';
import 'package:taxrefine/presentation/screens/profile_screen.dart';
import 'package:taxrefine/presentation/screens/transaction_dashboard_screen.dart';
import 'dart:ui'; // for BackdropFilter

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _CustomBottomNavBar extends StatelessWidget {
  final int currentIndex; // currently selected index
  final ValueChanged<int> onTap; // tap callback

  const _CustomBottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12), // spacing from edges
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30), // rounded corners
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // glass blur
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4), // glass background
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildItem(
                    Icons.swipe_right_alt_rounded,
                    AppStrings.tabSwipe,
                    0,
                  ),
                  _buildItem(Icons.history_rounded, AppStrings.tabHistory, 1),
                  _buildItem(
                    Icons.account_balance_wallet_rounded,
                    AppStrings.tabDashboard,
                    2,
                  ),
                  _buildItem(
                    Icons.person_outline_rounded,
                    AppStrings.tabProfile,
                    3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    final bool isSelected = currentIndex == index; // check active tab

    return Material(
      color: Colors.transparent, // needed for InkWell ripple
      child: InkWell(
        borderRadius: BorderRadius.circular(20), // match container radius
        onTap: () async {
          await HapticFeedback.selectionClick();
          onTap(index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250), // smooth animation
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // same radius
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // compact layout
            children: [
              Icon(
                icon,
                color: isSelected
                    ? const Color(0xFF00FF9C) // active color
                    : Colors.grey, // inactive
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00FF9C) : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
    final userId = ApiConstants.resolveUserId(AuthSession.userId);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          const HistoryScreen(),
          TransactionDashboardScreen(
            refreshNotifier: _dashboardRefreshNotifier,
          ),
          ProfileScreen(user: currentUser),
        ],
      ),
      bottomNavigationBar: _CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);

          if (index == 1) {
            context.read<HistoryCubit>().loadHistory();
          }
          if (index == 2) {
            _dashboardRefreshNotifier.value++;
            context.read<DashboardSummaryCubit>().loadSummary(userId);
          }
        },
      ),
    );
  }
}
