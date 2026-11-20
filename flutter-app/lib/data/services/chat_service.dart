import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/domain/models/chat.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final ValueNotifier<int> totalUnread = ValueNotifier<int>(0);
  final ValueNotifier<String> connectionStatus =
      ValueNotifier<String>('disconnected');
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);
  final StreamController<ChatMessage> _incoming =
      StreamController<ChatMessage>.broadcast();
  Stream<ChatMessage> get incoming => _incoming.stream;

  final StreamController<Map<String, dynamic>> _callInvited =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get callInvited => _callInvited.stream;

  PusherChannelsFlutter? _pusher;
  String? _initToken;
  int? _myId;
  int? _activePeer;

  bool get isReady => _pusher != null;

  int? get myId => _myId;

  Future<void> init() async {
    final token = ApiService.token;
    if (token == null || token.isEmpty) return;
    if (_initToken == token && _pusher != null) return;

    dispose();

    try {
      final me = await ApiService.get(ApiConfig.userEndpoint);
      _myId = (me['id'] as num?)?.toInt();
    } catch (_) {
      return;
    }

    _initToken = token;

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: ApiConfig.pusherAppKey,
        cluster: ApiConfig.pusherCluster,
        useTLS: true,
        onEvent: (event) => _handleEvent(event),
        onSubscriptionError: (message, error) {
          lastError.value = 'Abonnement Pusher: $message';
          debugPrint('Pusher sub error: $message $error');
        },
        onError: (message, code, error) {
          lastError.value = code != null ? 'Pusher $code: $message' : message;
          debugPrint('Pusher error: $message $code $error');
        },
        onConnectionStateChange: (state, prev) {
          if (state.toLowerCase() == 'connected') lastError.value = null;
          debugPrint('Pusher: $prev -> $state');
        },
        onAuthorizer: (channelName, socketId, options) =>
            _authorize(channelName, socketId),
      );

      _pusher!.onConnectionStateChange = (state, prev) {
        connectionStatus.value = state.toLowerCase();
        if (state.toLowerCase() == 'connected') lastError.value = null;
        debugPrint('Pusher: $prev -> $state');
      };

      final myId = _myId;
      if (myId != null) {
        _pusher!.subscribe(channelName: 'private-chat.$myId');
      }

      _pusher!.connect();
      refreshUnread();
    } catch (e) {
      _pusher = null;
      _initToken = null;
      lastError.value = 'Pusher init: $e';
      debugPrint('Pusher init failed: $e');
    }
  }

  Future<void> ensureConnected() async {
    final token = ApiService.token;
    if (token == null || token.isEmpty) return;
    if (_pusher != null) {
      if (connectionStatus.value == 'disconnected' ||
          connectionStatus.value == 'disconnecting') {
        try {
          _pusher!.connect();
        } catch (_) {}
      }
      return;
    }
    await init();
  }

  Future<Map<String, dynamic>> _authorize(
      String? channelName, String socketId) async {
    final token = ApiService.token;
    final senderId = socketId;
    try {
      final resp = await http.post(
        Uri.parse(ApiConfig.pusherAuthEndpoint),
        headers: {
          'Authorization': 'Bearer ${token ?? ''}',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'channel_name': channelName, 'socket_id': senderId}),
      );
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (e) {
      debugPrint('Pusher auth failed: $e');
    }
    return <String, dynamic>{};
  }

  void _handleEvent(PusherEvent event) {
    final payload = _toMap(event.data);

    if (event.eventName == 'call.invited') {
      final callData = payload;
      if (callData.isNotEmpty && callData['url'] != null) {
        debugPrint('[ChatService] call.invited from ${callData['doctor_name']}');
        _callInvited.add(callData);
      }
      return;
    }

    if (event.eventName != 'message.sent') return;

    final raw = payload['message'];
    if (raw is! Map) return;

    final msg = ChatMessage.fromJson(Map<String, dynamic>.from(raw));
    if (msg.senderId == _myId) return;

    _incoming.add(msg);
    refreshUnread();
  }

  Map<String, dynamic> _toMap(dynamic data) {
    try {
      if (data is String) return Map<String, dynamic>.from(jsonDecode(data));
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {}
    return {};
  }

  void setActivePeer(int? peerId) {
    _activePeer = peerId;
    refreshUnread();
  }

  Future<List<ChatUser>> fetchConversations() async {
    final data = await ApiService.get(ApiConfig.conversationsEndpoint);
    final list = (data is List) ? data : (data['conversations'] ?? []);
    final users = <ChatUser>[];
    for (final e in list) {
      if (e is Map) users.add(ChatUser.fromJson(Map<String, dynamic>.from(e)));
    }
    final unread = users.fold<int>(
      0,
      (sum, u) => sum + (u.id != _activePeer ? u.unread : 0),
    );
    totalUnread.value = unread;
    return users;
  }

  Future<List<ChatMessage>> fetchMessages(int peerId) async {
    final data = await ApiService.get(
      ApiConfig.chatEndpoint,
      queryParams: {'with': '$peerId'},
    );
    if (data is! List) return [];
    final out = <ChatMessage>[];
    for (final e in data) {
      if (e is Map) {
        out.add(ChatMessage.fromJson(Map<String, dynamic>.from(e)));
      }
    }
    _activePeer = peerId;
    refreshUnread();
    return out;
  }

  Future<ChatMessage> sendMessage(int peerId, String content) async {
    if (content.trim().isEmpty) throw ArgumentError('Message vide');
    final data = await ApiService.post(ApiConfig.chatEndpoint, body: {
      'receiver_id': peerId,
      'content': content,
    });
    return ChatMessage.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> refreshUnread() async {
    try {
      await fetchConversations();
    } catch (_) {}
  }

  void dispose() {
    final p = _pusher;
    if (p != null) {
      try {
        p.unsubscribe(channelName: 'private-chat.$_myId');
        p.disconnect();
      } catch (_) {}
    }
    _pusher = null;
    _initToken = null;
    _myId = null;
    _activePeer = null;
    totalUnread.value = 0;
    connectionStatus.value = 'disconnected';
  }
}
