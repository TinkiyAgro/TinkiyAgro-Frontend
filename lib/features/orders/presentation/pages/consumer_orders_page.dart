import 'package:flutter/material.dart';
import '../../data/order_model.dart';
import '../../data/remote/order_service.dart';

class ConsumerOrdersPage extends StatefulWidget {
  const ConsumerOrdersPage({super.key});

  @override
  State<ConsumerOrdersPage> createState() => _ConsumerOrdersPageState();
}

class _ConsumerOrdersPageState extends State<ConsumerOrdersPage> {
  final _service = OrderService();

  List<PedidoConsumidor> _pedidos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final pedidos = await _service.listarPedidos();
      if (mounted) setState(() => _pedidos = pedidos);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Pedidos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los pedidos',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargar,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CA399),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_pedidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes pedidos',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF5CA399),
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _pedidos.length,
        itemBuilder: (context, index) => _buildOrderCard(_pedidos[index]),
      ),
    );
  }

  Widget _buildOrderCard(PedidoConsumidor pedido) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Order header ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/order_detail',
                arguments: pedido.id,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF5CA399),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${pedido.numero}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${pedido.fechaLarga} • ${pedido.numAgricultores} ${pedido.numAgricultores == 1 ? 'agricultor' : 'agricultores'} • S/. ${pedido.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(pedido.estado),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      pedido.expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFF5CA399),
                    ),
                    onPressed: () {
                      setState(() {
                        pedido.expanded = !pedido.expanded;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Sub-orders (visible when expanded) ───────────────────────────
          if (pedido.expanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            ...pedido.subPedidos.map((sub) => _buildSubOrderRow(sub)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    final isProgress = estado == 'En Progreso';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isProgress
            ? const Color(0xFFFFF3E0)
            : const Color(0xFF5CA399).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isProgress ? Icons.access_time : Icons.check_circle_outline,
            size: 14,
            color: isProgress
                ? const Color(0xFFF57C00)
                : const Color(0xFF5CA399),
          ),
          const SizedBox(width: 5),
          Text(
            estado,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isProgress
                  ? const Color(0xFFF57C00)
                  : const Color(0xFF5CA399),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubOrderRow(SubPedido sub) {
    final isActive = sub.estadoTexto != 'Entregado';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: sub.farmerAvatarUrl.isNotEmpty
                    ? NetworkImage(sub.farmerAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: sub.farmerAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  sub.farmerName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                sub.estadoTexto,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive
                      ? const Color(0xFF5CA399)
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        if (isActive && sub.estadoTexto == 'Repartidor en camino')
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5CA399),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'El repartidor se dirige a entregar el pedido',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }
}
