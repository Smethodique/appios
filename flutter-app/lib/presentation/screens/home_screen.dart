// Nassreddin — home screen rebuilt for the DrImane redesign (November 2026).
// All data logic is unchanged and kept verbatim: _loadVideos, _checkLiveSessions,
// _filtered, the loading / error / empty states and every destination. What
// changed is the presentation: a forest header dome with the parent greeting,
// three action discs straddling the dome edge, three identical content tiles,
// a category filter rail and a new video card. The "?" button opens the guided
// tour (spotlight_tour.dart), which also runs once on first launch.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/core/storage/intro_storage.dart';
import 'package:medcin_app/core/theme/app_theme.dart';
import 'package:medcin_app/core/theme/app_tokens.dart';
import 'package:medcin_app/data/repositories/child_repository.dart';
import 'package:medcin_app/domain/models/video.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/screens/main_shell.dart';
import 'package:medcin_app/presentation/screens/parent/parent_calls_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_live_sessions_screen.dart';
import 'package:medcin_app/presentation/screens/parent/parent_workshops_screen.dart';
import 'package:medcin_app/presentation/screens/appointments/parent_appointments_screen.dart';
import 'package:medcin_app/presentation/screens/public_content_screen.dart';
import 'package:medcin_app/presentation/screens/premium_content_screen.dart';
import 'package:medcin_app/presentation/screens/video_player_screen.dart';
import 'package:medcin_app/presentation/widgets/spotlight_tour.dart';

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
  final ScrollController _categoryScrollController = ScrollController();
  bool _categoryAtEnd = false;
  bool _categoryHasOverflow = false;
  bool _categoryScrollForward = true;

  // Nassreddin — the header greets the parent and asks after the children by
  // first name. Loaded once, fail-silent: the header simply shows the tagline
  // if the children list is unavailable.
  List<String> _childNames = const [];

  // Nassreddin — targets for the guided tour.
  final GlobalKey _bellKey = GlobalKey(debugLabel: 'home-bell');
  final GlobalKey _livesKey = GlobalKey(debugLabel: 'home-lives');
  final GlobalKey _rdvKey = GlobalKey(debugLabel: 'home-rdv');
  final GlobalKey _premiumKey = GlobalKey(debugLabel: 'home-premium');
  final GlobalKey _chipsKey = GlobalKey(debugLabel: 'home-chips');

  @override
  void initState() {
    super.initState();
    _categoryScrollController.addListener(_onCategoryScroll);
    MainShell.homeRefreshTick.addListener(_loadVideos);
    _loadVideos();
    _checkLiveSessions();
    _loadChildren();
    _liveCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkLiveSessions());
    // Nassreddin — first launch: open the guide once the first frame has laid
    // out the controls it points at.
    if (!IntroStorage.seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) _openTour();
        });
      });
    }
  }

  void _onCategoryScroll() {
    if (!_categoryScrollController.hasClients || !mounted) return;
    final position = _categoryScrollController.position;
    final atEnd = position.pixels >= position.maxScrollExtent - 8;
    final atStart = position.pixels <= 8;
    bool? forward;
    if (atEnd && _categoryScrollForward) forward = false;
    if (atStart && !_categoryScrollForward) forward = true;
    if (forward != null || atEnd != _categoryAtEnd) {
      setState(() {
        _categoryAtEnd = atEnd;
        if (forward != null) _categoryScrollForward = forward;
      });
    }
  }

  void _syncCategoryOverflow() {
    if (!mounted) return;
    final overflow = _categoryScrollController.hasClients &&
        _categoryScrollController.position.maxScrollExtent > 8;
    if (overflow != _categoryHasOverflow ||
        (!overflow && (_categoryAtEnd || !_categoryScrollForward))) {
      setState(() {
        _categoryHasOverflow = overflow;
        if (!overflow) {
          _categoryAtEnd = false;
          _categoryScrollForward = true;
        }
      });
    }
  }

  void _slideCategories() {
    if (!_categoryScrollController.hasClients) return;
    final position = _categoryScrollController.position;
    // Small readable chunks in both directions: never jump to the opposite
    // end in one tap, even when the overflow is short.
    final viewportStep =
        (position.viewportDimension * 0.6).clamp(140.0, 260.0).toDouble();
    final third = position.maxScrollExtent / 3;
    final step = third < viewportStep
        ? (third < 80.0 ? 80.0 : third)
        : viewportStep;
    final target = (position.pixels + (_categoryScrollForward ? step : -step))
        .clamp(0.0, position.maxScrollExtent)
        .toDouble();
    _categoryScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    MainShell.homeRefreshTick.removeListener(_loadVideos);
    _liveCheckTimer?.cancel();
    _scrollController.dispose();
    _categoryScrollController.dispose();
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
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncCategoryOverflow());
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

  Future<void> _loadChildren() async {
    try {
      final children = await ChildRepository.list();
      if (!mounted) return;
      setState(() {
        _childNames = children
            .map((c) => c.firstName.trim())
            .where((n) => n.isNotEmpty)
            .toList();
      });
    } catch (_) {
      // Header falls back to the tagline.
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

  void _onNotificationsPressed() {
    context.push('/notifications');
  }

  /// Nassreddin — the "?" button. Scrolls to the top so every target is on
  /// screen, then runs the spotlight tour over the live screen.
  void _openTour() {
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    SpotlightTour.show(
      context,
      steps: [
        TourStep(target: _rdvKey, title: 'Prendre rendez-vous',
            body: 'Touchez ce bouton pour choisir un créneau libre et réserver en quelques secondes.'),
        TourStep(target: _livesKey, title: 'Lives et appels',
            body: 'Le point lumineux signale un live en cours. Juste à côté, vos appels vidéo avec le médecin.'),
        TourStep(target: _premiumKey, title: 'Contenu Premium', radius: AppRadius.lg + 8,
            body: 'Vidéos exclusives et ressources pour votre famille. Public et Ateliers suivent juste en dessous.'),
        TourStep(target: _chipsKey, title: 'Vidéos récentes', radius: 24,
            body: 'Filtrez par thème : les vidéos se mettent à jour instantanément.'),
        TourStep(target: MainShell.tabEnfantKey, title: 'Le carnet de vos enfants', radius: 20,
            body: 'Croissance, vaccins, antécédents et documents — un carnet par enfant, toujours à jour.'),
        TourStep(target: MainShell.tabAbonnementKey, title: 'Votre formule', radius: 20,
            body: 'Gratuit, Family ou Family Plus : débloquez les lives et le contenu quand vous en avez besoin.'),
        TourStep(target: _bellKey, title: 'Vos notifications',
            body: 'Rappels de rendez-vous, vaccins à prévoir et nouveaux documents arrivent ici.'),
      ],
      onFinished: IntroStorage.markSeen,
    );
  }

  // ---------------------------------------------------------------------------
  // Greeting
  // ---------------------------------------------------------------------------

  String get _greeting {
    final hour = DateTime.now().hour;
    final hello = (hour >= 18 || hour < 5) ? 'Bonsoir' : 'Bonjour';
    final full = AuthProvider.instance.user?.name.trim() ?? '';
    final first = full.isEmpty ? '' : full.split(RegExp(r'\s+')).first;
    return first.isEmpty ? hello : '$hello, $first';
  }

  /// Agrees in number: "Comment va Yasmine", "Comment vont Yasmine et Adam".
  String get _question {
    final n = _childNames;
    if (n.isEmpty) return 'Des conseils fiables, à portée de main.';
    if (n.length == 1) return "Comment va ${n.first} aujourd'hui ?";
    final joined = '${n.sublist(0, n.length - 1).join(', ')} et ${n.last}';
    return "Comment vont $joined aujourd'hui ?";
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: RefreshIndicator(
        color: AppColors.sage,
        onRefresh: _loadVideos,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildDome(context),
                  Positioned(left: 26, right: 26, bottom: -34, child: _buildDiscs()),
                ],
              ),
              const SizedBox(height: 34 + 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _tile(
                      key: _premiumKey,
                      gradient: AppGradients.amber,
                      iconColor: AppColors.forest,
                      icon: Icons.workspace_premium_rounded,
                      title: 'Contenu Premium',
                      subtitle: 'Vidéos exclusives et ressources pour votre famille',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PremiumContentScreen()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _tile(
                      gradient: AppGradients.tan,
                      iconColor: AppColors.forest,
                      icon: Icons.auto_stories_rounded,
                      title: 'Contenu public',
                      subtitle: 'Vidéos et ressources gratuites pour votre famille',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PublicContentScreen()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _tile(
                      gradient: AppGradients.sage,
                      iconColor: Colors.white,
                      icon: Icons.school_rounded,
                      title: 'Ateliers thématiques',
                      subtitle: 'Formations en direct avec votre médecin',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ParentWorkshopsScreen()),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(child: Text('Vidéos récentes', style: AppTypography.display(19))),
                        if (_videos.isNotEmpty && _selectedCategory != null)
                          TextButton(
                            onPressed: () => setState(() => _selectedCategory = null),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              foregroundColor: AppColors.tanText,
                            ),
                            child: const Text('Réinitialiser'),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _categoryRail(),
                    const SizedBox(height: AppSpacing.md),
                    _buildVideos(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header dome
  // ---------------------------------------------------------------------------

  Widget _buildDome(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.gutter, topInset + 10, AppSpacing.gutter, 46 + 30),
      decoration: const BoxDecoration(
        gradient: AppGradients.header,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Soft decorative blobs behind the header content.
          Positioned(right: -60, top: -80, child: _blob(190, AppColors.sage.withValues(alpha: 0.28))),
          Positioned(left: -40, bottom: -60, child: _blob(120, AppColors.amber.withValues(alpha: 0.12))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: _onLogoPressed,
                    borderRadius: BorderRadius.circular(18),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      child: Image.asset(
                        'assets/images/logo_brown.png',
                        width: 72,
                        height: 72,
                        fit: BoxFit.contain,
                        semanticLabel: 'Logo DrImane',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DrImane', style: AppTypography.display(18, color: Colors.white, height: 1.1)),
                        Text('Espace médical familial',
                            style: AppTypography.sans(11, color: Colors.white.withValues(alpha: 0.72))),
                      ],
                    ),
                  ),
                  ValueListenableBuilder<int>(
                    valueListenable: MainShell.unreadNotifier,
                    builder: (context, unread, _) => _roundButton(
                      key: _bellKey,
                      icon: Icons.notifications_outlined,
                      onTap: _onNotificationsPressed,
                      badge: unread,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _roundButton(icon: Icons.help_outline_rounded, onTap: _openTour),
                ],
              ),
              const SizedBox(height: 16),
              Text(_greeting, style: AppTypography.display(23, color: Colors.white)),
              const SizedBox(height: 4),
              Text(_question,
                  style: AppTypography.sans(14, color: Colors.white.withValues(alpha: 0.88))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );

  Widget _roundButton({Key? key, required IconData icon, required VoidCallback onTap, int badge = 0}) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Badge.count(
        count: badge,
        isLabelVisible: badge > 0,
        backgroundColor: AppColors.amber,
        textColor: AppColors.forest,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action discs
  // ---------------------------------------------------------------------------

  Widget _buildDiscs() {
    return Row(
      children: [
        Expanded(
          child: _disc(
            key: _livesKey,
            gradient: AppGradients.sage,
            iconColor: Colors.white,
            icon: Icons.live_tv_rounded,
            label: 'Lives',
            live: _hasLiveSession,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParentLiveSessionsScreen()),
            ),
          ),
        ),
        Expanded(
          child: _disc(
            key: _rdvKey,
            gradient: AppGradients.amber,
            iconColor: AppColors.forest,
            icon: Icons.calendar_month_rounded,
            label: 'Rendez-vous',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParentAppointmentsScreen()),
            ),
          ),
        ),
        Expanded(
          child: _disc(
            gradient: AppGradients.tan,
            iconColor: AppColors.forest,
            icon: Icons.call_rounded,
            label: 'Appels',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ParentCallsScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _disc({
    Key? key,
    required Gradient gradient,
    required Color iconColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool live = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            key: key,
            width: 64,
            height: 64,
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient, boxShadow: AppShadows.disc),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: iconColor, size: 28),
                if (live)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.forest, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(label, style: AppTypography.sans(12, weight: FontWeight.w800, color: AppColors.textSecondary)),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Content tiles — one design, stacked
  // ---------------------------------------------------------------------------

  Widget _tile({
    Key? key,
    required Gradient gradient,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      key: key,
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: AppGradients.tile,
            borderRadius: AppRadius.lgAll,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.display(15)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.sans(11.5, color: AppColors.textMuted, height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.border, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Category rail — reads the same _categories list the dropdown used
  // ---------------------------------------------------------------------------

  Widget _categoryRail() {
    if (_categories.isEmpty) return SizedBox(key: _chipsKey, height: 0);
    final all = <String?>[null, ..._categories];
    // Recheck after layout: on wide screens every chip fits, so the arrow hides.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCategoryOverflow());
    final canScroll = _categoryHasOverflow;
    return Row(
      key: _chipsKey,
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: all.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = all[i];
                final selected = cat == _selectedCategory;
                return InkWell(
                  onTap: () => setState(() => _selectedCategory = cat),
                  borderRadius: AppRadius.pillAll,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: selected ? AppGradients.sage : null,
                      color: selected ? null : AppColors.surface,
                      borderRadius: AppRadius.pillAll,
                      border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                    ),
                    child: Text(
                      cat ?? 'Toutes',
                      style: AppTypography.sans(12, weight: FontWeight.w800,
                          color: selected ? Colors.white : AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (canScroll) ...[
          const SizedBox(width: 8),
          Material(
            color: AppColors.amber,
            shape: const CircleBorder(),
            elevation: 3,
            shadowColor: AppColors.amberDeep.withValues(alpha: 0.4),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _slideCategories,
              child: SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  _categoryScrollForward
                      ? Icons.arrow_forward_rounded
                      : Icons.arrow_back_rounded,
                  size: 18,
                  color: AppColors.amberText,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Videos — states unchanged, card redesigned
  // ---------------------------------------------------------------------------

  Widget _buildVideos() {
    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator(color: AppColors.sage)),
      );
    }
    if (_error != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off_rounded, color: AppColors.textMuted, size: 44),
              const SizedBox(height: 12),
              Text(_error!, style: AppTypography.sans(13.5, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadVideos,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ],
          ),
        ),
      );
    }
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Text('Aucune vidéo trouvée', style: AppTypography.sans(13.5, color: AppColors.textMuted)),
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
        mainAxisExtent: 236,
      ),
      itemBuilder: (context, index) => _videoCard(filtered[index]),
    );
  }

  Widget _videoCard(Video video) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.none,
      child: InkWell(
        onTap: () => _openVideo(video),
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(borderRadius: AppRadius.lgAll, boxShadow: AppShadows.card),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: SizedBox(
                      height: 96,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          video.thumbnailUrl != null
                              ? Image.network(
                                  video.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const ColoredBox(
                                      color: AppColors.recess,
                                      child: Center(
                                        child: CircularProgressIndicator(color: AppColors.sage, strokeWidth: 2),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) => _thumbnailFallback(video),
                                )
                              : _thumbnailFallback(video),
                          if (video.ageRange != null)
                            Positioned(
                              left: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  borderRadius: AppRadius.pillAll,
                                ),
                                child: Text(video.ageRange!,
                                    style: AppTypography.sans(9.5, weight: FontWeight.w800, color: AppColors.forest)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.sans(13, weight: FontWeight.w800, height: 1.3)),
                        if (video.description != null) ...[
                          const SizedBox(height: 3),
                          Text(video.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.sans(11, color: AppColors.textMuted, height: 1.4)),
                        ],
                        if (video.category != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: const BoxDecoration(color: AppColors.sageTint, borderRadius: AppRadius.pillAll),
                            child: Text(video.category!,
                                style: AppTypography.sans(10.5, weight: FontWeight.w800, color: AppColors.sageText)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              // Play button sits on the seam between image and text.
              Positioned(
                right: 10,
                top: 96 - 17,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.amber, boxShadow: AppShadows.disc),
                  child: const Icon(Icons.play_arrow_rounded, color: AppColors.forest, size: 22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbnailFallback(Video video) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.sage),
      child: Center(
        child: Icon(Icons.play_circle_fill_rounded, color: Colors.white.withValues(alpha: 0.7), size: 48),
      ),
    );
  }
}
