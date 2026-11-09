import 'package:flutter/material.dart';
import '../../data/product_model.dart';
import '../../data/remote/catalog_service.dart';
import '../../../cart/data/cart_manager.dart';
import '../../../cart/data/remote/cart_service.dart';
import '../../../favorites/data/favorites_cache.dart';
import '../../../../core/evaluation/evaluation_analytics_service.dart';

class DetalleProductoPage extends StatefulWidget {
  const DetalleProductoPage({super.key});

  @override
  State<DetalleProductoPage> createState() => _DetalleProductoPageState();
}

class _DetalleProductoPageState extends State<DetalleProductoPage> {
  final _catalogService = CatalogService();
  final _cartService = CartService();

  late Producto _productoBase; // datos del card (carga inmediata)
  Producto? _productoDetalle; // datos completos del API
  bool _iniciado = false;
  bool _agregandoCarrito = false;

  String _formatoVenta = 'Kilo';
  int _cantidad = 1;

  Producto get _p => _productoDetalle ?? _productoBase;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iniciado) {
      _iniciado = true;
      _productoBase = ModalRoute.of(context)!.settings.arguments as Producto;
      if (!_productoBase.ventaPorKilo && _productoBase.ventaPorCaja) {
        _formatoVenta = 'Caja';
      }
      _cargarDetalle();
    }
  }

  Future<void> _cargarDetalle() async {
    try {
      final detalle = await _catalogService.obtenerDetalle(_productoBase.id);
      if (!mounted) return;
      setState(() {
        _productoDetalle = detalle.copiarCon(
          sourceSection: _productoBase.sourceSection,
          sourcePosition: _productoBase.sourcePosition,
          recommendationRequestId: _productoBase.recommendationRequestId,
          farmerUsername: _productoBase.farmerUsername,
        );
        if (!detalle.ventaPorKilo && detalle.ventaPorCaja) {
          _formatoVenta = 'Caja';
        } else if (detalle.ventaPorKilo) {
          _formatoVenta = 'Kilo';
        }
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorito() async {
    final producto = _p;
    final nuevoEstado = !producto.esFavorito;

    // Optimistic: actualiza UI y caché inmediatamente
    setState(() => producto.esFavorito = nuevoEstado);
    if (nuevoEstado) {
      FavoritosCache().agregarOptimista(producto);
    } else {
      FavoritosCache().quitarOptimista(producto.id);
    }

    try {
      if (nuevoEstado) {
        await _catalogService.agregarFavorito(producto.id);
      } else {
        await _catalogService.quitarFavorito(producto.id);
      }
    } catch (e) {
      // Revertir si falla
      if (mounted) {
        setState(() => producto.esFavorito = !nuevoEstado);
        if (nuevoEstado) {
          FavoritosCache().quitarOptimista(producto.id);
        } else {
          FavoritosCache().agregarOptimista(
            producto.copiarCon(esFavorito: true),
          );
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _agregarAlCarrito() async {
    setState(() => _agregandoCarrito = true);
    final formatoLocal = _formatoVenta == 'Kilo' ? 'Kg' : 'Caja';
    try {
      final apiId = await _cartService.agregarAlCarrito(
        productId: _p.id,
        cantidad: _cantidad,
        formato: formatoLocal,
      );
      // Actualiza el manager local para que el carrito muestre el ítem de inmediato
      final manager = CarritoManager();
      manager.agregarAlCarrito(_p, _cantidad, formatoLocal);
      // Asocia el apiId al ítem recién agregado
      final itemLocal = manager.items.lastWhere(
        (i) => i.producto.id == _p.id && i.formatoVenta == formatoLocal,
        orElse: () => manager.items.last,
      );
      itemLocal.apiId = apiId;

      await EvaluationAnalyticsService.instance.addToCart(
        productId: _p.id,
        farmer: _p.farmerUsername,
        section: _p.sourceSection,
        position: _p.sourcePosition,
        requestId: _p.recommendationRequestId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Agregado: $_cantidad ${_formatoVenta == "Kilo" ? "kg" : "caja(s)"} de ${_p.nombre}.',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: const Color(0xFF91B049),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar al carrito: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _agregandoCarrito = false);
    }
  }

  void _showFarmerSheet(Producto producto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: producto.urlAvatarVendedor.isNotEmpty
                  ? NetworkImage(producto.urlAvatarVendedor)
                  : null,
              child: producto.urlAvatarVendedor.isEmpty
                  ? const Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              producto.nombreVendedor.isNotEmpty
                  ? producto.nombreVendedor
                  : 'Agricultor',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(
                  producto.calificacionVendedor.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (producto.farmerDescription.isNotEmpty) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  producto.farmerDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (producto.farmerPhone.isNotEmpty) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: Color(0xFF5CA399),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    producto.farmerPhone,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final producto = _p;
    final esKilo = _formatoVenta == 'Kilo';
    final precioUnitario = esKilo
        ? producto.precio
        : (producto.precioCaja ?? (producto.precio * 15 * 0.9));
    final totalEstimado = precioUnitario * _cantidad;

    final stockKilo = producto.stockDisponible;
    final stockCaja =
        producto.stockCaja ??
        (producto.stockDisponible / 15).floor().toDouble();
    final stockTexto = esKilo
        ? '${stockKilo.toInt()} kg'
        : '${stockCaja.toInt()} cajas';

    // Texto de referencia según formato
    String textoReferencia;
    if (esKilo) {
      textoReferencia = producto.textoPesoUnidad.isNotEmpty
          ? producto.textoPesoUnidad
          : '1 Und. = ${producto.pesoUnidadAprox.toStringAsFixed(2)} Kg aprox.';
    } else {
      final unidades = producto.unidadesCajaReferencial?.toInt();
      textoReferencia = unidades != null
          ? '1 caja = $unidades unidades aprox.'
          : '1 caja = varias unidades';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Hero(
              tag: 'producto_img_${producto.id}',
              child: producto.urlImagen.isNotEmpty
                  ? Image.network(
                      producto.urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFF3F4F6),
                        child: const Icon(
                          Icons.eco_outlined,
                          size: 100,
                          color: Color(0xFF5CA399),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF3F4F6),
                      child: const Icon(
                        Icons.eco_outlined,
                        size: 100,
                        color: Color(0xFF5CA399),
                      ),
                    ),
            ),
          ),

          // Botón volver
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Panel de contenido
          Positioned(
            top: MediaQuery.of(context).size.height * 0.36,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF7F8FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 28.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + favorito
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              producto.nombre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleFavorito,
                            child: Icon(
                              producto.esFavorito
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: producto.esFavorito
                                  ? Colors.red
                                  : Colors.grey.shade400,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Calificación
                      Row(
                        children: [
                          Text(
                            producto.calificacion.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Row(
                            children: List.generate(5, (index) {
                              final val = index + 1;
                              final llena =
                                  val <= producto.calificacion.floor();
                              final media =
                                  !llena &&
                                  (producto.calificacion - index >= 0.5);
                              return Icon(
                                llena
                                    ? Icons.star
                                    : (media
                                          ? Icons.star_half
                                          : Icons.star_border),
                                color: const Color(0xFFFFC107),
                                size: 16,
                              );
                            }),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${producto.cantidadResenas} ${producto.cantidadResenas == 1 ? 'reseña' : 'reseñas'})',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Card del agricultor
                      GestureDetector(
                        onTap: () => _showFarmerSheet(producto),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundImage:
                                    producto.urlAvatarVendedor.isNotEmpty
                                    ? NetworkImage(producto.urlAvatarVendedor)
                                    : null,
                                backgroundColor: Colors.grey.shade200,
                                child: producto.urlAvatarVendedor.isEmpty
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producto.nombreVendedor.isNotEmpty
                                          ? producto.nombreVendedor
                                          : 'Agricultor',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          producto.calificacionVendedor
                                              .toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      if (producto.descripcion.trim().isNotEmpty) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Descripción',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                producto.descripcion,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reseñas
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/resenas',
                          arguments: producto,
                        ).then((_) => _cargarDetalle()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Reseñas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    producto.calificacion.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ...List.generate(5, (index) {
                                    final val = index + 1;
                                    final llena =
                                        val <= producto.calificacion.floor();
                                    final media =
                                        !llena &&
                                        (producto.calificacion - index >= 0.5);
                                    return Icon(
                                      llena
                                          ? Icons.star
                                          : (media
                                                ? Icons.star_half
                                                : Icons.star_border),
                                      color: Colors.amber,
                                      size: 14,
                                    );
                                  }),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${producto.cantidadResenas})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: Color(0xFF5CA399),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Selector de formato
                      const Text(
                        'Selecciona formato de venta',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSelectorFormato(producto),
                      const SizedBox(height: 16),

                      // Precio / Disponible
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              titulo: 'Precio',
                              valor: 's/. ${precioUnitario.toStringAsFixed(2)}',
                              subtitulo: esKilo ? 'Por kilo' : 'Por caja',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildInfoCard(
                              titulo: 'Disponible',
                              valor: stockTexto,
                              subtitulo: 'En Stock',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Texto de referencia (ej: "1 Und. = 0.4 Kg aprox.")
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            textoReferencia,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Cantidad
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Cantidad',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove,
                                      color: Color(0xFF5CA399),
                                    ),
                                    onPressed: () {
                                      if (_cantidad > 1) {
                                        setState(() => _cantidad--);
                                      }
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.symmetric(
                                        vertical: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      '$_cantidad',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add,
                                      color: Color(0xFF5CA399),
                                    ),
                                    onPressed: () =>
                                        setState(() => _cantidad++),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total estimado
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total estimado',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              's/. ${totalEstimado.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Botón agregar al carrito
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _agregandoCarrito
                              ? null
                              : _agregarAlCarrito,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5CA399),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 2,
                          ),
                          child: _agregandoCarrito
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Agregar al carrito',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorFormato(Producto producto) {
    if (!producto.ventaPorKilo || !producto.ventaPorCaja) {
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          producto.ventaPorKilo
              ? 'Formato: Por Kilogramo'
              : 'Formato: Por Caja',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A32),
          ),
        ),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: ['Kilo', 'Caja'].map((formato) {
          final activo = _formatoVenta == formato;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _formatoVenta = formato),
              child: Container(
                decoration: BoxDecoration(
                  color: activo ? const Color(0xFF5CA399) : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Text(
                  formato,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: activo ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoCard({
    required String titulo,
    required String valor,
    required String subtitulo,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A7C73),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8CAF3F).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C8C2E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
