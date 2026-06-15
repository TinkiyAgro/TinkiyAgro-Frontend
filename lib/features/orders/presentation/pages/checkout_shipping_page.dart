import 'package:flutter/material.dart';
import '../../../cart/data/cart_manager.dart';
import '../../data/order_model.dart';
import '../../data/remote/delivery_options_service.dart';

class CheckoutEnvioPage extends StatefulWidget {
  const CheckoutEnvioPage({super.key});

  @override
  State<CheckoutEnvioPage> createState() => _CheckoutEnvioPageState();
}

class _CheckoutEnvioPageState extends State<CheckoutEnvioPage> {
  final _service = DeliveryOptionsService();

  List<CheckoutFarmer> _farmers = [];
  bool _cargando = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() { _cargando = true; _errorMsg = null; });
    try {
      // Primary source: checkout options endpoint returns all farmers + options
      final farmerOptions = await _service.obtenerCheckoutOptions();
      _buildFarmersFromOptions(farmerOptions);
    } catch (e) {
      // Fallback: build from cart items and call per-farmer endpoint
      await _cargarDesdeCarrito();
    }
    if (mounted) setState(() => _cargando = false);
  }

  void _buildFarmersFromOptions(List<CheckoutFarmerOptions> farmerOptions) {
    // Group cart items by farmerUsername for product summary
    final cartItems = CarritoManager().items;
    final Map<String, List<CarritoItem>> grouped = {};
    for (final item in cartItems) {
      grouped.putIfAbsent(item.producto.nombreVendedor, () => []).add(item);
    }

    _farmers = farmerOptions.map((fo) {
      // Try to match cart items by username; fall back to all items if no match
      final items = grouped[fo.farmerUsername] ??
          grouped.values.expand((x) => x).toList();

      final checkoutItems = items
          .map((ci) => CheckoutItemData(
                productName: ci.producto.nombre,
                cantidad: ci.cantidad.toDouble(),
                unidad: ci.formatoVenta == 'Caja' ? 'Caja' : 'Kg',
                precioUnitario: ci.precioUnitario,
              ))
          .toList();

      final farmer = CheckoutFarmer(
        farmerUsername: fo.farmerUsername,
        farmerName: fo.farmerDisplayName,
        farmerAvatarUrl: fo.farmerAvatarUrl,
        items: checkoutItems,
        productsTotal: items.fold(0.0, (s, i) => s + i.total),
        availableOptions: fo.options,
        selectedOptionIndex: fo.options.isNotEmpty ? 0 : -1,
      );
      return farmer;
    }).toList();
  }

  Future<void> _cargarDesdeCarrito() async {
    final cartItems = CarritoManager().items;
    final Map<String, List<CarritoItem>> grouped = {};
    for (final item in cartItems) {
      grouped.putIfAbsent(item.producto.nombreVendedor, () => []).add(item);
    }

    final farmers = grouped.entries.map((e) {
      final items = e.value;
      return CheckoutFarmer(
        farmerUsername: e.key,
        farmerAvatarUrl: items.first.producto.urlAvatarVendedor,
        items: items
            .map((ci) => CheckoutItemData(
                  productName: ci.producto.nombre,
                  cantidad: ci.cantidad.toDouble(),
                  unidad: ci.formatoVenta == 'Caja' ? 'Caja' : 'Kg',
                  precioUnitario: ci.precioUnitario,
                ))
            .toList(),
        productsTotal: items.fold(0.0, (s, i) => s + i.total),
      );
    }).toList();

    // Fetch options per farmer (only if username is non-empty)
    await Future.wait(farmers.map((f) => _cargarOpcionesFarmer(f)));
    _farmers = farmers;
  }

  Future<void> _cargarOpcionesFarmer(CheckoutFarmer farmer) async {
    if (farmer.farmerUsername.isEmpty) return;
    try {
      final opts = await _service.obtenerOpciones(farmer.farmerUsername);
      if (opts.farmerDisplayName != null && opts.farmerDisplayName!.isNotEmpty) {
        farmer.farmerName = opts.farmerDisplayName!;
      }
      if (opts.farmerAvatarUrl != null && opts.farmerAvatarUrl!.isNotEmpty) {
        farmer.farmerAvatarUrl = opts.farmerAvatarUrl!;
      }
      farmer.availableOptions = opts.options;
      farmer.selectedOptionIndex = opts.options.isNotEmpty ? 0 : -1;
    } catch (_) {}
  }

  bool get _todosSeleccionados =>
      _farmers.isNotEmpty &&
      _farmers.every((f) => f.selectedOptionIndex >= 0);

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
          'Método de envío',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildStepIndicator(1),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMsg!,
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cargarTodo,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CA399)),
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    if (_farmers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No hay productos en el carrito.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: _farmers.map((f) => _buildFarmerCard(f)).toList(),
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
          _buildFarmerHeader(farmer),
          const SizedBox(height: 12),
          const Text(
            'Elige como recibir',
            style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          _buildOptionsRow(farmer),
        ],
      ),
    );
  }

  Widget _buildOptionsRow(CheckoutFarmer farmer) {
    final options = farmer.availableOptions.isNotEmpty
        ? farmer.availableOptions
        : [
            const DeliveryOption(type: 'PICKUP', cost: 0),
            const DeliveryOption(type: 'DELIVERY', cost: 0),
          ];

    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _buildOptionCard(farmer: farmer, option: options[i], index: i),
          ),
        ],
      ],
    );
  }

  Widget _buildFarmerHeader(CheckoutFarmer farmer) {
    return Row(
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
                farmer.itemsSummary,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required CheckoutFarmer farmer,
    required DeliveryOption option,
    required int index,
  }) {
    final selected = farmer.selectedOptionIndex == index;
    return GestureDetector(
      onTap: () => setState(() => farmer.selectedOptionIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF5CA399) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              option.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF1E3A32) : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              option.subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Text(
              option.cost > 0
                  ? 'S/. ${option.cost.toStringAsFixed(0)}'
                  : 'S/. —',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF5CA399) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: !_cargando && _todosSeleccionados
              ? () => Navigator.pushNamed(
                    context,
                    '/checkout_direccion',
                    arguments: _farmers,
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CA399),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: const Text(
            'Siguiente',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
