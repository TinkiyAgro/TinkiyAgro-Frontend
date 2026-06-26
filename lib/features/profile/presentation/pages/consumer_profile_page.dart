import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/notifications/push_notification_service.dart';
import 'package:tinkiyagro_app/core/session_manager.dart';
import 'package:tinkiyagro_app/features/catalog/data/product_model.dart';
import 'package:tinkiyagro_app/features/profile/data/remote/profile_service.dart';
import 'consumer_about_me_page.dart';
import 'consumer_addresses_page.dart';
import 'consumer_transactions_page.dart';
import 'notifications_page.dart';

class ConsumerProfilePage extends StatefulWidget {
  final void Function(int tabIndex) onTabSwitch;

  const ConsumerProfilePage({super.key, required this.onTabSwitch});

  @override
  State<ConsumerProfilePage> createState() => _ConsumerProfilePageState();
}

class _ConsumerProfilePageState extends State<ConsumerProfilePage> {
  final _service = ProfileService();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final data = await _service.obtenerPerfil();
      final raw =
          data['profileImageUrl'] ??
          data['avatarUrl'] ??
          data['imageUrl'] ??
          data['profileImage'] ??
          data['photo'];
      if (raw != null && mounted) {
        setState(() => _avatarUrl = resolveMediaUrl(raw.toString()));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionManager();
    final name =
        [
          session.nombre,
          session.apellido,
        ].where((s) => s != null && s.isNotEmpty).join(' ').isNotEmpty
        ? [
            session.nombre,
            session.apellido,
          ].where((s) => s != null && s.isNotEmpty).join(' ')
        : session.username ?? 'Usuario';
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(name),
            _buildMenuList(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: _avatarUrl == null || _avatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 56, color: Colors.white)
                    : null,
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConsumerAboutMePage(),
                    ),
                  ).then((_) => _loadAvatar()),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF5CA399),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            label: 'Sobre mi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsumerAboutMePage()),
            ).then((_) => _loadAvatar()),
          ),
          _buildMenuItem(
            context,
            icon: Icons.inbox_outlined,
            label: 'Mis pedidos',
            onTap: () => widget.onTabSwitch(3),
          ),
          _buildMenuItem(
            context,
            icon: Icons.favorite_border,
            label: 'Mis favoritos',
            onTap: () => widget.onTabSwitch(1),
          ),
          _buildMenuItem(
            context,
            icon: Icons.location_on_outlined,
            label: 'Mis direcciones',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConsumerAddressesPage()),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.receipt_long_outlined,
            label: 'Transacciones',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsumerTransactionsPage(),
              ),
            ),
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_none,
            label: 'Notificaciones',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
          ),
          _buildSignOutItem(context),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5CA399), size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PushNotificationService.instance.unregisterCurrentDevice();
        SessionManager().clearSession();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        child: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFF5CA399), size: 24),
            SizedBox(width: 14),
            Text(
              'Cerrar sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
