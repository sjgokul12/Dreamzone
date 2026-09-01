import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BbpsReceiptModel {
  final String serviceCategory; // e.g. 'Water', 'Electricity', 'FASTag', 'Landline', etc.
  final String operatorName;    // e.g. 'Bangalore Supply And Sewerage Board', 'BESCOM', etc.
  final String accountNumber;   // e.g. 'E-344132', '1800906050', 'KA05ML5476'
  final String customerName;    // e.g. 'C RAJAGOPAL', 'SADANANDAIAH N C', etc.
  final String merchantTxnId;   // e.g. 'S2605251035569268D4C0' or 'WAT1725166800'
  final String dateTimeStr;     // e.g. '25-May-2026 10:36:01' or current timestamp
  final double amount;          // e.g. 4431.00
  final String status;          // 'Success'
  final String? customerPhone;
  final String? customerEmail;
  final String? billNumber;
  final String? dueDate;
  final String? billPeriod;
  final String? refId;

  BbpsReceiptModel({
    required this.serviceCategory,
    required this.operatorName,
    required this.accountNumber,
    required this.customerName,
    required this.merchantTxnId,
    required this.dateTimeStr,
    required this.amount,
    this.status = 'Success',
    this.customerPhone,
    this.customerEmail,
    this.billNumber,
    this.dueDate,
    this.billPeriod,
    this.refId,
  });
}

