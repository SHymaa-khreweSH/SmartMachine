import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  final String machineId;

  const NotificationsScreen({super.key, required this.machineId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final CollectionReference _alertsRef;
  late final Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();

    _alertsRef = FirebaseFirestore.instance
        .collection('washing_machines')
        .doc(widget.machineId)
        .collection('alerts');

    _notificationsStream = _alertsRef
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markAllAsRead(List<QueryDocumentSnapshot> docs) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final isRead = (data['isRead'] == true);
      if (!isRead) {
        batch.update(d.reference, {'isRead': true});
      }
    }
    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Marked all as read")),
    );
  }

  Future<void> _markOneAsRead(DocumentReference ref) async {
    await ref.update({'isRead': true});
  }

  Future<void> _deleteAlert(DocumentReference ref) async {
    await ref.delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FD),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF263238)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Badge + Menu actions (Mark all read)
          StreamBuilder<QuerySnapshot>(
            stream: _notificationsStream,
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs.cast<QueryDocumentSnapshot>() ?? [];
              final unreadCount = _countUnread(docs);

              return Row(
                children: [
                  _BadgeIcon(
                    icon: Icons.notifications_rounded,
                    count: unreadCount,
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Color(0xFF263238)),
                    onSelected: (value) async {
                      if (value == 'mark_all') {
                        if (docs.isEmpty) return;
                        await _markAllAsRead(docs);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'mark_all',
                        child: Text('Mark all as read'),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                ],
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00BCD4)),
            );
          }

          final docs = snapshot.data?.docs.cast<QueryDocumentSnapshot>() ?? [];

          if (docs.isEmpty) {
            return const _EmptyNotifications();
          }

          // Build grouped list (headers + items)
          final items = _buildGroupedItems(docs);

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              if (item is _DayHeaderItem) {
                return _DayHeader(title: item.title);
              }

              final alert = item as _AlertItem;
              final data = alert.doc.data() as Map<String, dynamic>;

              final message = (data['message'] ?? 'No message').toString();
              final type = (data['type'] ?? 'info').toString();
              final createdAt = (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.now();
              final isRead = (data['isRead'] == true);

              // Swipe to delete
              return Dismissible(
                key: ValueKey(alert.doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete notification?"),
                      content: const Text("This action cannot be undone."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (_) async {
                  await _deleteAlert(alert.doc.reference);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Deleted")),
                  );
                },
                child: GestureDetector(
                  onTap: () async {
                    // Mark as read on tap (if not read)
                    if (!isRead) {
                      await _markOneAsRead(alert.doc.reference);
                    }
                  },
                  child: _NotificationCard(
                    message: message,
                    type: type,
                    createdAt: createdAt,
                    isRead: isRead,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static int _countUnread(List<QueryDocumentSnapshot> docs) {
    int c = 0;
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['isRead'] != true) c++;
    }
    return c;
  }

  List<_ListItem> _buildGroupedItems(List<QueryDocumentSnapshot> docs) {
    final List<_ListItem> out = [];
    DateTime? currentDay;

    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final createdAt = (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now();

      final day = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (currentDay == null || day != currentDay) {
        currentDay = day;
        out.add(_DayHeaderItem(_dayLabel(day)));
      }
      out.add(_AlertItem(d));
    }

    return out;
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (day == today) return "Today";
    if (day == yesterday) return "Yesterday";
    return "${day.day}/${day.month}/${day.year}";
  }
}

/// ===================== UI: BADGE ICON =====================
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox(width: 44, height: 44),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(icon, color: const Color(0xFF263238)),
            ),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  count > 99 ? "99+" : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// ===================== UI: EMPTY STATE =====================
class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: Color(0xFF4FC3F7),
            ),
            SizedBox(height: 14),
            Text(
              "No notifications yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF263238),
              ),
            ),
            SizedBox(height: 6),
            Text(
              "You will see alerts here when something happens.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== UI: DAY HEADER =====================
class _DayHeader extends StatelessWidget {
  final String title;

  const _DayHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== UI: NOTIFICATION CARD =====================
class _NotificationCard extends StatelessWidget {
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;

  const _NotificationCard({
    required this.message,
    required this.type,
    required this.createdAt,
    required this.isRead,
  });

  IconData get icon {
    switch (type) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'error':
        return Icons.error_outline_rounded;
      case 'success':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'warning':
        return const Color(0xFFF59E0B);
      case 'error':
        return const Color(0xFFEF4444);
      case 'success':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF0288D1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isRead ? Colors.transparent : const Color(0xFF00BCD4).withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),

          // content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF263238),
                        ),
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00BCD4),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _formatDate(createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m';
  }
}

/// ===================== LIST ITEM TYPES =====================
abstract class _ListItem {}

class _DayHeaderItem extends _ListItem {
  final String title;
  _DayHeaderItem(this.title);
}

class _AlertItem extends _ListItem {
  final QueryDocumentSnapshot doc;
  _AlertItem(this.doc);
}
