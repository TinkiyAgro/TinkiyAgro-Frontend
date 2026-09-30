import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/constants/app_constants.dart';
import 'package:tinkiyagro_app/core/offline/sync_coordinator.dart';
import 'package:tinkiyagro_app/core/offline/sync_types.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/location_tracking_service.dart';
import '../../data/farmer_order_model.dart';
import '../../data/farmer_order_repository.dart';
import '../../data/offline_farmer_order_group.dart';
import '../../data/remote/farmer_order_service.dart';

class FarmerOrdersPage extends StatefulWidget {
  const FarmerOrdersPage({super.key});

  @override
  State<FarmerOrdersPage> createState() => _FarmerOrdersPageState();
}

class _FarmerOrdersPageState extends State<FarmerOrdersPage> {
  final _service = FarmerOrderService();
  final _repository = FarmerOrderRepository.instance;
  StreamSubscription<List<OfflineFarmerOrderGroup>>? _groupsSubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<DateTime?>? _lastSyncSubscription;

  List<FarmerOrderGroup> _allGroups = [];
  Map<String, EntitySyncState> _syncStates = const {};
  bool _cargando = true;
  bool _sincronizando = false;
  int _pendientes = 0;
  DateTime? _ultimaSincronizacion;
  int _filterIndex = 0;
  final Set<String> _asignandoDespacho = {};
  static const _filters = ['Todo', 'Por preparar', 'En camino', 'Entregado'];

