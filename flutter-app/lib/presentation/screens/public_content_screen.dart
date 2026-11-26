import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_client.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/domain/models/guide.dart';
import 'package:medcin_app/domain/models/video.dart';
import 'package:medcin_app/presentation/screens/pdf_view_screen.dart';
import 'package:medcin_app/presentation/screens/video_player_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicContentScreen extends StatefulWidget {
  const PublicContentScreen({super.key});

  @override
  State<PublicContentScreen> createState() => _PublicContentScreenState();
}

class _PublicContentScreenState extends State<PublicContentScreen> {
  static const Color _accent = Color(0xFF8E7F68);

  List<Video> _videos = [];
  List<Guide> _guides = [];
  bool _loading = true;
  String? _error;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final videosData = await ApiService.get(ApiConfig.freeVideosEndpoint);
      final guidesData = await ApiService.get(ApiConfig.freePdfsEndpoint);
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
      debugPrint('Failed to load public content: $e');
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger le contenu public.';
          _loading = false;
        });
      }
    }
  }

  void _watchVideo(Video video) {
    if (video.videoUrl == null || video.videoUrl!.isEmpty) {
      _snack('Vidéo indisponible.', error: true);
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
    final url = guide.url;
    if (url == null) {
      _snack('Ressource indisponible.', error: true);
      return;
    }
    if (!mounted) return;
    if (kIsWeb) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (_) {
        _snack('Impossible d’ouvrir la ressource.', error: true);
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
      _snack('Impossible d’ouvrir la ressource.', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? const Color(0xFFDC2626) : _accent,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Contenu public',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: _accent,
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
            child: Center(child: CircularProgressIndicator(color: _accent)),
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
              child: Icon(Icons.cloud_off_rounded,
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
                backgroundColor: _accent,
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
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabButton(0, 'Vidéos', Icons.play_circle_outline_rounded),
          _tabButton(1, 'Ressources', Icons.menu_book_rounded),
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
            color: selected ? _accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17, color: selected ? Colors.white : _accent),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : _accent,
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
              child: Text('Aucune vidéo disponible',
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
              child: Text('Aucune ressource disponible',
                  style: TextStyle(color: Color(0xFFA69D8F)))),
        ),
      ];
    }
    return _guides.map(_guideCard).toList();
  }

  Widget _videoCard(Video video) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _accent.withValues(alpha: 0.06),
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
                    errorBuilder: (context, error, stack) => _thumbPlaceholder(),
                  )
                else
                  _thumbPlaceholder(),
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
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _watchVideo(video),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Regarder'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _thumbPlaceholder() {
    return Container(
      decoration: const BoxDecoration(color: _accent),
      child: const Icon(Icons.play_circle_outline_rounded,
          color: Colors.white, size: 44),
    );
  }

  Widget _guideCard(Guide guide) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: _accent.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 6)),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: () => _openGuide(guide),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 70,
            child: guide.thumbnailUrl != null
                ? Image.network(
                    guide.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _guideIcon(),
                  )
                : _guideIcon(),
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
        trailing: const Icon(Icons.chevron_right_rounded, color: _accent),
      ),
    );
  }

  Widget _guideIcon() {
    return Container(
      decoration: const BoxDecoration(color: _accent),
      child: const Icon(Icons.picture_as_pdf_rounded,
          color: Colors.white, size: 26),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              color: _accent, fontSize: 10.5, fontWeight: FontWeight.w600)),
    );
  }
}
