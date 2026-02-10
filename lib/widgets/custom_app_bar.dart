import 'package:flutter/material.dart';
import '../utils/helpers.dart';
import '../utils/themes.dart';

/// Custom App Bar with gradient background option
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showGradient;
  final bool centerTitle;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.showGradient = false,
    this.centerTitle = true,
    this.elevation = 0,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Column(
        children: [
          Text(title),
          if (subtitle != null)
            Text(
              subtitle!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.colors.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ),
      centerTitle: centerTitle,
      elevation: elevation,
      leading: leading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: showGradient
          ? Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryGradient,
              ),
            )
          : null,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}

/// Agent App Bar - Specifically for chat screen
class AgentAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String agentName;
  final String agentAvatar;
  final String? subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onSettings;
  final bool isTyping;

  const AgentAppBar({
    super.key,
    required this.agentName,
    required this.agentAvatar,
    this.subtitle,
    this.onBack,
    this.onSettings,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                agentAvatar,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  agentName,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isTyping)
                  Text(
                    'typing...',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  )
                else if (subtitle != null)
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (onSettings != null)
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: onSettings,
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Search App Bar with search field
class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final ValueChanged<String> onSearch;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  const SearchAppBar({
    super.key,
    required this.title,
    required this.onSearch,
    this.onBack,
    this.actions,
  });

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SearchAppBarState extends State<SearchAppBar> {
  bool _isSearching = false;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: widget.onBack ?? () => Navigator.pop(context),
      ),
      title: _isSearching
          ? TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: context.colors.onSurface.withOpacity(0.5),
                ),
              ),
              style: context.textTheme.titleMedium,
              onChanged: widget.onSearch,
            )
          : Text(widget.title),
      actions: [
        if (!_isSearching)
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() => _isSearching = true),
          )
        else
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _controller.clear();
              });
              widget.onSearch('');
            },
          ),
        if (widget.actions != null) ...widget.actions!,
      ],
    );
  }
}

/// Gradient App Bar - For special screens like splash
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppGradients.primaryGradient,
      ),
      child: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: leading,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
