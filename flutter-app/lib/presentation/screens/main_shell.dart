import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/core/theme/app_tokens.dart';
import 'package:medcin_app/presentation/widgets/notch_nav_bar.dart';
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

  // Nassreddin — the guided tour points at these two tabs.
  static final GlobalKey tabEnfantKey = GlobalKey(debugLabel: 'tab-enfant');
  static final GlobalKey tabAbonnementKey = GlobalKey(debugLabel: 'tab-abonnement');

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
    // Nassreddin — the flat BottomNavigationBar (with a full-opacity brand
    // shadow that painted a brown band) is replaced by the notch menu of the
    // redesign. Tab order and routing are unchanged; labels are now French.
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: widget.navigationShell,
      bottomNavigationBar: NotchNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _selectTab,
        items: [
          const NotchNavItem(icon: Icons.home_rounded, label: 'Accueil'),
          NotchNavItem(icon: Icons.child_care_rounded, label: 'Enfant', key: MainShell.tabEnfantKey),
          NotchNavItem(icon: Icons.workspace_premium_rounded, label: 'Abonnement', key: MainShell.tabAbonnementKey),
          const NotchNavItem(icon: Icons.chat_bubble_rounded, label: 'Messages'),
          const NotchNavItem(icon: Icons.person_rounded, label: 'Profil'),
        ],
      ),
    );
  }
}