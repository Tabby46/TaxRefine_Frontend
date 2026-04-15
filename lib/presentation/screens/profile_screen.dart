import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/core/auth/auth_session.dart';
import 'package:taxrefine/core/constants/api_constants.dart';
import 'package:taxrefine/core/constants/app_strings.dart';
import 'package:taxrefine/core/network/dio_client.dart';
import 'package:taxrefine/data/models/user_model.dart';
import 'package:taxrefine/data/services/plaid_integration_service.dart';
import 'package:taxrefine/features/profile/cubit/bank_connection_cubit.dart';
import 'package:taxrefine/features/profile/screens/linked_banks_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({required this.user, super.key});

  final UserModel user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late UserModel _user;
  bool _isLinking = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _connectOrRelinkBank() async {
    if (_isLinking) {
      return;
    }

    setState(() {
      _isLinking = true;
    });

    final userId = AuthSession.userId ?? _user.id;
    final effectiveUserId = userId.trim().isEmpty
        ? ApiConstants.defaultUserId
        : userId;

    final plaid = PlaidIntegrationService(
      dioClient: DioClient(),
      context: context,
    );

    final result = await plaid.openPlaidLink(effectiveUserId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isLinking = false;
      if (result == PlaidLinkFlowStatus.linked) {
        _user = _user.copyWith(
          plaidLinkActive: true,
          institutionName: _user.institutionName ?? 'Chase',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
         children: [
           _UserHeader(user: _user),
           const SizedBox(height: 32),

           const _SectionHeader(title: 'Accounts & Security'),
           const SizedBox(height: 8),

           _SettingsTile(
             icon: Icons.account_balance,
             title: 'Linked Bank Accounts',
             onTap: () {
               Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (_) => BlocProvider.value(
                     value: context.read<BankConnectionCubit>(),
                     child: const LinkedBanksScreen(),
                   ),
                 ),
               );
             },
           ),

           const _SettingsTile(
             icon: Icons.edit,
             title: 'Edit Profile',
           ),

           const _SettingsTile(
             icon: Icons.notifications,
             title: 'Notifications',
           ),

           const _SettingsTile(
             icon: Icons.lock,
             title: 'Privacy & Security',
           ),

           const SizedBox(height: 32),

           const _SectionHeader(title: 'Other'),
           const SizedBox(height: 8),

           const _SettingsTile(
             icon: Icons.help,
             title: 'Help & Support',
           ),

           const _SettingsTile(
             icon: Icons.logout,
             title: 'Log Out',
             color: Colors.red,
           ),
         ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkedInstitutionCard extends StatelessWidget {
  const _LinkedInstitutionCard({
    required this.institutionName,
    required this.isLoading,
    required this.onRelink,
  });

  final String institutionName;
  final bool isLoading;
  final VoidCallback onRelink;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                institutionName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : onRelink,
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Relink'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBankPlaceholder extends StatelessWidget {
  const _NoBankPlaceholder({required this.isLoading, required this.onConnect});

  final bool isLoading;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('No Bank Connected'),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onConnect,
              icon: const Icon(Icons.account_balance),
              label: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.plaidConnectTooltip),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}
