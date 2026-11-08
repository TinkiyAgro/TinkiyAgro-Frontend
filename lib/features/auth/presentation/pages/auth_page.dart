import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/auth_service.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/login_request.dart';
import 'package:tinkiyagro_app/core/notifications/push_notification_service.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/organization/data/organization_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();

  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  bool _loginPassVisible = false;
  final _authService = AuthService();

  bool _isInit = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is int) {
        _tabController.index = args;
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1E3A32).withValues(alpha: 0.85),
                    const Color(0xFF1E3A32).withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 150,
                    height: 150,
                  ),
                ),
              ],
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutQuad,
            left: 0,
            right: 0,
            bottom: 0,
            height: keyboardHeight > 0
                ? size.height * 0.75 + keyboardHeight
                : size.height * 0.72,
            child: Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 28,
                right: 28,
                bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    _buildToggleSlider(),
                    const SizedBox(height: 24),
                    Text(
                      _tabController.index == 0
                          ? 'Bienvenido a TinkiyAgro'
                          : 'Completa tu información',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [_buildLoginForm(), _buildRegisterForm()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSlider() {
    final width = MediaQuery.of(context).size.width - 56;

    return Container(
      height: 52,
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _tabController.index == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: Container(
              width: width / 2,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF5CA399),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5CA399).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabController.animateTo(0)),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 0
                            ? Colors.white
                            : Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _tabController.animateTo(1)),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _tabController.index == 1
                            ? Colors.white
                            : Colors.black54,
                      ),
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

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildTextField(
            controller: _loginUserCtrl,
            labelText: 'Usuario',
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Ingresa tu usuario' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _loginPassCtrl,
            labelText: 'Contraseña',
            obscureText: !_loginPassVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _loginPassVisible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _loginPassVisible = !_loginPassVisible),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
              if (v.length < 4) return 'Contraseña muy corta';
              return null;
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CA399),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _buildForgotPasswordLink(),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Icon(
          Icons.account_circle_outlined,
          size: 72,
          color: Color(0xFF5CA399),
        ),
        const SizedBox(height: 16),
        const Text(
          'Primero elige cómo usarás TinkiyAgro',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Te mostraremos únicamente los datos necesarios para tu tipo de cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/role_selection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5CA399),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Elegir tipo de cuenta',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        suffixIcon: suffixIcon,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD6D6D6), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF5CA399), width: 2.0),
        ),
        errorStyle: const TextStyle(fontSize: 11, height: 0.8),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Funcionalidad para recuperar contraseña en desarrollo.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _submitLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dto = await _authService.iniciarSesion(
        InicioSesionRequest(
          usuario: _loginUserCtrl.text.trim(),
          contrasenia: _loginPassCtrl.text,
        ),
      );

      String role = 'CONSUMIDOR';
      String name = _loginUserCtrl.text.trim();
      String apellido = '';
      String? telefono;
      String? email;

      String parseRole(dynamic roleVal) {
        if (roleVal == null) return 'CONSUMIDOR';
        if (roleVal is List) {
          if (roleVal.isEmpty) return 'CONSUMIDOR';
          return roleVal.first.toString().toUpperCase().replaceAll('ROLE_', '');
        }
        return roleVal.toString().toUpperCase().replaceAll('ROLE_', '');
      }

      try {
        final profile = await _authService.obtenerPerfil(dto.token);
        role = parseRole(profile['role'] ?? profile['rol']);
        final firstName = profile['firstName'] ?? profile['nombre'] ?? '';
        final lastName = profile['lastName'] ?? profile['apellido'] ?? '';
        if (firstName.isNotEmpty) {
          name = firstName;
          apellido = lastName;
        }
        telefono =
            profile['phone']?.toString() ?? profile['celular']?.toString();
        email = profile['email']?.toString();
      } catch (_) {
        final jwtData = SessionManager.decodeJwt(dto.token);
        if (jwtData != null) {
          role = parseRole(
            jwtData['role'] ?? jwtData['rol'] ?? jwtData['roles'],
          );
          name =
              jwtData['firstName'] ??
              jwtData['nombre'] ??
              jwtData['username'] ??
              name;
        }
      }

      SessionManager().setSession(
        token: dto.token,
        refreshToken: dto.refreshToken,
        rol: role,
        username: _loginUserCtrl.text.trim(),
        nombre: name,
        apellido: apellido.isNotEmpty ? apellido : null,
        telefono: telefono,
        email: email,
      );
      await PushNotificationService.instance.registerCurrentDevice();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inicio de sesión exitoso')));

      String destination = role == 'REPARTIDOR'
          ? '/courier_home'
          : role == 'ORGANIZACION'
          ? '/organization_home'
          : '/home';
      if (role == 'CONSUMIDOR') {
        try {
          final preference = await OrganizationService()
              .getDiscoveryPreferences();
          if (preference['configured'] != true) {
            destination = '/consumer_discovery_update';
          }
        } catch (_) {
          destination = '/consumer_discovery_update';
        }
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, destination, (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
