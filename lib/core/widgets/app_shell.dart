import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/design.dart';
import '../effects/logo_mark.dart';

class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
    this.badge = 0,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;
  final int badge;
}

/// Role home shell. A bottom bar on phones and a navigation rail from tablet
/// width up. Pages are built on first visit, then kept alive and
/// cross-faded when switching; tickers on hidden pages are paused.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
    this.railFooter,
    this.overlay,
  });

  final List<ShellDestination> destinations;
  final int initialIndex;

  /// Shown at the bottom of the rail, e.g. the role label.
  final Widget? railFooter;

  /// Drawn above the pages, e.g. an in-app notification banner.
  final Widget? overlay;

  @override
  State<AppShell> createState() => AppShellState();
}

class AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  // Pages are built on first visit, so a hidden tab (a map in particular)
  // never lays out before it has been shown.
  late final Set<int> _visited = {widget.initialIndex};

  int get index => _index;

  void select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _visited.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wide = !context.isCompact;

    final pages = Stack(
      children: [
        for (var i = 0; i < widget.destinations.length; i++)
          _FadeIndexed(
            active: i == _index,
            child: _visited.contains(i) ? widget.destinations[i].page : const SizedBox.shrink(),
          ),
        if (widget.overlay != null) widget.overlay!,
      ],
    );

    if (wide) {
      return Scaffold(
        backgroundColor: p.background,
        body: Row(
          children: [
            _Rail(
              destinations: widget.destinations,
              index: _index,
              onSelect: select,
              footer: widget.railFooter,
            ),
            VerticalDivider(width: 1, color: p.line),
            Expanded(child: pages),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      extendBody: true,
      body: pages,
      bottomNavigationBar: _BottomBar(
        destinations: widget.destinations,
        index: _index,
        onSelect: select,
      ),
    );
  }
}

/// Keeps a page mounted but hidden, fading it when it becomes active.
class _FadeIndexed extends StatelessWidget {
  const _FadeIndexed({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !active,
      // The fade sits outside TickerMode: muting it would freeze the page
      // that is leaving at full opacity on top of the one arriving.
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: context.reduceMotion ? Duration.zero : Motion.base,
        curve: Motion.standard,
        child: TickerMode(
          enabled: active,
          child: ExcludeSemantics(excluding: !active, child: child),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.index,
    required this.onSelect,
  });

  final List<ShellDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.line)),
      ),
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom - 6 : 6, top: 6),
      child: Row(
        children: [
          for (var i = 0; i < destinations.length; i++)
            Expanded(
              child: _BarItem(
                destination: destinations[i],
                selected: i == index,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.brand : p.inkSubtle;
    return Semantics(
      selected: selected,
      button: true,
      label: destination.label,
      child: InkResponse(
        onTap: onTap,
        radius: 36,
        highlightColor: Colors.transparent,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Motion.base,
                curve: Motion.emphasized,
                width: selected ? 56 : 40,
                height: 30,
                decoration: BoxDecoration(
                  color: selected ? p.brandSoft : Colors.transparent,
                  borderRadius: Radii.chip,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: Motion.quick,
                      child: Icon(
                        selected ? destination.activeIcon : destination.icon,
                        key: ValueKey(selected),
                        size: 22,
                        color: color,
                      ),
                    ),
                    if (destination.badge > 0)
                      Positioned(
                        top: 2,
                        right: selected ? 12 : 4,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: p.surface, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: Motion.quick,
                style: context.text.labelSmall!.copyWith(
                  color: color,
                  letterSpacing: 0,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(destination.label, maxLines: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.index,
    required this.onSelect,
    this.footer,
  });

  final List<ShellDestination> destinations;
  final int index;
  final ValueChanged<int> onSelect;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final extended = context.windowSize == WindowSize.expanded;
    return Container(
      width: extended ? 232 : 88,
      color: p.surface,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment:
              extended ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extended ? 20 : 0, 20, 0, 28),
              child: extended
                  ? const Wordmark(markSize: 36)
                  : const LogoMark(size: 40),
            ),
            for (var i = 0; i < destinations.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                child: _RailItem(
                  destination: destinations[i],
                  selected: i == index,
                  extended: extended,
                  onTap: () => onSelect(i),
                ),
              ),
            const Spacer(),
            if (footer != null)
              Padding(padding: const EdgeInsets.all(16), child: footer!),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  final ShellDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = selected ? p.brandStrong : p.inkMuted;
    final icon = Icon(
      selected ? destination.activeIcon : destination.icon,
      size: 22,
      color: color,
    );
    return Tooltip(
      message: extended ? '' : destination.label,
      child: Material(
        color: selected ? p.brandSoft : Colors.transparent,
        borderRadius: Radii.control,
        child: InkWell(
          onTap: onTap,
          borderRadius: Radii.control,
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: extended ? 14 : 0),
            alignment: extended ? Alignment.centerLeft : Alignment.center,
            child: extended
                ? Row(
                    children: [
                      icon,
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          destination.label,
                          style: context.text.titleSmall?.copyWith(
                            color: color,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      if (destination.badge > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: p.danger,
                            borderRadius: Radii.chip,
                          ),
                          child: Text(
                            '${destination.badge}',
                            style: context.text.labelSmall?.copyWith(
                              color: Colors.white,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                    ],
                  )
                : icon,
          ),
        ),
      ),
    );
  }
}
