import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/auth_service.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/login_request.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/register_request.dart';
import 'package:tinkiyagro_app/features/organization/data/organization_service.dart';

const _brand = Color(0xFF5CA8A0);
const _ink = Color(0xFF132823);
const _background = Color(0xFFF6F9F8);

class SellerTypePage extends StatefulWidget {
  const SellerTypePage({super.key});
  @override
  State<SellerTypePage> createState() => _SellerTypePageState();
}

class _SellerTypePageState extends State<SellerTypePage> {
  String _type = 'AGRICULTOR';
  @override
  Widget build(BuildContext context) {
    final args =
        (ModalRoute.of(context)?.settings.arguments as Map?)
            ?.cast<String, dynamic>() ??
        {};
    return _FlowScaffold(
      title: 'Elige tu perfil',
      subtitle:
          'Configura la experiencia según cómo comercializas tus productos.',
      children: [
        _ChoiceCard(
          title: 'Agricultor minorista',
          subtitle: 'Venta directa, cobertura cercana y reparto con GPS.',
          tag: 'Compra directa',
          selected: _type == 'AGRICULTOR',
          onTap: () => setState(() => _type = 'AGRICULTOR'),
        ),
        _ChoiceCard(
          title: 'Organización mayorista',
          subtitle: 'Administra miembros, volumen y cotizaciones formales.',
          tag: 'Cotizaciones',
          selected: _type == 'ORGANIZACION',
          onTap: () => setState(() => _type = 'ORGANIZACION'),
        ),
        const Text(
          'Podrás cambiar los datos del perfil más adelante.',
          style: TextStyle(color: Color(0xFF6E7A78), fontSize: 12),
        ),
        _PrimaryButton(
          label: 'Continuar',
          onPressed: () => Navigator.pushNamed(
            context,
            _type == 'ORGANIZACION'
                ? '/organization_register'
                : '/producer_location_setup',
            arguments: args,
          ),
        ),
      ],
    );
  }
}

class OrganizationRegistrationPage extends StatefulWidget {
  const OrganizationRegistrationPage({super.key});
  @override
  State<OrganizationRegistrationPage> createState() =>
      _OrganizationRegistrationPageState();
}

