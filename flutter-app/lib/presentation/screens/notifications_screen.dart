import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/presentation/screens/main_shell.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      read: json['read_at'] != null,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.get(ApiConfig.notificationsEndpoint);
      final list = data['notifications'] as List? ?? [];
      setState(() {
        _items = list.map((j) => AppNotification.fromJson(j as Map<String, dynamic>)).toList();
        _loading = false;
      });
      MainShell.notificationRefreshTick.value++;
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(AppNotification n) async {
    await ApiService.post('/notifications/${n.id}/read', body: {});
    _load();
  }

  Future<void> _markAll() async {
    await ApiService.post('/notifications/read-all', body: {});
    _load();
  }

  IconData _icon(String type) {
    if (type.contains('vaccine')) return Icons.vaccines;
    if (type.contains('appointment')) return Icons.event;
    if (type.contains('live')) return Icons.live_tv;
    if (type.contains('subscription')) return Icons.card_membership;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAll,
            child: const Text('Tout lire', style: TextStyle(color: Color(0xFFBD7F66))),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final n = _items[i];
                    return ListTile(
                      leading: Icon(_icon(n.type), color: n.read ? Colors.grey : const Color(0xFFBD7F66)),
                      title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.body.isEmpty ? n.createdAt : n.body),
                      trailing: n.read ? null : Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(color: Color(0xFFBD7F66), shape: BoxShape.circle),
                      ),
                      onTap: () => _markRead(n),
                    );
                  },
                ),
    );
  }
}
