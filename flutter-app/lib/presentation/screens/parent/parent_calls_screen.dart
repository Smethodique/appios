import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';

class _Call {
  final int id;
  final String roomName;
  final String status;
  final String? doctorName;
  final DateTime? createdAt;
  _Call({
    required this.id,
    required this.roomName,
    required this.status,
    this.doctorName,
    this.createdAt,
  });
}

class ParentCallsScreen extends StatefulWidget {
  const ParentCallsScreen({super.key});

  @override
  State<ParentCallsScreen> createState() => _ParentCallsScreenState();
}

class _ParentCallsScreenState extends State<ParentCallsScreen> {
  List<_Call> _calls = [];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refresh(silent: true);
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (silent && !mounted) return;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await ApiService.get('${ApiConfig.callsEndpoint}/mine');
      final list =
          (data is Map) ? ((data['calls'] as List?) ?? []) : (data is List ? data : []);
      final calls = <_Call>[];
      for (final e in list) {
        if (e is Map) {
          calls.add(_Call(
            id: (e['id'] as num?)?.toInt() ?? 0,
            roomName: (e['room_name'] as String?) ?? '',
            status: (e['status'] as String?) ?? '',
            doctorName: (e['doctor_name'] as String?),
            createdAt: DateTime.tryParse((e['created_at'] as String?) ?? ''),
          ));
        }
      }
      if (mounted) setState(() => _calls = calls);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _join(_Call call) async {
    if (call.status == 'ended') {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cet appel est terminé.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final r = await ApiService.post(
        '${ApiConfig.callJoinEndpoint}/${call.roomName}/join',
        body: {},
      );
      final url = (r is Map) ? r['prebuilt_url'] as String? : null;
      if (url == null || url.isEmpty) {
        throw ApiException(message: 'Impossible de rejoindre l\'appel', statusCode: 0);
      }
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RoomWebviewScreen(
              url: url,
              title: 'Appel — Dr. ${call.doctorName ?? 'Médecin'}',
              roomName: call.roomName)));
      if (mounted) _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String s) => switch (s) {
        'active' => const Color(0xFF22C55E),
        'ringing' => const Color(0xFFF59E0B),
        'ended' => const Color(0xFF64748B),
        _ => const Color(0xFF64748B),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Appels du Médecin',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _calls.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_in_talk_rounded,
                          color: const Color(0xFFBD7F66).withValues(alpha: 0.3),
                          size: 64),
                      const SizedBox(height: 14),
                      const Text('Aucun appel du médecin',
                          style: TextStyle(color: Color(0xFF8B8173), fontSize: 16)),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!,
                            style: const TextStyle(color: Color(0xFFEF4444))),
                      ],
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: () => _refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Actualiser',
                            style: TextStyle(color: Color(0xFFBD7F66))),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _refresh(),
                  color: const Color(0xFFBD7F66),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _calls.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = _calls[i];
                      final active = (c.status == 'active' || c.status == 'ringing') &&
                          c.createdAt != null &&
                          DateTime.now().difference(c.createdAt!).inMinutes < 30;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: active
                              ? Border.all(color: const Color(0xFF22C55E), width: 1.2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(c.status).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    c.status == 'active'
                                        ? 'EN COURS'
                                        : c.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(c.status),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(_fmt(c.createdAt),
                                    style: const TextStyle(
                                        color: Color(0xFFA69D8F), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Dr. ${c.doctorName ?? 'Médecin'}',
                                style: const TextStyle(
                                    color: Color(0xFFBD7F66),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            const Text('Appel vidéo privé',
                                style: TextStyle(
                                    color: Color(0xFF8B8173), fontSize: 13)),
                            if (active) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF22C55E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _join(c),
                                  icon: const Icon(Icons.call, size: 18),
                                  label: const Text('Rejoindre l\'appel'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
