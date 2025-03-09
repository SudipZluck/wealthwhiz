import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../utils/currency_formatter.dart';

class PdfExportUtil {
  static Future<void> exportTransactionsToPdf(
    List<Transaction> transactions,
    User user,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Group transactions by type
    final incomeTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final expenseTransactions = transactions
        .where((t) => t.type == TransactionType.expense)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    final totalIncome = incomeTransactions.fold<double>(
        0, (sum, transaction) => sum + transaction.amount);

    final totalExpenses = expenseTransactions.fold<double>(
        0, (sum, transaction) => sum + transaction.amount);

    final balance = totalIncome - totalExpenses;

    // Group expenses by category
    final Map<TransactionCategory, double> expensesByCategory = {};
    for (var transaction in expenseTransactions) {
      expensesByCategory[transaction.category] =
          (expensesByCategory[transaction.category] ?? 0) + transaction.amount;
    }

    // Sort categories by amount (descending)
    final sortedCategories = expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          context,
          font,
          boldFont,
          startDate,
          endDate,
          user.preferredCurrency,
        ),
        footer: (context) => _buildFooter(context, font),
        build: (context) => [
          // Summary section
          _buildSummarySection(
            boldFont,
            font,
            totalIncome,
            totalExpenses,
            balance,
            user.preferredCurrency,
          ),
          pw.SizedBox(height: 20),

          // Expenses by category
          _buildCategoryBreakdown(
            boldFont,
            font,
            sortedCategories,
            totalExpenses,
            user.preferredCurrency,
          ),
          pw.SizedBox(height: 20),

          // Income transactions
          _buildTransactionList(
            boldFont,
            font,
            'Income Transactions',
            incomeTransactions,
            user.preferredCurrency,
          ),
          pw.SizedBox(height: 20),

          // Expense transactions
          _buildTransactionList(
            boldFont,
            font,
            'Expense Transactions',
            expenseTransactions,
            user.preferredCurrency,
          ),
        ],
      ),
    );

    // Save and open the PDF
    await _savePdfAndOpen(pdf);
  }

  static pw.Widget _buildHeader(
    pw.Context context,
    pw.Font font,
    pw.Font boldFont,
    DateTime startDate,
    DateTime endDate,
    Currency currency,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'WealthWhiz Financial Report',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 20,
                color: PdfColors.blue900,
              ),
            ),
            pw.Text(
              'Generated: ${dateFormat.format(DateTime.now())}',
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Period: ${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
          style: pw.TextStyle(
            font: font,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Divider(color: PdfColors.grey400),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context, pw.Font font) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'WealthWhiz - Your Financial Partner',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(
    pw.Font boldFont,
    pw.Font regularFont,
    double totalIncome,
    double totalExpenses,
    double balance,
    Currency currency,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Financial Summary',
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 16,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildSummaryItem(
                boldFont,
                regularFont,
                'Total Income',
                totalIncome,
                PdfColors.green700,
                currency,
              ),
              _buildSummaryItem(
                boldFont,
                regularFont,
                'Total Expenses',
                totalExpenses,
                PdfColors.red700,
                currency,
              ),
              _buildSummaryItem(
                boldFont,
                regularFont,
                'Balance',
                balance,
                balance >= 0 ? PdfColors.blue700 : PdfColors.red700,
                currency,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Expanded _buildSummaryItem(
    pw.Font boldFont,
    pw.Font regularFont,
    String title,
    double amount,
    PdfColor color,
    Currency currency,
  ) {
    final formattedAmount = CurrencyFormatter.format(amount, currency);

    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: regularFont,
              fontSize: 12,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            formattedAmount,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCategoryBreakdown(
    pw.Font boldFont,
    pw.Font regularFont,
    List<MapEntry<TransactionCategory, double>> categories,
    double totalExpenses,
    Currency currency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Expense Breakdown by Category',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Category', boldFont, isHeader: true),
                _buildTableCell('Amount', boldFont, isHeader: true),
                _buildTableCell('Percentage', boldFont, isHeader: true),
              ],
            ),
            ...categories.map((entry) {
              final percentage =
                  totalExpenses > 0 ? (entry.value / totalExpenses * 100) : 0.0;
              return pw.TableRow(
                children: [
                  _buildTableCell(
                    _formatCategoryName(entry.key.toString()),
                    regularFont,
                  ),
                  _buildTableCell(
                    CurrencyFormatter.format(entry.value, currency),
                    regularFont,
                  ),
                  _buildTableCell(
                    '${percentage.toStringAsFixed(1)}%',
                    regularFont,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTransactionList(
    pw.Font boldFont,
    pw.Font regularFont,
    String title,
    List<Transaction> transactions,
    Currency currency,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 16,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        transactions.isEmpty
            ? pw.Text(
                'No transactions in this period',
                style: pw.TextStyle(
                  font: regularFont,
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              )
            : pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('Date', boldFont, isHeader: true),
                      _buildTableCell('Description', boldFont, isHeader: true),
                      _buildTableCell('Category', boldFont, isHeader: true),
                      _buildTableCell('Amount', boldFont, isHeader: true),
                    ],
                  ),
                  ...transactions.map((transaction) {
                    final dateFormat = DateFormat('MM/dd/yyyy');
                    return pw.TableRow(
                      children: [
                        _buildTableCell(
                          dateFormat.format(transaction.date),
                          regularFont,
                        ),
                        _buildTableCell(
                          transaction.description,
                          regularFont,
                        ),
                        _buildTableCell(
                          _formatCategoryName(transaction.category.toString()),
                          regularFont,
                        ),
                        _buildTableCell(
                          CurrencyFormatter.format(
                              transaction.amount, currency),
                          regularFont,
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
      ],
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _formatCategoryName(String category) {
    final name = category.split('.').last;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  static Future<void> _savePdfAndOpen(pw.Document pdf) async {
    try {
      // Generate a unique filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'wealthwhiz_report_$timestamp.pdf';

      // Get the temporary directory
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$filename');

      // Save the PDF
      await file.writeAsBytes(await pdf.save());

      // Open the PDF for viewing/printing/sharing
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: filename,
      );
    } catch (e) {
      print('Error saving or opening PDF: $e');
      rethrow;
    }
  }
}
