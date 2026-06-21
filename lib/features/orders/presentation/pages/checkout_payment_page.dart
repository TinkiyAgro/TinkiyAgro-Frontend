import 'package:flutter/material.dart';
import '../../data/order_model.dart';
import '../../data/remote/order_service.dart';
import '../../data/remote/delivery_options_service.dart';
import '../../../cart/data/cart_manager.dart';
import '../../../cart/data/remote/cart_service.dart';

class CheckoutPagoPage extends StatefulWidget {
  const CheckoutPagoPage({super.key});

  @override
  State<CheckoutPagoPage> createState() => _CheckoutPagoPageState();
}

class _CheckoutPagoPageState extends State<CheckoutPagoPage> {
  final _orderService = OrderService();

  late List<CheckoutFarmer> _farmers;
  bool _initialized = false;
  bool _confirmando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _farmers =
          ModalRoute.of(context)!.settings.arguments as List<CheckoutFarmer>;
      for (final f in _farmers) {
        if (f.paymentMethods.isNotEmpty &&
            !f.paymentMethods.contains(f.metodoPago)) {
          f.metodoPago = f.paymentMethods.first;
        }
      }
      _loadPaymentOptions();
    }
  }

  Future<void> _loadPaymentOptions() async {
    try {
      final summary = await DeliveryOptionsService().obtenerPaymentOptions(_farmers);
      if (!mounted) return;
      setState(() {
        // Apply per-farmer methods from breakdown
        for (final fs in summary.farmerBreakdown) {
          if (fs.paymentMethods.isEmpty) continue;
          final farmer = _farmers.firstWhere(
            (f) => f.farmerUsername == fs.farmerUsername,
            orElse: () => _farmers.first,
          );
          farmer.paymentMethods = List<String>.from(fs.paymentMethods);
          if (!farmer.paymentMethods.contains(farmer.metodoPago)) {
            farmer.metodoPago = farmer.paymentMethods.first;
          }
        }
        // If no per-farmer breakdown but global methods returned, apply to all
        if (summary.farmerBreakdown.isEmpty && summary.paymentMethods.isNotEmpty) {
          for (final f in _farmers) {
            f.paymentMethods = List<String>.from(summary.paymentMethods);
            if (!f.paymentMethods.contains(f.metodoPago)) {
              f.metodoPago = f.paymentMethods.first;
            }
          }
        }
      });
    } catch (_) {
      // Keep methods from the checkout options step
    }
  }

  double get _productosTotal =>
      _farmers.fold(0.0, (s, f) => s + f.productsTotal);

  double get _totalGeneral =>
      _farmers.fold(0.0, (s, f) => s + f.productsTotal + f.costoEnvio);

  bool get _todosPagosSeleccionados =>
      _farmers.every((f) => f.metodoPago.isNotEmpty);

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
          'Método de pago',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildStepIndicator(3),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._farmers.map((f) => _buildFarmerCard(f)),
                _buildSummary(),
                const SizedBox(height: 80),
              ],
            ),
          ),
          _buildConfirmButton(context),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _buildStep(1, 'ENTREGA', current),
          _buildLine(current > 1),
          _buildStep(2, 'DIRECCIÓN', current),
          _buildLine(current > 2),
          _buildStep(3, 'PAGO', current),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, int current) {
    final isDone = current > step;
    final isActive = current == step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive
                ? const Color(0xFF5CA399)
                : Colors.grey.shade300,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    )),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDone || isActive
                  ? const Color(0xFF5CA399)
                  : Colors.grey.shade500,
            )),
      ],
    );
  }

  Widget _buildLine(bool done) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: done ? const Color(0xFF5CA399) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFarmerCard(CheckoutFarmer farmer) {
    final total = farmer.productsTotal + farmer.costoEnvio;
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
                radius: 20,
                backgroundImage: farmer.farmerAvatarUrl.isNotEmpty
                    ? NetworkImage(farmer.farmerAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: farmer.farmerAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.farmerName.isNotEmpty
                          ? farmer.farmerName
                          : farmer.farmerUsername,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${farmer.tipoEntrega} • S/. ${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Método de pago',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 8),
          _buildPaymentMethodsRow(farmer),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  farmer.tipoEntrega == 'Recojo'
                      ? 'Pagarás al recibir tu pedido en el punto de recojo'
                      : 'El repartidor confirmará el Yape al entregar',
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsRow(CheckoutFarmer farmer) {
    final methods = farmer.paymentMethods.isNotEmpty
        ? farmer.paymentMethods
        : const ['Efectivo', 'Yape'];
    return Row(
      children: [
        for (int i = 0; i < methods.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _buildPaymentOption(farmer: farmer, method: methods[i]),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentOption({
    required CheckoutFarmer farmer,
    required String method,
  }) {
    final selected = farmer.metodoPago == method;
    final isYape = method.toLowerCase() == 'yape';

    return GestureDetector(
      onTap: () => setState(() => farmer.metodoPago = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5CA399) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isYape)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C3699),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text('y',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              )
            else
              Icon(Icons.wallet_outlined,
                  size: 18,
                  color: selected ? const Color(0xFF5CA399) : Colors.black87),
            const SizedBox(width: 6),
            Text(
              method,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF1E3A32) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final grandTotal = _totalGeneral;

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
        children: [
          _buildSummaryRow(
              'Productos', 'S/. ${_productosTotal.toStringAsFixed(2)}'),
          ..._farmers.map((f) {
            final name = f.farmerName.isNotEmpty ? f.farmerName : f.farmerUsername;
            return _buildSummaryRow(
              'Envío ($name)',
              f.costoEnvio > 0
                  ? 'S/. ${f.costoEnvio.toStringAsFixed(2)}'
                  : 'Por confirmar',
            );
          }),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              Text(
                'S/. ${grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ),
          Text(value,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: (!_confirmando && _todosPagosSeleccionados)
              ? _confirmOrder
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CA399),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: const Text(
            'Confirmar pedido',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmOrder() async {
    setState(() => _confirmando = true);
    final nav = Navigator.of(context);
    try {
      // 1. Confirm order via API (sends delivery & payment selections)
      await _orderService.confirmarPedido(_farmers);

      // 2. Clear local cart
      CarritoManager().vaciarCarrito();
      try {
        await CartService().cerrarCarrito();
      } catch (_) {}

      if (!mounted) return;
      _mostrarExito(nav);
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirmando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al confirmar: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _mostrarExito(NavigatorState nav) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFF8CAF3F),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pedido realizado correctamente',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      nav.popUntil((route) => route.settings.name == '/home');
    });
  }
}