class _OrganizationRegistrationPageState
    extends State<OrganizationRegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _account = _AccountControllers(personal: false);
  final _name = TextEditingController(),
      _region = TextEditingController(),
      _zone = TextEditingController(),
      _location = TextEditingController();
  Position? _position;
  File? _photo;
  bool _loading = false;
  @override
  void dispose() {
    _account.dispose();
    _name.dispose();
    _region.dispose();
    _zone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación requerido');
      }
      final p = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _position = p);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega una foto de la organización')),
      );
      return;
    }
    if (_position == null) {
      await _locate();
      if (_position == null) return;
      if (!mounted) return;
    }
    setState(() => _loading = true);
    try {
      await completeRegistration(
        context,
        _account.arguments(organizationName: _name.text.trim()),
        role: 'ORGANIZACION',
        organizationName: _name.text.trim(),
        region: _region.text.trim(),
        zone: _zone.text.trim(),
        locationLabel: _location.text.trim(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        organizationImage: _photo,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FlowScaffold(
    title: 'Registrar organización',
    subtitle: 'Datos comerciales',
    children: [
      Form(
        key: _form,
        child: Column(
          children: [
            _AccountFields(account: _account),
            const SizedBox(height: 18),
            InkWell(
              onTap: () async {
                final picked = await ImagePicker().pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 82,
                  maxWidth: 1400,
                );
                if (picked != null && mounted) {
                  setState(() => _photo = File(picked.path));
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFDCE5E2)),
                  borderRadius: BorderRadius.circular(16),
                  image: _photo == null
                      ? null
                      : DecorationImage(
                          image: FileImage(_photo!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: _photo == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _brand,
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text('Agregar foto de la organización'),
                        ],
                      )
                    : null,
              ),
            ),
            _Field(controller: _name, label: 'Nombre de la organización'),
            _Field(controller: _region, label: 'Región'),
            _Field(controller: _zone, label: 'Zona'),
            _Field(controller: _location, label: 'Ubicación de sede'),
            OutlinedButton.icon(
              onPressed: _locate,
              icon: Icon(
                _position == null ? Icons.my_location : Icons.check_circle,
                color: _brand,
              ),
              label: Text(
                _position == null
                    ? 'Capturar ubicación de la sede'
                    : 'Ubicación capturada',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
      const Text(
        'La sede será visible para consumidores según su radio elegido.',
        style: TextStyle(color: Color(0xFF6E7A78), fontSize: 12),
      ),
      _PrimaryButton(
        label: 'Crear organización',
        loading: _loading,
        onPressed: _submit,
      ),
    ],
  );
}

class ProducerLocationSetupPage extends StatefulWidget {
  const ProducerLocationSetupPage({super.key});
  @override
  State<ProducerLocationSetupPage> createState() =>
      _ProducerLocationSetupPageState();
}

class _ProducerLocationSetupPageState extends State<ProducerLocationSetupPage> {
  final _form = GlobalKey<FormState>();
  final _account = _AccountControllers();
  final _location = TextEditingController();
  Position? _position;
  bool _loading = false;
  @override
  void dispose() {
    _account.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final p = await Geolocator.getCurrentPosition();
    if (mounted) setState(() => _position = p);
  }

  @override
  Widget build(BuildContext context) {
    return _FlowScaffold(
      title: 'Ubicación del agricultor',
      subtitle: 'Necesitamos tu sede para mostrarte a consumidores cercanos.',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              _AccountFields(account: _account),
              const SizedBox(height: 18),
              _Field(
                controller: _location,
                label: 'Distrito, provincia o referencia',
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _locate,
          icon: Icon(
            _position == null ? Icons.my_location : Icons.check_circle,
            color: _brand,
          ),
          label: Text(
            _position == null
                ? 'Usar mi ubicación actual'
                : 'Ubicación capturada',
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        _PrimaryButton(
          label: 'Crear cuenta minorista',
          loading: _loading,
          onPressed: () async {
            if (!_form.currentState!.validate()) return;
            if (_location.text.trim().isEmpty || _position == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Escribe y captura tu ubicación')),
              );
              return;
            }
            setState(() => _loading = true);
            try {
              await completeRegistration(
                context,
                _account.arguments(),
                role: 'AGRICULTOR',
                locationLabel: _location.text.trim(),
                latitude: _position!.latitude,
                longitude: _position!.longitude,
              );
            } finally {
              if (mounted) setState(() => _loading = false);
            }
          },
        ),
      ],
    );
  }
}

class ConsumerDiscoverySetupPage extends StatefulWidget {
  const ConsumerDiscoverySetupPage({super.key, this.existingAccount = false});
  final bool existingAccount;
  @override
  State<ConsumerDiscoverySetupPage> createState() =>
      _ConsumerDiscoverySetupPageState();
}

class _ConsumerDiscoverySetupPageState
    extends State<ConsumerDiscoverySetupPage> {
  final _form = GlobalKey<FormState>();
  final _account = _AccountControllers();
  double _radius = 50;
  Position? _position;
  double? _savedLatitude;
  double? _savedLongitude;
  bool _loading = false;
  bool _loadingPreferences = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingAccount) _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loadingPreferences = true);
    try {
      final data = await OrganizationService().getDiscoveryPreferences();
      if (!mounted) return;
      setState(() {
        _radius = (data['radiusKm'] as num?)?.toDouble() ?? 50;
        _savedLatitude = (data['latitude'] as num?)?.toDouble();
        _savedLongitude = (data['longitude'] as num?)?.toDouble();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo cargar tu zona guardada: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingPreferences = false);
    }
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La ubicación es obligatoria para continuar'),
          ),
        );
      }
      return;
    }
    final p = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _position = p;
        _savedLatitude = p.latitude;
        _savedLongitude = p.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (_savedLatitude == null || _savedLongitude == null) {
      await _locate();
      if (_savedLatitude == null || _savedLongitude == null) return;
      if (!mounted) return;
    }
    setState(() => _loading = true);
    try {
      if (widget.existingAccount) {
        final saved = await OrganizationService().saveDiscoveryPreferences(
          _savedLatitude!,
          _savedLongitude!,
          _radius.round(),
        );
        if (mounted) {
          setState(() {
            _radius = (saved['radiusKm'] as num?)?.toDouble() ?? _radius;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Zona guardada: ${_radius.round()} km')),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
        }
      } else {
        if (!_form.currentState!.validate()) return;
        await completeRegistration(
          context,
          _account.arguments(),
          role: 'CONSUMIDOR',
          latitude: _savedLatitude!,
          longitude: _savedLongitude!,
          radius: _radius.round(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FlowScaffold(
    title: 'Tu zona de interés',
    subtitle:
        'Elige hasta qué distancia quieres descubrir agricultores y organizaciones.',
    children: [
      if (!widget.existingAccount)
        Form(
          key: _form,
          child: _AccountFields(account: _account),
        ),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDEE5E3)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '${_radius.round()} km',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: _ink,
              ),
            ),
            if (_loadingPreferences)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(color: _brand),
              )
            else
              Slider(
                value: _radius,
                min: 0,
                max: 400,
                divisions: 60,
                activeColor: _brand,
                label: '${_radius.round()} km',
                onChanged: (v) => setState(() => _radius = v),
              ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0 km'), Text('400 km')],
            ),
          ],
        ),
      ),
      OutlinedButton.icon(
        onPressed: _locate,
        icon: Icon(
          _savedLatitude == null ? Icons.my_location : Icons.check_circle,
          color: _brand,
        ),
        label: Text(
          _savedLatitude == null
              ? 'Usar mi ubicación actual *'
              : _position == null
              ? 'Ubicación guardada (toca para actualizar)'
              : 'Ubicación actualizada',
        ),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
      ),
      const Text(
        'Podrás cambiar este radio desde tu perfil.',
        style: TextStyle(color: Color(0xFF6E7A78), fontSize: 12),
      ),
      _PrimaryButton(
        label: 'Guardar y continuar',
        loading: _loading || _loadingPreferences,
        onPressed: _submit,
      ),
    ],
  );
}

