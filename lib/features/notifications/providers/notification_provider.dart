import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repository/notification_repository.dart';
import '../models/app_notification.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (_) => NotificationRepository(),
);

final unreadNotificationCountProvider = StreamProvider<int>((ref) async* {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    yield 0;
    return;
  }

  final repo = ref.read(notificationRepositoryProvider);

  // Fetch initial count via REST (authoritative)
  yield await repo.unreadCount(userId);

  // Use realtime stream as a "something changed" signal, but always
  // refetch the actual count via REST. This avoids stale snapshots
  // when the realtime channel reconnects after an auth state change.
  final stream = Supabase.instance.client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId);

  await for (final _ in stream) {
    try {
      yield await repo.unreadCount(userId);
    } catch (_) {
      // Ignore transient errors — keep last good value
    }
  }
});

class NotificationsNotifier extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];
    return ref.read(notificationRepositoryProvider).fetchNotifications(userId);
  }

  Future<void> markAsRead(String notificationId) async {
    await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    state.whenData((notifications) {
      state = AsyncData([
        for (final n in notifications)
          if (n.id == notificationId)
            AppNotification(
              id: n.id,
              userId: n.userId,
              type: n.type,
              title: n.title,
              body: n.body,
              data: n.data,
              isRead: true,
              createdAt: n.createdAt,
            )
          else
            n,
      ]);
    });
    ref.invalidate(unreadNotificationCountProvider);
  }

  Future<void> markAllAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await ref.read(notificationRepositoryProvider).markAllAsRead(userId);
    state.whenData((notifications) {
      state = AsyncData([
        for (final n in notifications)
          AppNotification(
            id: n.id,
            userId: n.userId,
            type: n.type,
            title: n.title,
            body: n.body,
            data: n.data,
            isRead: true,
            createdAt: n.createdAt,
          ),
      ]);
    });
    ref.invalidate(unreadNotificationCountProvider);
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  NotificationsNotifier.new,
);
