import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/utils/date_helpers.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/daily_record.dart';
import '../../domain/entities/dhikr_category.dart';

/// Generates CSV / PDF exports and shares them via the platform share sheet.
class ExportService {
  const ExportService();

  /// Builds a CSV file of daily records and opens the share sheet.
  Future<void> exportCsv({
    required List<DailyRecord> records,
    required List<DhikrCategory> categories,
  }) async {
    final nameById = {for (final c in categories) c.id: c.name};

    final rows = <List<dynamic>>[
      ['Date', 'Category', 'Count'],
      ...records.map((r) => [
            DateHelpers.dayKey(r.date),
            nameById[r.categoryId] ?? r.categoryId,
            r.count,
          ]),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final file = await _writeTempFile('dhikr_export.csv', csv);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'DhikrFlow export',
      text: 'My dhikr records',
    );
  }

  /// Builds a formatted PDF report and opens the share sheet.
  Future<void> exportPdf({
    required List<DailyRecord> records,
    required List<DhikrCategory> categories,
    required DateTime start,
    required DateTime end,
  }) async {
    final nameById = {for (final c in categories) c.id: c.name};

    // Totals per category and per day.
    final byCategory = <String, int>{};
    final byDay = <String, int>{};
    var grandTotal = 0;
    for (final r in records) {
      byCategory[r.categoryId] = (byCategory[r.categoryId] ?? 0) + r.count;
      byDay[DateHelpers.dayKey(r.date)] =
          (byDay[DateHelpers.dayKey(r.date)] ?? 0) + r.count;
      grandTotal += r.count;
    }

    final doc = pw.Document();
    final accent = PdfColor.fromInt(0xFF1F6E5E);

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DhikrFlow Report',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${DateHelpers.readable(start)}  —  ${DateHelpers.readable(end)}',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.Divider(color: PdfColors.grey400),
            ],
          ),
        ),
        build: (context) => [
          pw.Text('Summary',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text('Total dhikr counted: ${Formatters.number(grandTotal)}'),
          pw.Text('Active days: ${byDay.values.where((v) => v > 0).length}'),
          pw.SizedBox(height: 20),
          pw.Text('By category',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: accent),
            headerStyle: pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            cellAlignments: {1: pw.Alignment.centerRight},
            headers: ['Category', 'Total'],
            data: byCategory.entries
                .map((e) => [
                      nameById[e.key] ?? e.key,
                      Formatters.number(e.value),
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Daily breakdown',
              style:
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerDecoration: pw.BoxDecoration(color: accent),
            headerStyle: pw.TextStyle(
                color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            cellAlignments: {1: pw.Alignment.centerRight},
            headers: ['Date', 'Count'],
            data: (byDay.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                .map((e) => [e.key, Formatters.number(e.value)])
                .toList(),
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
      ),
    );

    final bytes = await doc.save();
    final file = await _writeTempBytes('dhikr_report.pdf', bytes);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'DhikrFlow report',
    );
  }

  Future<File> _writeTempFile(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    return file.writeAsString(content);
  }

  Future<File> _writeTempBytes(String name, List<int> bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, name));
    return file.writeAsBytes(bytes);
  }
}
