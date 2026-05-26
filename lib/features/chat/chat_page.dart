import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'chat_api.dart';
import 'chat_models.dart';
import 'mock_chat_data.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({required this.searchQuery, super.key});

  final String searchQuery;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _api = ChatApi();
  late List<Conversation> _allConversations = [...conversations];
  late List<Conversation> _visibleConversations = [...conversations];
  late Map<String, List<ChatMessage>> _messagesByConversation = Map.fromEntries(
    messagesByConversation.entries.map(
      (entry) => MapEntry(entry.key, [...entry.value]),
    ),
  );
  String _selectedConversationId = conversations.first.id;
  bool _isUsingBackend = false;
  bool _isSending = false;
  Timer? _searchDebounce;
  String? _syncNotice;

  Conversation get _selectedConversation {
    return _allConversations.firstWhere(
      (conversation) => conversation.id == _selectedConversationId,
      orElse: () => _visibleConversations.isNotEmpty
          ? _visibleConversations.first
          : conversations.first,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadFromBackend();
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 240), () {
        _applySearch(widget.searchQuery);
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedConversation;
    final messages =
        _messagesByConversation[selected.id] ?? const <ChatMessage>[];

    return Row(
      children: [
        ConversationSidebar(
          conversations: _visibleConversations,
          searchQuery: widget.searchQuery,
          selectedConversationId: selected.id,
          onConversationSelected: _selectConversation,
        ),
        const VerticalDivider(width: 1, color: AppColors.line),
        Expanded(
          child: ChatPanel(
            conversation: selected,
            messages: messages,
            syncNotice: _syncNotice,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ),
      ],
    );
  }

  Future<void> _loadFromBackend() async {
    try {
      final backendConversations = await _api.fetchConversations();
      if (!mounted || backendConversations.isEmpty) {
        return;
      }

      final selectedId =
          backendConversations.any(
            (conversation) => conversation.id == _selectedConversationId,
          )
          ? _selectedConversationId
          : backendConversations.first.id;
      final selectedMessages = await _api.fetchMessages(selectedId);
      final visibleConversations = _filterLocalConversations(
        backendConversations,
        widget.searchQuery,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _allConversations = backendConversations;
        _visibleConversations = visibleConversations;
        _selectedConversationId = selectedId;
        _messagesByConversation = {
          ..._messagesByConversation,
          selectedId: selectedMessages,
        };
        _isUsingBackend = true;
        _syncNotice = '已连接本地后端';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isUsingBackend = false;
        _visibleConversations = _filterLocalConversations(
          _allConversations,
          widget.searchQuery,
        );
        _syncNotice = '后端未连接，当前使用本地 mock 数据';
      });
    }
  }

  Future<void> _applySearch(String query) async {
    if (!_isUsingBackend) {
      setState(() {
        _visibleConversations = _filterLocalConversations(
          _allConversations,
          query,
        );
      });
      return;
    }

    try {
      final results = await _api.fetchConversations(query: query);
      if (!mounted) {
        return;
      }

      setState(() {
        if (query.trim().isEmpty) {
          _allConversations = results;
        }
        _visibleConversations = results;
        _syncNotice = results.isEmpty ? '没有找到相关会话' : '已连接本地后端';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleConversations = _filterLocalConversations(
          _allConversations,
          query,
        );
        _syncNotice = '搜索同步失败，已使用本地结果';
      });
    }
  }

  Future<void> _selectConversation(String id) async {
    setState(() {
      _selectedConversationId = id;
      final index = _allConversations.indexWhere(
        (conversation) => conversation.id == id,
      );
      if (index >= 0 && _allConversations[index].unreadCount > 0) {
        _allConversations[index] = _allConversations[index].copyWith(
          unreadCount: 0,
        );
        _visibleConversations = _filterLocalConversations(
          _allConversations,
          widget.searchQuery,
        );
      }
    });

    if (!_isUsingBackend) {
      return;
    }

    try {
      await _api.markRead(id);
      final messages = await _api.fetchMessages(id);
      if (!mounted) {
        return;
      }
      setState(() => _messagesByConversation[id] = messages);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _syncNotice = '后端同步失败，已保留本地状态');
    }
  }

  Future<void> _sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _isSending) {
      return;
    }

    setState(() => _isSending = true);
    final conversationId = _selectedConversationId;

    try {
      final message = _isUsingBackend
          ? await _api.sendMessage(
              conversationId: conversationId,
              content: trimmed,
            )
          : ChatMessage(
              id: 'local_${DateTime.now().microsecondsSinceEpoch}',
              senderName: '我',
              content: trimmed,
              time: formatMessageTime(DateTime.now().toIso8601String()),
              isMine: true,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _messagesByConversation[conversationId] = [
          ...(_messagesByConversation[conversationId] ?? const <ChatMessage>[]),
          message,
        ];

        final index = _allConversations.indexWhere(
          (conversation) => conversation.id == conversationId,
        );
        if (index >= 0) {
          _allConversations[index] = _allConversations[index].copyWith(
            lastMessage: trimmed,
            lastMessageTime: '现在',
          );
          _visibleConversations = _filterLocalConversations(
            _allConversations,
            widget.searchQuery,
          );
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _syncNotice = '发送失败，请确认本地后端是否运行');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  List<Conversation> _filterLocalConversations(
    List<Conversation> source,
    String query,
  ) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return [...source];
    }

    return source.where((conversation) {
      final searchable = [
        conversation.title,
        conversation.lastMessage,
        ...conversation.tags,
      ].join(' ').toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }
}

class ConversationSidebar extends StatelessWidget {
  const ConversationSidebar({
    required this.conversations,
    required this.searchQuery,
    required this.selectedConversationId,
    required this.onConversationSelected,
    super.key,
  });

  final List<Conversation> conversations;
  final String searchQuery;
  final String selectedConversationId;
  final ValueChanged<String> onConversationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 292,
      color: AppColors.panelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ConversationHeader(),
          const _QuickContactStrip(),
          Expanded(
            child: conversations.isEmpty
                ? _ConversationEmptyState(searchQuery: searchQuery)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ConversationTile(
                        conversation: conversation,
                        isSelected: conversation.id == selectedConversationId,
                        onTap: () => onConversationSelected(conversation.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ChatPanel extends StatelessWidget {
  const ChatPanel({
    required this.conversation,
    required this.messages,
    required this.onSend,
    required this.isSending,
    this.syncNotice,
    super.key,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;
  final ValueChanged<String> onSend;
  final bool isSending;
  final String? syncNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ChatHeader(conversation: conversation),
        Expanded(
          child: MessageList(conversation: conversation, messages: messages),
        ),
        if (syncNotice != null) SyncNotice(message: syncNotice!),
        ChatComposer(
          conversationTitle: conversation.title,
          isSending: isSending,
          onSend: onSend,
        ),
      ],
    );
  }
}

class SyncNotice extends StatelessWidget {
  const SyncNotice({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.tertiaryText, fontSize: 12),
      ),
    );
  }
}

class ChatHeader extends StatelessWidget {
  const ChatHeader({required this.conversation, super.key});

  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          UserAvatar(
            label: conversation.avatarLabel,
            color: conversation.avatarColor,
            size: 38,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                for (final tag in conversation.tags.take(1))
                  TagPill(label: tag),
              ],
            ),
          ),
          const Spacer(),
          const _HeaderIcon(icon: Icons.search_rounded, tooltip: '搜索聊天记录'),
          const _HeaderIcon(icon: Icons.call_rounded, tooltip: '语音通话'),
          const _HeaderIcon(
            icon: Icons.person_add_alt_1_rounded,
            tooltip: '添加成员',
          ),
          const _HeaderIcon(icon: Icons.calendar_today_rounded, tooltip: '日程'),
          const _HeaderIcon(icon: Icons.more_horiz_rounded, tooltip: '更多'),
        ],
      ),
    );
  }
}