  @override
  void initState() {
    super.initState();
    _groupsSubscription = _repository.watchGroups().listen((items) {
      if (!mounted) return;
      final expandedByGroup = {
        for (final group in _allGroups) group.id: group.isExpanded,
      };
      final nextGroups = items.map((item) {
        final group = item.group;
        group.isExpanded = expandedByGroup[group.id] ?? false;
        return group;
      }).toList();
      setState(() {
        _allGroups = nextGroups;
        _syncStates = {for (final item in items) item.group.id: item.syncState};
        _cargando = false;
      });
    });
    _pendingSubscription = _repository.watchPendingCount().listen((count) {
      if (mounted) setState(() => _pendientes = count);
    });
    _lastSyncSubscription = _repository.watchLastSyncedAt().listen((value) {
      if (mounted) setState(() => _ultimaSincronizacion = value);
    });
    _cargar();
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    _pendingSubscription?.cancel();
    _lastSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (_sincronizando) return;
    setState(() => _sincronizando = true);
    try {
      await SyncCoordinator.instance.syncNow(force: true);
    } catch (_) {
      // Los pedidos descargados permanecen disponibles.
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  List<FarmerOrderGroup> get _groups {
    switch (_filterIndex) {
      case 0:
        return _allGroups;
      // "Por preparar" includes porPreparar and seleccionandoDespacho (not yet dispatched)
      case 1:
        return _allGroups
            .where(
              (g) =>
                  g.state == OrderGroupState.porPreparar ||
                  g.state == OrderGroupState.seleccionandoDespacho,
            )
            .toList();
      case 2:
        return _allGroups
            .where((g) => g.state == OrderGroupState.despachado)
            .toList();
      case 3:
        return _allGroups
            .where((g) => g.state == OrderGroupState.entregado)
            .toList();
      default:
        return _allGroups;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 6),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pedidos',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Sincronizar',
                  onPressed: _sincronizando ? null : _cargar,
                  icon: _sincronizando
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Badge(
                          isLabelVisible: _pendientes > 0,
                          label: Text('$_pendientes'),
                          child: const Icon(Icons.sync),
                        ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(
              _ultimaSincronizacion == null
                  ? 'Sin sincronización previa'
                  : 'Última sincronización: '
                        '${_formatearFecha(_ultimaSincronizacion!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          _buildFilterTabs(),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  List<String> _subOrderIds(FarmerOrderGroup group) => group.clientes
      .expand((c) => c.subOrderIds)
      .where((id) => id.isNotEmpty)
      .toList();

  Future<void> _asignarYoMismo(FarmerOrderGroup group) async {
    final ids = _subOrderIds(group);
    if (ids.isEmpty || _asignandoDespacho.contains(group.id)) return;
    debugPrint('[FarmerPage] _asignarYoMismo ids=$ids');
    final previousType = group.despachoType;
    final previousName = group.repartidorNombre;
    final previousUsername = group.repartidorUsername;
    setState(() {
      _asignandoDespacho.add(group.id);
      group.despachoType = 'Yo mismo';
      group.repartidorNombre = null;
      group.repartidorUsername = null;
    });
    try {
      await _service.asignarDespachador(ids, 'FARMER');
      debugPrint('[FarmerPage] _asignarYoMismo OK');
    } catch (e) {
      debugPrint('[FarmerPage] _asignarYoMismo ERROR: $e');
      if (mounted) {
        setState(() {
          group.despachoType = previousType;
          group.repartidorNombre = previousName;
          group.repartidorUsername = previousUsername;
        });
      }
      _mostrarError('Error al asignar despachador: $e');
    } finally {
      if (mounted) setState(() => _asignandoDespacho.remove(group.id));
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
    final ids = _subOrderIds(group);
    try {
      await _repository.markPrepared(group.id, ids);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Preparación guardada. El despacho se habilitará cuando el servidor la confirme.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
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
                    border: Border.all(
                      color: const Color(0xFF5CA399),
                      width: 1.5,
                    ),
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
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      group.pickupSchedule.isNotEmpty
                          ? group.pickupSchedule
                          : '${group.diaEntrega} • ${group.horaEntrega}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
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
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 16,
                        ),
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
                            const Text(
                              '• ',
                              style: TextStyle(color: Colors.white),
                            ),
                            Expanded(
                              child: Text(
                                p.nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
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
            else if (group.state == OrderGroupState.seleccionandoDespacho &&
                _syncStates[group.id] == EntitySyncState.synced)
              _buildDispatchSection(group)
            else if (group.state == OrderGroupState.seleccionandoDespacho)
              _buildOfflineStatus(
                _syncStates[group.id] ?? EntitySyncState.pending,
                onRetry: _sincronizando ? null : _cargar,
              )
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

  Widget _buildCustomerRow(
    FarmerOrderGroup group,
    FarmerCustomerOrder customer,
  ) {
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
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  ...customer.items.map(
                    (i) => Text(
                      '${i.productName} × ${i.cantidad}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
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
                child: _buildDispatchTypeButton(
                  group,
                  'Yo mismo',
                  Icons.person_outline,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDispatchTypeButton(
                  group,
                  'Repartidor',
                  Icons.local_shipping_outlined,
                ),
              ),
            ],
          ),
          if (group.despachoType == 'Repartidor') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showAssignRepartidorDialog(group),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
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
                      group.repartidorNombre != null
                          ? 'Cambiar'
                          : 'Seleccionar',
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
    FarmerOrderGroup group,
    String type,
    IconData icon,
  ) {
    final selected = group.despachoType == type;
    final assigning = _asignandoDespacho.contains(group.id);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (assigning) return;
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
            if (assigning && selected)
              const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
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

  Widget _buildOfflineStatus(
    EntitySyncState state, {
    required VoidCallback? onRetry,
  }) {
    final conflict = state == EntitySyncState.conflict;
    final failed = state == EntitySyncState.failed;
    final color = conflict ? Colors.red.shade800 : Colors.orange.shade900;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: conflict ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_sincronizando && !conflict)
                SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(
                  conflict ? Icons.warning_amber : Icons.schedule,
                  size: 18,
                  color: conflict ? Colors.red : Colors.orange.shade800,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  conflict
                      ? 'El servidor rechazó la preparación. Revisa el estado del pedido.'
                      : _sincronizando
                      ? 'Confirmando la preparación con el servidor...'
                      : failed
                      ? 'Sin conexión. El despacho se habilitará cuando la preparación se sincronice.'
                      : 'Preparación guardada. Esperando confirmación del servidor para habilitar el despacho.',
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ],
          ),
          if (!conflict) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.sync, size: 17),
                label: Text(
                  _sincronizando ? 'Sincronizando' : 'Sincronizar ahora',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatearFecha(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
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
              setDialogState(() {
                results = [];
                searching = false;
              });
              return;
            }
            setDialogState(() => searching = true);
            try {
              final found = await _service.buscarRepartidor(query.trim());
              setDialogState(() {
                results = found;
                searching = false;
              });
            } catch (e) {
              debugPrint('[Dialog] buscarRepartidor error: $e');
              setDialogState(() {
                results = [];
                searching = false;
              });
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
                        vertical: 10,
                        horizontal: 14,
                      ),
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
                          color: Color(0xFF5CA399),
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  else if (searchCtrl.text.trim().isNotEmpty && results.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No se encontraron repartidores',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else if (searchCtrl.text.trim().isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Escribe para buscar un repartidor',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: SingleChildScrollView(
                        child: Column(
                          children: results
                              .map(
                                (r) => GestureDetector(
                                  onTap: () => setDialogState(() {
                                    selectedUsername = r.username;
                                    selectedNombre = r.nombre;
                                  }),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
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
                                          backgroundColor:
                                              selectedUsername == r.username
                                              ? const Color(0xFF5CA399)
                                              : Colors.grey.shade300,
                                          backgroundImage:
                                              r.profileImageUrl.isNotEmpty
                                              ? NetworkImage(r.profileImageUrl)
                                              : null,
                                          child: r.profileImageUrl.isEmpty
                                              ? Text(
                                                  r.nombre.isNotEmpty
                                                      ? r.nombre[0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color:
                                                        selectedUsername ==
                                                            r.username
                                                        ? Colors.white
                                                        : Colors.black87,
                                                  ),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                r.nombre,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                r.telefono != null
                                                    ? '@${r.username} • ${r.telefono}'
                                                    : '@${r.username}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
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
                              )
                              .toList(),
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
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              } catch (e) {
                                setDialogState(() => assigning = false);
                                if (mounted) {
                                  _mostrarError(
                                    'Error al asignar repartidor: $e',
                                  );
                                }
                              }
                            },
                      icon: assigning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
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
