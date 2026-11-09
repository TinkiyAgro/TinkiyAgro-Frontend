import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/offline/sync_coordinator.dart';
import '../../../../core/offline/sync_types.dart';
import '../../data/offline_pickup_point.dart';
import '../../data/pickup_point_model.dart';
import '../../data/pickup_point_repository.dart';
import 'farmer_pickup_point_form_page.dart';

class FarmerPickupPointsPage extends StatefulWidget {
  const FarmerPickupPointsPage({super.key});

  @override
  State<FarmerPickupPointsPage> createState() => _FarmerPickupPointsPageState();
}

class _FarmerPickupPointsPageState extends State<FarmerPickupPointsPage> {
  final _repository = PickupPointRepository.instance;
  StreamSubscription<List<OfflinePickupPoint>>? _pointsSubscription;
  StreamSubscription<int>? _pendingSubscription;
  StreamSubscription<DateTime?>? _lastSyncSubscription;
  List<OfflinePickupPoint> _points = const [];
  bool _loading = true;
  bool _syncing = false;
  int _pendingCount = 0;
  DateTime? _lastSyncedAt;

  @override
  void initState() {
    super.initState();
    _pointsSubscription = _repository.watchPickupPoints().listen((points) {
      if (mounted) {
        setState(() {
          _points = points;
          _loading = false;
        });
      }
    });
    _pendingSubscription = _repository.watchPendingCount().listen((count) {
      if (mounted) setState(() => _pendingCount = count);
    });
    _lastSyncSubscription = _repository.watchLastSyncedAt().listen((value) {
      if (mounted) setState(() => _lastSyncedAt = value);
    });
    unawaited(_sync());
  }

  @override
  void dispose() {
    _pointsSubscription?.cancel();
    _pendingSubscription?.cancel();
    _lastSyncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadLastSync() async {
    final value = await _repository.getLastSyncedAt();
    if (mounted) setState(() => _lastSyncedAt = value);
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await SyncCoordinator.instance.syncNow(force: true);
      await _loadLastSync();
    } catch (_) {
      // Cached points remain available.
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _delete(PuntoRecojo point) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar punto de recojo'),
        content: Text('¿Eliminar "${point.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.deletePickupPoint(point.id);
    }
  }

  Future<void> _openForm({PuntoRecojo? point}) {
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerPickupPointFormPage(puntoEditar: point),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Puntos de recojo'),
        actions: [
          IconButton(
            tooltip: 'Sincronizar',
            onPressed: _syncing ? null : _sync,
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
          IconButton(
            tooltip: 'Agregar punto',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              _lastSyncedAt == null
                  ? 'Sin sincronización previa'
                  : 'Última sincronización: ${_formatDate(_lastSyncedAt!)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          Expanded(
            child: _loading && _points.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _points.isEmpty
                ? const Center(child: Text('No tienes puntos de recojo.'))
                : RefreshIndicator(
                    onRefresh: _sync,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _points.length,
                      itemBuilder: (_, index) => _buildCard(_points[index]),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Agregar punto',
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFF5CA399),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(OfflinePickupPoint item) {
    final point = item.pickupPoint;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openForm(point: point),
        leading: Icon(
          Icons.location_on,
          color: point.activo ? const Color(0xFF5CA399) : Colors.grey,
        ),
        title: Text(
          point.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(point.address, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (point.city.isNotEmpty) Text(point.city),
            Text(point.horario),
            if (item.syncState != EntitySyncState.synced)
              _syncLabel(item.syncState),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _openForm(point: point);
            if (value == 'delete') _delete(point);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }

  Widget _syncLabel(EntitySyncState state) {
    final (label, color) = switch (state) {
      EntitySyncState.pending => ('Pendiente de sincronización', Colors.orange),
      EntitySyncState.failed => ('Sincronización fallida', Colors.red),
      EntitySyncState.conflict => ('Requiere revisión', Colors.red),
      EntitySyncState.synced => ('Sincronizado', Colors.green),
    };
    return Text(label, style: TextStyle(fontSize: 11, color: color));
  }

  String _formatDate(DateTime value) {
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)} '
        '${two(value.hour)}:${two(value.minute)}';
  }
}
