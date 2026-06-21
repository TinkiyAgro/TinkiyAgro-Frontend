import 'package:flutter/material.dart';
import '../../data/farmer_order_model.dart';

class FarmerCourierStatusPage extends StatelessWidget {
  const FarmerCourierStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final group = ModalRoute.of(context)!.settings.arguments as FarmerOrderGroup;

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
          'Estado de entregas',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourierCard(group),
            const SizedBox(height: 16),
            Text(
              '${group.clientes.length} ${group.clientes.length == 1 ? 'pedido' : 'pedidos'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            ...group.clientes.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildCustomerCard(c),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierCard(FarmerOrderGroup group) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: Color(0xFF5CA399),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.repartidorNombre ?? 'Repartidor asignado',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  group.repartidorUsername != null
                      ? '@${group.repartidorUsername}'
                      : 'Encargado de la entrega',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'En camino',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5CA399),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(FarmerCustomerOrder customer) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: customer.clienteColor,
                backgroundImage: customer.customerProfileImageUrl.isNotEmpty
                    ? NetworkImage(customer.customerProfileImageUrl)
                    : null,
                child: customer.customerProfileImageUrl.isEmpty
                    ? Text(
                        customer.clienteInicial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E3A32),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customer.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              _buildTypeBadge(customer.tipoEntrega),
            ],
          ),
          const SizedBox(height: 10),
          ...customer.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.productName} × ${item.cantidad}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'S/. ${item.precio.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          if (customer.deliveryCost > 0) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Envío',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                Text('S/. ${customer.deliveryCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ],
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'S/. ${customer.total.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String tipo) {
    final isDelivery = tipo == 'Delivery';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDelivery ? const Color(0xFFE8D5F5) : const Color(0xFFD5E8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDelivery ? const Color(0xFF7B2D8B) : const Color(0xFF1976D2),
        ),
      ),
    );
  }
}
