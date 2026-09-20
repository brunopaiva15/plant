import 'package:flutter/cupertino.dart';

/// La traduction des icônes d'Auxine en SF Symbols.
///
/// Depuis que la chrome de navigation est rendue par UIKit, les boutons des
/// pages sont dessinés par le système, et le système ne connaît que ses
/// propres symboles. Une table plutôt qu'un nom déclaré à chaque bouton : les
/// pages continuent de nommer une `CupertinoIcons`, et c'est ici que la
/// correspondance se fait — cent vingt sites d'appel n'ont pas eu à changer.
///
/// Une icône absente de la table n'est pas une faute : le bouton reste alors
/// dessiné par Flutter, et le nom manquant s'écrit dans la console en debug.
abstract final class SfSymbols {
  /// Le symbole d'une icône, ou `null` si la table ne l'a pas.
  static String? of(IconData icone) => _table[icone.codePoint];

  // Par point de code, et non par `IconData` : Dart refuse une clé de
  // table constante dont la classe redéfinit `==`.
  static final Map<int, String> _table = {
    CupertinoIcons.plus.codePoint: 'plus',
    CupertinoIcons.chart_bar.codePoint: 'chart.bar',
    CupertinoIcons.chart_bar_alt_fill.codePoint: 'chart.bar.fill',
    CupertinoIcons.chart_pie.codePoint: 'chart.pie',
    CupertinoIcons.list_bullet.codePoint: 'list.bullet',
    CupertinoIcons.square_list.codePoint: 'list.bullet.rectangle',
    CupertinoIcons.bolt.codePoint: 'bolt',
    CupertinoIcons.bolt_fill.codePoint: 'bolt.fill',
    CupertinoIcons.bolt_slash.codePoint: 'bolt.slash',
    CupertinoIcons.camera.codePoint: 'camera',
    CupertinoIcons.camera_fill.codePoint: 'camera.fill',
    CupertinoIcons.xmark.codePoint: 'xmark',
    CupertinoIcons.xmark_circle.codePoint: 'xmark.circle',
    CupertinoIcons.xmark_circle_fill.codePoint: 'xmark.circle.fill',
    CupertinoIcons.trash.codePoint: 'trash',
    CupertinoIcons.photo.codePoint: 'photo',
    CupertinoIcons.ellipsis.codePoint: 'ellipsis',
    CupertinoIcons.sparkles.codePoint: 'sparkles',
    CupertinoIcons.qrcode.codePoint: 'qrcode',
    CupertinoIcons.qrcode_viewfinder.codePoint: 'qrcode.viewfinder',
    CupertinoIcons.viewfinder.codePoint: 'viewfinder',
    CupertinoIcons.pencil.codePoint: 'pencil',
    CupertinoIcons.printer.codePoint: 'printer',
    CupertinoIcons.leaf_arrow_circlepath.codePoint: 'leaf.arrow.triangle.circlepath',
    CupertinoIcons.doc_on_doc.codePoint: 'doc.on.doc',
    CupertinoIcons.clock.codePoint: 'clock',
    CupertinoIcons.arrow_up_right_square.codePoint: 'arrow.up.right.square',
    CupertinoIcons.textformat.codePoint: 'textformat',
    CupertinoIcons.tag.codePoint: 'tag',
    CupertinoIcons.square_arrow_up.codePoint: 'square.and.arrow.up',
    CupertinoIcons.square_arrow_down.codePoint: 'square.and.arrow.down',
    CupertinoIcons.share.codePoint: 'square.and.arrow.up',
    CupertinoIcons.person_add.codePoint: 'person.badge.plus',
    CupertinoIcons.person.codePoint: 'person',
    CupertinoIcons.person_fill.codePoint: 'person.fill',
    CupertinoIcons.link.codePoint: 'link',
    CupertinoIcons.info.codePoint: 'info.circle',
    CupertinoIcons.question_circle.codePoint: 'questionmark.circle',
    CupertinoIcons.house.codePoint: 'house',
    CupertinoIcons.house_fill.codePoint: 'house.fill',
    CupertinoIcons.drop.codePoint: 'drop',
    CupertinoIcons.drop_triangle.codePoint: 'drop.triangle',
    CupertinoIcons.checkmark.codePoint: 'checkmark',
    CupertinoIcons.checkmark_alt.codePoint: 'checkmark',
    CupertinoIcons.book.codePoint: 'book',
    CupertinoIcons.arrow_uturn_left.codePoint: 'arrow.uturn.left',
    CupertinoIcons.arrow_2_squarepath.codePoint: 'arrow.triangle.2.circlepath',
    CupertinoIcons.arrow_clockwise.codePoint: 'arrow.clockwise',
    CupertinoIcons.archivebox.codePoint: 'archivebox',
    CupertinoIcons.sun_max.codePoint: 'sun.max',
    CupertinoIcons.sun_max_fill.codePoint: 'sun.max.fill',
    CupertinoIcons.square_stack.codePoint: 'square.stack',
    CupertinoIcons.square_grid_2x2.codePoint: 'square.grid.2x2',
    CupertinoIcons.square_grid_2x2_fill.codePoint: 'square.grid.2x2.fill',
    CupertinoIcons.square_arrow_left.codePoint: 'rectangle.portrait.and.arrow.right',
    CupertinoIcons.rectangle_split_3x1.codePoint: 'rectangle.split.3x1',
    CupertinoIcons.search.codePoint: 'magnifyingglass',
    CupertinoIcons.lightbulb.codePoint: 'lightbulb',
    CupertinoIcons.gear.codePoint: 'gearshape',
    CupertinoIcons.gear_alt.codePoint: 'gearshape',
    CupertinoIcons.bell.codePoint: 'bell',
    CupertinoIcons.chevron_left.codePoint: 'chevron.left',
    CupertinoIcons.chevron_back.codePoint: 'chevron.backward',
    CupertinoIcons.line_horizontal_3_decrease.codePoint: 'line.3.horizontal.decrease',
    CupertinoIcons.slider_horizontal_3.codePoint: 'slider.horizontal.3',
    CupertinoIcons.calendar.codePoint: 'calendar',
    CupertinoIcons.location.codePoint: 'location',
    CupertinoIcons.map.codePoint: 'map',
    CupertinoIcons.folder.codePoint: 'folder',
    CupertinoIcons.eye.codePoint: 'eye',
    CupertinoIcons.eye_slash.codePoint: 'eye.slash',
    CupertinoIcons.heart.codePoint: 'heart',
    CupertinoIcons.heart_fill.codePoint: 'heart.fill',
    CupertinoIcons.star_fill.codePoint: 'star.fill',
    CupertinoIcons.star.codePoint: 'star',
  };
}
