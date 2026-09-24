import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/workspace_join_request.dart';
import 'join_workspace_preview_page.dart';

class ScanJoinQrPage extends StatefulWidget {
  const ScanJoinQrPage({super.key});

  @override
  State<ScanJoinQrPage> createState() => _ScanJoinQrPageState();
}

class _ScanJoinQrPageState extends State<ScanJoinQrPage> {
  bool _handled = false;

  bool get _supportsCameraScan {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsCameraScan) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr(en: 'Scan QR', ar: 'مسح QR'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              context.tr(
                en:
                    'Camera scanning is currently supported on Android, iOS, macOS, and web.\n\nTODO: add gallery-based QR import later if needed.',
                ar:
                    'المسح بالكاميرا مدعوم حاليًا على Android وiOS وmacOS والويب.\n\nسيتم إضافة الاستيراد من المعرض لاحقًا عند الحاجة.',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(en: 'Scan QR', ar: 'مسح QR'))),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_handled) {
                return;
              }

              for (final barcode in capture.barcodes) {
                final value = barcode.rawValue;
                if (value == null || value.trim().isEmpty) {
                  continue;
                }

                _handled = true;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => JoinWorkspacePreviewPage(
                      rawCode: value,
                      requestedVia: WorkspaceJoinRequestVia.qrScan,
                    ),
                  ),
                );
                break;
              }
            },
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(20),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    context.tr(
                      en:
                          'Point the camera at a Nexora join QR code.\nGallery import is intentionally deferred for now.',
                      ar:
                          'وجّه الكاميرا نحو رمز QR الخاص بالانضمام في Nexora.\nتم تأجيل الاستيراد من المعرض مؤقتًا.',
                    ),
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