class MessageList extends StatefulWidget {
  const MessageList({
    required this.conversation,
    required this.messages,
    super.key,
  });

  final Conversation conversation;
  final List<ChatMessage> messages;

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id ||
        oldWidget.messages.length != widget.messages.length) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(
        child: Text(
          '暂无消息',
          style: TextStyle(color: AppColors.tertiaryText, fontSize: 13),
        ),
      );
    }

    return Container(
      color: AppColors.panelBackground,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        itemCount: widget.messages.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          if (message.isSystem) {
            return Center(
              child: Text(
                message.content,
                style: const TextStyle(
                  color: AppColors.tertiaryText,
                  fontSize: 12,
                ),
              ),
            );
          }

          return MessageBubble(
            message: message,
            avatarLabel: message.isMine ? '我' : widget.conversation.avatarLabel,
            avatarColor: message.isMine
                ? AppColors.brandBlue
                : widget.conversation.avatarColor,
          );
        },
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }
}

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    required this.conversationTitle,
    required this.onSend,
    required this.isSending,
    super.key,
  });

  final String conversationTitle;
  final ValueChanged<String> onSend;
  final bool isSending;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend = _hasText && !widget.isSending;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(color: AppColors.panelBackground),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC8CDD8)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: TextField(
                  controller: _controller,
                  enabled: !widget.isSending,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: '发送给 ${widget.conversationTitle}',
                    hintStyle: const TextStyle(
                      color: AppColors.tertiaryText,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const _ComposerIcon(icon: Icons.text_fields_rounded, tooltip: '格式'),
            const _ComposerIcon(
              icon: Icons.emoji_emotions_outlined,
              tooltip: '表情',
            ),
            const _ComposerIcon(
              icon: Icons.alternate_email_rounded,
              tooltip: '@',
            ),
            const _ComposerIcon(icon: Icons.content_cut_rounded, tooltip: '截图'),
            const _ComposerIcon(
              icon: Icons.add_circle_outline_rounded,
              tooltip: '附件',
            ),
            const _ComposerIcon(
              icon: Icons.open_in_full_rounded,
              tooltip: '展开',
            ),
            const SizedBox(width: 4),
            IconButton(
              tooltip: widget.isSending ? '发送中' : '发送',
              onPressed: canSend ? _submit : null,
              icon: widget.isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final content = _controller.text.trim();
    if (content.isEmpty || widget.isSending) {
      return;
    }
    widget.onSend(content);
    _controller.clear();
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    required this.conversation,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final Conversation conversation;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              UserAvatar(
                label: conversation.avatarLabel,
                color: conversation.avatarColor,
                size: 38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                              fontWeight: conversation.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          conversation.lastMessageTime,
                          style: const TextStyle(
                            color: AppColors.tertiaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final tag in conversation.tags.take(1)) ...[
                          TagPill(label: tag, compact: true),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            conversation.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
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

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchQuery.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: AppColors.tertiaryText,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery ? '没有找到相关会话' : '暂无会话',
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasQuery) ...[
              const SizedBox(height: 5),
              Text(
                searchQuery,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.tertiaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message,
    required this.avatarLabel,
    required this.avatarColor,
    super.key,
  });

  final ChatMessage message;
  final String avatarLabel;
  final Color avatarColor;

  @override
  Widget build(BuildContext context) {
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: message.isMine
              ? AppColors.bubbleMine
              : AppColors.bubbleIncoming,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Text(
            message.content,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: message.isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isMine) ...[
          UserAvatar(label: avatarLabel, color: avatarColor, size: 34),
          const SizedBox(width: 10),
        ],
        Flexible(child: bubble),
        if (message.isMine) ...[
          const SizedBox(width: 10),
          UserAvatar(label: avatarLabel, color: avatarColor, size: 34),
        ],
      ],
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.label,
    required this.color,
    this.size = 36,
    super.key,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        label.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TagPill extends StatelessWidget {
  const TagPill({required this.label, this.compact = false, super.key});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = switch (label) {
      '外部' => (AppColors.tagBlue, AppColors.brandBlue),
      '机器人' => (AppColors.tagGold, const Color(0xFFB77900)),
      '智能体' => (AppColors.tagPurple, const Color(0xFF7B4DFF)),
      '官方' => (AppColors.tagBlue, AppColors.brandBlue),
      _ => (AppColors.surfaceMuted, AppColors.secondaryText),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$2,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ConversationHeader extends StatelessWidget {
  const _ConversationHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 15, 12, 8),
      child: Row(
        children: [
          const Icon(
            Icons.sort_rounded,
            size: 20,
            color: AppColors.primaryText,
          ),
          const SizedBox(width: 7),
          Text('消息', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          IconButton(
            tooltip: '筛选',
            onPressed: () {},
            icon: const Icon(Icons.tune_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _QuickContactStrip extends StatelessWidget {
  const _QuickContactStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: quickContacts.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final contact = quickContacts[index];
          return SizedBox(
            width: 50,
            child: Column(
              children: [
                UserAvatar(
                  label: contact.avatarLabel,
                  color: contact.avatarColor,
                  size: 36,
                ),
                const SizedBox(height: 6),
                Text(
                  contact.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: () {},
      icon: Icon(icon, size: 19, color: AppColors.secondaryText),
    );
  }
}

class _ComposerIcon extends StatelessWidget {
  const _ComposerIcon({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      constraints: const BoxConstraints.tightFor(width: 32, height: 40),
      padding: EdgeInsets.zero,
      onPressed: () {},
      icon: Icon(icon, size: 19, color: AppColors.secondaryText),
    );
  }
}
