import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/offline/sync_coordinator.dart';
import '../../../../core/offline/sync_types.dart';
import '../../../../shared/presentation/widgets/product_image.dart';
import '../../data/farmer_product_repository.dart';
import '../../data/offline_farmer_product.dart';
import '../widgets/farmer_product_detail_dialog.dart';

class FarmerProductsPage extends StatefulWidget {
  const FarmerProductsPage({super.key});

  @override
  State<FarmerProductsPage> createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  final _repository = FarmerProductRepository.instance;
  StreamSubscription<List<OfflineFarmerProduct>>? _productsSubscription;
  StreamSubscription<int>? _pendingSubscription;
  List<OfflineFarmerProduct> _products = const [];
  String _searchQuery = '';
  bool _loading = true;
  bool _syncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;

  List<OfflineFarmerProduct> get _filtered {
    if (_searchQuery.isEmpty) return _products;
    final query = _searchQuery.toLowerCase();
    return _products
        .where(
          (item) =>
              item.product.nombre.toLowerCase().contains(query) ||
              item.product.descripcion.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _productsSubscription = _repository.watchProducts().listen(
      (products) {
        if (!mounted) return;
        setState(() {
          _products = products;
          _loading = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loading = false);
      },
    );
    _pendingSubscription = _repository.watchPendingCount().listen((count) {
      if (mounted) setState(() => _pendingCount = count);
    });
    unawaited(_loadLastSync());
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _pendingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLastSync() async {
    final value = await _repository.getLastSyncedAt();
    if (mounted) setState(() => _lastSyncedAt = value);
  }

  Future<void> _refresh() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await SyncCoordinator.instance.syncNow(force: true);
      await _loadLastSync();
    } catch (_) {
      // The cached list remains usable when the server is unavailable.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'TINKIAGRO',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A32),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sincronizar',
                    onPressed: _syncing ? null : _refresh,
                    icon: _syncing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Badge(
                            isLabelVisible: _pendingCount > 0,
                            label: Text('$_pendingCount'),
                            child: const Icon(Icons.sync),
                          ),
                  ),
                ],
              ),
              Text(
                _lastSyncedAt == null
                    ? 'Sin sincronización previa'
                    : 'Última sincronización: ${_formatDate(_lastSyncedAt!)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF5CA399),
                  ),
                  hintText: 'Buscar',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mis productos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading && _products.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No tienes productos guardados.'
                              : 'Sin resultados para "$_searchQuery".',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        child: ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, index) =>
                              _buildProductCard(filtered[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_product');
        },
        tooltip: 'Agregar producto',
        backgroundColor: const Color(0xFF5CA399),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildProductCard(OfflineFarmerProduct item) {
    final product = item.product;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showDialog<void>(
          context: context,
          builder: (_) => FarmerProductDetailDialog(product: product),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.square(
                  dimension: 64,
                  child: ProductImage(source: product.urlImagen, size: 64),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'S/. ${product.precio.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFF4A7C73)),
                    ),
                    const SizedBox(height: 5),
                    _productStatus(product.productStatus),
                    if (item.syncState != EntitySyncState.synced) ...[
                      const SizedBox(height: 5),
                      _syncLabel(item.syncState),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _productStatus(String rawStatus) {
    final normalized = rawStatus.trim().toUpperCase();
    final available = normalized == 'DISPONIBLE' || normalized == 'ACTIVE';
    final label = switch (normalized) {
      'DISPONIBLE' || 'ACTIVE' => 'Disponible',
      'AGOTADO' || 'OUT_OF_STOCK' => 'Agotado',
      'INACTIVO' || 'INACTIVE' => 'Inactivo',
      _ => normalized.isEmpty ? 'Sin estado' : rawStatus,
    };
    final color = available ? Colors.green.shade700 : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _syncLabel(EntitySyncState state) {
    final (text, color, icon) = switch (state) {
      EntitySyncState.pending => (
        'Pendiente de sincronización',
        Colors.orange.shade800,
        Icons.schedule,
      ),
      EntitySyncState.failed => (
        'Sincronización fallida',
        Colors.red.shade700,
        Icons.sync_problem,
      ),
      EntitySyncState.conflict => (
        'Requiere revisión',
        Colors.red.shade900,
        Icons.warning_amber,
      ),
      EntitySyncState.synced => (
        'Sincronizado',
        Colors.green,
        Icons.cloud_done,
      ),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(text, style: TextStyle(fontSize: 11, color: color)),
        ),
      ],
    );
  }

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} ${two(value.hour)}:${two(value.minute)}';
  }
}
