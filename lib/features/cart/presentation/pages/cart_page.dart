import 'package:flutter/material.dart';
import '../../data/cart_manager.dart';
import '../../data/remote/cart_service.dart';
import '../../../catalog/data/product_model.dart';

class CarritoPage extends StatefulWidget {
  final bool showBackButton;

  const CarritoPage({super.key, this.showBackButton = false});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  final _manager = CarritoManager();
  final _cartService = CartService();

  @override
  void initState() {
    super.initState();
    _sincronizarCarrito();
  }

  Future<void> _sincronizarCarrito() async {
    try {
      final carritoActivo = await _cartService.verCarritoActivo();
      final items = carritoActivo.items.map((item) {
        final producto = Producto(
          id: item.productId,
          nombre: item.productName,
          precio: item.precioUnitario,
          precioCaja: item.formato == 'Caja' ? item.precioUnitario : null,
          unidad: item.formato == 'Caja' ? 'Caja' : 'Kg',
          pesoUnidadAprox: 0,
          textoPesoUnidad: '',
          urlImagen: resolveMediaUrl(item.imageUrl),
          esFavorito: false,
          calificacion: 0,
          cantidadResenas: 0,
          nombreVendedor: item.farmerUsername,
          calificacionVendedor: 0,
          urlAvatarVendedor: resolveMediaUrl(item.farmerAvatarUrl),
          stockDisponible: 0,
          descripcion: '',
          categoria: '',
          envioGratis: false,
          ventaPorKilo: item.formato != 'Caja',
          ventaPorCaja: item.formato == 'Caja',
        );
        return CarritoItem(
          producto: producto,
          cantidad: item.cantidad,
          formatoVenta: item.formato,
          apiId: item.id,
        );
      }).toList();
      _manager.sincronizar(items);
    } catch (e) {
      debugPrint('[CarritoPage] _sincronizarCarrito error: $e');
    }
  }

  Future<void> _eliminarItem(CarritoItem item) async {
    _manager.eliminarItem(item);
    if (item.apiId != null) {
      try {
        await _cartService.eliminarItem(item.apiId!);
      } catch (_) {}
    }
  }

  void _eliminarConAviso(CarritoItem item) {
    _eliminarItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.producto.nombre} eliminado del carrito.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Future<bool> _confirmarEliminacion(CarritoItem item) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Eliminar producto'),
            content: Text(
              '¿Deseas eliminar ${item.producto.nombre} del carrito?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(dialogContext, true),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _confirmarYEliminar(CarritoItem item) async {
    if (await _confirmarEliminacion(item) && mounted) {
      _eliminarConAviso(item);
    }
  }

  Future<void> _cambiarFormato(CarritoItem item, String nuevoFormato) async {
    // La API no admite cambio de formato; actualizamos solo localmente
    _manager.cambiarFormato(item, nuevoFormato);
  }

  Future<void> _cambiarCantidad(CarritoItem item, int delta) async {
    if (delta < 0 && item.cantidad <= 1) {
      await _confirmarYEliminar(item);
      return;
    }
    if (delta > 0) {
      _manager.incrementarCantidad(item);
    } else if (delta < 0) {
      _manager.decrementarCantidad(item);
    }
    if (item.apiId != null) {
      try {
        await _cartService.modificarCantidad(
          itemId: item.apiId!,
          cantidad: item.cantidad,
        );
      } catch (_) {}
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
          'Tu carrito',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _manager,
        builder: (context, child) {
          final items = _manager.items;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tu carrito está vacío.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega productos desde la tienda.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (_) => false,
                    ),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Seguir comprando'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildCartItem(context, item);
                  },
                ),
              ),
              _buildBottomSummary(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, CarritoItem item) {
    return Dismissible(
      key: Key('cart_item_${item.producto.id}_${item.formatoVenta}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmarEliminacion(item),
      onDismissed: (_) => _eliminarConAviso(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24.0),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE57373),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Imagen
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: item.producto.urlImagen.isNotEmpty
                    ? Image.network(
                        item.producto.urlImagen,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.eco_outlined,
                          size: 28,
                          color: Color(0xFF5CA399),
                        ),
                      )
                    : const Icon(
                        Icons.eco_outlined,
                        size: 28,
                        color: Color(0xFF5CA399),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              's/. ${item.precioUnitario.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF4A7C73),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.producto.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: Key(
                          'delete_cart_item_${item.producto.id}_${item.formatoVenta}',
                        ),
                        tooltip: 'Eliminar del carrito',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.redAccent,
                        onPressed: () => _confirmarYEliminar(item),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFormatToggle(item),
                      _buildQuantityRow(item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatToggle(CarritoItem item) {
    final supportsBoth =
        item.producto.ventaPorKilo && item.producto.ventaPorCaja;

    return GestureDetector(
      onTap: () {
        if (!supportsBoth) return;
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          builder: (bottomContext) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Seleccionar formato',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFF5CA399),
                    ),
                    title: const Text('Por Kilogramo (Kg)'),
                    onTap: () {
                      Navigator.pop(bottomContext);
                      _cambiarFormato(item, 'Kg');
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.all_inbox_outlined,
                      color: Color(0xFF5CA399),
                    ),
                    title: const Text('Por Caja'),
                    onTap: () {
                      Navigator.pop(bottomContext);
                      _cambiarFormato(item, 'Caja');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.formatoVenta == 'Caja' ? 'Caja' : 'Kg',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            if (supportsBoth) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Colors.grey.shade500,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityRow(CarritoItem item) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _cambiarCantidad(item, -1),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.remove, size: 16, color: Color(0xFF5CA399)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '${item.cantidad}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        GestureDetector(
          onTap: () => _cambiarCantidad(item, 1),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF5CA399),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSummary(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SubTotal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'S/. ${_manager.subTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/checkout_envio');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CA399),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: const Text(
                  'Pedir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
