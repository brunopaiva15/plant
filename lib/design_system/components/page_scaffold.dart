import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';


/// La physique de défilement de toutes les pages : le rebond d'iOS, et rien
/// d'autre.
///
/// Surtout pas `AlwaysScrollableScrollPhysics` : elle accepte le geste même
/// quand le contenu tient à l'écran, et une page vide se laissait alors
/// pousser, grand titre replié dans la barre comme s'il y avait quelque
/// chose dessous. Sur iOS, une page qui tient ne bouge pas. La règle par
/// défaut de Flutter fait exactement cela ; il suffisait de ne pas la
/// contourner. Elle n'aurait de raison d'être qu'avec un « tirer pour
/// rafraîchir », que l'application n'a pas.
const ScrollPhysics floraScrollPhysics = BouncingScrollPhysics();

/// Un état vide posé au milieu de ce que l'œil voit : entre le bas de
/// l'en-tête et le haut de la barre d'onglets.
///
/// `SliverFillRemaining` seul centre dans tout ce qui reste du viewport — or
/// le contenu passe sous la barre flottante, et le Scaffold signale cette
/// bande dans le padding bas du MediaQuery. On la retire du calcul, sans
/// quoi le bloc tombe trop bas, comme aimanté par la barre.
class SliverCentered extends StatelessWidget {
  const SliverCentered({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: Center(child: child),
      ),
    );
  }
}

/// Page à grand titre (onglets) : CupertinoSliverNavigationBar natif sur iOS,
/// SliverAppBar.large sur Android. Le contenu est une liste de slivers.
class LargeTitlePage extends StatelessWidget {
  const LargeTitlePage({
    super.key,
    required this.title,
    required this.slivers,
    this.trailing,
    this.leading,
    this.searchField,
    this.controller,
    this.bottomPadding = 132,
  });

  final String title;
  final List<Widget> slivers;
  final Widget? trailing;
  final Widget? leading;
  final Widget? searchField;
  final ScrollController? controller;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final Widget header;
    if (isCupertino(context)) {
      header = CupertinoSliverNavigationBar(
        largeTitle: Text(title),
        leading: leading,
        trailing: trailing,
        backgroundColor: c.canvas.withValues(alpha: 0.82),
        border: null,
        stretch: true,
        automaticallyImplyLeading: false,
        // Plusieurs barres coexistent dans le shell à onglets : pas de Hero partagé.
        transitionBetweenRoutes: false,
        heroTag: 'large-title-$title',
        bottom: searchField == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs), child: searchField),
              ),
      );
    } else {
      header = SliverAppBar.large(
        title: Text(title),
        leading: leading,
        automaticallyImplyLeading: false,
        actions: trailing == null ? null : [Padding(padding: const EdgeInsets.only(right: Space.xs), child: trailing)],
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: context.text.display.copyWith(fontSize: 30),
        bottom: searchField == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.xs), child: searchField),
              ),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      body: CustomScrollView(
        controller: controller,
        physics: floraScrollPhysics,
        slivers: [
          header,
          ...slivers,
          SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
        ],
      ),
    );
  }
}

/// Page secondaire (push) à titre centré, avec retour natif.
class FloraPage extends StatelessWidget {
  const FloraPage({super.key, required this.title, required this.child, this.trailing, this.scrollable = true, this.bottom});

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool scrollable;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget body(double topInset) => scrollable
        ? SingleChildScrollView(
            physics: floraScrollPhysics,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(Space.page, topInset + Space.md, Space.page, Space.huge),
            child: child,
          )
        : Padding(padding: EdgeInsets.only(top: topInset), child: child);
    if (isCupertino(context)) {
      return CupertinoPageScaffold(
        backgroundColor: c.canvas,
        navigationBar: CupertinoNavigationBar(
          middle: Text(title),
          trailing: trailing,
          backgroundColor: c.canvas.withValues(alpha: 0.82),
          border: null,
          transitionBetweenRoutes: false,
          heroTag: 'page-$title',
        ),
        // La barre est translucide : le contenu défile dessous, décalé de sa hauteur.
        child: Builder(
          builder: (ctx) => SafeArea(
            top: false,
            bottom: false,
            child: Column(children: [Expanded(child: body(MediaQuery.paddingOf(ctx).top)), ?bottom]),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(title), actions: trailing == null ? null : [trailing!]),
      body: Column(children: [Expanded(child: body(0)), ?bottom]),
    );
  }
}
