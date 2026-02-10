import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/emoji_data.dart';

/// Emoji Picker Grid - Categorized emoji selection for agent creation
class EmojiPickerGrid extends StatefulWidget {
  final String? selectedEmoji;
  final Function(String emoji, String name) onSelected;
  final String? preferredGender;

  const EmojiPickerGrid({
    super.key,
    this.selectedEmoji,
    required this.onSelected,
    this.preferredGender,
  });

  @override
  State<EmojiPickerGrid> createState() => _EmojiPickerGridState();
}

class _EmojiPickerGridState extends State<EmojiPickerGrid> {
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<EmojiOption> _filteredEmojis = [];

  @override
  void initState() {
    super.initState();
    _filteredEmojis = EmojiCategories.all;
  }

  void _filterEmojis(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEmojis = _getEmojisByCategory();
      } else {
        _filteredEmojis = EmojiCategories.search(query);
      }
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _searchController.clear();
      _filteredEmojis = _getEmojisByCategory();
    });
  }

  List<EmojiOption> _getEmojisByCategory() {
    if (_selectedCategory == 'All') {
      // If gender preference, prioritize matching emojis
      if (widget.preferredGender != null) {
        final suggestions = VoiceMatchedEmojis.getSuggestionsByVoice(widget.preferredGender!);
        final allOthers = EmojiCategories.all.where(
          (e) => !suggestions.any((s) => s.emoji == e.emoji)
        ).toList();
        return [...suggestions, ...allOthers];
      }
      return EmojiCategories.all;
    }
    return EmojiCategories.getByCategory(_selectedCategory);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: _filterEmojis,
            decoration: InputDecoration(
              hintText: 'Search emojis...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ),

        // Category tabs
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildCategoryChip('All', Icons.apps),
              _buildCategoryChip('Relationship', Icons.favorite),
              _buildCategoryChip('Professional', Icons.work),
              _buildCategoryChip('Family', Icons.family_restroom),
              _buildCategoryChip('Personality', Icons.psychology),
              _buildCategoryChip('Emotional', Icons.emoji_emotions),
              _buildCategoryChip('Fantasy', Icons.auto_fix_high),
              _buildCategoryChip('Special', Icons.star),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Emoji grid
        Expanded(
          child: _filteredEmojis.isEmpty
              ? const Center(child: Text('No emojis found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredEmojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _filteredEmojis[index];
                    final isSelected = emoji.emoji == widget.selectedEmoji;

                    return _EmojiCard(
                      emoji: emoji,
                      isSelected: isSelected,
                      onTap: () => widget.onSelected(emoji.emoji, emoji.name),
                    ).animate(
                      effects: [
                        FadeEffect(
                          delay: (index * 20).ms,
                          duration: 300.ms,
                        ),
                        ScaleEffect(
                          delay: (index * 20).ms,
                          duration: 300.ms,
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : theme.colorScheme.primary,
        ),
        label: Text(category),
        selected: isSelected,
        onSelected: (_) => _selectCategory(category),
        selectedColor: theme.colorScheme.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

/// Individual emoji card
class _EmojiCard extends StatelessWidget {
  final EmojiOption emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiCard({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                emoji.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Voice-matched emoji suggestions widget
class VoiceMatchedEmojiSuggestions extends StatelessWidget {
  final String? voiceGender;
  final String? selectedEmoji;
  final Function(String emoji, String name) onSelected;

  const VoiceMatchedEmojiSuggestions({
    super.key,
    this.voiceGender,
    this.selectedEmoji,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = VoiceMatchedEmojis.getSuggestionsByVoice(voiceGender);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Suggested for ${voiceGender ?? "your"} voice',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final emoji = suggestions[index];
              final isSelected = emoji.emoji == selectedEmoji;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SuggestionCard(
                  emoji: emoji,
                  isSelected: isSelected,
                  onTap: () => onSelected(emoji.emoji, emoji.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Suggestion card for voice-matched emojis
class _SuggestionCard extends StatelessWidget {
  final EmojiOption emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 70,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.primaryGradient : null,
            color: isSelected ? null : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                emoji.name,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
