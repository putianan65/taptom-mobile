import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taptom/core/widgets/widgets.dart';

Widget _wrap(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('StatusBadge shows its label', (tester) async {
    await tester.pumpWidget(_wrap(const StatusBadge(label: 'อนุมัติแล้ว', tone: Tone.success)));
    expect(find.text('อนุมัติแล้ว'), findsOneWidget);
  });

  testWidgets('AppButton fires once and blocks taps while loading', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(AppButton(label: 'บันทึก', onPressed: () => taps++)));
    await tester.tap(find.text('บันทึก'));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      _wrap(AppButton(label: 'บันทึก', loading: true, onPressed: () => taps++)),
    );
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('palette is available in both themes', (tester) async {
    late AppPalette light;
    late AppPalette dark;
    await tester.pumpWidget(_wrap(Builder(builder: (c) {
      light = c.palette;
      return const SizedBox();
    })));
    await tester.pumpWidget(_wrap(Builder(builder: (c) {
      dark = c.palette;
      return const SizedBox();
    }), theme: AppTheme.dark));
    await tester.pumpAndSettle();
    expect(light.background, isNot(dark.background));
  });

  testWidgets('mascot renders without animation when motion is reduced', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: _wrap(const FarmerMascot(size: 120, mood: MascotMood.wave)),
      ),
    );
    expect(find.byType(FarmerMascot), findsOneWidget);
  });

  testWidgets('AppShell builds tabs on first visit and hides the one left behind', (tester) async {
    final shell = GlobalKey<AppShellState>();
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: AppShell(
        key: shell,
        destinations: const [
          ShellDestination(label: 'หน้าแรก', icon: Icons.home, activeIcon: Icons.home, page: Text('page one')),
          ShellDestination(label: 'สมาชิก', icon: Icons.people, activeIcon: Icons.people, page: Text('page two')),
        ],
      ),
    ));
    expect(find.text('page two'), findsNothing);

    shell.currentState!.select(1);
    await tester.pumpAndSettle();
    shell.currentState!.select(0);
    await tester.pumpAndSettle();

    double opacityOf(String text) => tester
        .widget<FadeTransition>(find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first)
        .opacity
        .value;
    expect(opacityOf('page one'), 1);
    expect(opacityOf('page two'), 0);
  });
}
