import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/auth_service.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/register_request.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  String? _selectedRole = '';
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final username = args['username']?.toString() ?? 'Usuario';
    final firstName = args['firstName']?.toString() ?? '';
    final lastName = args['lastName']?.toString() ?? '';
    final password = args['password']?.toString() ?? '';
    final phone = args['phone']?.toString() ?? '';

    return Scaffold(
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

          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1E3A32).withOpacity(0.90),
                  const Color(0xFF0F1E1A).withOpacity(0.75),
                  const Color(0xFF070F0D).withOpacity(0.90),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),

                  const Spacer(flex: 1),

                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 120,
                      height: 120,
                    ),
                  ),

                  const Spacer(flex: 2),

                  const Text(
                    '¿Cómo usarás la app?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '(Selecciona una opción para continuar)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),

                  // Roles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRoleCard(
                        roleId: 'AGRICULTOR',
                        title: 'Agricultor',
                        iconData: Icons.agriculture_rounded,
                      ),
                      _buildRoleCard(
                        roleId: 'CONSUMIDOR',
                        title: 'Cliente',
                        iconData: Icons.shopping_basket_rounded,
                      ),
                      _buildRoleCard(
                        roleId: 'REPARTIDOR',
                        title: 'Repartidor',
                        iconData: Icons.local_shipping_rounded,
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _selectedRole == null || _isLoading
                          ? null
                          : () => _finishRegistration(
                              username,
                              firstName,
                              lastName,
                              password,
                              phone,
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5CA399),
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: const StadiumBorder(),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Finalizar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard({
    required String roleId,
    required String title,
    required IconData iconData,
  }) {
    final isSelected = _selectedRole == roleId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 100,
          height: 155,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
            border: Border.all(
              color: isSelected ? const Color(0xFF5CA399) : Colors.transparent,
              width: 3.5,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF5CA399).withOpacity(0.45),
                  blurRadius: 16.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF5CA399).withOpacity(0.1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  size: 52,
                  color: isSelected ? const Color(0xFF5CA399) : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF5CA399) : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishRegistration(
    String username,
    String firstName,
    String lastName,
    String password,
    String phone,
  ) async {
    final roleName = _selectedRole ?? 'CONSUMIDOR';

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.registrarUsuario(
        RegistroRequest(
          nombre: firstName,
          apellido: lastName,
          usuario: username,
          contrasenia: password,
          rol: roleName.toUpperCase(),
          celular: phone.isNotEmpty ? phone : null,
        ),
      );

      SessionManager().setSession(
        rol: roleName,
        username: username,
        nombre: firstName.isNotEmpty ? firstName : username,
      );

      if (!mounted) {
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Column(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFF5CA399),
                size: 64,
              ),
              SizedBox(height: 12),
              Text(
                '¡Registro Completado!',
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Text(
            'Hola ${firstName.isNotEmpty ? firstName : username}, tu cuenta ha sido creada exitosamente con el perfil de ${_selectedRole == 'AGRICULTOR' ? 'Agricultor' : _selectedRole == 'REPARTIDOR' ? 'Repartidor' : 'Cliente'}.\n\nYa puedes conectar en TinkiyAgro.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            Center(
              child: SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    final dest = roleName == 'REPARTIDOR' ? '/repartidor_home' : '/home';
                    Navigator.of(context).pushNamedAndRemoveUntil(dest, (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CA399),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text(
                    'Comenzar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
