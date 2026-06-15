import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/catalog_repository.dart';

class FiltrosProductoPage extends StatefulWidget {
  const FiltrosProductoPage({super.key});

  @override
  State<FiltrosProductoPage> createState() => _FiltrosProductoPageState();
}

class _FiltrosProductoPageState extends State<FiltrosProductoPage> {
  final _repositorio = CatalogoRepositorio();
  late TextEditingController _ctrlMinimo;
  late TextEditingController _ctrlMaximo;
  double? _calificacionSeleccionada;
  bool _ventaPorKilo = false;
  bool _ventaPorCaja = false;
  String? _priceError;

  @override
  void initState() {
    super.initState();
    final filtros = _repositorio.filtrosActivos;
    _ctrlMinimo = TextEditingController(
      text: filtros.precioMinimo != null ? filtros.precioMinimo!.toStringAsFixed(0) : '',
    );
    _ctrlMaximo = TextEditingController(
      text: filtros.precioMaximo != null ? filtros.precioMaximo!.toStringAsFixed(0) : '',
    );
    _calificacionSeleccionada = filtros.calificacion;
    _ventaPorKilo = filtros.ventaPorKilo;
    _ventaPorCaja = filtros.ventaPorCaja;
  }

  @override
  void dispose() {
    _ctrlMinimo.dispose();
    _ctrlMaximo.dispose();
    super.dispose();
  }

  // Reinicia los filtros a su estado vacío
  void _limpiarFiltros() {
    setState(() {
      _ctrlMinimo.clear();
      _ctrlMaximo.clear();
      _calificacionSeleccionada = null;
      _ventaPorKilo = false;
      _ventaPorCaja = false;
      _priceError = null;
    });
  }

  void _aplicarFiltros() {
    final minText = _ctrlMinimo.text.trim();
    final maxText = _ctrlMaximo.text.trim();
    final precioMin = minText.isEmpty ? null : double.tryParse(minText);
    final precioMax = maxText.isEmpty ? null : double.tryParse(maxText);

    if ((minText.isNotEmpty && precioMin == null) ||
        (maxText.isNotEmpty && precioMax == null)) {
      setState(() => _priceError = 'Ingresa solo números o decimales (ej: 5.50)');
      return;
    }
    if (precioMin != null && precioMax != null && precioMin > precioMax) {
      setState(() => _priceError = 'El precio mínimo no puede ser mayor al máximo');
      return;
    }

    setState(() => _priceError = null);

    final nuevosFiltros = FiltrosCriterio(
      precioMinimo: precioMin,
      precioMaximo: precioMax,
      calificacion: _calificacionSeleccionada,
      ventaPorKilo: _ventaPorKilo,
      ventaPorCaja: _ventaPorCaja,
    );

    _repositorio.aplicarFiltros(nuevosFiltros);
    Navigator.pop(context, true);
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
          'Filtros',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            tooltip: 'Restablecer filtros',
            onPressed: _limpiarFiltros,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección: Rango de precio
                    const Text(
                      'Rango de precio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputPrecio(
                            controlador: _ctrlMinimo,
                            hint: 'Min.',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputPrecio(
                            controlador: _ctrlMaximo,
                            hint: 'Max.',
                          ),
                        ),
                      ],
                    ),
                    if (_priceError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _priceError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Sección: Calificación
                    const Text(
                      'Calificación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSelectorCalificacion(),
                    const SizedBox(height: 32),

                    // Sección: Otros
                    const Text(
                      'Otros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildOtroItem(
                            icon: Icons.inventory_2_outlined,
                            titulo: 'Venta por kilo',
                            valor: _ventaPorKilo,
                            onChanged: (val) => setState(() => _ventaPorKilo = val),
                          ),
                          const Divider(height: 1, indent: 56, endIndent: 16),
                          _buildOtroItem(
                            icon: Icons.grid_view_outlined,
                            titulo: 'Venta por caja',
                            valor: _ventaPorCaja,
                            onChanged: (val) => setState(() => _ventaPorCaja = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón de acción: Aplicar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _aplicarFiltros,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CA399),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Aplicar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para los inputs de rango de precio
  Widget _buildInputPrecio({
    required TextEditingController controlador,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controlador,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // Helper para el selector de estrellas de calificación
  Widget _buildSelectorCalificacion() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Row(
            children: List.generate(5, (index) {
              final estrellaIndex = index + 1;
              final seleccionada = _calificacionSeleccionada != null &&
                  estrellaIndex <= _calificacionSeleccionada!;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_calificacionSeleccionada == estrellaIndex.toDouble()) {
                      // Si hace click en la misma estrella seleccionada, deselecciona
                      _calificacionSeleccionada = null;
                    } else {
                      _calificacionSeleccionada = estrellaIndex.toDouble();
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    seleccionada ? Icons.star : Icons.star_border,
                    color: seleccionada ? const Color(0xFFFFC107) : Colors.grey.shade400,
                    size: 28,
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          Text(
            _calificacionSeleccionada != null
                ? '${_calificacionSeleccionada!.toInt()} estrellas'
                : 'Cualquiera',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Helper para construir cada fila de opciones en la sección "Otros"
  Widget _buildOtroItem({
    required IconData icon,
    required String titulo,
    required bool valor,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade700, size: 20),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: GestureDetector(
        onTap: () => onChanged(!valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: valor ? const Color(0xFF5CA399) : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: valor
              ? const Center(
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: Color(0xFF5CA399),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