class DriverRegistrationPage extends StatefulWidget {
  const DriverRegistrationPage({super.key});

  @override
  State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}

class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final _form = GlobalKey<FormState>();
  final _account = _AccountControllers();
  bool _loading = false;

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FlowScaffold(
    title: 'Crear cuenta de repartidor',
    subtitle: 'Datos personales y credenciales de acceso.',
    children: [
      Form(
        key: _form,
        child: _AccountFields(account: _account),
      ),
      _PrimaryButton(
        label: 'Crear cuenta',
        loading: _loading,
        onPressed: () async {
          if (!_form.currentState!.validate()) return;
          setState(() => _loading = true);
          try {
            await completeRegistration(
              context,
              _account.arguments(),
              role: 'REPARTIDOR',
            );
          } finally {
            if (mounted) setState(() => _loading = false);
          }
        },
      ),
    ],
  );
}

Future<void> completeRegistration(
  BuildContext context,
  Map<String, dynamic> args, {
  required String role,
  String? organizationName,
  String? region,
  String? zone,
  String? locationLabel,
  double? latitude,
  double? longitude,
  int? radius,
  File? organizationImage,
}) async {
  final auth = AuthService();
  try {
    await auth.registrarUsuario(
      RegistroRequest(
        nombre: role == 'ORGANIZACION'
            ? (organizationName ?? '')
            : (args['firstName'] ?? ''),
        apellido: role == 'ORGANIZACION' ? '' : (args['lastName'] ?? ''),
        usuario: args['username'] ?? '',
        contrasenia: args['password'] ?? '',
        rol: role,
        celular: args['phone'],
        organizationName: organizationName,
        region: region,
        zone: zone,
        locationLabel: locationLabel,
        latitude: latitude,
        longitude: longitude,
        discoveryRadiusKm: radius,
      ),
    );
    final dto = await auth.iniciarSesion(
      InicioSesionRequest(
        usuario: args['username'],
        contrasenia: args['password'],
      ),
    );
    SessionManager().setSession(
      token: dto.token,
      refreshToken: dto.refreshToken,
      rol: role,
      username: args['username'],
      nombre: args['firstName'],
      apellido: role == 'ORGANIZACION' ? null : args['lastName'],
      telefono: args['phone'],
    );
    if (role == 'ORGANIZACION' && organizationImage != null) {
      await OrganizationService().uploadProfileImage(organizationImage);
    }
    if (context.mounted) {
      final destination = role == 'ORGANIZACION'
          ? '/organization_home'
          : role == 'REPARTIDOR'
          ? '/courier_home'
          : '/home';
      Navigator.pushNamedAndRemoveUntil(context, destination, (_) => false);
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
    rethrow;
  }
}

class _AccountControllers {
  _AccountControllers({this.personal = true});
  final bool personal;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  final phone = TextEditingController();

  Map<String, dynamic> arguments({String? organizationName}) => {
    'firstName': personal ? firstName.text.trim() : (organizationName ?? ''),
    'lastName': personal ? lastName.text.trim() : '',
    'username': username.text.trim(),
    'password': password.text,
    'phone': phone.text.trim(),
  };

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    username.dispose();
    password.dispose();
    phone.dispose();
  }
}

