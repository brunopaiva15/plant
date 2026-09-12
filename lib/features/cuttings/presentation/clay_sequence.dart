import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../onboarding/presentation/clay_illustration.dart';

/// Une séquence d'argile : une image animée rendue sous Blender, jouée une
/// fois quand l'objet est au centre de l'écran, puis tenue sur sa dernière
/// image, où l'objet se met à respirer comme ceux de l'onboarding.
///
/// Elle est lue image par image plutôt que gardée d'un bloc : à cette
/// définition, tenir trente images en mémoire coûterait cent fois le prix
/// d'une seule. La lecture suit l'horloge des images de l'écran, pas une
/// minuterie : elle s'arrête net avec l'écran, et reprend où elle en était.
///
/// L'objet qui quitte la scène est défait, et refait quand on y revient : la
/// séquence se rejoue alors depuis le début, ce qui est ce qu'on attend d'un
/// geste qu'on revient regarder. Avec « réduire les animations », c'est la
/// dernière image qui est montrée, d'emblée.
class ClaySequence extends StatefulWidget {
  const ClaySequence({super.key, required this.asset, required this.side, this.animate = true});

  /// Chemin de l'image animée (WebP, fond transparent).
  final String asset;

  /// Côté de l'illustration, en points.
  final double side;

  /// L'objet est-il au centre de l'écran ? À `false`, la séquence patiente
  /// sur l'image où elle en est.
  final bool animate;

  /// Charge d'avance les octets d'une séquence, pour que l'objet suivant
  /// arrive sans temps mort. Le décodage, lui, se fait à l'arrivée.
  static Future<void> precache(String asset) async {
    try {
      await rootBundle.load(asset);
    } catch (_) {
      // Une séquence absente se verra à l'arrivée, pas ici.
    }
  }

  @override
  State<ClaySequence> createState() => _ClaySequenceState();
}

class _ClaySequenceState extends State<ClaySequence> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);

  ui.Codec? _codec;
  ui.Image? _image;

  /// L'instant, sur l'horloge de lecture, où l'image suivante est due. Les
  /// images n'ont pas toutes la même durée : l'emballage fond celles qui se
  /// répètent, la pose tenue au début ou à la fin, en une seule plus longue.
  Duration _due = Duration.zero;

  /// Rang de la dernière image décodée, -1 avant la première.
  int _index = -1;
  bool _decoding = false;
  bool _loading = false;

  /// Où en est la lecture. L'horloge de l'écran repart de zéro à chaque
  /// reprise : [_base] garde ce qui a déjà été joué.
  Duration _elapsed = Duration.zero;
  Duration _base = Duration.zero;

  /// La séquence est-elle finie ? L'objet respire alors.
  bool _done = false;
  final _breath = Breath();
  var _pose = const BreathPose.rest();

  /// La séquence doit-elle avancer ? Relevé à chaque changement, pour que le
  /// tick n'ait pas à interroger le contexte.
  bool _wanted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_codec == null && !_loading) _load();
    _sync();
  }

  @override
  void didUpdateWidget(ClaySequence old) {
    super.didUpdateWidget(old);
    _sync();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  Future<void> _load() async {
    _loading = true;
    try {
      final data = await rootBundle.load(widget.asset);
      if (!mounted) return;
      // Décodée à la taille d'affichage : à sa taille de fichier, une image
      // pèserait plusieurs mégaoctets en mémoire.
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
    if (_reduceMotion) {
      await _advance(_codec!.frameCount - 1);
      return;
    }
    await _advance(0);
    _sync();
  }

  /// Décode jusqu'à l'image [wanted], en n'affichant que celle-là : les
  /// images sautées, s'il y en a, ne servent qu'à avancer le décodeur.
  Future<void> _advance(int wanted) async {
    final codec = _codec;
    if (codec == null || _decoding) return;
    _decoding = true;
    final last = codec.frameCount - 1;
    final target = wanted.clamp(0, last);
    while (_index < target) {
      final frame = await codec.getNextFrame();
      _index++;
      if (!mounted) {
        frame.image.dispose();
        _decoding = false;
        return;
      }
      _due += frame.duration;
      if (_index >= target) {
        _show(frame.image);
      } else {
        frame.image.dispose();
      }
    }
    _decoding = false;
    if (_index >= last && !_done) {
      _done = true;
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
    if (!_done) {
      if (!_wanted) return _park();
      if (_elapsed >= _due) _advance(_index + 1);
      return;
    }
    _breath.advance(elapsed, breathing: _wanted);
    setState(() => _pose = _breath.pose);
    if (!_wanted && _breath.resting) _park();
  }

  /// Range l'horloge en gardant la place : la lecture reprendra où elle en est.
  void _park() {
    _base = _elapsed;
    _ticker.stop();
  }

  /// L'horloge ne tourne que quand il y a quelque chose à montrer : l'objet
  /// au centre de l'écran, animations permises — ou la respiration qu'il
  /// lui reste à rendre en le quittant.
  void _sync() {
    final reduce = _reduceMotion;
    _wanted = widget.animate && !reduce && _codec != null;
    if (reduce) {
      if (_ticker.isActive) _park();
      if (!_breath.resting) {
        setState(() {
          _breath.rest();
          _pose = _breath.pose;
        });
      }
      return;
    }
    if (_wanted && !_ticker.isActive) _ticker.start();
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
