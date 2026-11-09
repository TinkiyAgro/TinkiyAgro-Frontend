import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import 'package:tinkiyagro_app/features/organization/data/organization_service.dart';
import 'package:tinkiyagro_app/features/profile/presentation/pages/notifications_page.dart';
import 'package:tinkiyagro_app/features/wholesale/presentation/wholesale_pages.dart';

const _brand = Color(0xFF5CA8A0),
    _ink = Color(0xFF132823),
    _bg = Color(0xFFF6F9F8);

class OrganizationHomePage extends StatefulWidget {
  const OrganizationHomePage({super.key});
  @override
  State<OrganizationHomePage> createState() => _OrganizationHomePageState();
}

class _OrganizationHomePageState extends State<OrganizationHomePage> {
  int _tab = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    body: IndexedStack(
      index: _tab,
      children: const [
        _OrganizationOverview(),
        OrganizationMembersPage(),
        OrganizationCatalogPage(),
        OrganizationQuotesPage(),
        _OrganizationProfile(),
      ],
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE0F2ED),
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Miembros',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Órdenes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    ),
  );
}

class _OrganizationOverview extends StatelessWidget {
  const _OrganizationOverview();
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Panel de organización',
    child: FutureBuilder<Map<String, dynamic>>(
      future: OrganizationService().getOrganization(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final org = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    org['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${org['region']} · ${org['zone']}',
                    style: const TextStyle(color: Color(0xFFCCE5DB)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Gestiona tus agricultores y consolida su oferta para recibir cotizaciones mayoristas.',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF6E7A78),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class OrganizationMembersPage extends StatefulWidget {
  const OrganizationMembersPage({super.key});
  @override
  State<OrganizationMembersPage> createState() =>
      _OrganizationMembersPageState();
}

class _OrganizationMembersPageState extends State<OrganizationMembersPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = OrganizationService().getMembers();
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Agricultores miembros',
    action: FilledButton.icon(
      onPressed: () => _edit(),
      icon: const Icon(Icons.person_add_alt_1),
      label: const Text('Agregar agricultor'),
      style: FilledButton.styleFrom(
        backgroundColor: _brand,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                '${items.where((e) => e['active'] == true).length} miembros activos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const _Empty(
                icon: Icons.groups_outlined,
                text: 'Aún no agregaste agricultores',
              )
            else
              ...items.map((m) => _MemberCard(data: m, onEdit: () => _edit(m))),
          ],
        );
      },
    ),
  );
  Future<void> _edit([Map<String, dynamic>? data]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationMemberFormPage(member: data),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }
}

class OrganizationCatalogPage extends StatefulWidget {
  const OrganizationCatalogPage({super.key});
  @override
  State<OrganizationCatalogPage> createState() =>
      _OrganizationCatalogPageState();
}

class _OrganizationCatalogPageState extends State<OrganizationCatalogPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = OrganizationService().getProducts();
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Catálogo consolidado',
    action: FilledButton.icon(
      onPressed: () => _edit(),
      icon: const Icon(Icons.add_box_outlined),
      label: const Text('Registrar producto'),
      style: FilledButton.styleFrom(
        backgroundColor: _brand,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;
        final stock = items.fold<double>(
          0,
          (sum, e) => sum + ((e['stock'] as num?)?.toDouble() ?? 0),
        );
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} productos disponibles',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Stock total: ${stock.toStringAsFixed(1)} kg',
                    style: const TextStyle(color: Color(0xFFCCE5DB)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const _Empty(
                icon: Icons.inventory_2_outlined,
                text: 'El catálogo está vacío',
              )
            else
              ...items.map(
                (p) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFDEE5E3)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(14),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFE0F2ED),
                      backgroundImage: resolveMediaUrl(p['imageUrl']).isEmpty
                          ? null
                          : NetworkImage(resolveMediaUrl(p['imageUrl'])),
                      child: resolveMediaUrl(p['imageUrl']).isEmpty
                          ? const Icon(Icons.eco, color: _brand)
                          : null,
                    ),
                    title: Text(
                      p['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${p['category']} · ${p['active'] == true ? 'Activo' : 'Inactivo'}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${p['stock']} ${p['unit']}',
                          style: const TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _edit(p),
                          style: TextButton.styleFrom(
                            minimumSize: const Size(64, 30),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
  Future<void> _edit([Map<String, dynamic>? data]) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => OrganizationProductFormPage(product: data),
      ),
    );
    if (changed == true && mounted) setState(_reload);
  }
}

class OrganizationMemberFormPage extends StatefulWidget {
  const OrganizationMemberFormPage({super.key, this.member});
  final Map<String, dynamic>? member;
  @override
  State<OrganizationMemberFormPage> createState() =>
      _OrganizationMemberFormPageState();
}

