import 'dart:convert';

import '../api_client.dart';
import '../constants/app_constants.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.type,
    this.orderId,
    this.subOrderId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? type;
  final String? orderId;
  final String? subOrderId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'TinkiyAgro',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString(),
      orderId: json['orderId']?.toString(),
      subOrderId: json['subOrderId']?.toString(),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      read: json['read'] == true,
    );
  }

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      orderId: orderId,
      subOrderId: subOrderId,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }
}

class NotificationHistoryService {
  Future<List<AppNotification>> list() async {
    final response = await ApiClient.get(AppConstants.notificationsEndpoint);
    if (response.statusCode != 200) {
      throw Exception('No se pudieron cargar las notificaciones.');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => AppNotification.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<void> markRead(String notificationId) async {
    final response = await ApiClient.patch(
      '${AppConstants.notificationsEndpoint}/$notificationId/read',
      const {},
    );
    if (response.statusCode != 204) {
      throw Exception('No se pudo actualizar la notificación.');
    }
  }

  Future<void> markAllRead() async {
    final response = await ApiClient.patch(
      AppConstants.markAllNotificationsReadEndpoint,
      const {},
    );
    if (response.statusCode != 204) {
      throw Exception('No se pudieron actualizar las notificaciones.');
    }
  }
}
