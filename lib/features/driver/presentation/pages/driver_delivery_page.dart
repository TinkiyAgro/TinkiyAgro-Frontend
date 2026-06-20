import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/location_tracking_service.dart';
import '../../data/driver_model.dart';
import '../../data/remote/driver_service.dart';

class RepartidorDeliveryPage extends StatefulWidget {
  const RepartidorDeliveryPage({super.key});

  @override
  State<RepartidorDeliveryPage> createState() => _RepartidorDeliveryPageState();
}

class _RepartidorDeliveryPageState extends State<RepartidorDeliveryPage> {
  final _service = DriverService();
  final _tracking = LocationTrackingService();

  late RepartidorDeliveryGroup _group;
  bool _initialized = false;
  bool _trackingActive = false;

  final Map<String, bool> _confirmando = {};
  final Set<String> _confirmados = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _group = ModalRoute.of(context)!.settings.arguments as RepartidorDeliveryGroup;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTracking());
    }
  }

  @override
  void dispose() {
    // El singleton sigue enviando aunque se cierre la página.
    // Se detiene en logout o al confirmar la última entrega.
    super.dispose();
  }

  Future<void> _startTracking() async {
    if (!mounted) return;
    final granted = await _tracking.requestPermission();
    if (!granted || !mounted) return;
    final ids = _group.clientes.map((c) => c.subOrderId).toList();
    _tracking.start(
      subOrderIds: ids,
      endpointTemplate: AppConstants.updateTrackingCourierEndpoint,
    );
    if (mounted) setState(() => _trackingActive = true);
  }

  Future<void> _confirmar(RepartidorCustomer customer) async {
    setState(() => _confirmando[customer.subOrderId] = true);
    try {
      await _service.confirmarEntrega(customer.subOrderId);
      if (!mounted) return;
      setState(() => _confirmados.add(customer.subOrderId));

      final todosConfirmados =
          _group.clientes.every((c) => _confirmados.contains(c.subOrderId));
      if (todosConfirmados) {
        _group.estado = 'Entregado';
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
                child: const Text('OK')),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _confirmando[customer.subOrderId] = false);
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
        title: const Text(
          'Volver',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          if (_trackingActive)
            Container(
              width: double.infinity,
              color: const Color(0xFF5CA399).withValues(alpha: 0.12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF5CA399), size: 16),
                  const SizedBox(width: 8),
                  const Text(
                    'Compartiendo ubicación con los clientes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5CA399),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entrega de ${_group.farmerName}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Builder(builder: (context) {
              final addr = _group.fullAddress.isNotEmpty
                  ? _group.fullAddress
                  : _group.clientes.isNotEmpty
                      ? _group.clientes.first.destinationAddress
                      : '';
              if (addr.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Entregar en: $addr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 16),
            ..._group.clientes.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCustomerCard(c),
                )),
          ],
        ),
      ),
    ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(RepartidorCustomer customer) {
    final isBusy = _confirmando[customer.subOrderId] == true;
    final yaConfirmado = _confirmados.contains(customer.subOrderId);
    final canConfirm =
        customer.entregaConfirmada && customer.pagoConfirmado && !isBusy && !yaConfirmado;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.clienteNombre,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (customer.destinationAddress.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              customer.destinationAddress,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              _buildTypeBadge(customer.tipoEntrega),
            ],
          ),
          const SizedBox(height: 12),

          // Items
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
                  Text('Envío',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  Text('S/. ${customer.deliveryCost.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text(
            'Confirmar entrega',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Payment info card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5CA399),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Método:',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                    Text(
                      customer.metodoPago == 'Yape'
                          ? 'Yape - ${customer.yapeNumero ?? ''}'
                          : 'Efectivo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          _buildToggleRow(
            'Entregué los productos al cliente',
            customer.entregaConfirmada,
            (isBusy || yaConfirmado) ? null : (v) => setState(() => customer.entregaConfirmada = v),
          ),
          const SizedBox(height: 6),
          _buildToggleRow(
            'Recibí el pago',
            customer.pagoConfirmado,
            (isBusy || yaConfirmado) ? null : (v) => setState(() => customer.pagoConfirmado = v),
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
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      yaConfirmado ? 'Entrega confirmada ✓' : 'Confirmar entrega',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
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
        color: isDelivery
            ? const Color(0xFFE8D5F5)
            : const Color(0xFFD5E8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDelivery
              ? const Color(0xFF7B2D8B)
              : const Color(0xFF1976D2),
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
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
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
