import 'package:flutter/material.dart';
import 'package:tinkiyagro_app/core/notifications/notification_history_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationHistoryService();
  List<AppNotification> _notifications = const [];
  bool _loading = true;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final notifications = await _service.list();
      if (mounted) setState(() => _notifications = notifications);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudieron cargar las notificaciones');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read) return;
    setState(() {
      _notifications = _notifications
          .map(
            (item) =>
                item.id == notification.id ? item.copyWith(read: true) : item,
          )
          .toList();
    });
    try {
      await _service.markRead(notification.id);
    } catch (_) {
      if (mounted) await _load();
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAll || !_notifications.any((item) => !item.read)) return;
    setState(() => _markingAll = true);
    try {
      await _service.markAllRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((item) => item.copyWith(read: true))
              .toList();
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudieron marcar como leídas.')),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((item) => !item.read);
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          if (hasUnread)
            IconButton(
              tooltip: 'Marcar todas como leídas',
              onPressed: _markingAll ? null : _markAllRead,
              icon: _markingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.done_all, color: Color(0xFF5CA399)),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5CA399),
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5CA399)),
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 180),
          const Icon(Icons.cloud_off_outlined, size: 54, color: Colors.grey),
          const SizedBox(height: 12),
          Center(
            child: Text(_error!, style: const TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }
    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Icon(Icons.notifications_none, size: 58, color: Colors.grey),
          SizedBox(height: 12),
          Center(
            child: Text(
              'Aún no tienes notificaciones',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, index) => _notificationTile(_notifications[index]),
    );
  }

  Widget _notificationTile(AppNotification notification) {
    return Material(
      color: notification.read ? Colors.white : const Color(0xFFEAF6F3),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _markRead(notification),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF5CA399),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(notification.type),
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: notification.read
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.read)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                              radius: 4,
                              backgroundColor: Color(0xFF5CA399),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'ORDER_CONFIRMED':
      case 'FARMER_ORDER_RECEIVED':
        return Icons.receipt_long_outlined;
      case 'COURIER_ASSIGNED':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final now = DateTime.now();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    if (local.year == now.year &&
        local.month == now.month &&
        local.day == now.day) {
      return 'Hoy, $time';
    }
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} · $time';
  }
}