class _OrganizationMemberFormPageState
    extends State<OrganizationMemberFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _first, _last, _phone, _region, _zone;
  bool _saving = false;
  bool _active = true;
  File? _image;
  @override
  void initState() {
    super.initState();
    final m = widget.member ?? {};
    _first = TextEditingController(text: m['firstName']);
    _last = TextEditingController(text: m['lastName']);
    _phone = TextEditingController(text: m['phoneNumber']);
    _region = TextEditingController(text: m['region']);
    _zone = TextEditingController(text: m['zone']);
    _active = m['active'] as bool? ?? true;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    _region.dispose();
    _zone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FormPage(
    title: widget.member == null ? 'Agregar agricultor' : 'Editar agricultor',
    saving: _saving,
    onSave: _save,
    formKey: _key,
    fields: [
      InkWell(
        onTap: () async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 82,
            maxWidth: 1200,
          );
          if (picked != null && mounted) {
            setState(() => _image = File(picked.path));
          }
        },
        child: CircleAvatar(
          radius: 48,
          backgroundColor: const Color(0xFFE0F2ED),
          backgroundImage: _image != null
              ? FileImage(_image!)
              : (resolveMediaUrl(widget.member?['profileImageUrl']).isNotEmpty
                        ? NetworkImage(
                            resolveMediaUrl(widget.member?['profileImageUrl']),
                          )
                        : null)
                    as ImageProvider?,
          child:
              _image == null &&
                  resolveMediaUrl(widget.member?['profileImageUrl']).isEmpty
              ? const Icon(Icons.add_a_photo_outlined, color: _brand, size: 32)
              : null,
        ),
      ),
      _Input(_first, 'Nombre'),
      _Input(_last, 'Apellidos'),
      _Input(_phone, 'Celular', keyboard: TextInputType.phone),
      _Input(_region, 'Región'),
      _Input(_zone, 'Zona'),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: const Text('Miembro activo'),
        subtitle: Text(
          _active
              ? 'Puede aparecer en el catálogo de la organización'
              : 'No aparecerá como integrante disponible',
        ),
        value: _active,
        activeThumbColor: _brand,
        onChanged: (value) => setState(() => _active = value),
      ),
    ],
  );
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await OrganizationService().saveMember({
        'firstName': _first.text.trim(),
        'lastName': _last.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'region': _region.text.trim(),
        'zone': _zone.text.trim(),
        'profileImageUrl': widget.member?['profileImageUrl'],
        'active': _active,
      }, id: widget.member?['id']);
      if (_image != null) {
        await OrganizationService().uploadMemberImage(
          saved['id'].toString(),
          _image!,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class OrganizationProductFormPage extends StatefulWidget {
  const OrganizationProductFormPage({super.key, this.product});
  final Map<String, dynamic>? product;
  @override
  State<OrganizationProductFormPage> createState() =>
      _OrganizationProductFormPageState();
}

class _OrganizationProductFormPageState
    extends State<OrganizationProductFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _description, _stock, _price;
  String _category = 'TUBERCULOS', _unit = 'kg';
  String? _memberId;
  bool _saving = false;
  bool _active = true;
  File? _image;
  List<Map<String, dynamic>> _members = [];
  @override
  void initState() {
    super.initState();
    final p = widget.product ?? {};
    _name = TextEditingController(text: p['name']);
    _description = TextEditingController(text: p['description']);
    _stock = TextEditingController(text: p['stock']?.toString());
    _price = TextEditingController(text: p['referencePrice']?.toString());
    _category = p['category'] ?? _category;
    _unit = p['unit'] ?? _unit;
    _memberId = p['memberId'];
    _active = p['active'] as bool? ?? true;
    OrganizationService().getMembers().then((v) {
      if (mounted)
        setState(() {
          _members = v.where((e) => e['active'] == true).toList();
          _memberId ??= _members.isEmpty ? null : _members.first['id'];
        });
    });
  }

  @override
  Widget build(BuildContext context) => _FormPage(
    title: widget.product == null ? 'Registrar producto' : 'Editar producto',
    saving: _saving,
    onSave: _save,
    formKey: _key,
    fields: [
      InkWell(
        onTap: () async {
          final picked = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 82,
            maxWidth: 1400,
          );
          if (picked != null && mounted) {
            setState(() => _image = File(picked.path));
          }
        },
        child: Container(
          height: 145,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDEE5E3)),
            borderRadius: BorderRadius.circular(14),
            image: _image != null
                ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                : (resolveMediaUrl(widget.product?['imageUrl']).isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(
                            resolveMediaUrl(widget.product?['imageUrl']),
                          ),
                          fit: BoxFit.cover,
                        )
                      : null),
          ),
          child:
              _image == null &&
                  resolveMediaUrl(widget.product?['imageUrl']).isEmpty
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      color: _brand,
                      size: 40,
                    ),
                    SizedBox(height: 6),
                    Text('Agregar imagen del producto'),
                  ],
                )
              : null,
        ),
      ),
      _Input(_name, 'Nombre'),
      DropdownButtonFormField<String>(
        initialValue: _category,
        decoration: _decoration('Categoría'),
        items:
            const [
                  'VERDURAS',
                  'FRUTAS',
                  'HIERBAS',
                  'TUBERCULOS',
                  'GRANOS_CEREALES',
                ]
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(e.replaceAll('_', ' ')),
                  ),
                )
                .toList(),
        onChanged: (v) => _category = v!,
      ),
      DropdownButtonFormField<String>(
        initialValue: _memberId,
        decoration: _decoration('Agricultor miembro'),
        items: _members
            .map(
              (m) => DropdownMenuItem(
                value: m['id'] as String,
                child: Text('${m['firstName']} ${m['lastName']}'),
              ),
            )
            .toList(),
        validator: (v) =>
            v == null ? 'Agrega y selecciona un agricultor' : null,
        onChanged: (v) => _memberId = v,
      ),
      _Input(_description, 'Descripción', lines: 3),
      Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: _decoration('Unidad'),
              items: const [
                'kg',
                'ton',
                'caja',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => _unit = v!,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _Input(_stock, 'Stock', keyboard: TextInputType.number),
          ),
        ],
      ),
      _Input(
        _price,
        'Precio referencial por unidad',
        keyboard: TextInputType.number,
      ),
      SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        title: const Text('Producto activo'),
        subtitle: Text(
          _active
              ? 'Disponible para mostrarse y recibir cotizaciones'
              : 'Oculto temporalmente del catálogo',
        ),
        value: _active,
        activeThumbColor: _brand,
        onChanged: (value) => setState(() => _active = value),
      ),
    ],
  );
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final saved = await OrganizationService().saveProduct({
        'name': _name.text.trim(),
        'category': _category,
        'memberId': _memberId,
        'description': _description.text.trim(),
        'unit': _unit,
        'stock': double.parse(_stock.text.replaceAll(',', '.')),
        'referencePrice': double.parse(_price.text.replaceAll(',', '.')),
        'imageUrl': widget.product?['imageUrl'],
        'active': _active,
      }, id: widget.product?['id']);
      if (_image != null) {
        await OrganizationService().uploadProductImage(
          saved['id'].toString(),
          _image!,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'TINKIYAGRO',
                style: TextStyle(
                  fontSize: 20,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Notificaciones',
              icon: const Icon(Icons.notifications_none, color: _ink),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2933),
          ),
        ),
        if (action != null) ...[const SizedBox(height: 18), action!],
        const SizedBox(height: 18),
        child,
      ],
    ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.data, required this.onEdit});
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      side: const BorderSide(color: Color(0xFFDEE5E3)),
      borderRadius: BorderRadius.circular(14),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(14),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE0F2ED),
        backgroundImage: resolveMediaUrl(data['profileImageUrl']).isEmpty
            ? null
            : NetworkImage(resolveMediaUrl(data['profileImageUrl'])),
        child: resolveMediaUrl(data['profileImageUrl']).isEmpty
            ? Text(
                ((data['firstName'] as String?) ?? '?').substring(0, 1),
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(
        '${data['firstName']} ${data['lastName']}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${data['zone'] ?? ''}, ${data['region'] ?? ''}\n${data['active'] == true ? 'Activo' : 'Inactivo'}',
      ),
      isThreeLine: true,
      trailing: TextButton(onPressed: onEdit, child: const Text('Editar')),
    ),
  );
}

