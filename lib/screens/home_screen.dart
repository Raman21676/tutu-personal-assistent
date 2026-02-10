import 'package:flutter/material.dart';
import '../models/agent_model.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/agent_card.dart';
import '../widgets/custom_app_bar.dart';

/// Home Screen - Main screen with agent list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  List<Agent> _agents = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);
    try {
      final agents = await _storage.getAllAgents();
      // Sort: default first, then by last interaction
      agents.sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }
        return b.lastInteractionAt.compareTo(a.lastInteractionAt);
      });
      setState(() {
        _agents = agents;
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

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    switch (index) {
      case 0:
        // Home - already here
        break;
      case 1:
        Navigator.pushNamed(context, Routes.agentList);
        break;
      case 2:
        Navigator.pushNamed(context, Routes.settings);
        break;
    }
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

  String get _greeting {
    final hour = DateTime.now().hour;
    final userName = _storage.userName;
    
    if (hour < 12) return 'Good morning, $userName ☀️';
    if (hour < 17) return 'Good afternoon, $userName 👋';
    return 'Good evening, $userName 🌙';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: AppConstants.appName,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, Routes.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAgents,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Greeting header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: context.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Who would you like to chat with today?',
                            style: context.textTheme.bodyLarge?.copyWith(
                              color: context.colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TuTu Agent (always first)
                  if (_agents.isNotEmpty && _agents.first.isDefault)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: AgentCard(
                          agent: _agents.first,
                          onTap: () => _openChat(_agents.first),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text(
                            'Your Agents',
                            style: context.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _createAgent,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Create'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Agent grid
                  if (_agents.length > 1)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final agent = _agents[index + 1]; // Skip TuTu
                            return AgentGridItem(
                              agent: agent,
                              onTap: () => _openChat(agent),
                            );
                          },
                          childCount: _agents.length - 1,
                        ),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: context.colors.onSurface.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No agents yet',
                                style: context.textTheme.titleMedium?.copyWith(
                                  color: context.colors.onSurface.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first AI companion!',
                                style: context.textTheme.bodyMedium?.copyWith(
                                  color: context.colors.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Add agent button
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AddAgentButton(onTap: _createAgent),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Agents',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createAgent,
        icon: const Icon(Icons.add),
        label: const Text('New Agent'),
      ),
    );
  }
}
