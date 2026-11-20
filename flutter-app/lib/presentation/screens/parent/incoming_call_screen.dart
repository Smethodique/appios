import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/core/network/api_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final String doctorName;
  final String roomUrl;
  final String roomName;

  const IncomingCallScreen({
    super.key,
    required this.doctorName,
    required this.roomUrl,
    required this.roomName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _timeout = Timer(const Duration(seconds: 30), () {
      _endCall();
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _endCall() async {
    try {
      await ApiService.post(
        '${ApiConfig.callJoinEndpoint}/${widget.roomName}/end',
        body: {},
      );
    } catch (_) {}
  }

  Future<void> _accept() async {
    _timeout?.cancel();
    try {
      final r = await ApiService.post(
        '${ApiConfig.callJoinEndpoint}/${widget.roomName}/join',
        body: {},
      );
      final url = (r is Map) ? r['prebuilt_url'] as String? : widget.roomUrl;
      if (!mounted) return;
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => RoomWebviewScreen(
              url: url ?? widget.roomUrl,
              title: 'Appel — Dr. ${widget.doctorName}',
              roomName: widget.roomName)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.message;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _decline() async {
    _timeout?.cancel();
    await _endCall();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                    border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                        width: 3),
                  ),
                  child: const Icon(Icons.videocam_rounded,
                      color: Color(0xFF22C55E), size: 48),
                ),
              ),
              const SizedBox(height: 32),
              const Text('Appel entrant',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 8),
              Text('Dr. ${widget.doctorName}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text('Appel vidéo',
                  style: TextStyle(color: Colors.white38, fontSize: 14)),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _callButton(
                    icon: Icons.call_end_rounded,
                    color: const Color(0xFFEF4444),
                    label: 'Refuser',
                    onTap: _decline,
                  ),
                  const SizedBox(width: 48),
                  _callButton(
                    icon: Icons.videocam_rounded,
                    color: const Color(0xFF22C55E),
                    label: 'Accepter',
                    onTap: _accept,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _callButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
