import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });
}

class NotificationStore {
  static final List<AppNotification> _items = [];
  static final ValueNotifier<int> itemsVN = ValueNotifier<int>(0);

  static void _notify() => itemsVN.value++;

  // ✅ your current usage
  static void add(String title, String message) {
    _items.insert(
      0,
      AppNotification(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        isRead: false,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
  }

  // ✅ used by notifications_center_page.dart
  static List<AppNotification> items() => List.unmodifiable(_items);

  static int unreadCount() => _items.where((n) => !n.isRead).length;

  static void markRead(String id) {
    for (final n in _items) {
      if (n.id == id) n.isRead = true;
    }
    _notify();
  }

  static void markAllRead() {
    for (final n in _items) {
      n.isRead = true;
    }
    _notify();
  }

  static void clearAll() {
    _items.clear();
    _notify();
  }

  // ✅ extra alias if your old code uses clear()
  static void clear() => clearAll();
}