class _AccountFields extends StatelessWidget {
  const _AccountFields({required this.account});
  final _AccountControllers account;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (account.personal) ...[
        _Field(controller: account.firstName, label: 'Nombres'),
        _Field(controller: account.lastName, label: 'Apellidos'),
      ],
      _Field(
        controller: account.username,
        label: 'Usuario',
        validator: (value) {
          final username = value?.trim() ?? '';
          if (username.isEmpty) return 'Campo obligatorio';
          if (username.length < 3) return 'Usa al menos 3 caracteres';
          if (username.contains(RegExp(r'\s'))) return 'No uses espacios';
          return null;
        },
      ),
      _Field(
        controller: account.password,
        label: 'Contraseña',
        obscureText: true,
        validator: (value) => value == null || value.length < 6
            ? 'Usa al menos 6 caracteres'
            : null,
      ),
      _Field(
        controller: account.phone,
        label: 'Celular',
        keyboardType: TextInputType.phone,
        validator: (value) {
          final phone = (value ?? '').replaceAll(RegExp(r'[\s()+-]'), '');
          if (phone.isEmpty) return 'Campo obligatorio';
          if (!RegExp(r'^\d{9,15}$').hasMatch(phone)) {
            return 'Ingresa un celular válido';
          }
          return null;
        },
      ),
    ],
  );
}

class _FlowScaffold extends StatelessWidget {
  const _FlowScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });
  final String title, subtitle;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      elevation: 0,
      title: const Text(
        'TINKIYAGRO',
        style: TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 27,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2933),
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6E7A78))),
          const SizedBox(height: 20),
          ...children.map(
            (e) =>
                Padding(padding: const EdgeInsets.only(bottom: 14), child: e),
          ),
        ],
      ),
    ),
  );
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.selected,
    required this.onTap,
  });
  final String title, subtitle, tag;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE0F2ED) : Colors.white,
        border: Border.all(
          color: selected ? _brand : const Color(0xFFDEE5E3),
          width: selected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(color: Color(0xFF6E7A78))),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: selected ? _brand : _background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? Colors.white : const Color(0xFF6E7A78),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator:
        validator ??
        (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
    decoration: InputDecoration(
      labelText: '$label *',
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDEE5E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDEE5E3)),
      ),
    ),
  );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: _brand,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: loading
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}
