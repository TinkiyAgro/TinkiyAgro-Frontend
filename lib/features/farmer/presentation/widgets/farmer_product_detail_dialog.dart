import 'package:flutter/material.dart';
import '../../../catalog/data/product_model.dart';
import '../../data/remote/farmer_product_service.dart';

class FarmerProductDetailDialog extends StatelessWidget {
  final Producto product;
  final VoidCallback? onProductoModificado;

  const FarmerProductDetailDialog({
    super.key,
    required this.product,
    this.onProductoModificado,
  });

  @override
  Widget build(BuildContext context) {
    final service = FarmerProductService();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.nombre,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.categoria,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              size: 40,
                              color: Color(0xFF5CA399),
                            ),
                          )
                        : const Icon(Icons.eco_outlined,
                            size: 40, color: Color(0xFF5CA399)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFECECEC), height: 1),
            const SizedBox(height: 16),
            const Text(
              'Formato de venta',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            if (product.ventaPorKilo) ...[
              _buildFormatCard(
                title: product.unidad == 'Kg' ? 'Por kilogramo' : 'Por unidad',
                icon: Icons.shopping_bag_outlined,
                price: product.precio,
                stock: product.stockDisponible,
                stockLabel: product.unidad.toLowerCase(),
                lastColLabel: 'Peso unit:',
                lastColVal: '${product.pesoUnidadAprox} kg',
                available: product.stockDisponible > 0,
              ),
              if (product.ventaPorCaja) const SizedBox(height: 12),
            ],
            if (product.ventaPorCaja) ...[
              _buildFormatCard(
                title: 'Por caja',
                icon: Icons.all_inbox_outlined,
                price: product.precioCaja ?? (product.precio * 15 * 0.9),
                stock: product.stockCaja ??
                    (product.stockDisponible / 15).floor().toDouble(),
                stockLabel: 'cajas',
                lastColLabel: 'U. por caja:',
                lastColVal:
                    '${(product.unidadesCajaReferencial ?? 15.0).toStringAsFixed(0)} und.',
                available: (product.stockCaja ??
                        (product.stockDisponible / 15).floor().toDouble()) >
                    0,
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _confirmDelete(context, service),
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Eliminar',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE57373),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          '/add_product',
                          arguments: product,
                        ).then((_) => onProductoModificado?.call());
                      },
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.white, size: 20),
                      label: const Text(
                        'Editar',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CA399),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard({
    required String title,
    required IconData icon,
    required double price,
    required double stock,
    required String stockLabel,
    required String lastColLabel,
    required String lastColVal,
    required bool available,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
            color: const Color(0xFF5CA399).withValues(alpha: 0.5), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5ECEB), width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2F1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF5CA399), size: 20),
                ),
                const SizedBox(width: 12),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCol('Precio:', 'S/. ${price.toStringAsFixed(2)}'),
                _buildCol('Stock:',
                    '${stock.toStringAsFixed(0)} $stockLabel'),
                _buildCol(lastColLabel, lastColVal),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FBFB),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Text('Estado: ',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                Text(
                  available ? 'Disponible' : 'Agotado',
                  style: TextStyle(
                    fontSize: 13,
                    color: available
                        ? const Color(0xFF5CA399)
                        : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
      ],
    );
  }

  void _confirmDelete(BuildContext context, FarmerProductService service) {
    showDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: Text(
            '¿Estás seguro de que deseas eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmContext),
            child: const Text('Cancelar',
                style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(confirmContext);
              Navigator.pop(context);
              try {
                await service.eliminarProducto(product.id);
                onProductoModificado?.call();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            '"${product.nombre}" eliminado exitosamente.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
