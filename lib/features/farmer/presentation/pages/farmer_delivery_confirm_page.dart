import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/location_tracking_service.dart';
import '../../data/farmer_order_model.dart';
import '../../data/remote/farmer_order_service.dart';

class FarmerDeliveryConfirmPage extends StatefulWidget {
  const FarmerDeliveryConfirmPage({super.key});

  @override
  State<FarmerDeliveryConfirmPage> createState() =>
      _FarmerDeliveryConfirmPageState();
}

class _FarmerDeliveryConfirmPageState extends State<FarmerDeliveryConfirmPage> {
  final _service = FarmerOrderService();
  final _tracking = LocationTrackingService();

  late FarmerOrderGroup _group;
  bool _initialized = false;

  final Map<String, bool> _confirmando = {};
  final Set<String> _confirmados = {};

  // Courier dispatch: set by API (despachoType == 'Repartidor') or in-session assignment.
  // despachoType is '' until explicitly set, so this is only true when courier was confirmed.
  bool get _isCourierDelivery =>
      _group.repartidorUsername != null || _group.despachoType == 'Repartidor';

  bool get _isDeliveryType => _group.deliveryMethod == 'DELIVERY';

  String _buildFullAddress() {
    final parts = <String>[
      if (_group.direccion.isNotEmpty) _group.direccion,
      if (_group.district != null && _group.district!.isNotEmpty)
        _group.district!,
      if (_group.reference != null && _group.reference!.isNotEmpty)
        _group.reference!,
    ];
    return parts.join(', ');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _group = ModalRoute.of(context)!.settings.arguments as FarmerOrderGroup;

      // Courier flow: if already delivered when page opens, auto-dismiss after 2 s
      if (_isCourierDelivery && _group.state == OrderGroupState.entregado) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  void dispose() {
    // No detenemos el tracking aquí: el singleton sigue enviando
    // aunque el usuario navegue a otra pantalla.
    // Se detiene solo en logout o al confirmar la última entrega.
    super.dispose();
  }

  // ── Self-delivery confirm ─────────────────────────────────────────────────

  Future<void> _confirmar(FarmerCustomerOrder customer) async {
    final ids = customer.subOrderIds;
    if (ids.isEmpty) return;
    setState(() {
      for (final id in ids) {
        _confirmando[id] = true;
      }
    });
    try {
      for (final id in ids) {
        await _service.confirmarEntrega(id);
      }
      if (!mounted) return;
      for (final id in ids) {
        _tracking.stopForSubOrder(id);
      }
      setState(() => _confirmados.addAll(ids));

      final todosConfirmados = _group.clientes.every(
        (c) => c.subOrderIds.every(_confirmados.contains),
      );
      if (todosConfirmados) {
        _group.state = OrderGroupState.entregado;
        _tracking.stop(); // todas entregadas → detener tracking
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          for (final id in ids) {
            _confirmando[id] = false;
          }
        });
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
          _isDeliveryType ? 'Delivery' : 'Volver',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────────────
            if (_isDeliveryType) ...[
              const Text(
                'Delivery',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _buildFullAddress(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                _group.nombrePunto,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              if (_group.direccion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _group.direccion,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),

            // ── Customer cards ───────────────────────────────────────────
            ..._group.clientes.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _isCourierDelivery
                    ? _buildCourierStatusCard(c)
                    : _buildSelfDeliveryCard(c),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Courier status card (read-only) ───────────────────────────────────────

  Widget _buildCourierStatusCard(FarmerCustomerOrder customer) {
    final isEntregado = _group.state == OrderGroupState.entregado;
    return Container(
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
                radius: 19,
                backgroundColor: customer.clienteColor,
                backgroundImage: customer.customerProfileImageUrl.isNotEmpty
                    ? NetworkImage(customer.customerProfileImageUrl)
                    : null,
                child: customer.customerProfileImageUrl.isEmpty
                    ? Text(
                        customer.clienteInicial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E3A32),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customer.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildTypeBadge(customer.tipoEntrega),
            ],
          ),
          const SizedBox(height: 12),

          ...customer.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.productName} × ${item.cantidad}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'S/. ${item.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (customer.deliveryCost > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Envío',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    'S/. ${customer.deliveryCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a cobrar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'S/. ${customer.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Status badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isEntregado
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEntregado
                    ? const Color(0xFF5CA399)
                    : const Color(0xFFFFB300),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isEntregado
                      ? Icons.check_circle_outline
                      : Icons.local_shipping_outlined,
                  color: isEntregado
                      ? const Color(0xFF5CA399)
                      : const Color(0xFFFFB300),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Estado: ${isEntregado ? 'Entregado' : 'En camino'}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEntregado
                        ? const Color(0xFF5CA399)
                        : const Color(0xFFFFB300),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Self-delivery confirm card ────────────────────────────────────────────

  Widget _buildSelfDeliveryCard(FarmerCustomerOrder customer) {
    final isYape = customer.metodoPago == 'Yape';
    final isBusy = customer.subOrderIds.any((id) => _confirmando[id] == true);
    final yaConfirmado = customer.subOrderIds.every(_confirmados.contains);
    final canConfirm =
        customer.entregaConfirmada &&
        customer.pagoConfirmado &&
        !isBusy &&
        !yaConfirmado;

    return Container(
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
                radius: 19,
                backgroundColor: customer.clienteColor,
                backgroundImage: customer.customerProfileImageUrl.isNotEmpty
                    ? NetworkImage(customer.customerProfileImageUrl)
                    : null,
                child: customer.customerProfileImageUrl.isEmpty
                    ? Text(
                        customer.clienteInicial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E3A32),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  customer.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildTypeBadge(customer.tipoEntrega),
            ],
          ),
          const SizedBox(height: 12),

          ...customer.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.productName} × ${item.cantidad}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'S/. ${item.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (customer.deliveryCost > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Envío',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Text(
                    'S/. ${customer.deliveryCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total a cobrar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'S/. ${customer.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Text(
            'Confirmar entrega',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5CA399),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto a cobrar:',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        'S/. ${customer.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Método:',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                      Text(
                        isYape
                            ? 'Yape: ${customer.yapeNumero ?? 'No configurado'}'
                            : 'Efectivo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildToggleRow(
            'Entregué los productos al cliente',
            customer.entregaConfirmada,
            (isBusy || yaConfirmado)
                ? null
                : (v) => setState(() => customer.entregaConfirmada = v),
          ),
          const SizedBox(height: 6),
          _buildToggleRow(
            'Recibí el pago',
            customer.pagoConfirmado,
            (isBusy || yaConfirmado)
                ? null
                : (v) => setState(() => customer.pagoConfirmado = v),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: canConfirm ? () => _confirmar(customer) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CA399),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: isBusy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirmar entrega',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String tipo) {
    final isDelivery = tipo == 'Delivery';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDelivery ? const Color(0xFFE8D5F5) : const Color(0xFFD5E8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDelivery ? const Color(0xFF7B2D8B) : const Color(0xFF1976D2),
        ),
      ),
    );
  }

  Widget _buildToggleRow(
    String label,
    bool value,
    ValueChanged<bool>? onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF5CA399),
          ),
        ],
      ),
    );
  }
}
