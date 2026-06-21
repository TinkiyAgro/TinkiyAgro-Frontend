import 'package:flutter/material.dart';
import '../../data/order_model.dart';
import '../../../farmer/data/pickup_point_model.dart';
import '../../../farmer/data/remote/pickup_point_service.dart';
import '../../../profile/data/address_model.dart';
import '../../../profile/data/remote/profile_service.dart';

class CheckoutDireccionPage extends StatefulWidget {
  const CheckoutDireccionPage({super.key});

  @override
  State<CheckoutDireccionPage> createState() => _CheckoutDireccionPageState();
}

class _CheckoutDireccionPageState extends State<CheckoutDireccionPage> {
  final _profileService = ProfileService();
  final _pickupService = PickupPointService();

  late List<CheckoutFarmer> _farmers;
  bool _initialized = false;

  // Pickup points per farmer (fetched from API or extracted from embedded options)
  final Map<String, List<PuntoRecojo>> _puntosPorFarmer = {};
  final Map<String, bool> _cargandoPickup = {};

  // Delivery address (shared — consumer's address)
  Direccion? _defaultDireccion;
  bool _cargandoDireccion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _farmers =
          ModalRoute.of(context)!.settings.arguments as List<CheckoutFarmer>;
      _initCarga();
    }
  }

  void _initCarga() {
    bool needsAddress = false;
    for (final f in _farmers) {
      if (f.tipoEntrega == 'Recojo') {
        _cargarPuntos(f);
      } else {
        needsAddress = true;
      }
    }
    if (needsAddress) _cargarDireccionDefault();
  }

  Future<void> _cargarPuntos(CheckoutFarmer farmer) async {
    final username = farmer.farmerUsername;
    if (username.isEmpty) return;

    setState(() => _cargandoPickup[username] = true);

    // 1. Try pickup points already embedded in the PICKUP delivery option
    final embedded = farmer.availableOptions
        .where((o) => o.type == 'PICKUP')
        .firstOrNull
        ?.pickupPoints ?? [];

    if (embedded.isNotEmpty) {
      final converted = embedded.map((p) => PuntoRecojo(
        id: p.id,
        farmerUsername: username,
        name: p.name,
        address: p.address,
        deliveryDate: '',
        availableFrom: '',
        availableTo: '',
        orderDeadlineDate: '',
        orderDeadlineTime: '',
        status: 'ACTIVE',
      )).toList();
      if (mounted) {
        setState(() {
          _puntosPorFarmer[username] = converted;
          _cargandoPickup[username] = false;
          _autoSelectFirst(farmer, converted);
        });
      }
      return;
    }

    // 2. Fallback: call listActivePickupPointsEndpoint
    try {
      final puntos = await _pickupService.listarActivos(username);
      if (mounted) {
        setState(() {
          _puntosPorFarmer[username] = puntos;
          _autoSelectFirst(farmer, puntos);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _puntosPorFarmer[username] = []);
    } finally {
      if (mounted) setState(() => _cargandoPickup[username] = false);
    }
  }

  void _autoSelectFirst(CheckoutFarmer farmer, List<PuntoRecojo> puntos) {
    if (farmer.selectedPickupPoint == null && puntos.isNotEmpty) {
      farmer.selectedPickupPoint = puntos.first.id;
    }
  }

  Future<void> _cargarDireccionDefault() async {
    setState(() => _cargandoDireccion = true);
    try {
      final dir = await _profileService.obtenerDireccionDefault();
      if (mounted && dir != null) {
        setState(() {
          _defaultDireccion = dir;
          for (final f in _farmers) {
            if (f.tipoEntrega == 'Delivery' && f.selectedAddressId == null) {
              f.selectedAddressId = dir.id;
              f.selectedAddressText = dir.textoCompleto;
            }
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _cargandoDireccion = false);
    }
  }

  Future<void> _mostrarSelectorDirecciones(CheckoutFarmer farmer) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _AddressSelectorSheet(
          profileService: _profileService,
          currentId: farmer.selectedAddressId,
          onSelected: (dir) {
            setState(() {
              farmer.selectedAddressId = dir.id;
              farmer.selectedAddressText = dir.textoCompleto;
              _defaultDireccion ??= dir;
            });
          },
        );
      },
    );
  }

  bool get _puedeAvanzar {
    return _farmers.every((f) {
      if (f.tipoEntrega == 'Recojo') {
        final pts = _puntosPorFarmer[f.farmerUsername] ?? [];
        return pts.isNotEmpty && f.selectedPickupPoint != null;
      } else {
        return f.selectedAddressId != null;
      }
    });
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
          'Dirección de envío',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildStepIndicator(2),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _farmers.map((f) => _buildFarmerCard(f)).toList(),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _buildStep(1, 'ENTREGA', current),
          _buildLine(current > 1),
          _buildStep(2, 'DIRECCIÓN', current),
          _buildLine(current > 2),
          _buildStep(3, 'PAGO', current),
        ],
      ),
    );
  }

  Widget _buildStep(int step, String label, int current) {
    final isDone = current > step;
    final isActive = current == step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone || isActive
                ? const Color(0xFF5CA399)
                : Colors.grey.shade300,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isDone || isActive
                ? const Color(0xFF5CA399)
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool done) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: done ? const Color(0xFF5CA399) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFarmerCard(CheckoutFarmer farmer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: farmer.farmerAvatarUrl.isNotEmpty
                    ? NetworkImage(farmer.farmerAvatarUrl)
                    : null,
                backgroundColor: Colors.grey.shade200,
                child: farmer.farmerAvatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 20, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmer.farmerName.isNotEmpty
                          ? farmer.farmerName
                          : farmer.farmerUsername,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      farmer.tipoEntrega,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (farmer.tipoEntrega == 'Recojo') ...[
            const Text(
              'Recoger en:',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildPickupSection(farmer),
          ] else ...[
            const Text(
              'Entregar en:',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildDeliverySection(farmer),
          ],
        ],
      ),
    );
  }

  // ── Pickup section ─────────────────────────────────────────────────────────

  Widget _buildPickupSection(CheckoutFarmer farmer) {
    final cargando = _cargandoPickup[farmer.farmerUsername] ?? false;
    final pts = _puntosPorFarmer[farmer.farmerUsername] ?? [];

    if (cargando) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF5CA399)),
        ),
      );
    }

    if (pts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Este agricultor no tiene puntos de recojo disponibles.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pts.map((p) => _buildPickupPointOption(farmer, p)).toList(),
    );
  }

  Widget _buildPickupPointOption(CheckoutFarmer farmer, PuntoRecojo punto) {
    final selected = farmer.selectedPickupPoint == punto.id;
    return GestureDetector(
      onTap: () => setState(() => farmer.selectedPickupPoint = punto.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF5CA399) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(punto.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13)),
            if (punto.horario.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(punto.horario,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
            if (punto.address.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(punto.address,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF5CA399))),
            ],
          ],
        ),
      ),
    );
  }

  // ── Delivery address section ───────────────────────────────────────────────

  Widget _buildDeliverySection(CheckoutFarmer farmer) {
    if (_cargandoDireccion && farmer.selectedAddressId == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF5CA399)),
        ),
      );
    }

    final addressText = farmer.selectedAddressText;
    final hasAddress = addressText != null && addressText.isNotEmpty;

    return GestureDetector(
      onTap: () => _mostrarSelectorDirecciones(farmer),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF5CA399), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasAddress) ...[
              Text(
                addressText,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (_defaultDireccion != null &&
                  farmer.selectedAddressId == _defaultDireccion!.id &&
                  _defaultDireccion!.district.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  _defaultDireccion!.district,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 8),
            ] else ...[
              Text(
                'Selecciona una dirección',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.edit_outlined,
                    size: 13, color: Color(0xFF5CA399)),
                const SizedBox(width: 4),
                Text(
                  hasAddress ? 'Cambiar dirección' : 'Agregar dirección',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF5CA399),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom button ──────────────────────────────────────────────────────────

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _puedeAvanzar
              ? () => Navigator.pushNamed(
                    context,
                    '/checkout_pago',
                    arguments: _farmers,
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CA399),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: const Text(
            'Siguiente',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

// ── Address selector bottom sheet ────────────────────────────────────────────

class _AddressSelectorSheet extends StatefulWidget {
  final ProfileService profileService;
  final String? currentId;
  final void Function(Direccion) onSelected;

  const _AddressSelectorSheet({
    required this.profileService,
    required this.currentId,
    required this.onSelected,
  });

  @override
  State<_AddressSelectorSheet> createState() => _AddressSelectorSheetState();
}

class _AddressSelectorSheetState extends State<_AddressSelectorSheet> {
  List<Direccion> _direcciones = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await widget.profileService.listarDirecciones();
      if (mounted) setState(() => _direcciones = lista);
    } catch (_) {}
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elige una dirección',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: Color(0xFF5CA399)),
                ),
              )
            else if (_direcciones.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No tienes direcciones guardadas.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...(_direcciones.map((dir) => _buildAddressTile(dir))),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(Direccion dir) {
    final selected = dir.id == widget.currentId;
    return GestureDetector(
      onTap: () {
        widget.onSelected(dir);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF5CA399) : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              dir.esDefault ? Icons.home_outlined : Icons.location_on_outlined,
              color: const Color(0xFF5CA399),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dir.label.isNotEmpty)
                    Text(
                      dir.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  Text(
                    dir.textoCompleto,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF5CA399), size: 20),
          ],
        ),
      ),
    );
  }
}
