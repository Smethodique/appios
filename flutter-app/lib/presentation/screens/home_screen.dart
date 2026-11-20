import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/video.dart';
import 'package:medcin_app/presentation/screens/main_shell.dart';
import 'package:medcin_app/presentation/screens/parent/parent_calls_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_live_sessions_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_workshops_screen.dart';
import 'package:medcin_app/presentation/screens/appointments/parent_appointments_screen.dart';
import 'package:medcin_app/presentation/screens/guides_screen.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _liveCheckTimer;
  String _query = '';
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
    _debounce?.cancel();
    _liveCheckTimer?.cancel();
    _searchController.dispose();
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
    final q = _query.trim().toLowerCase();
    return _videos.where((v) {
      final matchesCategory =
          _selectedCategory == null || v.category == _selectedCategory;
      final matchesQuery = q.isEmpty ||
          (v.title.toLowerCase().contains(q) ||
              (v.description?.toLowerCase().contains(q) ?? false));
      return matchesCategory && matchesQuery;
    }).toList();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value);
    });
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
                  'Guides, conseils et ressources en un clic.',
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
                        icon: Icons.call_rounded,
                        label: 'Appels',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const ParentCallsScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.menu_book_rounded,
                        label: 'Guides',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const GuidesScreen()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _quickAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Rendez-vous',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) =>
                                  const ParentAppointmentsScreen()),
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
                                  'Vidéos exclusives et guides pour votre famille',
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
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher une vidéo…',
                    hintStyle: const TextStyle(color: Color(0xFFA69D8F), fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Color(0xFFBD7F66), size: 22),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFFA69D8F), size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFFBD7F66), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Des vidéos pour prendre soin de vos enfants',
                  style: GoogleFonts.playfairDisplay(
                    color: const Color(0xFF9C5B3E),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _categoryChips(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Vidéos',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFBD7F66))),
                    ),
                    if (_videos.isNotEmpty && _selectedCategory != null)
                      TextButton(
                        onPressed: () => setState(() {
                          _selectedCategory = null;
                          _searchController.clear();
                          _query = '';
                        }),
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

  Widget _categoryChips() {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = _categories[index];
          final selected = c == _selectedCategory;
          return ChoiceChip(
            label: Text(c),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = selected ? null : c),
            selectedColor: const Color(0xFFBD7F66),
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFFBD7F66),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            side: BorderSide(
              color: selected ? const Color(0xFFBD7F66) : const Color(0xFFBD7F66).withValues(alpha: 0.25),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            showCheckmark: false,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          );
        },
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFFBD7F66), size: 28),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF2C2B22), fontWeight: FontWeight.w600, fontSize: 13)),
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