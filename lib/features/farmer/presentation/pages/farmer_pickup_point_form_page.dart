import 'package:flutter/material.dart';
import '../../data/pickup_point_model.dart';
import '../../data/remote/pickup_point_service.dart';

const _kDays = [
  'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
];

class FarmerPickupPointFormPage extends StatefulWidget {
  final PuntoRecojo? puntoEditar;

  const FarmerPickupPointFormPage({super.key, this.puntoEditar});

  @override
  State<FarmerPickupPointFormPage> createState() =>
      _FarmerPickupPointFormPageState();
}

class _FarmerPickupPointFormPageState
    extends State<FarmerPickupPointFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PickupPointService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;

  Set<String> _selectedDays = {};
  TimeOfDay _availableFrom = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _availableTo = const TimeOfDay(hour: 12, minute: 0);
  String _deadlineDay = 'SUNDAY';
  TimeOfDay _deadlineTime = const TimeOfDay(hour: 15, minute: 0);
  bool _activo = true;

  bool _guardando = false;

  bool get _esEdicion => widget.puntoEditar != null;

  @override
  void initState() {
    super.initState();
    final p = widget.puntoEditar;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    if (p != null) {
      _selectedDays = Set.from(p.deliveryDays);
      _availableFrom = _parseTime(p.availableFrom);
      _availableTo = _parseTime(p.availableTo);
      _deadlineDay = p.orderDeadlineDay;
      _deadlineTime = _parseTime(p.orderDeadlineTime);
      _activo = p.activo;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickTime(
    String label,
    TimeOfDay initial,
    void Function(TimeOfDay) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: label,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: const Color(0xFF5CA399)),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día de entrega.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final days = _kDays.where(_selectedDays.contains).toList();
      if (_esEdicion) {
        await _service.editar(
          id: widget.puntoEditar!.id,
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          deliveryDays: days,
          availableFrom: _formatTime(_availableFrom),
          availableTo: _formatTime(_availableTo),
          orderDeadlineDay: _deadlineDay,
          orderDeadlineTime: _formatTime(_deadlineTime),
          status: _activo ? 'ACTIVE' : 'INACTIVE',
        );
      } else {
        await _service.crear(
          name: _nameCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          deliveryDays: days,
          availableFrom: _formatTime(_availableFrom),
          availableTo: _formatTime(_availableTo),
          orderDeadlineDay: _deadlineDay,
          orderDeadlineTime: _formatTime(_deadlineTime),
          status: _activo ? 'ACTIVE' : 'INACTIVE',
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _esEdicion ? 'Editar punto de recojo' : 'Nuevo punto de recojo',
          style: const TextStyle(
              color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSection('Información básica', [
              _buildTextField(_nameCtrl, 'Nombre del punto', Icons.location_on_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
              const SizedBox(height: 12),
              _buildTextField(_addressCtrl, 'Dirección', Icons.map_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Campo requerido' : null),
            ]),
            const SizedBox(height: 16),
            _buildSection('Días de entrega', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kDays.map((day) {
                  final selected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedDays.remove(day);
                        } else {
                          _selectedDays.add(day);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF5CA399)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? const Color(0xFF5CA399)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        PuntoRecojo.diaLabelCompleto(day),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Horario de atención', [
              _buildTimeTile(
                'Desde',
                _availableFrom,
                () => _pickTime('Hora de inicio', _availableFrom,
                    (t) => setState(() => _availableFrom = t)),
              ),
              const SizedBox(height: 10),
              _buildTimeTile(
                'Hasta',
                _availableTo,
                () => _pickTime('Hora de cierre', _availableTo,
                    (t) => setState(() => _availableTo = t)),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Fecha límite de pedidos', [
              _buildDropdownDia(),
              const SizedBox(height: 10),
              _buildTimeTile(
                'Hora límite',
                _deadlineTime,
                () => _pickTime('Hora límite', _deadlineTime,
                    (t) => setState(() => _deadlineTime = t)),
              ),
            ]),
            const SizedBox(height: 16),
            _buildSection('Estado', [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _activo ? 'Activo' : 'Inactivo',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        _activo ? const Color(0xFF5CA399) : Colors.grey.shade600,
                  ),
                ),
                subtitle: Text(
                  _activo
                      ? 'Los consumidores pueden seleccionarlo al comprar.'
                      : 'No aparecerá en el checkout.',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                value: _activo,
                activeColor: const Color(0xFF5CA399),
                onChanged: (v) => setState(() => _activo = v),
              ),
            ]),
            const SizedBox(height: 24),
            SizedBox(
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
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        _esEdicion ? 'Guardar cambios' : 'Crear punto',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF5CA399), size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5CA399), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildTimeTile(String label, TimeOfDay time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time,
                color: Color(0xFF5CA399), size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const Spacer(),
            Text(
              time.format(context),
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5CA399)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownDia() {
    return DropdownButtonFormField<String>(
      value: _deadlineDay,
      decoration: InputDecoration(
        labelText: 'Día límite',
        prefixIcon:
            const Icon(Icons.calendar_today, color: Color(0xFF5CA399), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5CA399), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      items: _kDays
          .map((d) => DropdownMenuItem(
                value: d,
                child: Text(PuntoRecojo.diaLabelCompleto(d)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _deadlineDay = v);
      },
    );
  }
}
