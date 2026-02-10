import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Settings Screen - App configuration and preferences
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  
  String _userName = '';
  bool _isDarkMode = false;
  bool _autoSpeak = false;
  Map<String, int> _storageStats = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = _storage.getUserPreferences();
    final stats = await _storage.getStorageStats();
    
    setState(() {
      _userName = _storage.userName;
      _isDarkMode = prefs['dark_mode'] ?? false;
      _autoSpeak = prefs['auto_speak'] ?? false;
      _storageStats = stats;
    });
  }

  Future<void> _updateUserName() async {
    final controller = TextEditingController(text: _userName);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Name',
            hintText: 'Enter your name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _storage.setUserName(result);
      setState(() => _userName = result);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Clear All Data',
      message: 'This will delete all agents, conversations, and memories. This action cannot be undone.',
      confirmText: 'Clear All',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _storage.clearAllData();
        if (mounted) {
          Helpers.showSnackbar(
            context,
            message: 'All data cleared successfully',
          );
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackbar(
            context,
            message: 'Failed to clear data: $e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User Profile Section
          _buildSectionHeader('User Profile'),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Name'),
            subtitle: Text(_userName),
            trailing: const Icon(Icons.chevron_right),
            onTap: _updateUserName,
          ),
          
          // Appearance Section
          _buildSectionHeader('Appearance'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              _storage.saveUserPreferences({
                ..._storage.getUserPreferences(),
                'dark_mode': value,
              });
            },
          ),
          
          // Voice Section
          _buildSectionHeader('Voice'),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Auto-speak Responses'),
            subtitle: const Text('Automatically read agent responses aloud'),
            value: _autoSpeak,
            onChanged: (value) {
              setState(() => _autoSpeak = value);
              _storage.saveUserPreferences({
                ..._storage.getUserPreferences(),
                'auto_speak': value,
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_voice),
            title: const Text('Voice Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, Routes.voiceSettings);
            },
          ),
          
          // API Configuration Section
          _buildSectionHeader('API Configuration'),
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('API Setup'),
            subtitle: const Text('Configure LLM providers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, Routes.apiSetup);
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('OpenRouter Dashboard'),
            subtitle: const Text('Balance, usage, and models'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, Routes.openRouterDashboard);
            },
          ),
          
          // Data Management Section
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Storage Usage'),
            subtitle: Text(
              '${_storageStats['agents'] ?? 0} agents, '
              '${_storageStats['messages'] ?? 0} messages, '
              '${_storageStats['memories'] ?? 0} memories',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export Data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final data = await _storage.exportAllData();
                // In a real app, you would share this data
                Helpers.showSnackbar(
                  context,
                  message: 'Data exported successfully',
                );
              } catch (e) {
                Helpers.showSnackbar(
                  context,
                  message: 'Export failed: $e',
                  isError: true,
                );
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red.shade400),
            title: Text(
              'Clear All Data',
              style: TextStyle(color: Colors.red.shade400),
            ),
            onTap: _clearAllData,
          ),
          
          // About Section
          _buildSectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('App Version'),
            subtitle: Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () {
              // Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: context.textTheme.titleSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
