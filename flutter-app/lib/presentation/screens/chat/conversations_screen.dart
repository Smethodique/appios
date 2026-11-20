import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/domain/models/chat.dart';
import 'package:medcin_app/presentation/screens/chat/chat_screen.dart';
import 'package:medcin_app/data/services/chat_service.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<ChatUser> _convs = [];
  bool _loading = true;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _sub = ChatService.instance.incoming.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final convs = await ChatService.instance.fetchConversations();
      if (mounted) setState(() => _convs = convs);
    } catch (e) {
      debugPrint('conversations: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(ChatUser peer) async {
    ChatService.instance.setActivePeer(peer.id);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(peer: peer)),
    );
    ChatService.instance.setActivePeer(null);
    _refresh();
  }

  String _fmtTime(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
  }

  Widget _statusChip() {
    return ValueListenableBuilder<String>(
      valueListenable: ChatService.instance.connectionStatus,
      builder: (_, status, __) {
        final connected = status == 'connected';
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              ChatService.instance.ensureConnected();
              _refresh();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  connected ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: connected ? const Color(0xFFB9F6CA) : Colors.white70,
                ),
                const SizedBox(width: 5),
                Text(
                  connected ? 'Connecté' : 'Hors ligne',
                  style: TextStyle(
                      fontSize: 11,
                      color: connected ? Colors.white : Colors.white70),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        title: const Text('Messagerie',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [_statusChip()],
      ),
      body: Column(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: ChatService.instance.lastError,
            builder: (_, err, __) {
              if (err == null ||
                  ChatService.instance.connectionStatus.value == 'connected') {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                color: const Color(0xFFDC2626),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    ChatService.instance.lastError.value = null;
                    ChatService.instance.ensureConnected();
                    _refresh();
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Temps réel indisponible — $err. Appuyez pour réessayer.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
                : _convs.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 52, color: Color(0xFFD2C9BC)),
                            SizedBox(height: 14),
                            Text('Aucune conversation',
                                style: TextStyle(
                                    color: Color(0xFFBD7F66),
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: 6),
                            Text(
                                'Discutez avec votre médecin depuis le dossier de votre enfant.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Color(0xFF8E7F68), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _convs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFEAE4D9)),
                        itemBuilder: (context, i) {
                          final c = _convs[i];
                          final initials = c.name
                              .split(' ')
                              .where((w) => w.isNotEmpty)
                              .take(2)
                              .map((w) => w[0].toUpperCase())
                              .join();
                          return ListTile(
                            onTap: () => _open(c),
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFFBD7F66),
                              foregroundColor: Colors.white,
                              child: Text(initials),
                            ),
                            title: Text(c.name,
                                style: const TextStyle(
                                    color: Color(0xFFBD7F66),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15)),
                            subtitle: Text(
                              c.last ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xFF8E7F68), fontSize: 13),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_fmtTime(c.lastAt),
                                    style: const TextStyle(
                                        color: Color(0xFFD2C9BC),
                                        fontSize: 11)),
                                const SizedBox(height: 4),
                                if (c.unread > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFBD7F66),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                        '${c.unread > 99 ? '99+' : c.unread}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
