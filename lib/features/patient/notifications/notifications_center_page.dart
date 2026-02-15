import 'package:flutter/material.dart';

import '../../../shared/stores/notification_store.dart';

class NotificationsCenterPage extends StatelessWidget {
  const NotificationsCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          IconButton(
            tooltip: "Mark all read",
            onPressed: () {
              NotificationStore.markAllRead();
            },
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: "Clear all",
            onPressed: () {
              NotificationStore.clearAll();
            },
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: NotificationStore.itemsVN,
        builder: (context, _, __) {
          final items = NotificationStore.items(); // ✅ FIX: call method

          if (items.isEmpty) {
            return Center(
              child: Text(
                "No notifications",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.black.withOpacity(0.65),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final n = items[i];

              return InkWell(
                onTap: () => NotificationStore.markRead(n.id),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: n.isRead
                          ? Colors.transparent
                          : const Color(0xFF2BB673).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (n.isRead
                              ? Colors.black.withOpacity(0.08)
                              : const Color(0xFF2BB673).withOpacity(0.15)),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          n.isRead
                              ? Icons.notifications
                              : Icons.notifications_active,
                          color: n.isRead
                              ? Colors.black.withOpacity(0.55)
                              : const Color(0xFF0B8F4D),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: n.isRead
                                    ? Colors.black.withOpacity(0.85)
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.message,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.70),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _timeAgo(n.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!n.isRead)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} min ago";
    if (diff.inHours < 24) return "${diff.inHours} hr ago";
    return "${diff.inDays} day(s) ago";
  }
}
