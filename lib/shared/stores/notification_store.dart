import 'package:flutter/foundation.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });
}

class NotificationStore {
  NotificationStore._();

  static final ValueNotifier<List<AppNotification>> itemsVN =
      ValueNotifier<List<AppNotification>>([]);

  static List<AppNotification> get items => itemsVN.value;

  static void add(String title, String message) {
    final n = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      message: message,
      time: DateTime.now(),
      read: false,
    );
    itemsVN.value = [n, ...itemsVN.value];
  }

  static int unreadCount() => items.where((n) => !n.read).length;

  static void markAllRead() {
    for (final n in items) {
      n.read = true;
    }
    itemsVN.value = List<AppNotification>.from(itemsVN.value);
  }

  static void markRead(String id) {
    final idx = items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    items[idx].read = true;
    itemsVN.value = List<AppNotification>.from(itemsVN.value);
  }

  static void clearAll() {
    itemsVN.value = [];
  }
}
