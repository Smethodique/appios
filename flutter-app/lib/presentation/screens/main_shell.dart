import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/data/services/chat_service.dart';
import 'package:medcin_app/presentation/screens/parent/incoming_call_screen.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  static final ValueNotifier<int> homeRefreshTick = ValueNotifier<int>(0);
  static final ValueNotifier<int> notificationRefreshTick =
      ValueNotifier<int>(0);
  static final ValueNotifier<int> unreadNotifier = ValueNotifier<int>(0);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  StreamSubscription<Map<String, dynamic>>? _callSub;
  Timer? _unreadTimer;

  @override
  void initState() {
    super.initState();
    ChatService.instance.init();
    MainShell.notificationRefreshTick.addListener(_refreshUnread);
    _listenForCalls();
    _refreshUnread();
    _unreadTimer = Timer.periodic(const Duration(seconds: 60), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _unreadTimer?.cancel();
    MainShell.notificationRefreshTick.removeListener(_refreshUnread);
    _callSub?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnread() async {
    try {
      final data = await ApiService.get(ApiConfig.notificationsEndpoint);
      final unread = (data as Map)['unread'];
      final count = (unread as num?)?.toInt() ?? 0;
      MainShell.unreadNotifier.value = count;
    } catch (_) {}
  }

  void _listenForCalls() {
    _callSub = ChatService.instance.callInvited.listen((callData) {
      if (!mounted) return;
      final doctorName = callData['doctor_name'] as String? ?? 'Docteur';
      final roomUrl = callData['url'] as String? ?? '';
      final roomName = callData['room_name'] as String? ?? '';
      if (roomUrl.isEmpty || roomName.isEmpty) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => IncomingCallScreen(
            doctorName: doctorName,
            roomUrl: roomUrl,
            roomName: roomName,
          ),
        ),
      );
    });
  }

  void _selectTab(int index) {
    if (index == 0 && index != widget.navigationShell.currentIndex) {
      MainShell.homeRefreshTick.value++;
    }
    if (index != widget.navigationShell.currentIndex) {
      MainShell.notificationRefreshTick.value++;
    }
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(color: Color(0xFFBD7F66), blurRadius: 10, offset: Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _selectTab,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFBD7F66),
          unselectedItemColor: const Color(0xFFA69D8F),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.child_care_outlined),
              activeIcon: Icon(Icons.child_care_rounded),
              label: 'Enfant',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.workspace_premium_outlined),
              activeIcon: Icon(Icons.workspace_premium_rounded),
              label: 'Abonnement',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}