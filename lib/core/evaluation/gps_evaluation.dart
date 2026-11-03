import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../api_client.dart';

class GpsEvaluation {
  static const enabled = bool.fromEnvironment(
    'GPS_EVALUATION_ENABLED',
    defaultValue: false,
  );
  static const configuredRunId = String.fromEnvironment(
    'GPS_EVALUATION_RUN_ID',
  );
  static const routeId = String.fromEnvironment('GPS_EVALUATION_ROUTE_ID');
  static const deviceModel = String.fromEnvironment(
    'GPS_EVALUATION_DEVICE_MODEL',
  );
  static const androidVersion = String.fromEnvironment(
    'GPS_EVALUATION_ANDROID_VERSION',
  );
  static const emulator = bool.fromEnvironment(
    'GPS_EVALUATION_EMULATOR',
    defaultValue: false,
  );
  static const intervalSeconds = int.fromEnvironment(
    'GPS_EVALUATION_INTERVAL_SECONDS',
    defaultValue: 10,
  );
  static const sessionSeconds = int.fromEnvironment(
    'GPS_EVALUATION_SESSION_SECONDS',
    defaultValue: 330,
  );

  static String? _activeRunId;
  static Timer? _sessionTimer;

  static String? get activeRunId => _activeRunId;

  static Duration get trackingInterval => enabled
      ? Duration(seconds: intervalSeconds.clamp(5, 60))
      : const Duration(hours: 1);

  static Future<String?> startSession() async {
    if (!enabled) return null;
    if (_activeRunId != null) return _activeRunId;

    if (routeId.isEmpty) {
      if (configuredRunId.isEmpty) {
        throw StateError(
          'Configura GPS_EVALUATION_ROUTE_ID o GPS_EVALUATION_RUN_ID.',
        );
      }
      _activate(configuredRunId);
      return _activeRunId;
    }
    if (deviceModel.isEmpty || androidVersion.isEmpty) {
      throw StateError(
        'Configura el modelo y la versión de Android para la sesión GPS.',
      );
    }

    final response = await ApiClient.post('/api/evaluation/gps/runs', {
      'routeId': routeId,
      'condition': 'FULL',
      'deviceModel': deviceModel,
      'androidVersion': androidVersion,
      'emulator': emulator,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'No se pudo iniciar la sesión GPS: '
        '${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    final createdRunId = decoded is String
        ? decoded
        : (decoded as Map<String, dynamic>)['id']?.toString();
    if (createdRunId == null || createdRunId.isEmpty) {
      throw StateError('El backend no devolvió el runId de la sesión GPS.');
    }
    _activate(createdRunId);
    return _activeRunId;
  }

  static void _activate(String runId) {
    _activeRunId = runId;
    _sessionTimer?.cancel();
    _sessionTimer = Timer(
      Duration(seconds: sessionSeconds.clamp(300, 900)),
      endSession,
    );
    debugPrint('[GpsEvaluation] sesión iniciada runId=$runId');
  }

  static void endSession() {
    final finishedRunId = _activeRunId;
    _activeRunId = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    if (finishedRunId != null) {
      debugPrint('[GpsEvaluation] sesión finalizada runId=$finishedRunId');
    }
  }

  static Future<void> recordContinuous({
    required String trackingMeasurementId,
    required double latitude,
    required double longitude,
    required double accuracyM,
    required DateTime capturedAt,
  }) async {
    if (!enabled) return;
    final runId = _activeRunId;
    if (runId == null) {
      debugPrint('[GpsEvaluation] no hay una sesión GPS activa');
      return;
    }

    final response =
        await ApiClient.post('/api/evaluation/gps/runs/$runId/readings', {
          'id': const Uuid().v4(),
          'trackingMeasurementId': trackingMeasurementId,
          'latitude': latitude,
          'longitude': longitude,
          'accuracyM': accuracyM,
          'captureType': 'CONTINUOUS',
          'deviceTs': capturedAt.toUtc().toIso8601String(),
        });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw StateError(
        'No se pudo registrar la muestra GPS: '
        '${response.statusCode} ${response.body}',
      );
    }
    debugPrint(
      '[GpsEvaluation] lectura=${jsonDecode(response.body)} '
      'tracking=$trackingMeasurementId',
    );
  }

  static String? trackingMeasurementId(Map<String, dynamic> response) {
    final direct = response['positionUpdateId']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final tracking = response['tracking'];
    if (tracking is Map) {
      final nested = tracking['positionUpdateId']?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    final timeline = response['timeline'];
    if (timeline is List) {
      for (final step in timeline.reversed) {
        if (step is! Map || step['tracking'] is! Map) continue;
        final nested = (step['tracking'] as Map)['positionUpdateId']
            ?.toString();
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }
}
