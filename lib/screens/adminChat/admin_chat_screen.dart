import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/colors.dart';

class AdminChatManagementScreen extends StatefulWidget {
  const AdminChatManagementScreen({super.key});

  @override
  State<AdminChatManagementScreen> createState() =>
      _AdminChatManagementScreenState();
}

class _AdminChatManagementScreenState extends State<AdminChatManagementScreen> {
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xfff4f7f4),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 760;
          if (narrow && _selectedUserId != null) {
            return _ConversationPane(
              userId: _selectedUserId!,
              onBack: () => setState(() => _selectedUserId = null),
            );
          }
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .06), blurRadius: 16)
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                SizedBox(
                  width: narrow ? constraints.maxWidth : 330,
                  child: _InboxPane(
                    selectedUserId: _selectedUserId,
                    onSelected: (id) => setState(() => _selectedUserId = id),
                  ),
                ),
                if (!narrow) ...[
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _selectedUserId == null
                        ? const _EmptyConversation()
                        : _ConversationPane(userId: _selectedUserId!),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InboxPane extends StatelessWidget {
  const _InboxPane({required this.selectedUserId, required this.onSelected});

  final String? selectedUserId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Color(0xffe5f4ea),
                child: Icon(Icons.forum_outlined, color: MyColors.color1),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User Chats',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Text('Messages from Luminara users',
                      style: TextStyle(fontSize: 12, color: MyColors.greyDark)),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('admin_chats')
                .orderBy('updatedAt', descending: true)
                .snapshots(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: MyColors.color1));
              }
              final threads = snapshot.data!.docs;
              if (threads.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('No user messages yet.',
                        style: TextStyle(color: MyColors.greyDark)),
                  ),
                );
              }
              return ListView.separated(
                itemCount: threads.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, index) {
                  final doc = threads[index];
                  final data = doc.data();
                  final unread = (data['unreadForAdmin'] as num?)?.toInt() ?? 0;
                  final selected = doc.id == selectedUserId;
                  final updatedAt = data['updatedAt'] as Timestamp?;
                  return Material(
                    color: selected ? const Color(0xffedf7ef) : Colors.white,
                    child: ListTile(
                      selected: selected,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 7),
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                MyColors.color2.withValues(alpha: .16),
                            child: Text(_initials(data['fullName']?.toString()),
                                style: const TextStyle(
                                    color: MyColors.color2,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (_ConversationPaneState._isOnline(data))
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xff31c15f),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                                data['fullName']?.toString() ?? 'Luminara User',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: unread > 0
                                        ? FontWeight.w700
                                        : FontWeight.w600)),
                          ),
                          if (updatedAt != null)
                            Text(_listTime(updatedAt.toDate()),
                                style: const TextStyle(
                                    fontSize: 10, color: MyColors.greyDark)),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['lastMessage']?.toString() ??
                                  'New conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontWeight: unread > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal),
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: const BoxDecoration(
                                  color: MyColors.color2,
                                  shape: BoxShape.circle),
                              child: Text(unread > 99 ? '99+' : '$unread',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      onTap: () => onSelected(doc.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static String _initials(String? name) {
    final parts = (name ?? 'U').trim().split(RegExp(r'\s+'));
    return parts
        .take(2)
        .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
        .join();
  }

  static String _listTime(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(now, date)) {
      return DateFormat('h:mm a').format(date);
    }
    return DateFormat('MMM d').format(date);
  }
}

class _ConversationPane extends StatefulWidget {
  const _ConversationPane({required this.userId, this.onBack});

  final String userId;
  final VoidCallback? onBack;

  @override
  State<_ConversationPane> createState() => _ConversationPaneState();
}

