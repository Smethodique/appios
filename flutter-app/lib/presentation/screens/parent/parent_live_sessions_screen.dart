import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:medcin_app/presentation/screens/subscription_screen.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class ParentLiveSessionsScreen extends StatefulWidget {
  const ParentLiveSessionsScreen({super.key});

  @override
  State<ParentLiveSessionsScreen> createState() => _ParentLiveSessionsScreenState();
}

class _ParentLiveSessionsScreenState extends State<ParentLiveSessionsScreen> {
  List<Map<String, dynamic>> _sessions = [];
  List<Map<String, dynamic>> _polls = [];
  int? _liveSessionId;
  int? _votingPollId;
  int? _votingIndex;
  bool _loading = true;
  bool _refreshing = false;
  bool _pollsLoading = false;
  String? _error;
  PusherChannelsFlutter? _pusher;
  Timer? _pollsTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscribeToLives();
    _pollsTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_loading) _silentRefresh();
    });
  }

  @override
  void dispose() {
    _pollsTimer?.cancel();
    _disconnectPusher();
    super.dispose();
  }

  Future<void> _subscribeToLives() async {
    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: ApiConfig.pusherAppKey,
        cluster: ApiConfig.pusherCluster,
        useTLS: true,
        onEvent: (event) {
          if (event.eventName == 'live.started') {
            debugPrint('[Lives] live.started received');
            _refresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Un live vient de commencer !'),
                  backgroundColor: const Color(0xFF22C55E),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }
        },
        onConnectionStateChange: (state, prev) {
          debugPrint('[Lives] Pusher: $prev -> $state');
        },
        onAuthorizer: (channelName, socketId, options) =>
            _authorize(channelName, socketId),
      );
      _pusher!.subscribe(channelName: 'lives');
      _pusher!.connect();
    } catch (e) {
      debugPrint('[Lives] Pusher subscribe failed: $e');
    }
  }

  Future<Map<String, dynamic>> _authorize(String? channelName, String socketId) async {
    final token = ApiService.token;
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.pusherAuthEndpoint),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'channel_name': channelName, 'socket_id': socketId}),
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  void _disconnectPusher() {
    try {
      _pusher?.unsubscribe(channelName: 'lives');
      _pusher?.disconnect();
    } catch (_) {}
    _pusher = null;
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.get(ApiConfig.liveSessionsEndpoint);
      final parsed = _parseSessions(data);
      if (mounted) {
        setState(() {
          _sessions = parsed;
        });
        _attachPollsToLive();
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('[Lives] _refresh error: $e');
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await ApiService.get(ApiConfig.liveSessionsEndpoint);
      final parsed = _parseSessions(data);
      if (!mounted || parsed.isEmpty) return;
      setState(() {
        _sessions = parsed;
      });
      _attachPollsToLive();
    } on Exception {
      // silent : keep previous sessions on network failure
    }
  }

  List<Map<String, dynamic>> _parseSessions(dynamic data) {
    try {
      final raw = (data is Map) ? (data['data'] ?? []) : (data is List ? data : []);
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (e) {
      debugPrint('[Lives] parse error: $e');
    }
    return [];
  }

  void _attachPollsToLive() {
    final live = _sessions.where((s) => s['status'] == 'live').toList();
    final target =
        live.isNotEmpty ? live.first : (_sessions.isNotEmpty ? _sessions.first : null);
    if (target != null) {
      final id = (target['id'] as num?)?.toInt();
      if (id != null) {
        setState(() => _liveSessionId = id);
        _loadPolls(id);
      }
    } else {
      setState(() {
        _liveSessionId = null;
        _polls = [];
      });
    }
  }

  Future<void> _loadPolls(int sessionId) async {
    if (_pollsLoading) return;
    setState(() => _pollsLoading = true);
    try {
      final data = await ApiService.get('/live-sessions/$sessionId/polls');
      final list = data is List ? data : [];
      if (mounted) {
        setState(() {
          _polls = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        });
      }
    } on Exception {
      // silencieux : les sondages sont optionnels
    } finally {
      if (mounted) setState(() => _pollsLoading = false);
    }
  }

  Future<void> _vote(Map<String, dynamic> poll, int index) async {
    final id = (poll['id'] as num?)?.toInt();
    if (id == null || _votingPollId != null) return;
    setState(() {
      _votingPollId = id;
      _votingIndex = index;
    });
    try {
      await ApiService.post('/live-sessions/polls/$id/vote', body: {
        'option_index': index,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Vote enregistré. Merci !'),
          backgroundColor: const Color(0xFFBD7F66),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        if (_liveSessionId != null) _loadPolls(_liveSessionId!);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur de connexion au serveur.')));
      }
    } finally {
      if (mounted) _removeVotingState();
    }
  }

  void _removeVotingState() {
    setState(() {
      _votingPollId = null;
      _votingIndex = null;
    });
  }

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

  Future<void> _joinSession(Map<String, dynamic> session) async {
    final id = (session['id'] as num?)?.toInt();
    setState(() => _loading = true);
    try {
      final r = await ApiService.post('/live-sessions/$id/join', body: {});
      final url = (r is Map) ? r['prebuilt_url'] as String? : null;
      if (url == null || url.isEmpty) throw ApiException(message: 'Impossible de rejoindre', statusCode: 0);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RoomWebviewScreen(
              url: url,
              title: 'Live — ${session['title'] ?? ''}',
              sessionId: id,
              isOwner: false,
              viewOnly: true)));
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        if (e.statusCode == 403) {
          _showSubscriptionGate(session);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSubscriptionGate(Map<String, dynamic> session) {
    final target = (session['target_plan'] as String?) ?? 'all';
    final label = target == 'family_plus'
        ? 'Family Plus'
        : (target == 'family' ? 'Family' : 'Family / Family Plus');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Abonnement requis',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text(
          'Ce live est réservé aux abonnés $label. Souscrivez pour y accéder.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            },
            child: const Text('Voir les offres',
                style: TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveSessions = _sessions.where((s) => s['status'] == 'live').toList();
    final otherSessions = _sessions.where((s) => s['status'] != 'live').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Lives du Docteur', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.live_tv_rounded,
                          color: const Color(0xFFBD7F66).withValues(alpha: 0.3), size: 64),
                      const SizedBox(height: 14),
                      const Text('Aucun live disponible',
                          style: TextStyle(color: Color(0xFF8B8173), fontSize: 16)),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Color(0xFFEF4444))),
                      ],
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  color: const Color(0xFFBD7F66),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      if (liveSessions.isNotEmpty) ...[
                        Row(
                          children: [
                            Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF22C55E),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('EN DIRECT',
                                style: TextStyle(
                                    color: Color(0xFF22C55E),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...liveSessions.map((s) => _sessionCard(s, isLive: true)),
                        if (_polls.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _pollSection(),
                        ],
                        const SizedBox(height: 20),
                      ],
                      if (otherSessions.isNotEmpty) ...[
                        const Text('À venir',
                            style: TextStyle(
                                color: Color(0xFF8B8173),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6)),
                        const SizedBox(height: 10),
                        ...otherSessions.map((s) => _sessionCard(s, isLive: false)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _pollSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.bar_chart_rounded,
              color: Color(0xFFBD7F66), size: 18),
          const SizedBox(width: 6),
          const Text('Sondages du live',
              style: TextStyle(
                  color: Color(0xFF8B8173),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6)),
          if (_pollsLoading) ...[
            const SizedBox(width: 8),
            const SizedBox(
                height: 12,
                width: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFBD7F66))),
          ],
        ]),
        const SizedBox(height: 10),
        ..._polls.map((p) => _pollCard(p)),
      ],
    );
  }

  Widget _pollCard(Map<String, dynamic> poll) {
    final results = poll['results'] is List
        ? (poll['results'] as List).cast<num>()
        : <num>[];
    final options = (poll['options'] as List? ?? []).cast<String>();
    final total = (poll['total_votes'] as num?)?.toInt() ?? 0;
    final myOption = poll['my_option'] as num?;
    final closed = poll['closed_at'] != null;
    final voted = myOption != null;
    final showResults = results.isNotEmpty || voted || closed;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBD7F66).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(poll['question']?.toString() ?? '',
                    style: const TextStyle(
                        color: Color(0xFF2C2B22),
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
              if (closed) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Fermé',
                      style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          if (showResults)
            ...List.generate(options.length, (i) {
              final count = i < results.length ? results[i].toInt() : 0;
              final pct = total > 0 ? (count * 100 / total).round() : 0;
              final isMine = myOption == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          '${options[i]}${isMine ? '  ✓' : ''}',
                          style: TextStyle(
                            color: const Color(0xFF2C2B22),
                            fontSize: 13,
                            fontWeight:
                                isMine ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text('$count ($pct%)',
                          style: const TextStyle(
                              color: Color(0xFFBD7F66),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEDE7DD),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMine
                              ? const Color(0xFFBD7F66)
                              : const Color(0xFF34C07B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            ...options.asMap().entries.map((e) {
              final i = e.key;
              final o = e.value;
              final voting = _votingPollId == (poll['id'] as num?)?.toInt();
              final selected = _votingIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: voting ? null : () => _vote(poll, i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFBD7F66)
                            : const Color(0xFFF4F1EB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFFBD7F66)
                                : const Color(0xFFE7E0D5)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            o,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF2C2B22),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (voting && selected)
                          const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                      ]),
                    ),
                  ),
                ),
              );
            }),
          if (!showResults)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Touchez une option pour voter.',
                  style: TextStyle(color: Color(0xFFA69D8F), fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(total == 0 ? 'Aucun vote pour le moment.'
                  : '$total vote${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                      color: Color(0xFFA69D8F), fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _sessionCard(Map<String, dynamic> session, {required bool isLive}) {
    final status = (session['status'] as String?) ?? '';
    final targetPlan = (session['target_plan'] as String?) ?? 'all';
    final targetLabel = targetPlan == 'family_plus'
        ? 'Family Plus'
        : (targetPlan == 'family' ? 'Family' : null);
    final doctorName = session['doctor'] is Map
        ? (session['doctor'] as Map)['name'] as String?
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isLive
                ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                : const Color(0xFFBD7F66).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: isLive
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
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status == 'live' ? 'EN DIRECT' : status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              Text(_fmt(session['scheduled_at'] as String?),
                  style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          Text(session['title'] as String? ?? '',
              style: const TextStyle(
                  color: Color(0xFFBD7F66),
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
          if ((session['theme'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(session['theme'] as String,
                style: const TextStyle(color: Color(0xFF8B8173), fontSize: 13)),
          ],
          if (doctorName != null) ...[
            const SizedBox(height: 4),
            Text('Dr. $doctorName',
                style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 12)),
          ],
          if (targetLabel != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(targetLabel,
                  style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
          if (isLive || status == 'scheduled') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLive
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => _joinSession(session),
                icon: Icon(
                  isLive ? Icons.sensors_rounded : Icons.login_rounded,
                  size: 18,
                ),
                label: Text(isLive ? 'Rejoindre le live' : 'S\'inscrire au live'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
