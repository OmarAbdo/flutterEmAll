import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../shared/services/supabase_service.dart';
import '../../../main.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('settings')),
      ),
      body: ListView(
        children: [
          // Language Section
          _buildSectionHeader(context, context.tr('language')),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.tr('language')),
            subtitle: Text(locale.languageCode == 'ar'
                ? context.tr('arabic')
                : context.tr('english')),
            trailing: DropdownButton<Locale>(
              value: locale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: Locale('ar'),
                  child: Text('العربية'),
                ),
                DropdownMenuItem(
                  value: Locale('en'),
                  child: Text('English'),
                ),
              ],
              onChanged: (newLocale) {
                if (newLocale != null) {
                  ref.read(localeProvider.notifier).state = newLocale;
                }
              },
            ),
          ),

          const Divider(),

          // Theme Section
          _buildSectionHeader(context, context.tr('theme')),
          SwitchListTile(
            secondary: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: Text(context.tr('dark_mode')),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).state =
                  value ? ThemeMode.dark : ThemeMode.light;
            },
          ),

          const Divider(),

          // Subscription Section
          _buildSectionHeader(context, context.tr('subscription')),
          ListTile(
            leading: const Icon(Icons.card_membership),
            title: Text(context.tr('subscription')),
            subtitle: Text(context.tr('current_plan')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/subscription'),
          ),

          const Divider(),

          // Account Section
          _buildSectionHeader(context, context.tr('profile')),
          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person,
                  color: Theme.of(context).primaryColor),
              backgroundColor:
                  Theme.of(context).primaryColor.withOpacity(0.1),
            ),
            title: Text(SupabaseService.instance.currentUser?.email ?? ''),
            subtitle: const Text('Free Plan'),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              context.tr('logout'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('logout')),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('logout')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await SupabaseService.instance.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
