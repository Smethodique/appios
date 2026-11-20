import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/data/services/offline_file_service.dart';
import 'package:medcin_app/domain/models/guide.dart';
import 'package:medcin_app/presentation/screens/pdf_view_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  List<Guide> _guides = [];
  final Set<int> _downloaded = {};
  final Map<int, double> _progress = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _guides.isEmpty;
      _error = null;
    });
    try {
      final response = await ApiService.get(ApiConfig.freePdfsEndpoint);
      final list = response['guides'] as List? ?? [];
      final guides = list
          .map((j) => Guide.fromJson(Map<String, dynamic>.from(j as Map)))
          .toList();
      final downloaded = <int>{};
      if (!kIsWeb) {
        for (final g in guides) {
          if (await OfflineFileService.tracked(OfflineFileService.pdfKey, g.id) !=
              null) {
            downloaded.add(g.id);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _guides = guides;
        _downloaded.addAll(downloaded);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load guides: $e');
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger les guides.';
          _loading = false;
        });
      }
    }
  }

  String _fileName(Guide guide) {
    final base =
        guide.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 _-]'), '').trim();
    final safe = base.isEmpty ? 'guide' : base.replaceAll(' ', '_');
    final original = guide.originalName?.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '') ?? '';
    return 'guide_${guide.id}_$safe${original.toLowerCase().endsWith('.pdf') ? '' : '.pdf'}';
  }

  Future<void> _download(Guide guide) async {
    if (kIsWeb) {
      await _open(guide);
      return;
    }
    final url = guide.url;
    if (url == null) return;
    setState(() => _progress[guide.id] = 0);
    var saved = false;
    try {
      final path = await OfflineFileService.downloadPdf(
        url: url,
        fileName: _fileName(guide),
        onProgress: (p) {
          if (mounted) setState(() => _progress[guide.id] = p);
        },
      );
      if (path != null) {
        await OfflineFileService.markTracked(OfflineFileService.pdfKey, guide.id, path);
        saved = true;
      }
    } on Exception catch (e) {
      debugPrint('Guide download failed: $e');
    }
    if (mounted) {
      setState(() {
        _progress.remove(guide.id);
        if (saved) _downloaded.add(guide.id);
      });
      if (!saved) _snack('Échec du téléchargement.', error: true);
    }
  }

  Future<void> _open(Guide guide) async {
    if (kIsWeb) {
      final url = guide.url;
      if (url == null) {
        _snack('Lien indisponible.', error: true);
        return;
      }
      try {
        final ok = await launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication);
        if (!ok && mounted) _snack('Impossible d’ouvrir le guide.', error: true);
      } catch (e) {
        if (mounted) _snack('Impossible d’ouvrir le guide.', error: true);
      }
      return;
    }
    final path =
        await OfflineFileService.tracked(OfflineFileService.pdfKey, guide.id);
    if (path == null) {
      _snack('Guide introuvable sur cet appareil.', error: true);
      return;
    }
    try {
      final bytes = await OfflineFileService.readBytes(path);
      if (!mounted) return;
      _pushViewer(guide.title, () async => bytes);
    } on Exception {
      if (mounted) _snack('Impossible d’ouvrir le guide.', error: true);
    }
  }

  void _pushViewer(String title, Future<Uint8List> Function() loader) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewScreen(title: title, loader: loader),
      ),
    );
  }

  Future<void> _remove(Guide guide) async {
    if (kIsWeb) return;
    final path = await OfflineFileService.tracked(OfflineFileService.pdfKey, guide.id);
    if (path != null) {
      try {
        await OfflineFileService.deleteFile(path);
      } catch (_) {}
    }
    await OfflineFileService.untrack(OfflineFileService.pdfKey, guide.id);
    if (mounted) {
      setState(() => _downloaded.remove(guide.id));
      _snack('Guide supprimé de cet appareil.');
    }
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
        title: const Text('Guides', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
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
              child: Icon(Icons.menu_book_rounded,
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
    if (_guides.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 100),
            child: Center(
                child: Text('Aucun guide disponible',
                    style: TextStyle(color: Color(0xFFA69D8F)))),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _guides.length,
      itemBuilder: (context, index) => _guideCard(_guides[index]),
    );
  }

  Widget _guideCard(Guide guide) {
    final downloading = _progress.containsKey(guide.id);
    final progress = _progress[guide.id] ?? 0;
    final downloaded = kIsWeb || _downloaded.contains(guide.id);

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
        onTap: () => downloaded ? _open(guide) : _download(guide),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 72,
            child: guide.thumbnailUrl != null
                ? Image.network(
                    guide.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => _pdfIcon(),
                  )
                : _pdfIcon(),
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
        trailing: downloading
            ? SizedBox(
                height: 36,
                width: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircularProgressIndicator(
                        strokeWidth: 2.5, color: Color(0xFFBD7F66)),
                    Text('${(progress * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 9, color: Color(0xFFBD7F66))),
                  ],
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (downloaded && !kIsWeb)
                    IconButton(
                      tooltip: 'Supprimer',
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626), size: 20),
                      onPressed: () => _remove(guide),
                    ),
                  IconButton(
                    tooltip: downloaded ? 'Ouvrir' : 'Télécharger',
                    icon: Icon(
                      downloaded
                          ? Icons.visibility_rounded
                          : Icons.download_rounded,
                      color: const Color(0xFFBD7F66),
                      size: 24,
                    ),
                    onPressed: () =>
                        downloaded ? _open(guide) : _download(guide),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _pdfIcon() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF9C5B3E),
      ),
      child: const Icon(Icons.picture_as_pdf_rounded,
          color: Colors.white, size: 28),
    );
  }
}