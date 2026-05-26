import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'contact_api.dart';
import 'contact_models.dart';
import 'mock_contact_data.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({required this.searchQuery, super.key});

  final String searchQuery;

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final _api = ContactApi();
  late List<Contact> _allContacts = [...mockContacts];
  late List<Contact> _visibleContacts = [...mockContacts];
  Contact? _selectedContact = mockContacts.first;
  Timer? _searchDebounce;
  String _syncNotice = '正在连接本地后端...';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void didUpdateWidget(covariant ContactsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
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
    return Row(
      children: [
        _ContactsSidebar(
          contacts: _visibleContacts,
          selectedContactId: _selectedContact?.id,
          searchQuery: widget.searchQuery,
          onSelected: (contact) => setState(() => _selectedContact = contact),
        ),
        const VerticalDivider(width: 1, color: AppColors.line),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _selectedContact == null
                    ? const _NoContactSelected()
                    : _ContactDetail(contact: _selectedContact!),
              ),
              _ContactSyncNotice(message: _syncNotice),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _api.fetchContacts(query: widget.searchQuery);
      if (!mounted) {
        return;
      }
      setState(() {
        _allContacts = widget.searchQuery.trim().isEmpty
            ? contacts
            : _allContacts;
        _visibleContacts = contacts;
        _selectedContact = contacts.isNotEmpty ? contacts.first : null;
        _syncNotice = '已连接本地后端';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _visibleContacts = _filterLocalContacts(
          _allContacts,
          widget.searchQuery,
        );
        _selectedContact = _visibleContacts.isNotEmpty
            ? _visibleContacts.first
            : null;
        _syncNotice = '后端未连接，当前使用本地联系人数据';
      });
    }
  }

  Future<void> _applySearch(String query) async {
    try {
      final contacts = await _api.fetchContacts(query: query);
      if (!mounted) {
        return;
      }
      setState(() {
        if (query.trim().isEmpty) {
          _allContacts = contacts;
        }
        _visibleContacts = contacts;
        _selectedContact =
            contacts.any((contact) => contact.id == _selectedContact?.id)
            ? _selectedContact
            : contacts.isNotEmpty
            ? contacts.first
            : null;
        _syncNotice = contacts.isEmpty ? '没有找到相关联系人' : '已连接本地后端';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      final contacts = _filterLocalContacts(_allContacts, query);
      setState(() {
        _visibleContacts = contacts;
        _selectedContact =
            contacts.any((contact) => contact.id == _selectedContact?.id)
            ? _selectedContact
            : contacts.isNotEmpty
            ? contacts.first
            : null;
        _syncNotice = '联系人搜索同步失败，已使用本地结果';
      });
    }
  }

  List<Contact> _filterLocalContacts(List<Contact> source, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return [...source];
    }

    return source.where((contact) {
      final searchable = [
        contact.name,
        contact.department,
        contact.title,
        contact.email,
      ].join(' ').toLowerCase();
      return searchable.contains(normalized);
    }).toList();
  }
}

class _ContactsSidebar extends StatelessWidget {
  const _ContactsSidebar({
    required this.contacts,
    required this.selectedContactId,
    required this.searchQuery,
    required this.onSelected,
  });

  final List<Contact> contacts;
  final String? selectedContactId;
  final String searchQuery;
  final ValueChanged<Contact> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 292,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 16, 10),
            child: Row(
              children: [
                Text('通讯录', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '添加联系人',
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 16, 10),
            child: Text(
              '${contacts.length} 位联系人',
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? _ContactsEmptyState(searchQuery: searchQuery)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _ContactTile(
                        contact: contact,
                        isSelected: contact.id == selectedContactId,
                        onTap: () => onSelected(contact),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.contact,
    required this.isSelected,
    required this.onTap,
  });

  final Contact contact;
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
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.selected : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _ContactAvatar(contact: contact, size: 36),
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
                            contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (contact.isFavorite)
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFFFB020),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${contact.department} · ${contact.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 12,
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

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Text('联系人资料', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  tooltip: '发消息',
                  onPressed: () {},
                  icon: const Icon(Icons.chat_bubble_rounded, size: 19),
                ),
                IconButton(
                  tooltip: '更多',
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz_rounded, size: 20),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 32, 36, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContactAvatar(contact: contact, size: 72),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              contact.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (contact.isExternal) ...[
                            const SizedBox(width: 8),
                            const _ContactTag(label: '外部'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${contact.department} · ${contact.title}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _StatusLine(status: contact.status),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(36, 24, 36, 0),
            child: Column(
              children: [
                _InfoRow(label: '邮箱', value: contact.email),
                _InfoRow(label: '部门', value: contact.department),
                _InfoRow(label: '职位', value: contact.title),
                _InfoRow(label: '联系人 ID', value: contact.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactAvatar extends StatelessWidget {
  const _ContactAvatar({required this.contact, required this.size});

  final Contact contact;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: contact.avatarColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        contact.avatarLabel.characters.first,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ContactTag extends StatelessWidget {
  const _ContactTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tagBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.brandBlue,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'online' => AppColors.brandGreen,
      'busy' => const Color(0xFFFFB020),
      _ => AppColors.tertiaryText,
    };
    final label = switch (status) {
      'online' => '在线',
      'busy' => '忙碌',
      _ => '离线',
    };

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.tertiaryText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactsEmptyState extends StatelessWidget {
  const _ContactsEmptyState({required this.searchQuery});

  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search_rounded,
              size: 34,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(height: 10),
            const Text(
              '没有找到联系人',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (searchQuery.trim().isNotEmpty) ...[
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

class _NoContactSelected extends StatelessWidget {
  const _NoContactSelected();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '选择一个联系人查看资料',
        style: TextStyle(color: AppColors.tertiaryText, fontSize: 13),
      ),
    );
  }
}

class _ContactSyncNotice extends StatelessWidget {
  const _ContactSyncNotice({required this.message});

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
