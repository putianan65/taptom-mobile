import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../design/design.dart';
import '../effects/shader_backdrop.dart';
import 'buttons.dart';

/// Centres [child] and caps its width so lines stay readable on tablets and
/// the web.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContent,
    this.padding = const EdgeInsets.symmetric(horizontal: Space.gutter),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Standard page: a large serif title that collapses into the toolbar as the
/// content scrolls, followed by [slivers]. Handles pull-to-refresh, centred
/// content on wide screens and bottom padding for the navigation bar.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions = const [],
    this.onRefresh,
    this.floatingActionButton,
    this.bottomBar,
    this.leading,
    this.showBack,
    this.bottomPadding = Space.x4,
    this.backgroundColor,
  });

  final String title;
  final String? subtitle;
  final List<Widget> slivers;
  final List<Widget> actions;
  final Future<void> Function()? onRefresh;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final Widget? leading;

  /// Defaults to whether the navigator can pop.
  final bool? showBack;
  final double bottomPadding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final gutter = context.pageGutter;
    final canPop = showBack ?? Navigator.of(context).canPop();
    final expanded = subtitle == null ? 112.0 : 136.0;

    Widget scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: expanded,
          backgroundColor: backgroundColor ?? p.background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leadingWidth: canPop || leading != null ? 64 : 0,
          leading: leading ??
              (canPop
                  ? Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Center(
                        child: AppIconButton(
                          icon: AppIcons.back,
                          tooltip: 'ย้อนกลับ',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                      ),
                    )
                  : null),
          actions: [
            ...actions,
            SizedBox(width: math.max(12, gutter - 8)),
          ],
          flexibleSpace: _CollapsingTitle(
            title: title,
            subtitle: subtitle,
            gutter: gutter,
            hasLeading: canPop || leading != null,
          ),
        ),
        for (final sliver in slivers)
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            sliver: sliver,
          ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: bottomPadding + MediaQuery.paddingOf(context).bottom,
          ),
        ),
      ],
    );

    if (onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: onRefresh!,
        color: p.brand,
        backgroundColor: p.surface,
        edgeOffset: 80,
        child: scroll,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? p.background,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: scroll,
    );
  }
}

class _CollapsingTitle extends StatelessWidget {
  const _CollapsingTitle({
    required this.title,
    required this.subtitle,
    required this.gutter,
    required this.hasLeading,
  });

  final String title;
  final String? subtitle;
  final double gutter;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final top = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, constraints) {
        final min = settings?.minExtent ?? kToolbarHeight + top;
        final max = settings?.maxExtent ?? constraints.maxHeight;
        final t = ((constraints.maxHeight - min) / math.max(1, max - min))
            .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Hairline appears once the large title has collapsed.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: (1 - t * 4).clamp(0.0, 1.0),
                child: Divider(height: 1, color: p.line),
              ),
            ),
            // Compact title in the toolbar.
            Positioned(
              left: hasLeading ? 72 : gutter,
              right: 120,
              top: top,
              height: kToolbarHeight,
              child: Opacity(
                opacity: (1 - t * 2.5).clamp(0.0, 1.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.titleMedium,
                  ),
                ),
              ),
            ),
            // Large serif title.
            Positioned(
              left: gutter,
              right: gutter,
              bottom: 12,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.headlineLarge,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodyMedium?.copyWith(
                            color: p.inkMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Simple toolbar for screens that do not need a large title, such as maps
/// and full-screen tools.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showBack,
    this.transparent = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool? showBack;
  final bool transparent;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final canPop = showBack ?? Navigator.of(context).canPop();
    return AppBar(
      toolbarHeight: 64,
      backgroundColor: transparent ? Colors.transparent : p.background,
      automaticallyImplyLeading: false,
      leadingWidth: canPop ? 64 : 0,
      leading: canPop
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: AppIconButton(
                  icon: AppIcons.back,
                  tooltip: 'ย้อนกลับ',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            )
          : null,
      titleSpacing: canPop ? 4 : Space.gutter,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle != null)
            Text(subtitle!, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      actions: [...actions, const SizedBox(width: 12)],
      bottom: transparent
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(height: 1, color: p.line),
            ),
    );
  }
}

/// Deep green header with drifting contour lines, used on home dashboards.
/// [child] sits on top; the content sheet below overlaps the rounded edge.
class HeroHeader extends StatelessWidget {
  const HeroHeader({
    super.key,
    required this.child,
    this.trailing,
    this.minHeight = 200,
  });

  final Widget child;
  final Widget? trailing;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final gutter = context.pageGutter;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight + top),
      child: Stack(
        children: [
          const Positioned.fill(child: ContourBackdrop()),
          if (trailing != null)
            Positioned(right: math.max(8, gutter - 12), bottom: 0, child: trailing!),
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, top + Space.lg, gutter, Space.x4 + Radii.xl),
            child: child,
          ),
          // The top of the sheet that follows. Painted here rather than by
          // overlapping slivers, because a viewport paints earlier slivers on
          // top of later ones.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: Radii.xl,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.background,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page body under a [HeroHeader], which draws the sheet's rounded top.
class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.palette.background, child: child);
  }
}

/// Grid that picks a column count from a minimum tile width.
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minTileWidth = 150,
    this.spacing = Space.md,
    this.maxColumns = 4,
  });

  final List<Widget> children;
  final double minTileWidth;
  final double spacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = math.max(
          1,
          math.min(
            maxColumns,
            ((constraints.maxWidth + spacing) / (minTileWidth + spacing)).floor(),
          ),
        );
        final w = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: w, child: c),
          ],
        );
      },
    );
  }
}

extension EntranceX on Widget {
  /// Fade and rise into place, staggered by [index]. No-op when the platform
  /// asks for reduced motion.
  Widget entrance(BuildContext context, {int index = 0, double offset = 12}) {
    if (context.reduceMotion) return this;
    return animate(delay: Motion.stagger * math.min(index, 10))
        .fadeIn(duration: Motion.slow, curve: Motion.standard)
        .moveY(begin: offset, end: 0, duration: Motion.slow, curve: Motion.emphasized);
  }
}
