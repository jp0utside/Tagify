import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../import/import_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (authService.user != null) _buildUserSection(authService.user!),
          const Divider(),
          _buildDatabaseSection(databaseService),
          const Divider(),
          _buildAppSection(),
          const Divider(),
          _buildActionsSection(authService),
        ],
      ),
    );
  }

  Widget _buildUserSection(user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            user.imageUrl != null ? NetworkImage(user.imageUrl!) : null,
        child: user.imageUrl == null ? const Icon(Icons.person) : null,
      ),
      title: Text(user.displayName),
      subtitle: Text(user.email ?? 'No email'),
    );
  }

  Widget _buildDatabaseSection(DatabaseService databaseService) {
    return FutureBuilder<int>(
      future: databaseService.getSongCount(),
      builder: (context, snapshot) {
        final songCount = snapshot.data ?? 0;
        return ListTile(
          leading: const Icon(Icons.storage),
          title: const Text('Local Database'),
          subtitle: Text('$songCount songs stored locally'),
        );
      },
    );
  }

  Widget _buildAppSection() {
    return const ListTile(
      leading: Icon(Icons.info),
      title: Text('About Tagify'),
      subtitle: Text('Version 1.0.0'),
    );
  }

  Widget _buildActionsSection(AuthService authService) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.cloud_download),
          title: const Text('Import Library'),
          subtitle: const Text('Import songs and playlists from Spotify'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Disconnect Account',
              style: TextStyle(color: Colors.red)),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Disconnect Account'),
                content: const Text(
                  'Are you sure you want to disconnect your Spotify account? '
                  'You will need to reconnect to use the app.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await authService.logout();
            }
          },
        ),
      ],
    );
  }
}
