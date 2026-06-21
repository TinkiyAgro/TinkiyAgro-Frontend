import 'package:flutter/material.dart';
import '../../data/pickup_point_model.dart';
import '../../data/remote/pickup_point_service.dart';
import 'farmer_pickup_point_form_page.dart';

class FarmerEntregasPage extends StatefulWidget {
  const FarmerEntregasPage({super.key});

  @override
  State<FarmerEntregasPage> createState() => _FarmerEntregasPageState();
}

class _FarmerEntregasPageState extends State<FarmerEntregasPage> {
  final _service = PickupPointService();
  final _searchCtrl = TextEditingController();

  List<PuntoRecojo> _puntos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _service.listar();
      if (mounted) setState(() => _puntos = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar puntos: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  List<PuntoRecojo> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _puntos;
    return _puntos
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.address.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _eliminar(PuntoRecojo punto) async {
    try {
      await _service.eliminar(punto.id);
      setState(() => _puntos.removeWhere((p) => p.id == punto.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Punto de recojo eliminado.'),
            backgroundColor: Color(0xFF5CA399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _abrirFormulario({PuntoRecojo? punto}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FarmerPickupPointFormPage(puntoEditar: punto),
      ),
    );
    if (result == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Mis entregas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Buscar',
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF5CA399)))
                    : _filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 64,
                                    color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                Text(
                                  'No tienes puntos de recojo.',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade500),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Toca + para agregar uno.',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _cargar,
                            color: const Color(0xFF5CA399),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) =>
                                  _buildEntregaCard(_filtered[i]),
                            ),
                          ),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              backgroundColor: const Color(0xFF5CA399),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregaCard(PuntoRecojo punto) {
    return GestureDetector(
      onTap: () => _showDetailModal(punto),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            Text(
              punto.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              punto.deliveryDate.isNotEmpty
                  ? PuntoRecojo.formatDate(punto.deliveryDate)
                  : '—',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5CA399),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_horaCorta(punto.availableFrom)} - ${_horaCorta(punto.availableTo)}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Estado: ${punto.activo ? "Activo" : "Inactivo"}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailModal(PuntoRecojo punto) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                punto.name,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                punto.address,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Fecha de entrega',
                punto.deliveryDate.isNotEmpty
                    ? PuntoRecojo.formatDate(punto.deliveryDate)
                    : '—',
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                'Hora',
                '${_horaCorta(punto.availableFrom)} - ${_horaCorta(punto.availableTo)}',
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                'Cierre de pedidos',
                '${punto.orderDeadlineDate.isNotEmpty ? PuntoRecojo.formatDate(punto.orderDeadlineDate) : '—'} ${_horaCorta(punto.orderDeadlineTime)}',
              ),
              const SizedBox(height: 6),
              _buildDetailRow(
                  'Estado', punto.activo ? 'Activo' : 'Inactivo'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDelete(punto);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text('Eliminar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _abrirFormulario(punto: punto);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CA399),
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: const Text('Editar',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  void _confirmDelete(PuntoRecojo punto) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar punto de recojo'),
        content: Text('¿Eliminar "${punto.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminar(punto);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _horaCorta(String t) {
    final parts = t.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return t;
  }
}

// Stub para compatibilidad con la ruta '/farmer_entrega_form' en main.dart
class FarmerEntregaFormPage extends StatelessWidget {
  const FarmerEntregaFormPage({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
