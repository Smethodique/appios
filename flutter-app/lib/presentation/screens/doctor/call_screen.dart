import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';

class _Parent {
  final int id;
  final String name;
  final String email;
  _Parent({required this.id, required this.name, required this.email});
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  List<_Parent> _parents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get('${ApiConfig.callsEndpoint}/parents');
      final list = (data is Map) ? (data['parents'] ?? []) : (data is List ? data : []);
      final parents = <_Parent>[];
      for (final e in list) {
        if (e is Map) {
          parents.add(_Parent(
            id: (e['id'] as num?)?.toInt() ?? 0,
            name: (e['name'] as String?) ?? '',
            email: (e['email'] as String?) ?? '',
          ));
        }
      }
      if (mounted) setState(() => _parents = parents);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startCall(_Parent parent) async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.post(ApiConfig.callsEndpoint,
          body: {'parent_id': parent.id});
      final call = (r is Map) ? (r['call'] as Map?) : null;
      final url = call?['url'] as String?;
      if (url == null || url.isEmpty) {
        throw ApiException(message: 'Impossible de créer l\'appel', statusCode: 0);
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RoomWebviewScreen(
              url: url,
              title: 'Appel — ${parent.name}',
              roomName: call?['room_name'] as String?)));
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Appels vidéo',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _parents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone_in_talk_rounded,
                          color: Colors.white24, size: 64),
                      const SizedBox(height: 14),
                      const Text('Aucun parent dans vos contacts',
                          style: TextStyle(color: Colors.white54)),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
                      ],
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _refresh,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Actualiser',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFFBD7F66),
                  backgroundColor: const Color(0xFF0F172A),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final p = _parents[i];
                      return Material(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFBD7F66)
                                .withValues(alpha: 0.25),
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(p.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(p.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white38)),
                          trailing: IconButton(
                            icon: const Icon(Icons.videocam_rounded,
                                color: Color(0xFFBD7F66), size: 26),
                            tooltip: 'Appeler',
                            onPressed: () => _startCall(p),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}