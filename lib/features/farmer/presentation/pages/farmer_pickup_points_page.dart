import 'package:flutter/material.dart';
import '../../data/pickup_point_model.dart';
import '../../data/remote/pickup_point_service.dart';
import 'farmer_pickup_point_form_page.dart';

class FarmerPickupPointsPage extends StatefulWidget {
  const FarmerPickupPointsPage({super.key});

  @override
  State<FarmerPickupPointsPage> createState() => _FarmerPickupPointsPageState();
}

class _FarmerPickupPointsPageState extends State<FarmerPickupPointsPage> {
  final _service = PickupPointService();
  List<PuntoRecojo> _puntos = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final lista = await _service.listar();
      setState(() => _puntos = lista);
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

  Future<void> _eliminar(PuntoRecojo punto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar punto de recojo'),
        content: Text('¿Eliminar "${punto.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar != true) return;
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
              backgroundColor: Colors.redAccent),
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
          'Puntos de recojo',
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF5CA399)),
            onPressed: () => _abrirFormulario(),
            tooltip: 'Agregar punto',
          ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CA399)))
          : _puntos.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: const Color(0xFF5CA399),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _puntos.length,
                    itemBuilder: (_, i) => _buildCard(_puntos[i]),
                  ),
                ),
      floatingActionButton: _cargando
          ? null
          : FloatingActionButton(
              onPressed: () => _abrirFormulario(),
              backgroundColor: const Color(0xFF5CA399),
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No tienes puntos de recojo.',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca + para agregar uno.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(PuntoRecojo punto) {
    final activo = punto.activo;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: activo
                ? const Color(0xFFE8F5E9)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.location_on,
            color: activo ? const Color(0xFF5CA399) : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          punto.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(
              punto.address,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              punto.horario,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: activo
                    ? const Color(0xFFE8F5E9)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                activo ? 'Activo' : 'Inactivo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: activo
                      ? const Color(0xFF5CA399)
                      : Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Color(0xFF5CA399), size: 20),
              onPressed: () => _abrirFormulario(punto: punto),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () => _eliminar(punto),
              tooltip: 'Eliminar',
            ),
          ],
        ),
        onTap: () => _abrirFormulario(punto: punto),
      ),
    );
  }
}
