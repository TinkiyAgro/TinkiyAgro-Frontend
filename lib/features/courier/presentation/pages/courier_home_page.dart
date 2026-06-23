import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/offline/sync_coordinator.dart';
import '../../data/courier_delivery_repository.dart';
import '../../data/courier_model.dart';
import 'package:tinkiyagro_app/features/orders/data/remote/location_tracking_service.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/driver_profile_page.dart';

class CourierHomePage extends StatefulWidget {
  const CourierHomePage({super.key});

  @override
  State<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  final _repository = CourierDeliveryRepository.instance;
  StreamSubscription<List<CourierDeliveryGroup>>? _deliveriesSubscription;
  StreamSubscription<DateTime?>? _lastSyncSubscription;

  int _tabIndex = 0; // 0: Entregas, 1: Perfil
  int _filterIndex = 0;
  static const _filters = ['Todo', 'En curso', 'Entregados'];
  List<CourierDeliveryGroup> _groups = [];
  bool _loading = true;
  bool _syncing = false;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _deliveriesSubscription = _repository.watchDeliveries().listen((groups) {
      if (mounted) {
        setState(() {
          _groups = groups;
          _loading = false;
        });
      }
    });
    _lastSyncSubscription = _repository.watchLastSyncedAt().listen((value) {
      if (mounted) setState(() => _lastSyncedAt = value);
    });
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LocationTrackingService().requestPermission();
    });
  }

  @override
  void dispose() {
    _deliveriesSubscription?.cancel();
    _lastSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await SyncCoordinator.instance.syncNow(force: true);
    } catch (_) {
      // Las entregas descargadas permanecen disponibles.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _tabIndex == 0 ? _buildEntregasTab() : const DriverProfilePage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF5CA399),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined, size: 26),
            activeIcon: Icon(Icons.local_shipping, size: 26),
            label: 'Entregas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildEntregasTab() {
    final filtered = _filterIndex == 0
        ? _groups
        : _groups
              .where(
                (g) => _filterIndex == 1
                    ? g.status == 'En curso'
                    : g.status == 'Entregado',
              )
              .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TINKIAGRO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A32),
                    letterSpacing: 0.5,
                  ),
                ),
                IconButton(
                  tooltip: 'Sincronizar',
                  onPressed: _syncing ? null : _load,
                  icon: _syncing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
            child: Text(
              _lastSyncedAt == null
                  ? 'Sin sincronización previa'
                  : 'Última sincronización: ${_formatDate(_lastSyncedAt!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterTabs(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Entregas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(child: _buildListBody(filtered)),
        ],
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

  Widget _buildListBody(List<CourierDeliveryGroup> filtered) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No hay entregas en esta categoría.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF5CA399),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _buildGroupCard(filtered[i]),
      ),
    );
  }

  Widget _buildGroupCard(CourierDeliveryGroup group) {
    final entregado = group.status == 'Entregado';
    return GestureDetector(
      onTap: entregado
          ? null
          : () => Navigator.pushNamed(
              context,
              '/courier_delivery',
              arguments: group,
            ).then((_) => _load()),
      child: Opacity(
        opacity: entregado ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
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
              // Farmer header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFF5CA399),
                    backgroundImage: group.farmerImageUrl.isNotEmpty
                        ? NetworkImage(group.farmerImageUrl)
                        : null,
                    child: group.farmerImageUrl.isEmpty
                        ? Text(
                            group.farmerName.isNotEmpty
                                ? group.farmerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.farmerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${group.customers.length} pedido${group.customers.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (group.location.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  group.fullAddress,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (entregado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Entregado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5CA399),
                        ),
                      ),
                    )
                  else
                    _buildTypeBadge(group.groupType),
                ],
              ),
              const SizedBox(height: 8),
              // Customers
              ...group.customers.map((c) => _buildCustomerRow(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerRow(CourierCustomer customer) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: customer.clientColor,
            backgroundImage: customer.customerProfileImageUrl.isNotEmpty
                ? NetworkImage(customer.customerProfileImageUrl)
                : null,
            child: customer.customerProfileImageUrl.isEmpty
                ? Text(
                    customer.clientInitial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
                  customer.clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                ...customer.items.map(
                  (i) => Text(
                    '${i.productName} × ${i.quantity}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