class _ConversationPaneState extends State<_ConversationPane> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  Timer? _typingTimer;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _messagesStream;

  DocumentReference<Map<String, dynamic>> get _thread =>
      _firestore.collection('admin_chats').doc(widget.userId);

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildMessagesStream() => _thread
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _messagesStream = _buildMessagesStream();
    _markRead();
  }

  @override
  void didUpdateWidget(covariant _ConversationPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // Rebuild the messages stream only when the selected user actually
      // changes, so unrelated thread updates (typing/read receipts) don't tear
      // down and recreate the live listener.
      _messagesStream = _buildMessagesStream();
      _markRead();
    }
  }

  /// The user is considered online only when their app flagged them online and
  /// the heartbeat is fresh (guards against stale flags left by a crash/kill).
  static bool _isOnline(Map<String, dynamic>? thread) {
    if (thread?['userOnline'] != true) return false;
    final lastActive = thread?['userLastActiveAt'] as Timestamp?;
    if (lastActive == null) return false;
    return DateTime.now().difference(lastActive.toDate()) <
        const Duration(seconds: 45);
  }

  static String _lastSeen(Map<String, dynamic>? thread) {
    final lastActive = thread?['userLastActiveAt'] as Timestamp?;
    if (lastActive == null) return 'Offline';
    final date = lastActive.toDate();
    final diff = DateTime.now().difference(date);
    if (diff < const Duration(minutes: 1)) return 'Last seen just now';
    if (diff < const Duration(hours: 1)) {
      return 'Last seen ${diff.inMinutes}m ago';
    }
    if (DateUtils.isSameDay(DateTime.now(), date)) {
      return 'Last seen ${DateFormat('h:mm a').format(date)}';
    }
    return 'Last seen ${DateFormat('MMM d, h:mm a').format(date)}';
  }

  Future<void> _markRead() => _thread.set({
        'unreadForAdmin': 0,
        'adminLastReadAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> _setTyping(bool typing) => _thread.set({
        'adminTyping': typing,
        'adminTypingAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  void _onChanged(String value) {
    _typingTimer?.cancel();
    _setTyping(value.trim().isNotEmpty);
    _typingTimer = Timer(const Duration(seconds: 2), () => _setTyping(false));
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await _setTyping(false);
    final batch = _firestore.batch();
    batch.set(_thread.collection('messages').doc(), {
      'message': text,
      'sender': 'admin',
      'senderId': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
      'deleted': false,
    });
    batch.set(
        _thread,
        {
          'lastMessage': text,
          'lastSender': 'admin',
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadForUser': FieldValue.increment(1),
          'unreadForAdmin': 0,
        },
        SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> _unsend(DocumentReference reference) async {
    await reference.update({
      'message': '',
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _setTyping(false);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _thread.snapshots(),
      builder: (_, threadSnapshot) {
        final thread = threadSnapshot.data?.data();
        // Reset the unread badge after the frame is built so we never write to
        // the thread document during build (doing so re-triggers this stream
        // and recreates the messages listener).
        if (((thread?['unreadForAdmin'] as num?)?.toInt() ?? 0) > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
        }
        final typing = thread?['userTyping'] == true;
        final online = _isOnline(thread);
        return Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              color: Colors.white,
              child: Row(
                children: [
                  if (widget.onBack != null)
                    IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back)),
                  Stack(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xffe5f4ea),
                        child:
                            Icon(Icons.person_outline, color: MyColors.color1),
                      ),
                      if (online)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xff31c15f),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(thread?['fullName']?.toString() ?? 'Luminara User',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                        Text(
                            typing
                                ? 'typing…'
                                : online
                                    ? 'Online'
                                    : _lastSeen(thread),
                            style: TextStyle(
                              fontSize: 12,
                              color: typing
                                  ? MyColors.color1
                                  : online
                                      ? const Color(0xff31c15f)
                                      : MyColors.greyDark,
                              fontWeight: online && !typing
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontStyle: typing
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _messages()),
            _composer(),
          ],
        );
      },
    );
  }

  Widget _messages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _messagesStream,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: MyColors.color1));
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(18),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (_, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data();
            final mine = data['sender'] == 'admin';
            final deleted = data['deleted'] == true;
            final timestamp = data['timestamp'] as Timestamp?;
            return Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onLongPress: mine && !deleted
                    ? () => showMenu(
                          context: context,
                          position:
                              const RelativeRect.fromLTRB(300, 300, 20, 20),
                          items: [
                            PopupMenuItem(
                              onTap: () => _unsend(doc.reference),
                              child: const Row(children: [
                                Icon(Icons.undo,
                                    color: Colors.redAccent, size: 19),
                                SizedBox(width: 8),
                                Text('Unsend message'),
                              ]),
                            ),
                          ],
                        )
                    : null,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: mine ? MyColors.color1 : const Color(0xffedf0ed),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(mine ? 16 : 4),
                      bottomRight: Radius.circular(mine ? 4 : 16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          deleted
                              ? 'Message unsent'
                              : data['message']?.toString() ?? '',
                          style: TextStyle(
                            color:
                                mine ? Colors.white : const Color(0xff273229),
                            fontStyle:
                                deleted ? FontStyle.italic : FontStyle.normal,
                          )),
                      const SizedBox(height: 4),
                      Text(
                          timestamp == null
                              ? 'Sending…'
                              : DateFormat('MMM d, h:mm a')
                                  .format(timestamp.toDate()),
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  mine ? Colors.white70 : MyColors.greyDark)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xffe5e9e5)))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onChanged,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Reply to user…',
                filled: true,
                fillColor: const Color(0xfff4f7f4),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            onPressed: _send,
            style: IconButton.styleFrom(backgroundColor: MyColors.color2),
            icon: const Icon(Icons.send_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _EmptyConversation extends StatelessWidget {
  const _EmptyConversation();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 54, color: Color(0xffb6c1b8)),
          SizedBox(height: 14),
          Text('Select a user to start chatting',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: MyColors.greyDark)),
        ],
      ),
    );
  }
}
