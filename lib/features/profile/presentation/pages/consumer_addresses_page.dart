import 'package:flutter/material.dart';
import '../../data/address_model.dart';
import '../../data/remote/profile_service.dart';
import 'consumer_add_address_page.dart';

class ConsumerAddressesPage extends StatefulWidget {
  const ConsumerAddressesPage({super.key});

  @override
  State<ConsumerAddressesPage> createState() => _ConsumerAddressesPageState();
}

class _ConsumerAddressesPageState extends State<ConsumerAddressesPage> {
  final _service = ProfileService();
  List<Direccion> _direcciones = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.listarDirecciones();
      // Si ninguna tiene esDefault, intentar obtener la predeterminada
      if (lista.isNotEmpty && lista.every((d) => !d.esDefault)) {
        try {
          final def = await _service.obtenerDireccionDefault();
          if (def != null) {
            final idx = lista.indexWhere((d) => d.id == def.id);
            if (idx != -1) {
              lista[idx] = lista[idx].copyWith(esDefault: true);
            }
          }
        } catch (_) {}
      }
      setState(() {
        _direcciones = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  List<Direccion> get _actual => _direcciones.where((d) => d.esDefault).toList();
  List<Direccion> get _otras => _direcciones.where((d) => !d.esDefault).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF5CA399)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _cargarDirecciones,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CA399)),
                        child: const Text('Reintentar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      if (_actual.isNotEmpty) ...[
                        _buildSectionTitle('Dirección de entrega actual'),
                        const SizedBox(height: 12),
                        ..._actual.map((d) => _buildAddressCard(d, isCurrent: true)),
                        const SizedBox(height: 20),
                      ],
                      if (_otras.isNotEmpty) ...[
                        _buildSectionTitle('Otras direcciones'),
                        const SizedBox(height: 12),
                        ..._otras.map((d) => _buildAddressCard(d, isCurrent: false)),
                      ],
                      if (_direcciones.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Text('No tienes direcciones registradas.',
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarAgregarDireccion,
        backgroundColor: const Color(0xFF5CA399),
        elevation: 2,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Mis direcciones',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black));
  }

  Widget _buildAddressCard(Direccion direccion, {required bool isCurrent}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrent
            ? Border.all(color: const Color(0xFF5CA399), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: isCurrent
            ? const Icon(Icons.location_on, color: Color(0xFF5CA399))
            : const Icon(Icons.location_on_outlined, color: Colors.grey),
        title: Text(
          direccion.textoCompleto,
          style: TextStyle(
            fontSize: 15,
            color: isCurrent ? Colors.black87 : Colors.grey.shade500,
            fontWeight: isCurrent ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
        subtitle: direccion.label.isNotEmpty
            ? Text(direccion.label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onSelected: (value) => _handleAccion(value, direccion),
          itemBuilder: (_) => [
            if (!isCurrent)
              const PopupMenuItem(
                value: 'set_default',
                child: Text('Usar como actual'),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAccion(String accion, Direccion direccion) async {
    if (accion == 'set_default') {
      try {
        await _service.editarDireccion(
          id: direccion.id,
          label: direccion.label,
          address: direccion.address,
          district: direccion.district,
          reference: direccion.reference,
          defaultAddress: true,
        );
        await _cargarDirecciones();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.redAccent),
          );
        }
      }
    } else if (accion == 'delete') {
      try {
        await _service.eliminarDireccion(direccion.id);
        await _cargarDirecciones();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dirección eliminada.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: ${e.toString()}'),
                backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  Future<void> _navegarAgregarDireccion() async {
    final agregada = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ConsumerAddAddressPage()),
    );
    if (agregada == true) {
      await _cargarDirecciones();
    }
  }
}
