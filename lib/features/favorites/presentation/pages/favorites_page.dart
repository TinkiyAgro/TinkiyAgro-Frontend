import 'package:flutter/material.dart';
import '../../../catalog/data/product_model.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../../../catalog/data/remote/catalog_service.dart';
import '../../data/favorites_cache.dart';

class PaginaFavoritos extends StatefulWidget {
  const PaginaFavoritos({super.key});

  @override
  State<PaginaFavoritos> createState() => _PaginaFavoritosState();
}

class _PaginaFavoritosState extends State<PaginaFavoritos> {
  final _service = CatalogService();
  final _cache = FavoritosCache();
  bool _cargando = false;

  bool get _enModoFiltro {
    final f = CatalogoRepositorio().filtrosActivos;
    return f.precioMinimo != null ||
        f.precioMaximo != null ||
        f.calificacion != null ||
        f.ventaPorKilo ||
        f.ventaPorCaja;
  }

  List<Producto> get _favoritosFiltrados {
    if (!_enModoFiltro) return _cache.productos;
    final f = CatalogoRepositorio().filtrosActivos;
    return _cache.productos.where((p) {
      if (f.precioMinimo != null && p.precio < f.precioMinimo!) return false;
      if (f.precioMaximo != null && p.precio > f.precioMaximo!) return false;
      if (f.calificacion != null && p.calificacion < f.calificacion!) return false;
      if (f.ventaPorKilo && !p.ventaPorKilo) return false;
      if (f.ventaPorCaja && !p.ventaPorCaja) return false;
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _cargarFavoritos(silencioso: _cache.cargado);
  }

  Future<void> _cargarFavoritos({bool silencioso = false}) async {
    if (!silencioso) setState(() => _cargando = true);
    try {
      final lista = await _service.listarFavoritos();
      _cache.actualizar(lista);
    } catch (_) {}
    if (mounted && !silencioso) setState(() => _cargando = false);
  }

  void _limpiarFiltros() {
    CatalogoRepositorio().limpiarFiltros();
    setState(() {});
  }

  Future<void> _quitarFavorito(Producto producto) async {
    _cache.quitarOptimista(producto.id);
    try {
      await _service.quitarFavorito(producto.id);
    } catch (_) {
      _cache.agregarOptimista(producto);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Favoritos',
          style: TextStyle(
              color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (_enModoFiltro)
            TextButton.icon(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear_all,
                  size: 18, color: Color(0xFF5CA399)),
              label: const Text('Limpiar',
                  style: TextStyle(
                      color: Color(0xFF5CA399),
                      fontWeight: FontWeight.bold)),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () async {
                final aplicar =
                    await Navigator.pushNamed(context, '/filtros');
                if (aplicar == true) setState(() {});
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _enModoFiltro
                      ? const Color(0xFF1E3A32)
                      : const Color(0xFF5CA399),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.filter_alt,
                    color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _cache,
        builder: (context, _) {
          if (_cargando && !_cache.cargado) {
            return const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF5CA399)));
          }

          final lista = _favoritosFiltrados;

          if (_enModoFiltro) {
            return _buildResultadosFiltro(lista);
          }

          if (lista.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No tienes productos favoritos aún.',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _cargarFavoritos(),
            color: const Color(0xFF5CA399),
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.76,
              ),
              itemCount: lista.length,
              itemBuilder: (context, index) =>
                  _buildTarjetaProducto(context, lista[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultadosFiltro(List<Producto> lista) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${lista.length} resultado${lista.length != 1 ? "s" : ""} en favoritos',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
        ),
        if (lista.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off,
                      size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'Ningún favorito coincide con los filtros.',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.76,
              ),
              itemCount: lista.length,
              itemBuilder: (context, index) =>
                  _buildTarjetaProducto(context, lista[index]),
            ),
          ),
      ],
    );
  }

  Widget _buildTarjetaProducto(BuildContext context, Producto producto) {
    return GestureDetector(
      onTap: () async {
        await Navigator.pushNamed(context, '/detalle_producto',
            arguments: producto);
        _cargarFavoritos(silencioso: true);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: producto.urlImagen.isNotEmpty
                          ? Image.network(
                              producto.urlImagen,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_outlined,
                                size: 40,
                                color: Color(0xFF5CA399),
                              ),
                            )
                          : const Icon(Icons.eco_outlined,
                              size: 40, color: Color(0xFF5CA399)),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => _quitarFavorito(producto),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(Icons.favorite,
                            color: Colors.red, size: 24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: Column(
                children: [
                  Text(
                    's/. ${producto.precio.toStringAsFixed(2)} x ${producto.unidad}',
                    style: const TextStyle(
                        color: Color(0xFF4A7C73),
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    producto.nombre,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    producto.textoPesoUnidad.isNotEmpty
                        ? producto.textoPesoUnidad
                        : '1 Und. = ${producto.pesoUnidadAprox.toStringAsFixed(2)} Kg',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
