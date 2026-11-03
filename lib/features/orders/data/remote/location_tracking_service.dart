import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
import 'package:tinkiyagro_app/core/evaluation/gps_evaluation.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/courier/data/courier_tracking_repository.dart';

/// Singleton que envía la ubicación GPS al backend cada hora.
/// Persiste mientras el usuario esté logueado y tenga pedidos en tránsito.
/// Se inicia desde la página de entrega y se detiene solo en logout o al
/// confirmar la última entrega.
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._();

  Timer? _timer;
  List<String> _subOrderIds = [];
  String _endpointTemplate = '';
  bool _sending = false;

  static const _targetAccuracyM = 5.0;
  static const _accuracySamplingWindow = Duration(seconds: 12);

  Duration get _interval => GpsEvaluation.trackingInterval;

  bool get isActive => _timer != null;

  /// Solicita permiso de ubicación. Retorna true si fue concedido.
  Future<bool> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationTracking] Servicio de ubicación desactivado');
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint('[LocationTracking] Permiso denegado: $permission');
      return false;
    }
    return true;
  }

  /// Inicia (o reinicia) el envío periódico de ubicación cada hora.
  /// Envía inmediatamente y luego cada hora.
  void start({
    required List<String> subOrderIds,
    required String endpointTemplate,
  }) {
    final ids = subOrderIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;

    _subOrderIds = ids;
    _endpointTemplate = endpointTemplate;

    _timer?.cancel();
    _sendAll(); // envío inmediato al iniciar
    _timer = Timer.periodic(_interval, (_) => _sendAll());

    debugPrint(
      '[LocationTracking] iniciado para $ids — cada ${_interval.inSeconds}s',
    );
  }

  /// Detiene el tracking. Llamar en logout o al confirmar todas las entregas.
  void stop() {
    if (!isActive) return;
    _timer?.cancel();
    _timer = null;
    _subOrderIds = [];
    _endpointTemplate = '';
    debugPrint('[LocationTracking] detenido');
  }

  /// Retira un pedido ya entregado y detiene el GPS cuando no queda ninguno.
  void stopForSubOrder(String subOrderId) {
    _subOrderIds.remove(subOrderId);
    if (_subOrderIds.isEmpty) {
      stop();
    } else {
      debugPrint(
        '[LocationTracking] pedido $subOrderId finalizado; '
        'continúan $_subOrderIds',
      );
    }
  }

  Future<void> _sendAll() async {
    if (_subOrderIds.isEmpty || _sending) return;
    _sending = true;
    try {
      final position = await _getBestAvailablePosition();
      final label = await _buildLabel(position.latitude, position.longitude);
      final body = {
        'label': label,
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
      debugPrint('[LocationTracking] enviando: $body');
      for (final id in _subOrderIds) {
        final endpoint = _endpointTemplate.replaceAll('{subOrderId}', id);
        if (SessionManager().rol == 'REPARTIDOR' &&
            endpoint.startsWith('/api/courier/')) {
          await CourierTrackingRepository.instance.recordLocation(
            subOrderId: id,
            label: label,
            latitude: position.latitude,
            longitude: position.longitude,
            accuracyM: position.accuracy,
          );
        } else {
          await ApiClient.post(endpoint, body);
        }
      }
    } catch (e) {
      debugPrint('[LocationTracking] error al enviar: $e');
    } finally {
      _sending = false;
    }
  }

  Future<Position> _getBestAvailablePosition() async {
    final settings = _highAccuracySettings();
    var best = await Geolocator.getCurrentPosition(locationSettings: settings);
    if (best.accuracy <= _targetAccuracyM) return best;

    final completer = Completer<Position>();
    StreamSubscription<Position>? subscription;
    Timer? timeout;

    void complete() {
      if (!completer.isCompleted) completer.complete(best);
    }

    subscription = Geolocator.getPositionStream(locationSettings: settings)
        .listen(
          (candidate) {
            if (candidate.accuracy < best.accuracy) best = candidate;
            if (best.accuracy <= _targetAccuracyM) complete();
          },
          onError: (_) => complete(),
          onDone: complete,
        );
    timeout = Timer(_accuracySamplingWindow, complete);

    final selected = await completer.future;
    timeout.cancel();
    await subscription.cancel();
    debugPrint(
      '[LocationTracking] mejor precisión disponible: '
      '${selected.accuracy.toStringAsFixed(1)} m',
    );
    return selected;
  }

  LocationSettings _highAccuracySettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: Duration(seconds: 1),
        timeLimit: Duration(seconds: 15),
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 0,
      timeLimit: Duration(seconds: 15),
    );
  }

  Future<String> _buildLabel(double lat, double lon) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
        ];
        if (parts.isNotEmpty) return parts.join(' - ');
      }
    } catch (e) {
      debugPrint('[LocationTracking] geocoding error: $e');
    }
    return '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
  }
}
