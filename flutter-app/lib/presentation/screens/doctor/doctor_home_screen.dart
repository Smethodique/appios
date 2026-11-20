import 'package:flutter/material.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/chat/conversations_screen.dart';
import 'package:medcin_app/presentation/screens/doctor/live_sessions_screen.dart';
import 'package:medcin_app/presentation/screens/doctor/call_screen.dart';
import 'package:medcin_app/presentation/screens/doctor/doctor_appointments_screen.dart';
import 'package:medcin_app/presentation/screens/doctor/doctor_schedule_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  Future<void> _logout() async {
    await AuthProvider.instance.logout();
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.55)],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFBD7F66),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.medical_information_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Espace Médecin',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800)),
                        Row(
                          children: [
                            const Icon(Icons.circle, size: 8, color: Color(0xFFB9F6CA)),
                            const SizedBox(width: 5),
                            Text('Connecté',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Déconnexion',
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.white70, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Bonjour,',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 15, fontWeight: FontWeight.w600)),
              Text(AuthProvider.instance.displayName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 26),
              _featureCard(
                icon: Icons.live_tv_rounded,
                title: 'Live',
                subtitle: 'Lancer ou rejoindre un direct\nen vidéo avec vos patients.',
                color: const Color(0xFFE11D48),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const LiveSessionsScreen())),
              ),
              const SizedBox(height: 14),
              _featureCard(
                icon: Icons.videocam_rounded,
                title: 'Appel',
                subtitle: 'Vidéo-appel en direct avec\nun parent en 1 clic.',
                color: const Color(0xFFBD7F66),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CallScreen())),
              ),
              const SizedBox(height: 14),
              _featureCard(
                icon: Icons.chat_bubble_rounded,
                title: 'Messages',
                subtitle: 'Discutez en temps réel avec\nvos patients.',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ConversationsScreen())),
              ),
              const SizedBox(height: 14),
              _featureCard(
                icon: Icons.event_rounded,
                title: 'Rendez-vous',
                subtitle: 'Gérez les demandes de\nrendez-vous des parents.',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DoctorAppointmentsScreen())),
              ),
              const SizedBox(height: 14),
              _featureCard(
                icon: Icons.calendar_month_rounded,
                title: 'Planning',
                subtitle: 'Définissez vos jours et\nhoraires de consultation.',
                color: const Color(0xFFBD7F66),
                onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DoctorScheduleScreen())),
              ),
              const SizedBox(height: 34),
              Center(
                child: TextButton(
                  onPressed: _logout,
                  child: const Text('Déconnexion',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}