import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxrefine/features/profile/cubit/bank_connection_cubit.dart';
import 'package:taxrefine/features/profile/screens/linked_banks_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User Header
          const _UserHeader(),
          const SizedBox(height: 32),

          // Accounts & Security Section
          const SectionHeader(title: 'Accounts & Security'),
          const SizedBox(height: 8),

          BlocBuilder<BankConnectionCubit, BankConnectionState>(
            builder: (context, state) {
              String subtitle = 'Manage connected banks';
              
              if (state is BankConnectionLoaded) {
                final count = state.connections.length;
                subtitle = 'Manage $count connected bank${count != 1 ? 's' : ''}';
              } else if (state is BankConnectionLoading) {
                subtitle = 'Loading connections...';
              }
              
              return SettingsTile(
                icon: Icons.account_balance,
                title: 'Linked Bank Accounts',
                subtitle: subtitle,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LinkedBanksScreen(),
                  ),
                ),
              );
            },
          ),

          const SettingsTile(
            icon: Icons.edit,
            title: 'Edit Profile',
          ),

          const SettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
          ),

          const SettingsTile(
            icon: Icons.lock,
            title: 'Privacy & Security',
          ),

          const SizedBox(height: 32),

          const SectionHeader(title: 'Other'),
          const SizedBox(height: 8),

          const SettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
          ),

          const SettingsTile(
            icon: Icons.logout,
            title: 'Log Out',
            color: Colors.red,
            showTrailing: false,
          ),
        ],
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          CircleAvatar(
            radius: 40,
            child: Icon(Icons.person, size: 40),
          ),
          SizedBox(height: 16),
          Text(
            'User',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'user@taxrefine.app',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

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

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final bool showTrailing;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.color,
    this.showTrailing = true,
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
      subtitle: subtitle != null ? Text(
        subtitle!,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ) : null,
      trailing: showTrailing ? const Icon(Icons.chevron_right, size: 20) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
    );
  }
}