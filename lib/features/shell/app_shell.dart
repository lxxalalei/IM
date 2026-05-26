import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../chat/chat_page.dart';
import '../chat/mock_chat_data.dart';
import '../contacts/contacts_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _activeNavId = 'messages';
  String _globalSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    final activeItem = navItems.firstWhere((item) => item.id == _activeNavId);

    return Scaffold(
      body: Container(
        color: AppColors.appBackground,
        child: SafeArea(
          child: Column(
            children: [
              GlobalSearchBar(
                query: _globalSearchQuery,
                onChanged: (query) =>
                    setState(() => _globalSearchQuery = query),
              ),
              Expanded(
                child: Row(
                  children: [
                    GlobalSidebar(
                      activeNavId: _activeNavId,
                      onSelected: (id) => setState(() => _activeNavId = id),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 10),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.panelBackground,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: switch (_activeNavId) {
                              'messages' => ChatPage(
                                searchQuery: _globalSearchQuery,
                              ),
                              'contacts' => ContactsPage(
                                searchQuery: _globalSearchQuery,
                              ),
                              _ => ModulePlaceholder(
                                icon: activeItem.icon,
                                label: activeItem.label,
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalSidebar extends StatelessWidget {
  const GlobalSidebar({
    required this.activeNavId,
    required this.onSelected,
    super.key,
  });

  final String activeNavId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 68,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const _CurrentUserAvatar(),
          const SizedBox(height: 10),
          _CircleActionButton(
            icon: Icons.add_rounded,
            tooltip: '新建',
            onPressed: () {},
          ),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: navItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = navItems[index];
                return _SidebarNavItem(
                  icon: item.icon,
                  label: item.label,
                  isActive: item.id == activeNavId,
                  hasDot: item.id == 'more',
                  onTap: () => onSelected(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GlobalSearchBar extends StatefulWidget {
  const GlobalSearchBar({
    required this.query,
    required this.onChanged,
    super.key,
  });

  final String query;
  final ValueChanged<String> onChanged;

  @override
  State<GlobalSearchBar> createState() => _GlobalSearchBarState();
}

class _GlobalSearchBarState extends State<GlobalSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant GlobalSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          const SizedBox(width: 68),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _controller,
                    onChanged: widget.onChanged,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.panelBackground,
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: AppColors.tertiaryText,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 34,
                      ),
                      hintText: '搜索联系人、群聊、聊天记录',
                      hintStyle: const TextStyle(
                        color: AppColors.tertiaryText,
                        fontSize: 13,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      suffixIcon: widget.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: '清除搜索',
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () => widget.onChanged(''),
                            ),
                      suffixIconConstraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 34,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(17),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _TopBarAction(icon: Icons.history_rounded, tooltip: '最近访问'),
          const _TopBarAction(icon: Icons.more_horiz_rounded, tooltip: '更多'),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.tertiaryText),
          const SizedBox(height: 12),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            '模块建设中',
            style: TextStyle(color: AppColors.tertiaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CurrentUserAvatar extends StatelessWidget {
  const _CurrentUserAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Color(0xFF6DBA28),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text(
            'A',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: AppColors.brandGreen,
              border: Border.all(color: Colors.white, width: 1.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBarAction extends StatelessWidget {
  const _TopBarAction({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: IconButton(
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        onPressed: () {},
        icon: Icon(icon, size: 19, color: AppColors.secondaryText),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  const _CircleActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 450),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: AppColors.secondaryText),
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.hasDot = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool hasDot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isActive ? AppColors.brandBlue : AppColors.secondaryText;

    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 450),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            height: 46,
            decoration: BoxDecoration(
              color: isActive ? AppColors.panelBackground : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 10,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasDot)
                  Positioned(
                    right: 16,
                    top: 6,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4D4F),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
