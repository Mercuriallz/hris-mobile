import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hris_mobile/constant/theme/app_color.dart';
import 'package:hris_mobile/constant/theme/app_widget.dart';
import 'package:hris_mobile/features/salary_slip/model/salary_slip_model.dart';
import 'package:hris_mobile/features/salary_slip/presentation/salary_slip_widgets.dart';
import 'package:hris_mobile/features/warning_letter/model/warning_letter_model.dart';
import 'package:hris_mobile/features/warning_letter/presentation/warning_letter_widgets.dart';

import '../helpers/test_env.dart';

Widget _list(List<Widget> children) => Scaffold(
      body: ListView(padding: const EdgeInsets.all(16), children: children),
    );

WarningLetter _letter(String level, String status, {bool unread = true, String violation = 'Terlambat'}) =>
    WarningLetter.fromJson({
      'id': '$level-$status',
      'level': level,
      'status': status,
      'issuedDate': '2026-10-01',
      'expiresDate': '2027-04-01',
      'violation': violation,
      'viewedAt': unread ? null : '2026-10-02',
    });

void main() {
  setUpAll(() async {
    await setUpTestEnv();
    await loadApproximateFonts();
  });

  for (final brightness in Brightness.values) {
    group('mode ${brightness.name}', () {
      testWidgets('StatusBadge memakai warna tone dari palet aktif', (tester) async {
        await tester.pumpWidget(wrapApp(
          _list([
            for (final t in StatusTone.values) StatusBadge(label: t.name, tone: t, icon: Icons.check),
          ]),
          brightness: brightness,
        ));
        final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
        Color bgOf(String label) {
          final c = tester.widget<Container>(
            find.ancestor(of: find.text(label), matching: find.byType(Container)).first,
          );
          return (c.decoration as BoxDecoration).color!;
        }

        expect(bgOf('success'), p.successSurface);
        expect(bgOf('warning'), p.warningSurface);
        expect(bgOf('danger'), p.dangerSurface);
        expect(bgOf('info'), p.infoSurface);
        expect(bgOf('neutral'), p.background);
        expect(tester.widget<Text>(find.text('danger')).style!.color, p.danger);
      });

      testWidgets('EmptyState & ErrorState', (tester) async {
        var retried = 0;
        useSmallPhone(tester);
        await tester.pumpWidget(wrapApp(
          Scaffold(
            body: Column(children: [
              const Expanded(
                child: EmptyState(icon: Icons.inbox, title: 'Kosong', message: 'Belum ada data.'),
              ),
              Expanded(child: ErrorState(message: 'Gagal', onRetry: () => retried++)),
            ]),
          ),
          brightness: brightness,
        ));
        expect(find.text('Kosong'), findsOneWidget);
        expect(find.text('Gagal memuat'), findsOneWidget);
        await tester.tap(find.text('Coba Lagi'));
        expect(retried, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('SalarySlipCard: nominal disembunyikan / ditampilkan, 360px tanpa overflow', (tester) async {
        useSmallPhone(tester);
        const slip = SalarySlip(
          id: 's',
          month: '2026-09',
          startDate: '2026-09-01',
          endDate: '2026-09-30',
          netPay: 125750000,
        );
        var taps = 0;
        await tester.pumpWidget(wrapApp(
          _list([
            SalarySlipCard(slip: slip, showAmount: false, onTap: () => taps++),
            SalarySlipCard(slip: slip, showAmount: true, onTap: () {}),
          ]),
          brightness: brightness,
        ));
        expect(find.text('September 2026'), findsNWidgets(2));
        expect(find.text(kHiddenAmount), findsOneWidget);
        expect(find.text('Rp 125.750.000'), findsOneWidget);
        expect(find.text('1 Sep 2026 – 30 Sep 2026'), findsNWidgets(2));
        await tester.tap(find.text(kHiddenAmount));
        expect(taps, 1);
        expect(tester.takeException(), isNull);
      });

      testWidgets('WarningLetterCard: semua tingkat x status di 360px tanpa overflow', (tester) async {
        useSmallPhone(tester);
        final errors = await collectFlutterErrors(() async {
          await tester.pumpWidget(wrapApp(
            _list([
              for (final level in kWarningLevelLabels.keys)
                for (final status in kWarningStatusLabels.keys)
                  WarningLetterCard(letter: _letter(level, status), onTap: () {}),
            ]),
            brightness: brightness,
          ));
          await tester.pump();
        });
        expect(errors, isEmpty);
        expect(find.text('Baru'), findsWidgets);
      });

      testWidgets('WarningLetterCard SP3: teks "Evaluasi", surat lama diredupkan', (tester) async {
        await tester.pumpWidget(wrapApp(
          _list([
            WarningLetterCard(letter: _letter('sp3', 'evaluation_due'), onTap: () {}),
            WarningLetterCard(letter: _letter('sp1', 'expired', unread: false), onTap: () {}),
          ]),
          brightness: brightness,
        ));
        expect(find.text('Evaluasi 1 Okt 2026 – 1 Apr 2027'), findsOneWidget);
        expect(find.text('Berlaku 1 Okt 2026 – 1 Apr 2027'), findsOneWidget);
        final dimmed = tester.widget<Text>(find.text('Terlambat').last);
        expect(dimmed.style!.color, AppColor.textSecondary);
        expect(find.text('Baru'), findsOneWidget);
      });
    });
  }

  testWidgets('WarningLetterCard SP3 + Baru + "Menunggu hasil evaluasi" di 360px, teks 130%', (tester) async {
    useSmallPhone(tester, textScale: 1.3);
    final errors = await collectFlutterErrors(() async {
      await tester.pumpWidget(wrapApp(_list([
        WarningLetterCard(letter: _letter('verbal', 'evaluation_due'), onTap: () {}),
      ])));
      await tester.pump();
    });
    expect(errors, isEmpty);
  });
}
