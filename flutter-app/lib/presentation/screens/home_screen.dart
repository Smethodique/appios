import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/video.dart';
import 'package:medcin_app/presentation/screens/main_shell.dart';
import 'package:medcin_app/presentation/screens/parent/parent_calls_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_live_sessions_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_workshops_screen.dart';
import 'package:medcin_app/presentation/screens/appointments/parent_appointments_screen.dart';
import 'package:medcin_app/presentation/screens/public_content_screen.dart';
import 'package:medcin_app/presentation/screens/premium_content_screen.dart';
import 'package:medcin_app/presentation/screens/video_player_screen.dart';
import 'package:medcin_app/presentation/screens/how_to_use_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Video> _videos = [];
  List<String> _categories = [];
  String? _selectedCategory;
  Timer? _liveCheckTimer;
  bool _loading = true;
  bool _hasLiveSession = false;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    MainShell.homeRefreshTick.addListener(_loadVideos);
    _loadVideos();
    _checkLiveSessions();
    _liveCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkLiveSessions());
  }

  @override
  void dispose() {
    MainShell.homeRefreshTick.removeListener(_loadVideos);
    _liveCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkLiveSessions() async {
    try {
      final data = await ApiService.get(ApiConfig.liveSessionsEndpoint);
      if (data is Map) {
        final list = data['data'];
        if (list is List) {
          final hasLive = list.any((e) => e is Map && e['status'] == 'live');
          if (mounted) setState(() => _hasLiveSession = hasLive);
          return;
        }
      }
    } catch (_) {}
  }

  Future<void> _loadVideos() async {
    setState(() {
      _loading = _videos.isEmpty;
      _error = null;
    });
    try {
      final response = await ApiService.get(ApiConfig.freeVideosEndpoint);
      final list = response['videos'] as List? ?? [];
      final videos =
          list.map((j) => Video.fromJson(Map<String, dynamic>.from(j as Map))).toList();
      final categories = <String>{};
      // Show every category from the server, even when it has no videos yet.
      try {
        final categoriesResponse =
            await ApiService.get(ApiConfig.videoCategoriesEndpoint);
        final categoriesList = categoriesResponse['categories'] as List? ?? [];
        for (final c in categoriesList) {
          if (c is String && c.trim().isNotEmpty) categories.add(c.trim());
        }
      } catch (e) {
        debugPrint('Failed to load video categories: $e');
      }
      for (final v in videos) {
        if (v.category != null && v.category!.isNotEmpty) categories.add(v.category!);
      }
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _categories = categories.toList()..sort();
        if (_selectedCategory != null &&
            !_categories.contains(_selectedCategory)) {
          _selectedCategory = null;
        }
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load free videos: $e');
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les vidéos.';
          _loading = false;
        });
      }
    }
  }

  List<Video> get _filtered {
    return _videos
        .where((v) =>
            _selectedCategory == null || v.category == _selectedCategory)
        .toList();
  }

  void _openVideo(Video video) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoId: video.id,
          title: video.title,
          videoUrl: video.videoUrl,
          category: video.category,
          ageRange: video.ageRange,
          description: video.description,
        ),
      ),
    );
  }

  void _onLogoPressed() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  void _onHelpPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HowToUseScreen()),
    );
  }

  void _onNotificationsPressed() {
    context.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F2EC),
        foregroundColor: const Color(0xFF2C2B22),
        centerTitle: false,
        elevation: 0,
        toolbarHeight: 80,
        leadingWidth: 96,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: InkWell(
              onTap: _onLogoPressed,
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/logo_brown.png',
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: ValueListenableBuilder<int>(
                valueListenable: MainShell.unreadNotifier,
                builder: (context, unread, _) {
                  return InkWell(
                    onTap: _onNotificationsPressed,
                    borderRadius: BorderRadius.circular(22),
                    child: Badge.count(
                      count: unread,
                      isLabelVisible: unread > 0,
                      backgroundColor: const Color(0xFF9C5B3E),
                      textColor: Colors.white,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C5B3E).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFF9C5B3E).withValues(alpha: 0.28),
                              width: 1.2),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: Color(0xFF9C5B3E), size: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InkWell(
                onTap: _onHelpPressed,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C5B3E).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF9C5B3E).withValues(alpha: 0.28),
                        width: 1.2),
                  ),
                  child: const Icon(Icons.help_outline_rounded,
                      color: Color(0xFF9C5B3E), size: 26),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFFBD7F66),
        onRefresh: _loadVideos,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Des conseils fiables, à portée de main.',
                  style: TextStyle(color: Color(0xFFA69D8F), fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                  child: Stack(
                    fit: StackFit.passthrough,
                    clipBehavior: Clip.none,
                    children: [
                      _quickAction(
                        icon: Icons.live_tv_rounded,
                        label: 'Lives',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ParentLiveSessionsScreen()),
                        ),
                      ),
                      if (_hasLiveSession)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Rendez-vous',
                        highlight: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ParentAppointmentsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.call_rounded,
                        label: 'Appels',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ParentCallsScreen()),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PremiumContentScreen()),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C5B3E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded,
                            color: Color(0xFFFFC857), size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contenu Premium',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              SizedBox(height: 2),
                              Text(
                                  'Vidéos exclusives et ressources pour votre famille',
                                  style: TextStyle(
                                      color: Color(0xFFBFDCCD),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const PublicContentScreen()),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E7F68),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            color: Color(0xFFFFF3E0), size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contenu public',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              SizedBox(height: 2),
                              Text(
                                  'Vidéos et ressources gratuites pour votre famille',
                                  style: TextStyle(
                                      color: Color(0xFFF1EAE3),
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const ParentWorkshopsScreen()),
                  ),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF888D44),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.school_rounded,
                            color: Color(0xFFFFFFFF), size: 26),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ateliers thématiques',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              SizedBox(height: 2),
                              Text(
                                'Formations en direct avec votre médecin',
                                style: TextStyle(
                                    color: Color(0xCFFFFFFF), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _categoryDropdown(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Vidéos récentes',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFBD7F66))),
                    ),
                    if (_videos.isNotEmpty && _selectedCategory != null)
                      TextButton(
                        onPressed: () =>
                            setState(() => _selectedCategory = null),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Réinitialiser',
                            style: TextStyle(
                                color: Color(0xFFBD7F66), fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildVideos(),
                ],
              ),
            ),
          ),
        ),
      );
    }

  Widget _categoryDropdown() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    const all = '__all_categories__';
    const brown = Color(0xFFBD7F66);
    const labelStyle = TextStyle(
      color: brown,
      fontWeight: FontWeight.w600,
      fontSize: 12.5,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: brown.withValues(alpha: 0.35)),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory ?? all,
        isDense: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: brown, size: 18),
        iconSize: 18,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: [
          const DropdownMenuItem<String>(
            value: all,
            child: Text('Toutes les catégories', style: labelStyle),
          ),
          ..._categories.map(
            (c) => DropdownMenuItem<String>(
              value: c,
              child:
                  Text(c, style: labelStyle, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) => setState(() {
          _selectedCategory = (value == null || value == all) ? null : value;
        }),
      ),
    );
  }

  Widget _buildVideos() {
    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFBD7F66)),
        ),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: Color(0xFFA69D8F), size: 44),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Color(0xFF8B8173))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadVideos,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBD7F66),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text('Aucune vidéo trouvée',
              style: TextStyle(color: Color(0xFFA69D8F))),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 250,
      ),
      itemBuilder: (context, index) => _videoCard(filtered[index]),
    );
  }

  Widget _videoCard(Video video) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: InkWell(
        onTap: () => _openVideo(video),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                  SizedBox(
                    width: double.infinity,
                    height: 118,
                  child: video.thumbnailUrl != null
                      ? Image.network(
                          video.thumbnailUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const ColoredBox(
                              color: Color(0xFFBD7F66),
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFBD7F66), strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) =>
                              _thumbnailFallback(video),
                        )
                      : _thumbnailFallback(video),
                ),
                const Positioned(
                  right: 12,
                  bottom: 12,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2C2B22),
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5),
                  ),
                  if (video.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      video.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 11.5, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (video.category != null)
                        _infoChip(Icons.video_library_rounded, video.category!),
                      if (video.ageRange != null)
                        _infoChip(Icons.child_care_rounded, video.ageRange!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailFallback(Video video) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF9C5B3E),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white.withValues(alpha: 0.6),
          size: 56,
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final color = highlight ? const Color(0xFF9C5B3E) : Colors.white;
    final foreground = highlight ? Colors.white : const Color(0xFFBD7F66);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: foreground, size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    color: highlight ? Colors.white : const Color(0xFF2C2B22),
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFBD7F66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFBD7F66)),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBD7F66))),
        ],
      ),
    );
  }
}