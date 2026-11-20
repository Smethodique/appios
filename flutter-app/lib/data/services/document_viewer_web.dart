// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> openBytes(Uint8List bytes, String filename, String mime) async {
  final type = mime.trim().isEmpty ? 'application/octet-stream' : mime.trim();
  final blob = html.Blob([bytes], type);
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  final closeButton = html.ButtonElement()
    ..style.position = 'absolute'
    ..style.top = '10px'
    ..style.right = '10px'
    ..style.zIndex = '2'
    ..style.padding = '8px 14px'
    ..style.border = '0'
    ..style.borderRadius = '10px'
    ..style.background = '#1f2937'
    ..style.color = '#ffffff'
    ..style.fontWeight = '600'
    ..style.cursor = 'pointer';

  final closeIcon = html.SpanElement()
    ..text = '×'
    ..style.marginRight = '8px'
    ..style.fontSize = '18px'
    ..style.verticalAlign = 'middle';
  closeButton.children.add(closeIcon);
  closeButton.children.add(html.SpanElement()..text = 'Fermer');

  final overlay = html.DivElement()
    ..style.position = 'fixed'
    ..style.top = '0'
    ..style.right = '0'
    ..style.bottom = '0'
    ..style.left = '0'
    ..style.zIndex = '2147483647'
    ..style.background = 'rgba(0, 0, 0, 0.92)';

  final frame = html.IFrameElement()
    ..src = objectUrl
    ..style.width = '100%'
    ..style.height = '100%'
    ..style.border = '0'
    ..style.background = '#ffffff';

  closeButton.onClick.listen((_) {
    overlay.remove();
    html.Url.revokeObjectUrl(objectUrl);
  });

  overlay.children.add(closeButton);
  overlay.children.add(frame);
  html.document.body?.append(overlay);
}
