import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../api_client.dart';
import '../constants/app_constants.dart';
import '../session_manager.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _initialized = false;
  String? _lastRegisteredToken;

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'tinkiyagro_orders',
        'Pedidos y entregas',
        description:
            'Cambios de estado de pedidos, entregas y puntos de recojo.',
        importance: Importance.high,
      );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_androidChannel);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((token) {
      unawaited(registerCurrentDevice(tokenOverride: token));
    });
  }

  Future<void> registerCurrentDevice({String? tokenOverride}) async {
    if (!SessionManager().isLoggedIn) return;
    if (!Platform.isAndroid) return;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[PushNotificationService] Notification permission denied');
        return;
      }

      final token = tokenOverride ?? await _messaging.getToken();
      if (token == null || token.isEmpty) return;
      if (_lastRegisteredToken == token) return;

      final response = await ApiClient.post(
        AppConstants.registerDeviceEndpoint,
        {
          'fcmToken': token,
          'platform': 'ANDROID',
          'notificationsEnabled': true,
        },
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _lastRegisteredToken = token;
      } else {
        debugPrint(
          '[PushNotificationService] Token registration failed: '
          '${response.statusCode} ${response.body}',
        );
      }
    } catch (error) {
      debugPrint('[PushNotificationService] Token registration error: $error');
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (_lastRegisteredToken == null || !SessionManager().isLoggedIn) {
      _lastRegisteredToken = null;
      return;
    }
    try {
      await ApiClient.delete(AppConstants.unregisterDeviceEndpoint);
    } catch (error) {
      debugPrint('[PushNotificationService] Token unregister error: $error');
    } finally {
      _lastRegisteredToken = null;
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title ?? 'TinkiyAgro',
      body: body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
}
