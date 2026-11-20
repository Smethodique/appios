import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';

class LiveSessionsScreen extends StatefulWidget {
  const LiveSessionsScreen({super.key});

  @override
  State<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends State<LiveSessionsScreen> {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _phpDateTime(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get(ApiConfig.liveSessionsEndpoint);
      final list = _parseSessions(data);
      final mine = <Map<String, dynamic>>[];
      for (final e in list) {
        if ((e['doctor_id'] as num?)?.toInt() == ApiService.meId) {
          mine.add(e);
        }
      }
      if (mounted) setState(() => _sessions = mine);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('[Lives] doctor _refresh error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> _parseSessions(dynamic data) {
    try {
      final raw = (data is Map) ? (data['data'] ?? []) : (data is List ? data : []);
      if (raw is List) {
        return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> _createSession(
      String title, String theme, String scheduledAt, String targetPlan) async {
    final r = await ApiService.post(ApiConfig.liveSessionsEndpoint, body: {
      'title': title,
      'theme': theme,
      'scheduled_at': scheduledAt,
      'target_plan': targetPlan,
    });
    if (r is Map && r['session'] is Map) {
      return Map<String, dynamic>.from(r['session'] as Map);
    }
    return null;
  }

  Future<void> _createDialog() async {
    final title = TextEditingController();
    final theme = TextEditingController();
    final schedule =
        TextEditingController(text: _phpDateTime(DateTime.now().add(const Duration(minutes: 1))));
    String targetPlan = 'all';
    final form = GlobalKey<FormState>();
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialState) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Nouveau live',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: title,
                style: const TextStyle(color: Colors.white),
                decoration: _in('Titre du live'),
                validator: (v) => v?.isEmpty == true ? 'Titre requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: theme,
                style: const TextStyle(color: Colors.white),
                decoration: _in('Thème (ex: Vaccins)'),
                validator: (v) => v?.isEmpty == true ? 'Thème requis' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: schedule,
                style: const TextStyle(color: Colors.white),
                decoration: _in('Début (AAAA-MM-JJ HH:MM:SS)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Date requise';
                  final parsed = DateTime.tryParse(v.replaceFirst(' ', 'T'));
                  if (parsed == null || !parsed.isAfter(DateTime.now())) {
                    return 'Date après maintenant';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: targetPlan,
                dropdownColor: const Color(0xFF0F172A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _in('Public du live'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous les abonnés')),
                  DropdownMenuItem(value: 'family', child: Text('Family uniquement')),
                  DropdownMenuItem(value: 'family_plus', child: Text('Family Plus uniquement')),
                ],
                onChanged: (v) => setDialState(() => targetPlan = v ?? 'all'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Créer', style: TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w700))),
        ],
      ),
    ),
    );
    if (created != true || !mounted) return;
    setState(() => _loading = true);
    try {
      final s = await _createSession(title.text.trim(), theme.text.trim(), schedule.text.trim(), targetPlan);
      if (s == null) throw ApiException(message: 'Création du live impossible', statusCode: 0);
      await _goLive(s, announce: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _goLive(Map<String, dynamic> session,
      {bool announce = false}) async {
    final id = (session['id'] as num?)?.toInt();
    String? url;
    try {
      // joining marks the session as "live" and returns a FRESH owner URL
      final r = await ApiService.post('/live-sessions/$id/join', body: {});
      if (r is Map) {
        url = r['prebuilt_url'] as String?;
      }
    } catch (_) {}
    url ??= (session['stream_url'] as String?) ??
        'https://mediped.daily.co/${session['daily_room_name']}';
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RoomWebviewScreen(
            url: url!,
            title: 'Live — ${session['title']}',
            sessionId: id,
            isOwner: true)));
    _refresh();
  }

  Future<void> _endSession(Map<String, dynamic> session) async {
    final id = (session['id'] as num?)?.toInt();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Terminer le live ?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Oui, terminer',
                  style: TextStyle(
                      color: Color(0xFFEF4444), fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || id == null) return;
    try {
      await ApiService.post('/live-sessions/$id/end', body: {});
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
    _refresh();
  }

  InputDecoration _in(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        errorStyle: const TextStyle(color: Color(0xFFFCA5A5)),
      );

  String _fmt(String? iso) {
    final d = DateTime.tryParse(iso ?? '');
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} à '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String s) => switch (s) {
        'live' => const Color(0xFF22C55E),
        'scheduled' => const Color(0xFFF59E0B),
        'ended' => const Color(0xFF64748B),
        'canceled' => const Color(0xFFEF4444),
        _ => const Color(0xFF64748B),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Mes Lives', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE11D48),
        foregroundColor: Colors.white,
        onPressed: _loading ? null : _createDialog,
        icon: const Icon(Icons.live_tv_rounded),
        label: const Text('Lancer un live'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.live_tv_rounded, color: Colors.white24, size: 64),
                      const SizedBox(height: 14),
                      const Text('Aucun live pour le moment',
                          style: TextStyle(color: Colors.white54)),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5))),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFFBD7F66),
                  backgroundColor: const Color(0xFF0F172A),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final s = _sessions[i];
                      final status = (s['status'] as String?) ?? '';
                      final live = status == 'live';
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(18),
                          border: live
                              ? Border.all(color: const Color(0xFF22C55E), width: 1.2)
                              : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status == 'live'
                                        ? 'EN DIRECT'
                                        : status.toUpperCase(),
                                    style: TextStyle(
                                        color: _statusColor(status),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6),
                                  ),
                                ),
                                const Spacer(),
                                Text(_fmt(s['scheduled_at'] as String?),
                                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(s['title'] as String? ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700)),
                            if ((s['theme'] as String?)?.isNotEmpty == true)
                              Text(s['theme'] as String,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            if ((s['target_plan'] as String?) == 'family' ||
                                (s['target_plan'] as String?) == 'family_plus') ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  (s['target_plan'] as String) == 'family_plus'
                                      ? 'Family Plus'
                                      : 'Family',
                                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            if (!live && status != 'ended' && status != 'canceled') ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF22C55E)),
                                      onPressed: () => _goLive(s),
                                      icon: const Icon(Icons.sensors_rounded, size: 18),
                                      label: const Text('Lancer'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _endSession(s),
                                    icon: const Icon(Icons.stop_circle_rounded,
                                        color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            ] else if (live) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFFBD7F66)),
                                      onPressed: () => _goLive(s),
                                      icon: const Icon(Icons.videocam_rounded, size: 18),
                                      label: const Text('Rejoindre'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => _endSession(s),
                                    icon: const Icon(Icons.stop_circle_rounded,
                                        color: Color(0xFFEF4444)),
                                  ),
                                ],
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