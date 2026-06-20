import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/order_model.dart';
import '../../data/remote/order_service.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _service = OrderService();

  PedidoConsumidor? _pedido;
  String? _pedidoId;
  bool _cargando = true;
  String? _error;
  final Map<String, TrackingInfo?> _courierTracking = {};

  Timer? _pollTimer;
  Timer? _courierPollTimer;
  static const _pollInterval = Duration(seconds: 30);
  static const _courierPollInterval = Duration(hours: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pedido == null && _error == null) {
      final id = ModalRoute.of(context)!.settings.arguments as String;
      _pedidoId = id;
      _cargar(id);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _courierPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _cargar(String id) async {
    try {
      final pedido = await _service.detallePedido(id);
      if (mounted) {
        setState(() => _pedido = pedido);
        await _fetchCourierTracking(pedido);
        _iniciarPolling(pedido);
        _debugEstado();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _fetchCourierTracking(PedidoConsumidor pedido) async {
    for (final sub in pedido.subPedidos) {
      if (!sub.isCourierDelivery) continue;
      final t = await _service.fetchTracking(sub.id, isCourier: true);
      if (mounted && t != null) {
        setState(() => _courierTracking[sub.id] = t);
      }
    }
  }

  void _debugEstado() {
    if (_pedido == null) return;
    for (final sub in _pedido!.subPedidos) {
      debugPrint('[DEBUG] id=${sub.id} estado="${sub.estadoTexto}" tracking="${sub.tracking?.label}" steps=${sub.timeline.length}');
    }
  }

  /// Activa un timer que re-obtiene el pedido completo cada 30s
  /// solo cuando hay subpedidos en tránsito (tracking activo del agricultor/courier).
  void _iniciarPolling(PedidoConsumidor pedido) {
    final hayEnCamino = pedido.subPedidos.any(
      (s) => s.estadoTexto == 'En camino' || s.estadoTexto == 'Repartidor en camino',
    );
    if (!hayEnCamino || _pedidoId == null) return;

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      if (!mounted) return;
      try {
        final fresh = await _service.detallePedido(_pedidoId!);
        if (mounted) setState(() => _pedido = fresh);
      } catch (_) {
        // Fallo silencioso: se sigue mostrando el último dato conocido
      }
    });

    final hayCourier = pedido.subPedidos.any((s) => s.isCourierDelivery);
    if (hayCourier && _pedidoId != null) {
      _courierPollTimer?.cancel();
      _courierPollTimer = Timer.periodic(_courierPollInterval, (_) async {
        if (!mounted) return;
        final current = _pedido;
        if (current != null) await _fetchCourierTracking(current);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _pedido != null ? 'Pedido #${_pedido!.numero}' : 'Detalle de pedido',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_error != null || _pedido == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text('No se pudo cargar el pedido',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    final pedido = _pedido!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${pedido.fechaCorta} • S/. ${pedido.total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${pedido.numAgricultores} agricultores - ${pedido.estado}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...pedido.subPedidos.map((sub) => _buildFarmerCard(sub)),
        ],
      ),
    );
  }

  Widget _buildFarmerCard(SubPedido sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: sub.farmerAvatarUrl.isNotEmpty
                    ? NetworkImage(sub.farmerAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: sub.farmerAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sub.farmerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    ...sub.itemsText.map((item) => Text(
                      item,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    )),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildTypeBadge(sub.tipo),
            ],
          ),
          const SizedBox(height: 16),
          ...sub.timeline.asMap().entries.map(
            (entry) => _buildTimelineRow(
              entry.value,
              entry.key,
              sub.timeline.length,
              liveTracking: _courierTracking[sub.id] ?? sub.tracking,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String tipo) {
    final isDelivery = tipo == 'Delivery';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isDelivery ? const Color(0xFFE8D5F5) : const Color(0xFFD5E8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDelivery ? const Color(0xFF7B2D8B) : const Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _buildTimelineRow(
    TimelineEvent event,
    int index,
    int total, {
    TrackingInfo? liveTracking,
  }) {
    final dotColor = event.completed || event.active
        ? const Color(0xFF5CA399)
        : Colors.grey.shade300;

    // Mostrar tracking en cualquier paso activo que tenga datos reales de ubicación
    final hasLive = event.active && liveTracking != null && liveTracking.label.isNotEmpty;

    final effectiveLocationText =
        hasLive ? liveTracking.label : event.locationText;
    final effectiveLocationSubtext =
        hasLive ? liveTracking.subtextActualizado : event.locationSubtext;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 3),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (index < total - 1)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: event.completed
                          ? const Color(0xFF5CA399)
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: index < total - 1 ? 12 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        event.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: event.completed || event.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: event.completed || event.active
                              ? Colors.black87
                              : Colors.grey.shade500,
                        ),
                      ),
                      Text(
                        event.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: event.active
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: event.active
                              ? const Color(0xFF5CA399)
                              : event.completed
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (effectiveLocationText != null &&
                      effectiveLocationText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 14, color: Color(0xFF1565C0)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  effectiveLocationText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (effectiveLocationSubtext != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 11, color: Colors.grey),
                                const SizedBox(width: 3),
                                Text(
                                  effectiveLocationSubtext,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  if (event.addressText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.addressText!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5CA399),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
