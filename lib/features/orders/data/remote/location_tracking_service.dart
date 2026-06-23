import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:tinkiyagro_app/core/api_client.dart';
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

  static const _interval = Duration(hours: 1);

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
      '[LocationTracking] iniciado para $ids — cada ${_interval.inHours}h',
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

  Future<void> _sendAll() async {
    if (_subOrderIds.isEmpty) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
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
          );
        } else {
          await ApiClient.post(endpoint, body);
        }
      }
    } catch (e) {
      debugPrint('[LocationTracking] error al enviar: $e');
    }
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
