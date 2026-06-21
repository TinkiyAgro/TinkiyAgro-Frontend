import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/location_tracking_service.dart';
import '../../data/farmer_order_model.dart';
import '../../data/remote/farmer_order_service.dart';

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key});

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> {
  final _service = FarmerOrderService();

  List<FarmerOrderGroup> _allGroups = [];
  bool _cargando = true;
  String? _error;
  int _filterIndex = 0;
  static const _filters = ['Todo', 'Por preparar', 'En camino', 'Entregado'];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final groups = await _service.listarGrupos();
      if (mounted) setState(() => _allGroups = groups);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<FarmerOrderGroup> get _groups {
    switch (_filterIndex) {
      case 0: return _allGroups;
      // "Por preparar" includes porPreparar and seleccionandoDespacho (not yet dispatched)
      case 1: return _allGroups.where((g) =>
          g.state == OrderGroupState.porPreparar ||
          g.state == OrderGroupState.seleccionandoDespacho).toList();
      case 2: return _allGroups.where((g) => g.state == OrderGroupState.despachado).toList();
      case 3: return _allGroups.where((g) => g.state == OrderGroupState.entregado).toList();
      default: return _allGroups;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Pedidos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          _buildFilterTabs(),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  List<String> _subOrderIds(FarmerOrderGroup group) =>
      group.clientes.map((c) => c.subOrderId).where((id) => id.isNotEmpty).toList();

  Future<void> _asignarYoMismo(FarmerOrderGroup group) async {
    final ids = _subOrderIds(group);
    debugPrint('[FarmerPage] _asignarYoMismo ids=$ids');
    try {
      await _service.asignarDespachador(ids, 'FARMER');
      debugPrint('[FarmerPage] _asignarYoMismo OK');
      if (mounted) setState(() => group.despachoType = 'Yo mismo');
    } catch (e) {
      debugPrint('[FarmerPage] _asignarYoMismo ERROR: $e');
      _mostrarError('Error al asignar despachador: $e');
    }
  }

  Future<void> _confirmarDespacho(FarmerOrderGroup group) async {
    final ids = _subOrderIds(group);
    debugPrint('[FarmerPage] _confirmarDespacho ids=$ids');
    try {
      await _service.confirmarDespacho(ids);
      debugPrint('[FarmerPage] _confirmarDespacho OK');
      if (mounted) setState(() => group.state = OrderGroupState.despachado);

      if (group.despachoType == 'Yo mismo') {
        final tracking = LocationTrackingService();
        final granted = await tracking.requestPermission();
        if (granted) {
          tracking.start(
            subOrderIds: ids,
            endpointTemplate: AppConstants.updateDeliveryStatusFarmerEndpoint,
          );
        }
      }
    } catch (e) {
      debugPrint('[FarmerPage] _confirmarDespacho ERROR: $e');
      _mostrarError('Error al confirmar despacho: $e');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _marcarPreparado(FarmerOrderGroup group) async {
    final ids = group.clientes.map((c) => c.subOrderId).where((id) => id.isNotEmpty).toList();
    try {
      await _service.marcarPreparado(ids);
      if (mounted) setState(() => group.state = OrderGroupState.seleccionandoDespacho);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: ${e.toString()}'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text('No se pudieron cargar los pedidos',
                style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CA399),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_groups.isEmpty) {
      return Center(
        child: Text(
          'Sin pedidos en esta categoría',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF5CA399),
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _groups.length,
        itemBuilder: (context, i) => _buildGroupCard(_groups[i]),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF5CA399) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? const Color(0xFF5CA399)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(FarmerOrderGroup group) {
    final isDelivery = group.deliveryMethod == 'DELIVERY';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDelivery
                        ? const Color(0xFFE8D5F5)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isDelivery ? 'Delivery' : 'Punto de acopio',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDelivery
                          ? const Color(0xFF7B2D8B)
                          : Colors.black87,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF5CA399), width: 1.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      group.isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF5CA399),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() => group.isExpanded = !group.isExpanded);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(
              isDelivery ? group.direccion : group.nombrePunto,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          if (!isDelivery)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    '${group.diaEntrega} • ${group.horaEntrega}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 10),

          if (group.isExpanded) ...[
            // ── Pedidos count + total ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${group.numPedidos} ${group.numPedidos == 1 ? 'pedido' : 'pedidos'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    'Total: S/. ${group.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Customer list ─────────────────────────────────────────────
            ...group.clientes.map((c) => _buildCustomerRow(group, c)),

            const SizedBox(height: 8),

            // ── A preparar section ───────────────────────────────────────────
            if (group.state == OrderGroupState.porPreparar)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CA399),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'A preparar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...group.productosAPreparar.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(color: Colors.white)),
                            Expanded(
                              child: Text(
                                p.nombre,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                            Text(
                              p.cantidad,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // ── Action area ───────────────────────────────────────────────
            if (group.state == OrderGroupState.porPreparar)
              _buildActionButton(
                'Marcar como preparado',
                () => _marcarPreparado(group),
              )
            else if (group.state == OrderGroupState.seleccionandoDespacho)
              _buildDispatchSection(group)
            else if (group.state == OrderGroupState.despachado)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildActionButton(
                  'Gestionar entregas',
                  () => Navigator.pushNamed(
                    context,
                    group.despachoType == 'Repartidor'
                        ? '/farmer_courier_status'
                        : '/farmer_delivery_confirm',
                    arguments: group,
                  ),
                ),
              )
            else
              const SizedBox(height: 4),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${group.numPedidos} ${group.numPedidos == 1 ? 'pedido' : 'pedidos'}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  Text(
                    'Total: S/. ${group.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerRow(FarmerOrderGroup group, FarmerCustomerOrder customer) {
    return GestureDetector(
      onTap: null,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: customer.clienteColor,
              backgroundImage: customer.customerProfileImageUrl.isNotEmpty
                  ? NetworkImage(customer.customerProfileImageUrl)
                  : null,
              child: customer.customerProfileImageUrl.isEmpty
                  ? Text(
                      customer.clienteInicial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  ...customer.items.map((i) => Text(
                    '${i.productName} × ${i.cantidad}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  )),
                ],
              ),
            ),
            Text(
              'S/. ${customer.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDispatchSection(FarmerOrderGroup group) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿Quién despachará?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDispatchTypeButton(group, 'Yo mismo', Icons.person_outline),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDispatchTypeButton(
                    group, 'Repartidor', Icons.local_shipping_outlined),
              ),
            ],
          ),
          if (group.despachoType == 'Repartidor') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAssignRepartidorDialog(group),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CA399),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (group.repartidorNombre ?? 'R')[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group.repartidorNombre ?? 'Sin asignar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      group.repartidorNombre != null ? 'Cambiar' : 'Seleccionar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _buildActionButton(
            'Confirmar despacho',
            group.despachoType.isEmpty ? null : () => _confirmarDespacho(group),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchTypeButton(
      FarmerOrderGroup group, String type, IconData icon) {
    final selected = group.despachoType == type;
    return GestureDetector(
      onTap: () {
        if (type == 'Yo mismo') {
          _asignarYoMismo(group);
        } else {
          setState(() => group.despachoType = type);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5CA399) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xFF5CA399) : Colors.black54,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              type,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: selected ? const Color(0xFF5CA399) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CA399),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showAssignRepartidorDialog(FarmerOrderGroup group) {
    String? selectedUsername = group.repartidorUsername;
    String? selectedNombre = group.repartidorNombre;
    final searchCtrl = TextEditingController();
    List<RepartidorInfo> results = [];
    bool searching = false;
    bool assigning = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> doSearch(String query) async {
            if (query.trim().isEmpty) {
              setDialogState(() { results = []; searching = false; });
              return;
            }
            setDialogState(() => searching = true);
            try {
              final found = await _service.buscarRepartidor(query.trim());
              setDialogState(() { results = found; searching = false; });
            } catch (e) {
              debugPrint('[Dialog] buscarRepartidor error: $e');
              setDialogState(() { results = []; searching = false; });
            }
          }

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Asignar repartidor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${group.nombrePunto} • ${group.numPedidos} ${group.numPedidos == 1 ? 'pedido' : 'pedidos'} • S/. ${group.total.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: searchCtrl,
                    onChanged: doSearch,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, usuario o teléfono',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (searching)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(
                            color: Color(0xFF5CA399), strokeWidth: 2),
                      ),
                    )
                  else if (searchCtrl.text.trim().isNotEmpty && results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No se encontraron repartidores',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    )
                  else if (searchCtrl.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Escribe para buscar un repartidor',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Column(
                          children: results.map(
                            (r) => GestureDetector(
                              onTap: () => setDialogState(() {
                                selectedUsername = r.username;
                                selectedNombre = r.nombre;
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selectedUsername == r.username
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: selectedUsername == r.username
                                          ? const Color(0xFF5CA399)
                                          : Colors.grey.shade300,
                                      backgroundImage: r.profileImageUrl.isNotEmpty
                                          ? NetworkImage(r.profileImageUrl)
                                          : null,
                                      child: r.profileImageUrl.isEmpty
                                          ? Text(
                                              r.nombre.isNotEmpty ? r.nombre[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: selectedUsername == r.username
                                                    ? Colors.white
                                                    : Colors.black87,
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
                                            r.nombre,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14),
                                          ),
                                          Text(
                                            r.telefono != null
                                                ? '@${r.username} • ${r.telefono}'
                                                : '@${r.username}',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (selectedUsername == r.username)
                                      const Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF5CA399),
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: (selectedUsername == null || assigning)
                          ? null
                          : () async {
                              setDialogState(() => assigning = true);
                              try {
                                final ids = _subOrderIds(group);
                                await _service.asignarDespachador(
                                  ids,
                                  'COURIER',
                                  courierUsername: selectedUsername,
                                );
                                if (mounted) {
                                  setState(() {
                                    group.repartidorNombre = selectedNombre;
                                    group.repartidorUsername = selectedUsername;
                                    group.despachoType = 'Repartidor';
                                  });
                                }
                                if (ctx.mounted) Navigator.pop(ctx);
                              } catch (e) {
                                setDialogState(() => assigning = false);
                                if (mounted) _mostrarError('Error al asignar repartidor: $e');
                              }
                            },
                      icon: assigning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check, size: 16),
                      label: const Text(
                        'Confirmar asignación',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CA399),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: assigning ? null : () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
