import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/agent_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';

/// Create Agent Screen - Form for creating new agents
class CreateAgentScreen extends StatefulWidget {
  const CreateAgentScreen({super.key});

  @override
  State<CreateAgentScreen> createState() => _CreateAgentScreenState();
}

class _CreateAgentScreenState extends State<CreateAgentScreen> {
  final StorageService _storage = StorageService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _personalityController = TextEditingController();
  final _uuid = const Uuid();

  String _selectedRole = AgentRoles.friend;
  String _selectedAvatar = AvatarEmojis.characters.first;
  String _selectedVoiceGender = 'female';
  bool _isLoading = false;

  void _onRoleChanged(String? role) {
    if (role != null) {
      setState(() {
        _selectedRole = role;
        _personalityController.text = AgentRoles.getDefaultPersonality(role);
        _selectedAvatar = AgentRoles.getDefaultAvatar(role);
      });
    }
  }

  Future<void> _createAgent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final agent = Agent(
        id: _uuid.v4(),
        name: _nameController.text.trim(),
        role: _selectedRole,
        personality: _personalityController.text.trim(),
        avatar: _selectedAvatar,
        voiceGender: _selectedVoiceGender,
        createdAt: DateTime.now(),
        lastInteractionAt: DateTime.now(),
      );

      await _storage.saveAgent(agent);

      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'Agent "${agent.name}" created successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'Failed to create agent: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _previewVoice() async {
    // Show voice preview dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Preview'),
        content: const Text(
          'Voice preview will be available once the agent is created. '
          'You can test different voices in the agent settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _personalityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Agent'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createAgent,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar selection
            _buildAvatarSection(),
            const SizedBox(height: 24),
            // Name input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Agent Name',
                hintText: 'e.g., Maya, Alex, Prof. Chen',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Role selection
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.work),
              ),
              items: AgentRoles.all.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(AgentRoles.getDisplayName(role)),
                );
              }).toList(),
              onChanged: _onRoleChanged,
            ),
            const SizedBox(height: 16),
            // Personality input
            TextFormField(
              controller: _personalityController,
              decoration: const InputDecoration(
                labelText: 'Personality Description',
                hintText: 'Describe how this agent should behave...',
                prefixIcon: Icon(Icons.psychology),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the personality';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // Voice settings
            _buildVoiceSection(),
            const SizedBox(height: 32),
            // Suggestions
            _buildSuggestionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an Avatar',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                _selectedAvatar,
                style: const TextStyle(fontSize: 56),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: AvatarEmojis.all.length,
            itemBuilder: (context, index) {
              final emoji = AvatarEmojis.all[index];
              final isSelected = emoji == _selectedAvatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = emoji),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.colors.primary.withAlpha(51)
                        : context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.outline.withAlpha(51),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Settings',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderOption(
                label: 'Female',
                icon: Icons.female,
                isSelected: _selectedVoiceGender == 'female',
                onTap: () => setState(() => _selectedVoiceGender = 'female'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderOption(
                label: 'Male',
                icon: Icons.male,
                isSelected: _selectedVoiceGender == 'male',
                onTap: () => setState(() => _selectedVoiceGender = 'male'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _previewVoice,
          icon: const Icon(Icons.volume_up, size: 18),
          label: const Text('Preview Voice'),
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary.withAlpha(26)
              : context.colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.outline.withAlpha(51),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? context.colors.primary : null,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? context.colors.primary : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need Inspiration?',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AgentSuggestions.suggestions.map((suggestion) {
            return ActionChip(
              avatar: Text(suggestion['avatar']!),
              label: Text(suggestion['name']!),
              onPressed: () {
                _nameController.text = suggestion['name']!;
                final role = suggestion['role']!.toLowerCase().replaceAll(' ', '_');
                _onRoleChanged(role);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
