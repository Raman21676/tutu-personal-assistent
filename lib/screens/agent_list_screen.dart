import 'package:flutter/material.dart';
import '../models/agent_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/agent_card.dart';
import '../widgets/custom_app_bar.dart';

/// Agent List Screen - Full list of agents with search
class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  final StorageService _storage = StorageService();
  List<Agent> _allAgents = [];
  List<Agent> _filteredAgents = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);
    try {
      final agents = await _storage.getAllAgents();
      // Sort by last interaction (newest first), but keep TuTu first
      agents.sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return b.lastInteractionAt.compareTo(a.lastInteractionAt);
      });
      setState(() {
        _allAgents = agents;
        _filteredAgents = agents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Helpers.showSnackbar(
          context,
          message: 'Failed to load agents: $e',
          isError: true,
        );
      }
    }
  }

  void _searchAgents(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredAgents = _allAgents;
      } else {
        _filteredAgents = _allAgents.where((agent) {
          return agent.name.toLowerCase().contains(_searchQuery) ||
                 agent.role.toLowerCase().contains(_searchQuery) ||
                 agent.personality.toLowerCase().contains(_searchQuery);
        }).toList();
      }
    });
  }

  void _openChat(Agent agent) {
    Navigator.pushNamed(
      context,
      Routes.chat,
      arguments: agent,
    );
  }

  void _createAgent() {
    Navigator.pushNamed(context, Routes.createAgent);
  }

  Future<void> _deleteAgent(Agent agent) async {
    if (agent.isDefault) {
      Helpers.showSnackbar(
        context,
        message: 'Cannot delete the default TuTu agent',
        isError: true,
      );
      return;
    }

    final confirmed = await Helpers.showConfirmationDialog(
      context,
      title: 'Delete Agent',
      message: 'Are you sure you want to delete "${agent.name}"? This will also delete all conversations.',
      confirmText: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      try {
        await _storage.deleteAgent(agent.id);
        await _loadAgents();
        if (mounted) {
          Helpers.showSnackbar(
            context,
            message: 'Agent deleted',
          );
        }
      } catch (e) {
        if (mounted) {
          Helpers.showSnackbar(
            context,
            message: 'Failed to delete agent: $e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        title: 'My Agents',
        onSearch: _searchAgents,
        onBack: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAgents,
              child: _filteredAgents.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredAgents.length,
                      itemBuilder: (context, index) {
                        final agent = _filteredAgents[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AgentListItem(
                            agent: agent,
                            onTap: () => _openChat(agent),
                            onDelete: () => _deleteAgent(agent),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAgent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: context.colors.onSurface.withAlpha(77),
            ),
            const SizedBox(height: 16),
            Text(
              'No agents found',
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colors.onSurface.withAlpha(128),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurface.withAlpha((0.4 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: context.colors.onSurface.withAlpha(77),
          ),
          const SizedBox(height: 16),
          Text(
            'No agents yet',
            style: context.textTheme.titleMedium?.copyWith(
              color: context.colors.onSurface.withAlpha(128),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first AI companion!',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurface.withAlpha((0.4 * 255).round()),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createAgent,
            icon: const Icon(Icons.add),
            label: const Text('Create Agent'),
          ),
        ],
      ),
    );
  }
}
