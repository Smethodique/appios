import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/network/api_client.dart';
import 'package:medcin_app/data/services/offline_file_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  final int videoId;
  final String title;
  final String? videoUrl;
  final String? category;
  final String? ageRange;
  final String? description;

  const VideoPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.videoUrl,
    this.category,
    this.ageRange,
    this.description,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  String? _error;
  bool _downloading = false;
  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initPlayer() async {
    try {
      final uri = widget.videoUrl != null && widget.videoUrl!.isNotEmpty
          ? Uri.parse(widget.videoUrl!)
          : await _resolveStreamUrl();
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging: true,
        errorBuilder: (context, message) => _errorView('Erreur de lecture'),
      );
      setState(() {
        _videoController = controller;
        _chewieController = chewie;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<Uri> _resolveStreamUrl() async {
    final response = await ApiClient.instance.dio.get<dynamic>(
      '${ApiConfig.videosEndpoint}/${widget.videoId}/stream',
      options: Options(followRedirects: false),
    );
    final location = response.headers.value('location');
    if (location != null && location.isNotEmpty) {
      return Uri.parse(location);
    }
    return Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.videosEndpoint}/${widget.videoId}/serve',
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_off_rounded, color: Color(0xFFA69D8F), size: 44),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF8B8173))),
        ],
      ),
    );
  }

  Future<void> _share() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          subject: widget.title,
          text: 'Regarde cette vidéo : $url',
        ),
      );
    } catch (e) {
      debugPrint('Share failed: $e');
    }
  }

  Future<void> _downloadVideo() async {
    final url = widget.videoUrl;
    if (url == null || url.isEmpty || _downloading || kIsWeb) return;
    setState(() {
      _downloading = true;
      _downloadProgress = 0;
    });
    try {
      final safe = widget.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9 _-]'), '')
          .trim()
          .replaceAll(' ', '_');
      final name = 'video_${widget.videoId}_${safe.isEmpty ? 'clip' : safe}.mp4';
      final path = await OfflineFileService.downloadVideo(
        url: url,
        fileName: name,
        onProgress: (p) {
          if (mounted) setState(() => _downloadProgress = p);
        },
      );
      if (path != null) {
        await OfflineFileService
            .markTracked(OfflineFileService.videoKey, widget.videoId, path);
        _snack('Vidéo téléchargée pour lecture hors ligne.');
      }
    } on Exception {
      _snack('Échec du téléchargement de la vidéo.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
          _downloadProgress = 0;
        });
      }
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
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFBD7F66),
        elevation: 0,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) ...[
            if (!kIsWeb)
              if (_downloading)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: const Color(0xFFBD7F66),
                        value:
                            _downloadProgress == 0 ? null : _downloadProgress,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Télécharger',
                  icon: const Icon(Icons.download_rounded),
                  onPressed: _downloadVideo,
                ),
            IconButton(
              tooltip: 'Partager',
              icon: const Icon(Icons.share_rounded),
              onPressed: _share,
            ),
          ],
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildBody(size),
      ),
    );
  }

  Widget _buildBody(Size size) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFBD7F66)),
      );
    }
    if (_error != null) {
      return _errorView('Impossible de charger la vidéo. $_error');
    }
    final chewie = _chewieController!;
    final ratio = chewie.videoPlayerController.value.aspectRatio == 0
        ? 16 / 9
        : chewie.videoPlayerController.value.aspectRatio;
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            color: Colors.black,
            width: double.infinity,
            child: AspectRatio(
              aspectRatio: ratio,
              child: Chewie(controller: chewie),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill_rounded,
                        color: Color(0xFFBD7F66), size: 18),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2B22)),
                      ),
                    ),
                  ],
                ),
                if (widget.category != null || widget.ageRange != null) ...[
                  SizedBox(height: 10.w),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.w,
                    children: [
                      if (widget.category != null)
                        _metaChip(Icons.video_library_rounded, widget.category!),
                      if (widget.ageRange != null)
                        _metaChip(Icons.child_care_rounded, widget.ageRange!),
                    ],
                  ),
                ],
                if (widget.description != null &&
                    widget.description!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.description!,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.w),
      decoration: BoxDecoration(
        color: const Color(0xFFBD7F66).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFBD7F66)),
          SizedBox(width: 4.w),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFBD7F66))),
        ],
      ),
    );
  }
}