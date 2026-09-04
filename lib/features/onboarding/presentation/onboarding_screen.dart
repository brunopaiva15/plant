import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../core/haptics.dart';
import '../../../core/l10n/l10n.dart';
import '../../../design_system/design_system.dart';
import '../../plants/presentation/create_plant_flow.dart';

/// Onboarding en deux écrans : la promesse, puis le prénom. La première
/// plante se crée dans le flow standard ; l'utilisateur découvre l'app en l'utilisant.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _name = TextEditingController();
  int _page = 0;
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _name.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _finish({required bool addPlant}) async {
    final prefs = ref.read(preferencesProvider.notifier);
    if (_name.text.trim().isNotEmpty) await prefs.setDisplayName(_name.text);
    await prefs.setOnboardingDone();
    if (!mounted) return;
    context.go(Routes.today);
    if (addPlant) {
      await Future<void>.delayed(Motion.of(context, Motion.emphasis));
      if (mounted) await startCreatePlantFlow(context, ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.emphasis),
          switchInCurve: Motion.emphasized,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim), child: child),
          ),
          child: _page == 0
              ? Padding(
                  key: const ValueKey(0),
                  padding: const EdgeInsets.all(Space.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Center(
                        child: ScaleTransition(
                          scale: reduce ? const AlwaysStoppedAnimation(1.0) : CurvedAnimation(parent: _intro, curve: Motion.spring),
                          child: _Hero(),
                        ),
                      ),
                      const SizedBox(height: Space.xxl),
                      Text(l10n.onboardingTitle, style: context.text.display, textAlign: TextAlign.center),
                      const SizedBox(height: Space.sm),
                      Text(l10n.onboardingSubtitle, style: context.text.body.copyWith(color: c.inkSecondary), textAlign: TextAlign.center),
                      const Spacer(),
                      FloraButton(
                        label: l10n.continueLabel,
                        expand: true,
                        onPressed: () {
                          Haptics.light();
                          setState(() => _page = 1);
                        },
                      ),
                    ],
                  ),
                )
              : Padding(
                  key: const ValueKey(1),
                  padding: const EdgeInsets.all(Space.page),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: Space.huge),
                      Text(l10n.askNameTitle, style: context.text.title1),
                      const SizedBox(height: Space.xs),
                      Text(l10n.askNameSubtitle, style: context.text.callout),
                      const SizedBox(height: Space.xl),
                      FloraTextField(controller: _name, hint: l10n.yourNameHint, autofocus: true, large: true, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.done, onSubmitted: (_) => _finish(addPlant: true)),
                      const Spacer(),
                      FloraButton(label: l10n.addFirstPlant, expand: true, onPressed: () => _finish(addPlant: true)),
                      const SizedBox(height: Space.xs),
                      FloraButton(label: l10n.later, style: FloraButtonStyle.ghost, expand: true, onPressed: () => _finish(addPlant: false)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Illustration douce : disque sauge, pot et feuilles en emoji, sans asset externe.
class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(decoration: BoxDecoration(color: c.sageSoft, shape: BoxShape.circle)),
          Positioned(top: 26, left: 30, child: Text('🍃', style: TextStyle(fontSize: 26, color: c.sage))),
          const Positioned(top: 44, right: 34, child: Text('🌿', style: TextStyle(fontSize: 22))),
          const Text('🪴', style: TextStyle(fontSize: 96)),
        ],
      ),
    );
  }
}
