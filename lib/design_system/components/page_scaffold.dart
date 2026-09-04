import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/flora_theme.dart';
import '../tokens/spacing.dart';
import 'adaptive.dart';

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
    this.bottomPadding = 120,
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
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
    final body = scrollable
        ? SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.huge),
            child: child,
          )
        : child;
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
        child: SafeArea(top: true, bottom: false, child: Column(children: [Expanded(child: body), ?bottom])),
      );
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(title), actions: trailing == null ? null : [trailing!]),
      body: Column(children: [Expanded(child: body), ?bottom]),
    );
  }
}
