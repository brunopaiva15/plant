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
import '../../../domain/models/models.dart';
import '../../inventory/presentation/inventory_item_sheet.dart';
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
    final link = PlantLinks.decodeLink(raw);
    if (link == null) {
      Haptics.warning();
      if (mounted) setState(() => _message = context.l10n.unknownQr);
      return;
    }
    // Une étiquette peut viser une plante ou un article d'inventaire : on
    // vérifie que la cible existe encore avant de quitter le scanner.
    final target = switch (link.kind) {
      FloraLinkKind.plant => await ref.read(plantRepositoryProvider).getPlant(link.id),
      FloraLinkKind.item => await ref.read(inventoryRepositoryProvider).get(link.id),
    };
    if (!mounted) return;
    if (target == null) {
      Haptics.warning();
      setState(() => _message = context.l10n.unknownQr);
      return;
    }
    _handling = true;
    Haptics.success();
    await _controller.stop();
    if (!mounted) return;
    context.pop();
    switch (target) {
      case InventoryItem item:
        await showInventoryItemSheet(context, existing: item);
      case _:
        context.push(Routes.plant(link.id));
    }
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
