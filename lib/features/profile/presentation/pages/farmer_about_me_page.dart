import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import 'package:tinkiyagro_app/features/profile/data/remote/profile_service.dart';

class FarmerAboutMePage extends StatefulWidget {
  const FarmerAboutMePage({super.key});

  @override
  State<FarmerAboutMePage> createState() => _FarmerAboutMePageState();
}

class _FarmerAboutMePageState extends State<FarmerAboutMePage> {
  final _service = ProfileService();

  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  File? _profileImage;
  String? _avatarUrl;
  bool _loadingProfile = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Pre-fill from session cache
    final session = SessionManager();
    _nameController.text = [session.nombre, session.apellido]
        .where((s) => s != null && s.isNotEmpty)
        .join(' ');
    _usernameController.text = session.username ?? '';
    _phoneController.text = session.telefono ?? '';

    try {
      final data = await _service.obtenerPerfilAgricultor();
      if (!mounted) return;
      final nombre = data['firstName']?.toString() ?? '';
      final apellido = data['lastName']?.toString() ?? '';
      final usuario = data['username']?.toString() ?? '';
      final telefono = data['phoneNumber']?.toString() ?? data['phone']?.toString() ?? '';
      final descripcion = data['description']?.toString()
          ?? data['bio']?.toString()
          ?? data['aboutMe']?.toString()
          ?? '';
      final avatarRaw = data['profileImageUrl']
          ?? data['avatarUrl']
          ?? data['imageUrl']
          ?? data['profileImage']
          ?? data['photo'];
      setState(() {
        if (nombre.isNotEmpty || apellido.isNotEmpty) {
          _nameController.text =
              [nombre, apellido].where((s) => s.isNotEmpty).join(' ');
        }
        if (usuario.isNotEmpty) _usernameController.text = usuario;
        if (telefono.isNotEmpty) _phoneController.text = telefono;
        _descriptionController.text = descripcion;
        if (avatarRaw != null) _avatarUrl = resolveMediaUrl(avatarRaw.toString());
      });
    } catch (_) {
      // keep session-cached values on error
    }

    if (mounted) setState(() => _loadingProfile = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final fullName = _nameController.text.trim();
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = _phoneController.text.trim();
    final description = _descriptionController.text.trim();

    final currentPwd = _currentPasswordController.text;
    final newPwd = _newPasswordController.text;
    final confirmPwd = _confirmPasswordController.text;
    final passwordFilled =
        currentPwd.isNotEmpty || newPwd.isNotEmpty || confirmPwd.isNotEmpty;

    if (passwordFilled) {
      if (currentPwd.isEmpty) {
        _showSnackBar('Ingresa tu contraseña actual', error: true);
        return;
      }
      if (newPwd.isEmpty) {
        _showSnackBar('Ingresa la nueva contraseña', error: true);
        return;
      }
      if (newPwd != confirmPwd) {
        _showSnackBar('Las contraseñas nuevas no coinciden', error: true);
        return;
      }
    }

    setState(() => _guardando = true);
    try {
      if (_profileImage != null) {
        await _service.subirFotoPerfil(_profileImage!);
      }
      await _service.editarPerfilAgricultor(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        description: description,
      );
      SessionManager().setSession(
        nombre: firstName,
        apellido: lastName,
        telefono: phone,
      );

      if (passwordFilled) {
        await _service.cambiarContrasena(
          currentPassword: currentPwd,
          newPassword: newPwd,
          confirmPassword: confirmPwd,
        );
      }

      if (mounted) {
        _showSnackBar('Perfil guardado correctamente');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString(), error: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showSnackBar(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.redAccent : const Color(0xFF5CA399),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: _buildAppBar(context),
      body: _loadingProfile
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5CA399)))
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
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  _buildField(
                    icon: Icons.phone_outlined,
                    controller: _phoneController,
                    hint: 'Celular',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _buildDescriptionField(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Cambiar contraseña'),
                  const SizedBox(height: 12),
                  _buildPasswordField(
                    controller: _currentPasswordController,
                    hint: 'Contraseña actual',
                    show: _showCurrentPassword,
                    onToggle: () => setState(
                        () => _showCurrentPassword = !_showCurrentPassword),
                  ),
                  const SizedBox(height: 10),
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
                    hint: 'Confirmar nueva contraseña',
                    show: _showConfirmPassword,
                    onToggle: () => setState(
                        () => _showConfirmPassword = !_showConfirmPassword),
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
                ? FileImage(_profileImage!) as ImageProvider
                : (_avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null),
            child: (_profileImage == null && (_avatarUrl == null || _avatarUrl!.isEmpty))
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
                child: const Icon(Icons.camera_alt,
                    size: 18, color: Colors.white),
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
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade50 : Colors.white,
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
        readOnly: readOnly,
        style: TextStyle(
            fontSize: 15,
            color: readOnly ? Colors.grey.shade500 : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon,
              color: readOnly
                  ? Colors.grey.shade300
                  : Colors.grey.shade400,
              size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
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
        controller: _descriptionController,
        maxLines: 3,
        style: const TextStyle(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Icon(Icons.info_outline,
                color: Colors.grey.shade400, size: 22),
          ),
          hintText:
              'ej: Mi nombre es Olivia, soy de la región de Ayacucho y '
              'me dedico a la agricultura, principalmente al cultivo de '
              'maíz, rocoto y choclo.',
          hintStyle: TextStyle(
              color: Colors.grey.shade400, fontSize: 14, height: 1.4),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
          prefixIcon: Icon(Icons.lock_outline,
              color: Colors.grey.shade400, size: 22),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          suffixIcon: IconButton(
            icon: Icon(
              show
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey.shade400,
              size: 22,
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
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
              : const Text(
                  'Guardar',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
