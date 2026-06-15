import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/delivery_settings_model.dart';
import '../../data/remote/profile_service.dart';

class FarmerDeliveryRatesPage extends StatefulWidget {
  const FarmerDeliveryRatesPage({super.key});

  @override
  State<FarmerDeliveryRatesPage> createState() =>
      _FarmerDeliveryRatesPageState();
}

class _FarmerDeliveryRatesPageState extends State<FarmerDeliveryRatesPage> {
  final _service = ProfileService();
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  bool _offerPickup = false;
  bool _offerDelivery = false;
  final _pickupCostController = TextEditingController(text: '0');
  final _deliveryCostController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _cargarConfiguracion();
  }

  Future<void> _cargarConfiguracion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final config = await _service.obtenerConfiguracionEntrega();
      setState(() {
        _offerPickup = config.ofrecePuntoRecojo;
        _offerDelivery = config.ofreceDelivery;
        _pickupCostController.text = config.costoRecojo.toStringAsFixed(2);
        _deliveryCostController.text = config.costoDelivery.toStringAsFixed(2);
        _cargando = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final config = ConfiguracionEntrega(
        ofrecePuntoRecojo: _offerPickup,
        costoRecojo: double.tryParse(_pickupCostController.text) ?? 0.0,
        ofreceDelivery: _offerDelivery,
        costoDelivery: double.tryParse(_deliveryCostController.text) ?? 0.0,
      );
      await _service.guardarConfiguracionEntrega(config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarifas guardadas correctamente.'),
            backgroundColor: Color(0xFF5CA399),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    _pickupCostController.dispose();
    _deliveryCostController.dispose();
    super.dispose();
  }

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
                        onPressed: _cargarConfiguracion,
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
                    children: [
                      const SizedBox(height: 8),
                      _buildSection(
                        icon: Icons.directions_bus_outlined,
                        title: 'Punto de recojo',
                        offerLabel: 'Ofrecer punto de recojo',
                        offerValue: _offerPickup,
                        onOfferChanged: (v) => setState(() => _offerPickup = v),
                        costController: _pickupCostController,
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        icon: Icons.local_shipping_outlined,
                        title: 'Delivery',
                        offerLabel: 'Ofrecer delivery',
                        offerValue: _offerDelivery,
                        onOfferChanged: (v) =>
                            setState(() => _offerDelivery = v),
                        costController: _deliveryCostController,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _cargando ? null : _buildSaveButton(context),
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
        'Tarifas de entrega',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String offerLabel,
    required bool offerValue,
    required ValueChanged<bool> onOfferChanged,
    required TextEditingController costController,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: Colors.black87),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(offerLabel,
                    style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ),
              Switch(
                value: offerValue,
                onChanged: onOfferChanged,
                activeColor: const Color(0xFF5CA399),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('Costo:',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: costController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: const Color(0xFFF7F8FA),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5CA399),
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
              : const Text('Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
