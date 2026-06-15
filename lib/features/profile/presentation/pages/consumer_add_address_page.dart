import 'package:flutter/material.dart';
import '../../data/remote/profile_service.dart';

class ConsumerAddAddressPage extends StatefulWidget {
  const ConsumerAddAddressPage({super.key});

  @override
  State<ConsumerAddAddressPage> createState() =>
      _ConsumerAddAddressPageState();
}

class _ConsumerAddAddressPageState extends State<ConsumerAddAddressPage> {
  final _service = ProfileService();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _referenceController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final label = _labelController.text.trim();
    final address = _addressController.text.trim();
    final district = _districtController.text.trim();

    if (label.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Etiqueta y dirección son obligatorios')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      await _service.agregarDireccion(
        label: label,
        address: address,
        district: district,
        reference: _referenceController.text.trim(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildField(
              icon: Icons.label_outline,
              hint: 'Etiqueta (ej: Casa, Trabajo)',
              controller: _labelController,
            ),
            const SizedBox(height: 10),
            _buildField(
              icon: Icons.location_on_outlined,
              hint: 'Dirección (ej: Av. La Marina 2355, Apto 4B)',
              controller: _addressController,
            ),
            const SizedBox(height: 10),
            _buildField(
              icon: Icons.map_outlined,
              hint: 'Distrito (ej: San Miguel, Lima)',
              controller: _districtController,
            ),
            const SizedBox(height: 10),
            _buildField(
              icon: Icons.info_outline,
              hint: 'Referencia (opcional)',
              controller: _referenceController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildAddButton(context),
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
        'Agregar dirección',
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

  Widget _buildField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
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
              : const Text(
                  'Agregar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
