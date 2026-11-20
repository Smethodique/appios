import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/domain/models/chat.dart';
import 'package:medcin_app/data/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser peer;
  const ChatScreen({super.key, required this.peer});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  List<ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  StreamSubscription? _sub;

  ChatService get _svc => ChatService.instance;

  @override
  void initState() {
    super.initState();
    _load();
    _svc.ensureConnected();
    _sub = _svc.incoming.listen((msg) {
      if (msg.senderId == widget.peer.id && mounted) {
        setState(() => _messages.add(msg));
        _scrollBottom();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final msgs = await _svc.fetchMessages(widget.peer.id);
      if (mounted) setState(() => _messages = msgs);
      _scrollBottom();
    } catch (e) {
      debugPrint('load messages: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      final m = await _svc.sendMessage(widget.peer.id, text);
      if (mounted) {
        setState(() => _messages.add(m));
        _scrollBottom();
      }
    } catch (e) {
      _controller.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Échec de l'envoi. Veuillez réessayer.")),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _time(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final myId = _svc.myId;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                widget.peer.name
                    .split(' ')
                    .where((w) => w.isNotEmpty)
                    .take(2)
                    .map((w) => w[0].toUpperCase())
                    .join(),
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFBD7F66),
                    fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Text(widget.peer.name,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _svc.ensureConnected(),
              child: ValueListenableBuilder<String>(
                valueListenable: _svc.connectionStatus,
                builder: (_, status, __) {
                  final connected = status == 'connected';
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        connected ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: connected
                            ? const Color(0xFFB9F6CA)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        connected ? 'Connecté' : 'Hors ligne',
                        style: TextStyle(
                            fontSize: 11,
                            color: connected ? Colors.white : Colors.white70),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
                : _messages.isEmpty
                    ? const Center(
                        child: Text('Commencez la conversation.',
                            style: TextStyle(color: Color(0xFF8E7F68))),
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(14),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) =>
                            _bubble(_messages[i], myId),
                      ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Écrivez votre message…',
                      hintStyle: const TextStyle(color: Color(0xFFD2C9BC)),
                      filled: true,
                      fillColor: const Color(0xFFF5F1EA),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFBD7F66)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, int? myId) {
    final mine = m.isMine(myId ?? -1);
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFBD7F66) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine ? null : Border.all(color: const Color(0xFFEAE4D9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              m.content,
              style: TextStyle(
                color: mine ? Colors.white : const Color(0xFFBD7F66),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _time(m.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? const Color(0xCCFFFFFF) : const Color(0xFFD2C9BC),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