class _FormPage extends StatelessWidget {
  const _FormPage({
    required this.title,
    required this.fields,
    required this.onSave,
    required this.saving,
    required this.formKey,
  });
  final String title;
  final List<Widget> fields;
  final VoidCallback onSave;
  final bool saving;
  final GlobalKey<FormState> formKey;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg,
      title: const Text(
        'TINKIYAGRO',
        style: TextStyle(color: _ink, fontWeight: FontWeight.bold),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ...fields.map(
              (e) =>
                  Padding(padding: const EdgeInsets.only(bottom: 14), child: e),
            ),
            FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Guardar',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Input extends StatelessWidget {
  const _Input(this.controller, this.label, {this.keyboard, this.lines = 1});
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final int lines;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: lines,
    decoration: _decoration(label),
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
  );
}

InputDecoration _decoration(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFDEE5E3)),
  ),
);

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Colors.grey),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    ),
  );
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => _Page(
    title: title,
    child: const _Empty(
      icon: Icons.description_outlined,
      text: 'Se implementará en la etapa de cotizaciones',
    ),
  );
}

class _OrganizationProfile extends StatelessWidget {
  const _OrganizationProfile();
  @override
  Widget build(BuildContext context) => _Page(
    title: 'Perfil',
    child: Column(
      children: [
        ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          leading: const Icon(Icons.business, color: _brand),
          title: Text(SessionManager().nombre ?? 'Organización'),
          subtitle: Text(SessionManager().username ?? ''),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            SessionManager().clearSession();
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/welcome',
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout),
          label: const Text('Cerrar sesión'),
        ),
      ],
    ),
  );
}
