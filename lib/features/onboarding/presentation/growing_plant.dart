import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'clay_illustration.dart';

/// La plante de l'icône, qui pousse.
///
/// Le premier écran de l'onboarding ne montre pas le logo posé : la plante y
/// sort de terre. Une feuille émerge en fuseau presque droit, s'allonge,
/// s'écarte, s'élargit, puis se découpe — fentes d'abord, fenestrations
/// ensuite, comme une vraie Monstera qui vieillit. Les cinq feuilles se
/// suivent, la plus vieille en premier, et la dernière image est exactement
/// l'icône de l'application.
///
/// La séquence est rendue sous Blender (`tool/grow_monstera.py`) et rangée en
/// une image animée. Elle est lue image par image plutôt que gardée d'un
/// bloc : à cette définition, tenir les quarante images en mémoire coûterait
/// cent fois le prix d'une seule. La lecture suit l'horloge des images de
/// l'écran, pas une minuterie : elle s'arrête net avec l'écran.
///
/// Une fois la plante poussée, elle reste — une plante ne repousse pas — et
/// se met à respirer comme les autres objets du jardin. Quitter l'écran de
/// bienvenue défait l'objet, mais pas la plante : elle se retrouve où on l'a
/// laissée, jamais au premier jour.
class GrowingPlant extends StatefulWidget {
  const GrowingPlant({super.key, required this.side, this.animate = true});

  /// Côté de l'illustration, en points.
  final double side;

  /// L'écran est-il à l'affichage ? À `false`, la pousse patiente.
  final bool animate;

  static const String asset = 'assets/onboarding/pousse.webp';

  @override
  State<GrowingPlant> createState() => _GrowingPlantState();
}

class _GrowingPlantState extends State<GrowingPlant> with SingleTickerProviderStateMixin {
  /// Jusqu'où la plante a poussé pendant ce lancement, par-delà les allers et
  /// retours entre les écrans : la scène défait l'objet dès qu'il sort du
  /// champ, et le referait pousser de la terre nue sans cette mémoire.
  static int _reached = -1;

  late final Ticker _ticker = createTicker(_tick);

  ui.Codec? _codec;
  ui.Image? _image;
  Duration _frame = const Duration(milliseconds: 70);

  /// Rang de la dernière image décodée, -1 avant la première.
  int _index = -1;
  bool _decoding = false;
  bool _loading = false;

  /// Où en est la pousse. L'horloge de l'écran repart de zéro à chaque
  /// reprise : [_base] garde ce qui a déjà été joué.
  Duration _elapsed = Duration.zero;
  Duration _base = Duration.zero;

  /// Moment où la plante est devenue adulte : l'origine de sa respiration.
  Duration? _grownAt;
  var _pose = const BreathPose(0);

  bool get _grown => _grownAt != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_codec == null && !_loading) _load();
    _sync();
  }

  @override
  void didUpdateWidget(GrowingPlant old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  Future<void> _load() async {
    _loading = true;
    try {
      final data = await rootBundle.load(GrowingPlant.asset);
      if (!mounted) return;
      // Décodée à la taille d'affichage : à sa taille de fichier, une image
      // pèserait quatre mégaoctets en mémoire.
      final side = (widget.side * MediaQuery.devicePixelRatioOf(context)).round();
      _codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: side, targetHeight: side);
    } catch (_) {
      // Sans la séquence, l'écran garde son halo et son texte : rien de vital.
      return;
    }
    if (!mounted) {
      _codec?.dispose();
      _codec = null;
      return;
    }
    final last = _codec!.frameCount - 1;
    // Sans animations, la plante est là d'emblée ; déjà poussée, elle l'est
    // aussi. Sinon on reprend à l'image où on l'avait laissée.
    if (_reduceMotion || _reached >= last) {
      await _advance(last);
      return;
    }
    await _advance(math.max(_reached, 0));
    // L'horloge repart au niveau atteint, sans quoi la pousse attendrait
    // d'avoir rattrapé le temps déjà joué.
    _base = _frame * math.max(_index, 0);
    _sync();
  }

  /// Décode jusqu'à l'image [wanted], en n'affichant que celle-là : les
  /// images sautées, s'il y en a, ne servent qu'à avancer le décodeur.
  Future<void> _advance(int wanted) async {
    final codec = _codec;
    if (codec == null || _decoding) return;
    _decoding = true;
    final last = codec.frameCount - 1;
    while (_index < wanted.clamp(0, last)) {
      final frame = await codec.getNextFrame();
      _index++;
      _reached = math.max(_reached, _index);
      if (!mounted) {
        frame.image.dispose();
        _decoding = false;
        return;
      }
      _frame = frame.duration;
      if (_index >= wanted.clamp(0, last)) {
        _show(frame.image);
      } else {
        frame.image.dispose();
      }
    }
    _decoding = false;
    if (_index >= last && !_grown) {
      _grownAt = _ticker.isActive ? _elapsed : Duration.zero;
      _sync();
    }
  }

  void _show(ui.Image next) {
    final previous = _image;
    setState(() => _image = next);
    // L'image précédente est encore à l'écran jusqu'à la prochaine peinture :
    // on ne la libère qu'après.
    if (previous != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed + _base;
    final grownAt = _grownAt;
    if (grownAt == null) {
      final wanted = _elapsed.inMicroseconds ~/ _frame.inMicroseconds;
      if (wanted > _index) _advance(wanted);
      return;
    }
    final since = _elapsed - grownAt;
    setState(() => _pose = BreathPose(since.inMicroseconds / ClayIllustration.breath.inMicroseconds));
  }

  /// L'horloge ne tourne que quand il y a quelque chose à montrer : l'objet
  /// au centre de l'écran, animations permises.
  void _sync() {
    final wanted = widget.animate && !_reduceMotion && _codec != null;
    if (wanted && !_ticker.isActive) {
      _ticker.start();
    } else if (!wanted && _ticker.isActive) {
      _base = _elapsed;
      _ticker.stop();
      setState(() => _pose = const BreathPose(0));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _image?.dispose();
    _codec?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return ClayFloat(
      side: widget.side,
      pose: _pose,
      child: image == null
          ? const SizedBox.shrink()
          : RawImage(image: image, width: widget.side, height: widget.side, fit: BoxFit.contain, filterQuality: FilterQuality.high),
    );
  }
}
