import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/theme_extensions.dart';
import '../utils/file_saver.dart';
import '../utils/formatters.dart';
import 'app_button.dart';
import 'app_toast.dart';
import 'copy_button.dart';

// Modules are always dark-on-white, even in dark mode: inverted QR codes scan
// unreliably on many phone cameras.
const _qrInk = AppColors.light;

Future<void> showQrDialog(BuildContext context, {required String url, required String code}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _QrDialog(url: url, code: code),
  );
}

class _QrDialog extends StatelessWidget {
  final String url;
  final String code;

  const _QrDialog({required this.url, required this.code});

  QrPainter _painter() => QrPainter(
    data: url,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _qrInk.textPrimary),
    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: _qrInk.textPrimary),
  );

  Future<void> _download(BuildContext context) async {
    // Render on a white canvas with a quiet zone, at print-friendly size.
    const size = 1024.0, pad = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size + pad * 2, size + pad * 2), Paint()..color = _qrInk.surface);
    canvas.translate(pad, pad);
    _painter().paint(canvas, const Size.square(size));
    final image = await recorder.endRecording().toImage((size + pad * 2).toInt(), (size + pad * 2).toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return;
    await saveBytes(data.buffer.asUint8List(), filename: 'qr-$code.png', mimeType: 'image/png');
    if (context.mounted) AppToast.success(context, 'QR code downloaded');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(Space.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('QR code', style: context.text.h2)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: Space.s4),
              Container(
                padding: const EdgeInsets.all(Space.s5),
                decoration: BoxDecoration(
                  color: _qrInk.surface,
                  borderRadius: Radii.lgAll,
                  border: Border.all(color: c.border),
                ),
                child: RepaintBoundary(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Semantics(
                      image: true,
                      label: 'QR code for $url',
                      child: CustomPaint(painter: _painter()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: Space.s4),
              Row(
                children: [
                  Expanded(
                    child: Text(Fmt.stripScheme(url), style: context.text.mono, overflow: TextOverflow.ellipsis),
                  ),
                  CopyButton(value: url),
                ],
              ),
              if (canSaveFiles) ...[
                const SizedBox(height: Space.s4),
                AppButton(
                  label: 'Download PNG',
                  icon: Icons.download_rounded,
                  expand: true,
                  onPressed: () => _download(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
