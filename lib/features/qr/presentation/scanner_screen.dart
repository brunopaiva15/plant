import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../application/plant_links.dart';

/// Scanner de QR codes : ouvre directement la fiche de la plante reconnue.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _controller = MobileScannerController(formats: const [BarcodeFormat.qrCode], detectionSpeed: DetectionSpeed.noDuplicates);
  bool _handling = false;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final raw = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) return;
    final id = PlantLinks.decode(raw);
    final plant = id == null ? null : await ref.read(plantRepositoryProvider).getPlant(id);
    if (!mounted) return;
    if (plant == null) {
      Haptics.warning();
      setState(() => _message = context.l10n.unknownQr);
      return;
    }
    _handling = true;
    Haptics.success();
    await _controller.stop();
    if (!mounted) return;
    context.pop();
    context.push(Routes.plant(plant.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(Space.xl),
                child: Text(l10n.cameraPermission, style: context.text.body.copyWith(color: Colors.white), textAlign: TextAlign.center),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(borderRadius: Radii.xlAll, border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.sm),
                  child: Row(
                    children: [
                      FloraIconButton(icon: CupertinoIcons.xmark, semanticLabel: l10n.close, onPressed: () => context.pop(), background: Colors.white24, color: Colors.white),
                      const Spacer(),
                      FloraIconButton(icon: CupertinoIcons.bolt, semanticLabel: 'torch', onPressed: _controller.toggleTorch, background: Colors.white24, color: Colors.white),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(Space.xl),
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.standard),
                    child: Text(
                      _message ?? l10n.scanHint,
                      key: ValueKey(_message),
                      style: context.text.callout.copyWith(color: _message == null ? Colors.white : c.terracotta),
                      textAlign: TextAlign.center,
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
}
