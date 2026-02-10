import 'package:flutter/material.dart';
import '../models/agent_model.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';

/// Agent Card Widget - Displays an agent in a card format
class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isCompact;

  const AgentCard({
    super.key,
    required this.agent,
    this.onTap,
    this.onLongPress,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppThemes.getMessageBubbleColors(context.isDarkMode);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: isCompact ? _buildCompactLayout(context) : _buildFullLayout(context, colors),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(context, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                AgentRoles.getDisplayName(agent.role),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        if (!agent.isDefault) ...[
          const SizedBox(width: 8),
          Text(
            _formatLastInteraction(),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurface.withOpacity(0.4),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, MessageBubbleColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildAvatar(context, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    agent.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AgentRoles.getDisplayName(agent.role),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (agent.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Default',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        if (!agent.isDefault) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last active: ${_formatLastInteraction()}',
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
              if (agent.voiceGender != null)
                Icon(
                  agent.voiceGender == 'female' 
                      ? Icons.female 
                      : Icons.male,
                  size: 16,
                  color: context.colors.onSurface.withOpacity(0.4),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAvatar(BuildContext context, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.primaryGradient,
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Center(
        child: Text(
          agent.avatar,
          style: TextStyle(
            fontSize: size * 0.5,
          ),
        ),
      ),
    );
  }

  String _formatLastInteraction() {
    final now = DateTime.now();
    final diff = now.difference(agent.lastInteractionAt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${agent.lastInteractionAt.day}/${agent.lastInteractionAt.month}';
  }
}

/// Agent List Item - For use in list views with swipe actions
class AgentListItem extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AgentListItem({
    super.key,
    required this.agent,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(agent.id),
      direction: agent.isDefault 
          ? DismissDirection.none 
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: AgentCard(
        agent: agent,
        onTap: onTap,
        isCompact: true,
      ),
    );
  }
}

/// Agent Grid Item - For grid layout
class AgentGridItem extends StatelessWidget {
  final Agent agent;
  final VoidCallback? onTap;

  const AgentGridItem({
    super.key,
    required this.agent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppGradients.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    agent.avatar,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                agent.name,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                AgentRoles.getDisplayName(agent.role),
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add Agent Button - For creating new agents
class AddAgentButton extends StatelessWidget {
  final VoidCallback? onTap;

  const AddAgentButton({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.colors.primary.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      color: context.colors.primary.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 40,
                color: context.colors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Create Agent',
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
