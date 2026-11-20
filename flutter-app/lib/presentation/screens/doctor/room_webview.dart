import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class RoomWebviewScreen extends StatefulWidget {
  final String url;
  final String title;
  final int? sessionId;
  final String? roomName;
  final bool isOwner;
  final bool viewOnly;
  const RoomWebviewScreen({
    super.key,
    required this.url,
    required this.title,
    this.sessionId,
    this.roomName,
    this.isOwner = false,
    this.viewOnly = false,
  });

  @override
  State<RoomWebviewScreen> createState() => _RoomWebviewScreenState();
}

class _RoomWebviewScreenState extends State<RoomWebviewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _polls = [];
  bool _pollsLoading = false;
  Timer? _pollsTimer;
  int? _votingPollId;
  int? _votingIndex;
  int? _busyPollId;
  bool _showPolls = false;
  final Set<int> _seenPollIds = {};

  bool get _hasPolls => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    const params = PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params);
    if (!kIsWeb) {
      _controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFF0A0F1D))
        ..setUserAgent(
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36 Medcin')
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (err) {
            if (err.errorCode == -102 || err.errorCode == -2) return;
            debugPrint('webview error: ${err.errorCode} ${err.description}');
            if (mounted) setState(() => _error = err.description);
          },
        ));
      _applyPermissionPolicy();
    } else {
      _loading = false;
    }
    _controller.loadRequest(Uri.parse(widget.url));

    final sid = widget.sessionId;
    if (sid != null) {
      _refreshPolls();
      _pollsTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        _refreshPolls(silent: true);
      });
    }
  }

  @override
  void dispose() {
    _pollsTimer?.cancel();
    super.dispose();
  }

  Future<void> _endCall() async {
    final room = widget.roomName;
    if (room == null || room.isEmpty) return;
    try {
      await ApiService.post('${ApiConfig.callJoinEndpoint}/$room/end', body: {});
    } catch (_) {}
  }

  Future<void> _leave() async {
    await _endCall();
    if (mounted) Navigator.of(context).pop(true);
  }

  void _applyPermissionPolicy() {
    try {
      _controller.platform.setOnPlatformPermissionRequest((request) {
        if (widget.viewOnly) {
          request.deny();
        } else {
          request.grant();
        }
      });
    } catch (e) {
      debugPrint('[Room] permission policy not supported: $e');
    }
  }

  Future<void> _refreshPolls({bool silent = false}) async {
    final sid = widget.sessionId;
    if (sid == null) return;
    if (!silent && mounted) {
      setState(() => _pollsLoading = true);
    }
    try {
      final data = await ApiService.get('/live-sessions/$sid/polls');
      if (!mounted) return;
      final list = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      final beforeIds = _polls.map((p) => (p['id'] as num?)?.toInt()).toSet();
      setState(() {
        _polls = list;
        _pollsLoading = false;
      });
      for (final p in list) {
        final id = (p['id'] as num?)?.toInt();
        if (id == null) continue;
        if (!widget.isOwner &&
            p['closed_at'] == null &&
            !beforeIds.contains(id) &&
            !_seenPollIds.contains(id)) {
          _seenPollIds.add(id);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Nouveau sondage du docteur : « ${p['question']} »'),
              backgroundColor: const Color(0xFFBD7F66),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          }
        } else {
          _seenPollIds.add(id);
        }
      }
    } catch (e) {
      debugPrint('[Room] polls refresh error: $e');
      if (mounted && !silent) setState(() => _pollsLoading = false);
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
      await ApiService.post('/live-sessions/polls/$id/vote', body: {'option_index': index});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Vote enregistré. Merci !'),
        backgroundColor: const Color(0xFFBD7F66),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      await _refreshPolls(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _votingPollId = null;
          _votingIndex = null;
        });
      }
    }
  }

  Future<void> _createPoll() async {
    final created = await _createPollDialog();
    if (created == null || !mounted) return;
    final sid = widget.sessionId;
    if (sid == null) return;
    try {
      await ApiService.post('/live-sessions/$sid/polls', body: {
        'question': created['question'],
        'options': created['options'],
      });
      await _refreshPolls(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<Map<String, dynamic>?> _createPollDialog() async {
    final question = TextEditingController();
    final options = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Nouveau sondage',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: question,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: _in('Question du sondage'),
                  ),
                  const SizedBox(height: 12),
                  ...options.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: e.value,
                          style: const TextStyle(color: Colors.white),
                          decoration: _in('Option ${e.key + 1}'),
                        ),
                      )),
                  if (options.length < 6)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(() {
                          options.add(TextEditingController());
                        }),
                        icon: const Icon(Icons.add_circle_outline, color: Color(0xFFBD7F66)),
                        label: const Text('Ajouter une option',
                            style: TextStyle(color: Color(0xFFBD7F66))),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler', style: TextStyle(color: Colors.white54))),
            TextButton(
                onPressed: () {
                  final q = question.text.trim();
                  final opts = options
                      .map((c) => c.text.trim())
                      .where((o) => o.isNotEmpty)
                      .toList();
                  if (q.isEmpty || opts.length < 2) {
                    return;
                  }
                  Navigator.pop(dialogContext, {'question': q, 'options': opts});
                },
                child: const Text('Lancer le sondage',
                    style: TextStyle(color: Color(0xFFBD7F66), fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );
  }

  InputDecoration _in(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      );

  Future<void> _closePoll(Map<String, dynamic> poll) async {
    final id = (poll['id'] as num?)?.toInt();
    if (id == null || _busyPollId != null) return;
    setState(() => _busyPollId = id);
    try {
      await ApiService.post('/live-sessions/polls/$id/close');
      await _refreshPolls(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyPollId = null);
    }
  }

  Future<void> _deletePoll(Map<String, dynamic> poll) async {
    final id = (poll['id'] as num?)?.toInt();
    if (id == null || _busyPollId != null) return;
    setState(() => _busyPollId = id);
    try {
      await ApiService.delete('/live-sessions/polls/$id');
      await _refreshPolls(silent: true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyPollId = null);
    }
  }

  void _togglePollPanel() {
    setState(() => _showPolls = !_showPolls);
    if (_showPolls) _refreshPolls(silent: true);
  }

  Widget _pollPanel() {
    return Container(
      color: const Color(0xFFEDE7DD),
      width: double.infinity,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(children: [
                const Icon(Icons.bar_chart_rounded, color: Color(0xFFBD7F66), size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Sondages du live',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF2C2B22))),
                ),
                if (_pollsLoading)
                  const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFBD7F66))),
                if (widget.isOwner)
                  TextButton.icon(
                    onPressed: _createPoll,
                    icon: const Icon(Icons.add_chart_rounded, size: 18),
                    label: const Text('Nouveau'),
                  ),
                IconButton(
                  tooltip: 'Réduire les sondages',
                  onPressed: () => setState(() => _showPolls = false),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFBD7F66)),
                ),
              ]),
            ),
            const Divider(color: Color(0xFFD8D0C2), height: 1),
            Expanded(
              child: _polls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart_rounded,
                              color: Color(0xFFA69D8F), size: 40),
                          const SizedBox(height: 10),
                          const Text('Aucun sondage pour le moment.',
                              style: TextStyle(color: Color(0xFFA69D8F))),
                          if (widget.isOwner) ...[
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _createPoll,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFBD7F66),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.add_chart_rounded, size: 18),
                              label: const Text('Lancer un sondage'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: _polls.map((p) => _pollCard(p)).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pollCard(Map<String, dynamic> poll) {
    final id = (poll['id'] as num?)?.toInt();
    final results = poll['results'] is List
        ? (poll['results'] as List).cast<num>()
        : <num>[];
    final options = (poll['options'] as List? ?? []).cast<String>();
    final total = (poll['total_votes'] as num?)?.toInt() ?? 0;
    final myOption = poll['my_option'] as num?;
    final closed = poll['closed_at'] != null;
    final voted = myOption != null;
    final showResults = results.isNotEmpty || voted || closed;
    final busy = _busyPollId == id;

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
                        color: Color(0xFF2C2B22), fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              if (closed) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Fermé',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
          if (widget.isOwner) ...[
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (busy)
                const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else ...[
                if (!closed)
                  TextButton(
                    onPressed: () => _closePoll(poll),
                    child: const Text('Fermer', style: TextStyle(color: Color(0xFFBD7F66))),
                  ),
                IconButton(
                  tooltip: 'Supprimer',
                  onPressed: () => _deletePoll(poll),
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ),
              ],
            ]),
          ],
          const SizedBox(height: 4),
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
                            fontWeight: isMine ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Text('$count ($pct%)',
                          style: const TextStyle(
                              color: Color(0xFFBD7F66), fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: total > 0 ? count / total : 0,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFEDE7DD),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            isMine ? const Color(0xFFBD7F66) : const Color(0xFF34C07B)),
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
              final voting = _votingPollId == id;
              final selected = _votingIndex == i;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: voting ? null : () => _vote(poll, i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFBD7F66) : const Color(0xFFF4F1EB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selected ? const Color(0xFFBD7F66) : const Color(0xFFE7E0D5)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            o,
                            style: TextStyle(
                              color: selected ? Colors.white : const Color(0xFF2C2B22),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (voting && selected)
                          const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
                  style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 12)),
            ),
        ],
      ),
    );
  }

  int _openPollCount() {
    if (widget.isOwner) return _polls.length;
    return _polls
        .where((p) => p['closed_at'] == null && p['my_option'] == null)
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _leave();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        actions: [
          if (_hasPolls)
            Badge(
              label: Text('${_openPollCount()}'),
              isLabelVisible: _openPollCount() > 0,
              backgroundColor: const Color(0xFF22C55E),
              child: IconButton(
                tooltip: 'Sondages du live',
                icon: const Icon(Icons.bar_chart_rounded),
                onPressed: _togglePollPanel,
              ),
            ),
          TextButton(
            onPressed: _leave,
            child: const Text('Quitter',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _hasPolls && _showPolls
          ? Column(children: [
              const SizedBox(height: 6),
              Flexible(flex: 4, child: _pollPanel()),
              Flexible(
                flex: 3,
                child: _webViewArea(),
              ),
            ])
          : _webViewArea(),
      ),
    );
  }

  Widget _webViewArea() {
    return Stack(children: [
      if (_error == null)
        WebViewWidget(controller: _controller)
      else
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                Text(_error!.isEmpty ? 'Impossible d\'ouvrir la salle' : _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _error = null);
                    if (!kIsWeb) _applyPermissionPolicy();
                    _controller.loadRequest(Uri.parse(widget.url));
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      if (_loading && _error == null)
        const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
    ]);
  }
}