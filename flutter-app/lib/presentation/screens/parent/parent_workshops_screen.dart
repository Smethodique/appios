import 'dart:async';

import 'package:flutter/material.dart';
import 'package:medcin_app/config/api_config.dart';
import 'package:medcin_app/core/errors/api_exception.dart';
import 'package:medcin_app/data/services/document_viewer.dart';
import 'package:medcin_app/data/services/payment_service.dart';
import 'package:medcin_app/data/services/workshop_service.dart';
import 'package:medcin_app/presentation/screens/doctor/room_webview.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kWsGreen = Color(0xFF888D44);
const Color kWsWhite = Color(0xFFFFFFFF);

class ParentWorkshopsScreen extends StatefulWidget {
  const ParentWorkshopsScreen({super.key});

  @override
  State<ParentWorkshopsScreen> createState() => _ParentWorkshopsScreenState();
}

class _ParentWorkshopsScreenState extends State<ParentWorkshopsScreen> {
  List<WorkshopItem> _workshops = [];
  bool _loading = true;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final items = await WorkshopService.list();
      if (mounted) setState(() => _workshops = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(WorkshopItem workshop) async {
    try {
      final url = await WorkshopService.purchase(workshop.id);
      if (!mounted) return;
      final launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir la page de paiement.')),
        );
        return;
      }
      final reference = PaymentService.referenceFromUrl(url);
      if (reference != null) {
        unawaited(PaymentService.waitUntilFinished(reference).then((status) async {
          if (!mounted) return;
          if (status == 'paid') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Inscription confirmée. Bienvenue à l’atelier !')),
            );
          }
          await _load();
        }));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement impossible : $e')),
        );
      }
    }
  }

  Future<void> _join(WorkshopItem workshop) async {
    try {
      final url = await WorkshopService.join(workshop.id);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => RoomWebviewScreen(
          url: url,
          title: workshop.title,
          isOwner: false,
          viewOnly: false,
        ),
      ));
      await _load();
    } catch (e) {
      if (mounted) {
        final detail = e is ApiException ? '${e.statusCode} : ${e.message}' : e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de rejoindre ($detail)')),
        );
      }
    }
  }

  Future<void> _openMaterial(WorkshopMaterial material) async {
    try {
      final filename = _materialFilename(material);
      await DocumentViewer.openFromEndpoint(
        '${ApiConfig.workshopsEndpoint}/materials/${material.id}',
        filename,
        material.mime ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ouverture impossible : $e')),
        );
      }
    }
  }

  String _materialFilename(WorkshopMaterial material) {
    var name = material.title
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    if (name.isEmpty) name = 'document';

    final extension = _extensionFromName(name) ?? _extensionFromMime(material.mime);
    if (extension != null && !name.toLowerCase().endsWith(extension)) {
      name += extension;
    }
    return name;
  }

  String? _extensionFromName(String name) {
    final index = name.lastIndexOf('.');
    if (index <= 0 || index == name.length - 1) return null;
    final ext = name.substring(index).toLowerCase();
    return ext.length <= 6 ? ext : null;
  }

  String? _extensionFromMime(String? mime) {
    final value = (mime ?? '').toLowerCase().split(';').first.trim();
    switch (value) {
      case 'application/pdf':
        return '.pdf';
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'text/plain':
        return '.txt';
      case 'application/msword':
        return '.doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return '.docx';
      case 'application/vnd.ms-excel':
        return '.xls';
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return '.xlsx';
      case 'application/vnd.ms-powerpoint':
        return '.ppt';
      case 'application/vnd.openxmlformats-officedocument.presentationml.presentation':
        return '.pptx';
      default:
        return null;
    }
  }

  void _showWaiting(WorkshopItem workshop) {
    final when = _formatTime(workshop.scheduledAt);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(when.isEmpty
            ? 'En attente du médecin. Vous serez notifié dès qu’il lancera l’atelier.'
            : 'En attente du médecin. Début prévu $when — notification à son arrivée.'),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date à annoncer';
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return 'à ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kWsWhite,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(22, 52, 22, 28),
              decoration: const BoxDecoration(
                color: kWsGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: kWsWhite),
                  ),
                  const SizedBox(height: 8),
                  const Text('Ateliers thématiques',
                      style: TextStyle(
                          color: kWsWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Formations en direct animées par votre médecin. Inscrivez-vous, recevez les supports et rejoignez la session.',
                    style: TextStyle(
                        color: kWsWhite.withValues(alpha: 0.78), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: kWsGreen))
                  : _error != null
                      ? Text(_error!, style: const TextStyle(color: kWsGreen))
                      : _workshops.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('Aucun atelier annoncé pour le moment.',
                                    style: TextStyle(color: kWsGreen)),
                              ),
                            )
                          : Column(
                              children: _workshops
                                  .map((w) => _workshopCard(w))
                                  .toList(),
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _workshopCard(WorkshopItem workshop) {
    const endedColor = Color(0xFFB45309);
    const ink = Color(0xFF2C2B22);
    const muted = Color(0xFF8B8173);
    const cream = Color(0xFFF5F1EA);

    final ended = workshop.status == 'ended';
    final waitingDoctor = workshop.enrolled &&
        workshop.doctorStartedAt == null &&
        !ended;
    final live = workshop.doctorStartedAt != null || workshop.status == 'live';

    final statusColor = ended
        ? endedColor
        : waitingDoctor
            ? const Color(0xFF9C5B3E)
            : kWsGreen;
    final statusLabel = ended
        ? 'TERMINÉ'
        : waitingDoctor
            ? 'EN ATTENTE DU MÉDECIN'
            : live
                ? 'EN DIRECT'
                : workshop.status.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ended ? const Color(0xFFFDF8F1) : kWsWhite,
        borderRadius: BorderRadius.circular(22),
        border: ended
            ? Border.all(color: endedColor.withValues(alpha: 0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: (ended ? endedColor : kWsGreen).withValues(alpha: 0.12),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workshop.title,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${workshop.price.toStringAsFixed(0)} DH',
                        style: const TextStyle(
                            color: kWsGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _chip(statusLabel, statusColor),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cream,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: kWsGreen, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('DATE',
                              style: TextStyle(
                                  color: muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_formatDate(workshop.scheduledAt),
                              style: const TextStyle(
                                  color: ink,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    _chip('${workshop.durationMinutes} min', kWsGreen),
                  ],
                ),
              ],
            ),
          ),
          if (workshop.description != null && workshop.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(workshop.description!,
                style: const TextStyle(color: muted, fontSize: 13)),
          ],
          if (waitingDoctor) ...[
            const SizedBox(height: 12),
            Text(
              'Le médecin lancera l’atelier ${_formatTime(workshop.scheduledAt)}. '
              'Vous recevrez une notification sur votre téléphone dès qu’il sera en direct.',
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          ],
          if (workshop.enrolled && workshop.materials.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text('Supports de l’atelier',
                style: TextStyle(
                    color: ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 13)),
            const SizedBox(height: 6),
            ...workshop.materials.map(
              (m) => Material(
                color: kWsWhite,
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_file_rounded,
                      color: kWsGreen),
                  title: Text(m.title,
                      style: const TextStyle(color: ink, fontSize: 13)),
                  trailing: const Icon(Icons.open_in_new_rounded,
                      color: kWsGreen, size: 18),
                  onTap: () => _openMaterial(m),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: ended
                  ? null
                  : !workshop.enrolled
                      ? () => _purchase(workshop)
                      : waitingDoctor
                          ? () => _showWaiting(workshop)
                          : () => _join(workshop),
              icon: Icon(ended
                  ? Icons.check_circle_rounded
                  : !workshop.enrolled
                      ? Icons.lock_open_rounded
                      : waitingDoctor
                          ? Icons.schedule_rounded
                          : Icons.live_tv_rounded),
              label: Text(ended
                  ? 'Atelier terminé'
                  : !workshop.enrolled
                      ? 'S’inscrire · ${workshop.price.toStringAsFixed(0)} DH'
                      : waitingDoctor
                          ? 'En attente du médecin'
                          : 'Rejoindre l’atelier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kWsGreen,
                foregroundColor: kWsWhite,
                disabledBackgroundColor: endedColor.withValues(alpha: 0.16),
                disabledForegroundColor: endedColor,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