class BbpsInvoicePdfService {
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF0D47A1);
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor successGreen = PdfColor.fromInt(0xFF16A34A);

  /// Generates vector PDF matching assets/BBPS.pdf with the 3 notes removed
  static Future<Uint8List> generateReceiptPdf(BbpsReceiptModel receipt) async {
    final pdf = pw.Document();

    // Try loading logo from assets
    pw.ImageProvider? logoImage;
    pw.ImageProvider? bbpsLogo;
    try {
      final logoBytes = await rootBundle.load('assets/dzi_logo.jpeg');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      try {
        final logoBytes = await rootBundle.load('assets/Round.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }

    try {
      final bbpsBytes = await rootBundle.load('assets/Bharat BillPay.png');
      bbpsLogo = pw.MemoryImage(bbpsBytes.buffer.asUint8List());
    } catch (_) {}

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ── Header Section ──
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Acknowledgement',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Thank you for transaction at DreamZone India Private Limited',
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 50,
                          height: 50,
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        ),
                      if (bbpsLogo != null) ...[
                        pw.SizedBox(width: 8),
                        pw.Container(
                          width: 60,
                          height: 40,
                          child: pw.Image(bbpsLogo, fit: pw.BoxFit.contain),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 14),

              // ── Merchant Details ──
              pw.Text(
                'Merchant Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Text(
                'DREAM ZONE CAFE',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Satish K   9886653886',
                style: pw.TextStyle(
                  fontSize: 11,
                  color: textDark,
                ),
              ),
              pw.SizedBox(height: 18),

              // ── Customer & Transaction Details ──
              pw.Text(
                'Customer Details',
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              pw.SizedBox(height: 8),

              // ── Receipt Table ──
              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2), // Time / Date
                  1: const pw.FlexColumnWidth(4.0), // Service Details
                  2: const pw.FlexColumnWidth(2.6), // Account Number
                  3: const pw.FlexColumnWidth(3.4), // Txn ID
                  4: const pw.FlexColumnWidth(1.8), // Status
                  5: const pw.FlexColumnWidth(2.0), // Amount
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _buildTableCell('Time', isHeader: true),
                      _buildTableCell('Service Details', isHeader: true),
                      _buildTableCell('Account\nNumber', isHeader: true),
                      _buildTableCell('Txn ID', isHeader: true),
                      _buildTableCell('Status', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Amt', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Row
                  pw.TableRow(
                    children: [
                      _buildTableCell(receipt.dateTimeStr),
                      _buildTableCell(
                        '${receipt.serviceCategory}\n${receipt.operatorName}${receipt.customerName.isNotEmpty && receipt.customerName != 'Consumer Account' ? '\nCustomer: ${receipt.customerName}' : ''}',
                      ),
                      _buildTableCell(receipt.accountNumber),
                      _buildTableCell(receipt.merchantTxnId),
                      _buildTableCell(
                        receipt.status,
                        textColor: successGreen,
                        isBold: true,
                        align: pw.TextAlign.center,
                      ),
                      _buildTableCell(
                        receipt.amount.toStringAsFixed(2),
                        isBold: true,
                        align: pw.TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ── Summary Box ──
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: tableHeaderBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total Amount Paid:',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: textDark,
                      ),
                    ),
                    pw.Text(
                      'Rs. ${receipt.amount.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              // NOTE: The 3 requested points are completely removed as requested!
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    PdfColor? textColor,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      alignment: align == pw.TextAlign.center
          ? pw.Alignment.center
          : align == pw.TextAlign.right
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9.5,
          fontWeight: isHeader || isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor ?? (isHeader ? textDark : textDark),
        ),
      ),
    );
  }

  static const String defaultWhatsAppNumber = '9880885551';
  static const String senderEmail = 'dreamzone.infinity@gmail.com';

  /// Saves the receipt PDF locally on device storage
  static Future<File> saveReceiptLocally(BbpsReceiptModel receipt) async {
    final pdfBytes = await generateReceiptPdf(receipt);
    final dir = await getApplicationDocumentsDirectory();
    final cleanTxn = receipt.merchantTxnId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/BBPS_Receipt_$cleanTxn.pdf');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }

  /// Print or open standard print dialog
  static Future<void> printReceipt(BbpsReceiptModel receipt) async {
    final pdfBytes = await generateReceiptPdf(receipt);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'BBPS_Receipt_${receipt.merchantTxnId}',
    );
  }

  /// Share to WhatsApp
  static Future<void> shareToWhatsApp(BbpsReceiptModel receipt, {String? targetPhone}) async {
    final phone = (targetPhone ?? receipt.customerPhone ?? defaultWhatsAppNumber).replaceAll(RegExp(r'[^0-9]'), '');
    final fullPhone = phone.length == 10 ? '91$phone' : phone;

    try {
      final file = await saveReceiptLocally(receipt);
      final message = '🧾 *BBPS Bill Payment Receipt*\n\n'
          '🔹 *Service:* ${receipt.serviceCategory}\n'
          '🏢 *Operator:* ${receipt.operatorName}\n'
          '🆔 *Account / ID:* ${receipt.accountNumber}\n'
          '👤 *Customer:* ${receipt.customerName}\n'
          '🔢 *Txn ID:* ${receipt.merchantTxnId}\n'
          '📅 *Date & Time:* ${receipt.dateTimeStr}\n'
          '💵 *Amount Paid:* ₹${receipt.amount.toStringAsFixed(2)}\n'
          '✅ *Status:* ${receipt.status}\n\n'
          'Thank you for your transaction at DreamZone India Private Limited.\n'
          'Support: $senderEmail | +91 $defaultWhatsAppNumber';

      await Share.shareXFiles(
        [XFile(file.path, name: 'BBPS_Receipt_${receipt.merchantTxnId}.pdf', mimeType: 'application/pdf')],
        text: message,
        subject: 'BBPS Receipt - ${receipt.merchantTxnId}',
      );
    } catch (_) {
      final text = Uri.encodeComponent(
        '🧾 *BBPS Bill Payment - ${receipt.merchantTxnId}*\n'
        'Service: ${receipt.serviceCategory}\n'
        'Operator: ${receipt.operatorName}\n'
        'Account: ${receipt.accountNumber}\n'
        'Amount: ₹${receipt.amount.toStringAsFixed(2)}\n'
        'Status: ${receipt.status}\n'
        'Contact: $senderEmail',
      );
      final uri = Uri.parse('https://wa.me/$fullPhone?text=$text');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Share via Email
  static Future<void> shareViaEmail(BbpsReceiptModel receipt) async {
    try {
      final file = await saveReceiptLocally(receipt);
      final subject = 'BBPS Bill Payment Receipt - ${receipt.merchantTxnId}';
      final body = 'Dear Customer,\n\n'
          'Thank you for completing your transaction at DreamZone India Private Limited.\n\n'
          'Receipt Details:\n'
          '-----------------------------------------\n'
          'Service: ${receipt.serviceCategory}\n'
          'Operator: ${receipt.operatorName}\n'
          'Account / ID: ${receipt.accountNumber}\n'
          'Customer Name: ${receipt.customerName}\n'
          'Transaction ID: ${receipt.merchantTxnId}\n'
          'Date & Time: ${receipt.dateTimeStr}\n'
          'Amount Paid: Rs. ${receipt.amount.toStringAsFixed(2)}\n'
          'Status: ${receipt.status}\n'
          '-----------------------------------------\n\n'
          'Your official BBPS acknowledgement receipt is attached with this email.\n\n'
          'Warm regards,\n'
          'Dream Zone Infinity Team\n'
          'Email: $senderEmail\n'
          'WhatsApp: +91 $defaultWhatsAppNumber';

      await Share.shareXFiles(
        [XFile(file.path, name: 'BBPS_Receipt_${receipt.merchantTxnId}.pdf', mimeType: 'application/pdf')],
        text: body,
        subject: subject,
      );
    } catch (_) {
      final uri = Uri(
        scheme: 'mailto',
        path: receipt.customerEmail ?? senderEmail,
        queryParameters: {
          'subject': 'BBPS Receipt - ${receipt.merchantTxnId}',
          'body': 'Transaction ID: ${receipt.merchantTxnId}\nService: ${receipt.serviceCategory}\nAccount: ${receipt.accountNumber}\nAmount: Rs. ${receipt.amount.toStringAsFixed(2)}\nSender: $senderEmail',
        },
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
