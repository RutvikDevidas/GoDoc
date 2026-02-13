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
            onPressed: () => NotificationStore.markAllRead(),
            icon: const Icon(Icons.done_all),
          ),
          IconButton(
            tooltip: "Clear all",
            onPressed: () => NotificationStore.clearAll(),
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: NotificationStore.itemsVN,
        builder: (context, _, __) {
          final items = NotificationStore.items;

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
                    color: n.read
                        ? Colors.white.withOpacity(0.85)
                        : const Color(0xFF2BB673).withOpacity(0.16),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          n.read
                              ? Icons.notifications
                              : Icons.notifications_active,
                          color: n.read
                              ? Colors.black87
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.message,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _timeText(n.time),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!n.read)
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

  static String _timeText(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}  $hh:$mm";
  }
}
