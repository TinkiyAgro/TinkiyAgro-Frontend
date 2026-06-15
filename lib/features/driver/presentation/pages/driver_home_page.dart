import 'package:flutter/material.dart';
import '../../data/driver_model.dart';
import '../../data/remote/driver_service.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/driver_profile_page.dart';

class RepartidorHomePage extends StatefulWidget {
  const RepartidorHomePage({super.key});

  @override
  State<RepartidorHomePage> createState() => _RepartidorHomePageState();
}

class _RepartidorHomePageState extends State<RepartidorHomePage> {
  final _service = DriverService();

  int _tabIndex = 0; // 0: Entregas, 1: Perfil
  int _filterIndex = 0;
  static const _filters = ['Todo', 'En curso', 'Entregados'];
  List<RepartidorDeliveryGroup> _groups = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final groups = await _service.listarEntregas();
      if (mounted) setState(() => _groups = groups);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _tabIndex == 0 ? _buildEntregasTab() : const DriverProfilePage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF5CA399),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined, size: 26),
            activeIcon: Icon(Icons.local_shipping, size: 26),
            label: 'Entregas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, size: 26),
            activeIcon: Icon(Icons.person, size: 26),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildEntregasTab() {
    final filtered = _filterIndex == 0
        ? _groups
        : _groups
            .where((g) =>
                _filterIndex == 1
                    ? g.estado == 'En curso'
                    : g.estado == 'Entregado')
            .toList();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TINKIAGRO',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A32),
                    letterSpacing: 0.5,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5CA399),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white, size: 22),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _buildFilterTabs(),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Entregas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(child: _buildListBody(filtered)),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (context, i) {
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF5CA399) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color:
                      active ? const Color(0xFF5CA399) : Colors.grey.shade300,
                ),
              ),
              child: Text(
                _filters[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListBody(List<RepartidorDeliveryGroup> filtered) {
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
            Text('No se pudieron cargar las entregas',
                style: TextStyle(color: Colors.grey.shade600)),
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
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No hay entregas en esta categoría.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF5CA399),
      onRefresh: _cargar,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, i) => _buildGroupCard(filtered[i]),
      ),
    );
  }

  Widget _buildGroupCard(RepartidorDeliveryGroup group) {
    final entregado = group.estado == 'Entregado';
    return GestureDetector(
      onTap: entregado
          ? null
          : () => Navigator.pushNamed(
                context,
                '/repartidor_delivery',
                arguments: group,
              ).then((_) => setState(() {})),
      child: Opacity(
        opacity: entregado ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
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
            children: [
              // Farmer header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5CA399),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        group.farmerName.isNotEmpty
                            ? group.farmerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.farmerName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${group.clientes.length} pedido${group.clientes.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entregado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Entregado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5CA399),
                        ),
                      ),
                    )
                  else
                    _buildTypeBadge(group.tipoGrupo),
                ],
              ),
              const SizedBox(height: 8),
              // Customers
              ...group.clientes.map((c) => _buildCustomerRow(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerRow(RepartidorCustomer customer) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: customer.clienteColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                customer.clienteInicial,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E3A32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.clienteNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  customer.items
                      .map((i) => '${i.productName} • ${i.cantidad}')
                      .join(', '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            'S/. ${customer.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
        color: isDelivery
            ? const Color(0xFFE8D5F5)
            : const Color(0xFFD5E8F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tipo,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDelivery
              ? const Color(0xFF7B2D8B)
              : const Color(0xFF1976D2),
        ),
      ),
    );
  }

}
