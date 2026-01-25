import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

/// Service for generating financial reports as PDF
class ReportService {
  static final ReportService _instance = ReportService._internal();
  factory ReportService() => _instance;
  ReportService._internal();

  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  /// Generate monthly financial report PDF
  Future<Uint8List> generateMonthlyReport({
    required List<TransactionModel> transactions,
    required int month,
    required int year,
    required double totalBalance,
  }) async {
    final pdf = pw.Document();

    // Filter transactions for the selected month
    final monthlyTransactions = transactions.where((tx) {
      return tx.date.month == month && tx.date.year == year;
    }).toList();

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    final incomeByCategory = <String, double>{};
    final expenseByCategory = <String, double>{};

    for (final tx in monthlyTransactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
        incomeByCategory[tx.category] =
            (incomeByCategory[tx.category] ?? 0) + tx.amount;
      } else if (tx.isExpense) {
        totalExpense += tx.amount;
        expenseByCategory[tx.category] =
            (expenseByCategory[tx.category] ?? 0) + tx.amount;
      }
    }

    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header
          _buildHeader(monthNames[month - 1], year),
          pw.SizedBox(height: 20),

          // Summary Section
          _buildSummarySection(totalIncome, totalExpense, totalBalance),
          pw.SizedBox(height: 20),

          // Income by Category
          if (incomeByCategory.isNotEmpty) ...[
            _buildCategorySection(
              'Pemasukan per Kategori',
              incomeByCategory,
              PdfColors.green,
            ),
            pw.SizedBox(height: 15),
          ],

          // Expense by Category
          if (expenseByCategory.isNotEmpty) ...[
            _buildCategorySection(
              'Pengeluaran per Kategori',
              expenseByCategory,
              PdfColors.red,
            ),
            pw.SizedBox(height: 20),
          ],

          // Transaction List
          _buildTransactionTable(monthlyTransactions),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String monthName, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1a9b86'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'LAPORAN KEUANGAN',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Baitul Qowwam',
            style: pw.TextStyle(fontSize: 16, color: PdfColors.white),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Periode: $monthName $year',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.white),
          ),
          pw.Text(
            'Dicetak: ${_dateFormat.format(DateTime.now())}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(
    double income,
    double expense,
    double balance,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Ringkasan Keuangan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Total Pemasukan', income, PdfColors.green),
              _buildSummaryItem('Total Pengeluaran', expense, PdfColors.red),
              _buildSummaryItem(
                'Saldo Akhir',
                balance,
                PdfColor.fromHex('#1a9b86'),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Selisih Bulan Ini:'),
              pw.Text(
                _currencyFormat.format(income - expense),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: (income - expense) >= 0
                      ? PdfColors.green
                      : PdfColors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, double amount, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 3),
        pw.Text(
          _currencyFormat.format(amount),
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCategorySection(
    String title,
    Map<String, double> categories,
    PdfColor color,
  ) {
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...sortedCategories.map(
            (entry) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(entry.key),
                  pw.Text(
                    _currencyFormat.format(entry.value),
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransactionTable(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(20),
        child: pw.Center(
          child: pw.Text('Tidak ada transaksi pada periode ini'),
        ),
      );
    }

    // Sort by date descending
    final sortedTx = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daftar Transaksi',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(2.5),
            3: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _tableCell('Tanggal', isHeader: true),
                _tableCell('Kategori', isHeader: true),
                _tableCell('Keterangan', isHeader: true),
                _tableCell('Jumlah', isHeader: true),
              ],
            ),
            // Data rows
            ...sortedTx.map(
              (tx) => pw.TableRow(
                children: [
                  _tableCell(DateFormat('dd/MM').format(tx.date)),
                  _tableCell(tx.category),
                  _tableCell(tx.description),
                  _tableCell(
                    '${tx.isIncome ? '+' : '-'}${_currencyFormat.format(tx.amount)}',
                    color: tx.isIncome ? PdfColors.green : PdfColors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Total ${transactions.length} transaksi',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool isHeader = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'Halaman ${context.pageNumber} dari ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
      ),
    );
  }
}
