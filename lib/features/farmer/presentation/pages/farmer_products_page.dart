import 'package:flutter/material.dart';
import '../../../catalog/data/product_model.dart';
import '../../data/remote/farmer_product_service.dart';
import '../widgets/farmer_product_detail_dialog.dart';

class FarmerProductsPage extends StatefulWidget {
  const FarmerProductsPage({super.key});

  @override
  State<FarmerProductsPage> createState() => _FarmerProductsPageState();
}

class _FarmerProductsPageState extends State<FarmerProductsPage> {
  final _service = FarmerProductService();
  List<Producto> _productos = [];
  List<Producto> _filtrados = [];
  bool _cargando = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _service.listarProductos();
      setState(() {
        _productos = lista;
        _filtrados = lista;
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  void _filtrar(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filtrados = _productos;
      } else {
        _filtrados = _productos
            .where((p) =>
                p.nombre.toLowerCase().contains(query.toLowerCase()) ||
                p.descripcion.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TINKIAGRO',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A32),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5CA399),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_none,
                          color: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('No tienes notificaciones nuevas.')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: _filtrar,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search,
                        color: Color(0xFF5CA399), size: 24),
                    hintText: 'Buscar',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mis productos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargando
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF5CA399)))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.redAccent)),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _cargarProductos,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF5CA399)),
                                  child: const Text('Reintentar',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          )
                        : _filtrados.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No tienes productos registrados.'
                                      : 'Sin resultados para "$_searchQuery".',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500),
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _cargarProductos,
                                color: const Color(0xFF5CA399),
                                child: ListView.builder(
                                  itemCount: _filtrados.length,
                                  itemBuilder: (context, index) {
                                    return _buildProductCard(_filtrados[index]);
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final agregado = await Navigator.pushNamed(context, '/add_product');
          if (agregado == true) _cargarProductos();
        },
        backgroundColor: const Color(0xFF5CA399),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildProductCard(Producto product) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => FarmerProductDetailDialog(
            product: product,
            onProductoModificado: _cargarProductos,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: product.urlImagen.isNotEmpty
                    ? Image.network(
                        product.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.eco_outlined,
                          size: 28,
                          color: Color(0xFF5CA399),
                        ),
                      )
                    : const Icon(Icons.eco_outlined,
                        size: 28, color: Color(0xFF5CA399)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                product.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              'S/. ${product.precio.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4A7C73),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
