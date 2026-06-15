import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/auth/data/remote/auth_service.dart';

class ConsumerAboutMePage extends StatefulWidget {
  const ConsumerAboutMePage({super.key});

  @override
  State<ConsumerAboutMePage> createState() => _ConsumerAboutMePageState();
}

class _ConsumerAboutMePageState extends State<ConsumerAboutMePage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  File? _profileImage;
  bool _loadingProfile = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final session = SessionManager();
    // Pre-fill from cached session first for instant display
    _nameController.text = [
      session.nombre,
      session.apellido,
    ].where((s) => s != null && s.isNotEmpty).join(' ');
    _usernameController.text = session.username ?? '';
    _phoneController.text = session.telefono ?? '';

    // Then try to refresh from API
    final token = session.token;
    if (token != null) {
      try {
        final data = await AuthService().obtenerPerfil(token);
        if (!mounted) return;
        final nombre = data['firstName']?.toString() ?? '';
        final apellido = data['lastName']?.toString() ?? '';
        final usuario = data['username']?.toString() ?? '';
        final telefono = data['phoneNumber']?.toString() ?? '';
        setState(() {
          _nameController.text = [
            nombre,
            apellido,
          ].where((s) => s.isNotEmpty).join(' ');
          _usernameController.text = usuario;
          _phoneController.text = telefono;
        });
      } catch (_) {
        // keep session-cached values on error
      }
    }

    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CA399)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildPhotoSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Detalles personales'),
                  const SizedBox(height: 12),
                  _buildField(
                    icon: Icons.person_outline,
                    controller: _nameController,
                    hint: 'Nombre completo',
                  ),
                  const SizedBox(height: 10),
                  _buildField(
                    icon: Icons.alternate_email,
                    controller: _usernameController,
                    hint: 'Usuario',
                  ),
                  const SizedBox(height: 10),
                  _buildField(
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    hint: 'Celular',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Cambiar contraseña'),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _newPasswordController,
                    hint: 'Nueva contraseña',
                    show: _showNewPassword,
                    onToggle: () =>
                        setState(() => _showNewPassword = !_showNewPassword),
                  ),
                  const SizedBox(height: 10),
                  _buildPasswordField(
                    controller: _confirmPasswordController,
                    hint: 'Confirmar contraseña',
                    show: _showConfirmPassword,
                    onToggle: () => setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _buildSaveButton(context),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFFE0EFED),
            backgroundImage: _profileImage != null
                ? FileImage(_profileImage!)
                : null,
            child: _profileImage == null
                ? const Icon(Icons.person, size: 48, color: Color(0xFF5CA399))
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFF5CA399),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
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
        'Sobre mi',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildField({
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
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
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
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
        obscureText: !show,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.grey.shade400,
            size: 22,
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          suffixIcon: IconButton(
            icon: Icon(
              show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.grey.shade400,
              size: 22,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final fullName = _nameController.text.trim();
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = _phoneController.text.trim();
    final token = SessionManager().token;

    if (token == null) return;

    setState(() => _guardando = true);
    try {
      await AuthService().actualizarPerfil(
        token: token,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      SessionManager().setSession(
        nombre: firstName,
        apellido: lastName,
        telefono: phone,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil guardado correctamente.'),
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
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
