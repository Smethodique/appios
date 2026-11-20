import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_client.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/guide.dart';
import 'package:medcin_app/domain/models/video.dart';
import 'package:medcin_app/presentation/screens/pdf_view_screen.dart';
import 'package:medcin_app/presentation/screens/subscription_screen.dart';
import 'package:medcin_app/presentation/screens/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PremiumContentScreen extends StatefulWidget {
  const PremiumContentScreen({super.key});

  @override
  State<PremiumContentScreen> createState() => _PremiumContentScreenState();
}

class _PremiumContentScreenState extends State<PremiumContentScreen> {
  List<Video> _videos = [];
  List<Guide> _guides = [];
  bool _checking = true;
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final allowed = await _hasActiveSubscription();
    if (!mounted) return;
    if (!allowed) {
      _redirectToSubscription();
      return;
    }
    setState(() => _checking = false);
    await _load();
  }

  Future<bool> _hasActiveSubscription() async {
    try {
      final data = await ApiService.get(ApiConfig.subscriptionsEndpoint);
      return data['current'] != null;
    } catch (e) {
      debugPrint('Subscription check failed: $e');
      return false;
    }
  }

  void _redirectToSubscription() {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Un abonnement actif est requis pour ce contenu.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFFDC2626),
      ));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videosData = await ApiService.get(ApiConfig.premiumVideosEndpoint);
      final guidesData = await ApiService.get(ApiConfig.premiumGuidesEndpoint);
      final videos = (videosData['videos'] as List? ?? [])
          .map((j) => Video.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      final guides = (guidesData['guides'] as List? ?? [])
          .map((j) => Guide.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _videos = videos;
        _guides = guides;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load premium content: $e');
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le contenu premium.';
          _loading = false;
        });
      }
    }
  }

  void _watchVideo(Video video) {
    if (video.locked || video.videoUrl == null || video.videoUrl!.isEmpty) {
      _requireUpgrade(video.visibility == 'family_plus' ? 'Family Plus' : 'Family');
      return;
    }
    if (!mounted) return;
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

  Future<void> _openGuide(Guide guide) async {
    if (guide.locked || guide.url == null) {
      _requireUpgrade(guide.visibility == 'family_plus' ? 'Family Plus' : 'Family');
      return;
    }
    final url = guide.url!;
    if (!mounted) return;
    if (kIsWeb) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        _snack('Impossible d’ouvrir le guide.', error: true);
      }
      return;
    }
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      final bytes = Uint8List.fromList(response.data ?? const []);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewScreen(title: guide.title, loader: () async => bytes),
        ),
      );
    } on Exception {
      _snack('Impossible d’ouvrir le guide.', error: true);
    }
  }

  void _requireUpgrade(String planName) {
    if (!mounted) return;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Contenu verrouillé'),
        content: Text('Cette fonctionnalité nécessite l’abonnement $planName.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Plus tard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Voir les offres'),
          ),
        ],
      ),
    ).then((go) {
      if (go == true && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
      }
    });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFDC2626) : const Color(0xFFBD7F66),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBD7F66),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Contenu Premium',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: _checking
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFBD7F66)))
          : RefreshIndicator(
              color: const Color(0xFFBD7F66),
              onRefresh: _load,
              child: _buildBody(),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 120),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFFBD7F66))),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Center(
              child: Icon(Icons.lock_outline_rounded,
                  color: Color(0xFFA69D8F), size: 44)),
          const SizedBox(height: 12),
          Center(
              child: Text(_error!,
                  style: const TextStyle(color: Color(0xFF8B8173)))),
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBD7F66),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tabSelector(),
        const SizedBox(height: 12),
        if (_tab == 0) ..._buildVideoList() else ..._buildGuideList(),
      ],
    );
  }

  Widget _tabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFBD7F66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabButton(0, 'Vidéos', Icons.play_circle_outline_rounded),
          _tabButton(1, 'Guides', Icons.menu_book_rounded),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label, IconData icon) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFBD7F66) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? Colors.white : const Color(0xFFBD7F66)),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color:
                          selected ? Colors.white : const Color(0xFFBD7F66),
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVideoList() {
    if (_videos.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 90),
          child: Center(
              child: Text('Aucune vidéo premium disponible',
                  style: TextStyle(color: Color(0xFFA69D8F)))),
        ),
      ];
    }
    return [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _videos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 270,
        ),
        itemBuilder: (context, index) => _videoCard(_videos[index]),
      ),
    ];
  }

  List<Widget> _buildGuideList() {
    if (_guides.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 90),
          child: Center(
              child: Text('Aucun guide premium disponible',
                  style: TextStyle(color: Color(0xFFA69D8F)))),
        ),
      ];
    }
    return _guides.map(_guideCard).toList();
  }

  Widget _videoCard(Video video) {
    final locked = video.locked;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (video.thumbnailUrl != null)
                  Image.network(
                    video.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        _thumbPlaceholder(video),
                  )
                else
                  _thumbPlaceholder(video),
                if (locked)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: Colors.white, size: 28),
                    ),
                  )
                else
                  Container(
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 32),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF2C2B22),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5)),
                const SizedBox(height: 8),
                if (video.category != null || video.ageRange != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (video.category != null) _chip(video.category!),
                      if (video.ageRange != null) _chip(video.ageRange!),
                      _chip(video.visibility == 'family_plus'
                          ? 'Family Plus'
                          : 'Family'),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: locked
                      ? OutlinedButton.icon(
                          onPressed: () => _watchVideo(video),
                          icon: const Icon(Icons.lock_rounded, size: 16),
                          label: const Text('Débloquer'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFBD7F66),
                            side: const BorderSide(color: Color(0xFFBD7F66)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: () => _watchVideo(video),
                          icon: const Icon(Icons.play_arrow_rounded, size: 18),
                          label: const Text('Regarder'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFBD7F66),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumbPlaceholder(Video video) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF9C5B3E),
      ),
      child: const Icon(Icons.play_circle_outline_rounded,
          color: Colors.white, size: 44),
    );
  }

  Widget _guideCard(Guide guide) {
    final locked = guide.locked;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFBD7F66).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => _openGuide(guide),
        leading: SizedBox(
          width: 56,
          height: 70,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: guide.thumbnailUrl != null
                    ? Image.network(
                        guide.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _guideIcon(),
                      )
                    : _guideIcon(),
              ),
              if (locked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.lock_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
        title: Text(guide.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Color(0xFF2C2B22),
                fontWeight: FontWeight.w700,
                fontSize: 14.5)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              if (guide.category != null) guide.category!,
              if (guide.ageRange != null) guide.ageRange!,
              guide.sizeDisplay,
            ].join(' · '),
            style: const TextStyle(color: Color(0xFFA69D8F), fontSize: 11.5),
          ),
        ),
        trailing: Icon(
          locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
          color: locked ? const Color(0xFFA69D8F) : const Color(0xFFBD7F66),
        ),
      ),
    );
  }

  Widget _guideIcon() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF9C5B3E),
      ),
      child: const Icon(Icons.picture_as_pdf_rounded,
          color: Colors.white, size: 26),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFBD7F66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFFBD7F66), fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }
}