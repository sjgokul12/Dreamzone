import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String defaultWhatsAppNumber = '9880885551';
  static const String senderEmail = 'satishurs.urs@gmail.com';

  /// Retrieves logged-in user profile from SharedPreferences
  static Future<Map<String, String>> getLoggedInUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      if (userStr != null && userStr.isNotEmpty) {
        final u = jsonDecode(userStr) as Map<String, dynamic>;
        return {
          'name': (u['name'] ?? u['customer_name'] ?? '').toString(),
          'email': (u['email'] ?? '').toString(),
          'mobile': (u['mobile'] ?? u['phone'] ?? '').toString(),
        };
      }
    } catch (_) {}
    return {'name': '', 'email': '', 'mobile': ''};
  }

  /// Generates the HTML template matching assets/BBPS.pdf
  static Future<String> generateHtmlBillTemplate(BbpsReceiptModel receipt) async {
    final userData = await getLoggedInUserData();
    final custName = receipt.customerName.isNotEmpty && receipt.customerName != 'Consumer Account'
        ? receipt.customerName
        : (userData['name']?.isNotEmpty == true ? userData['name']! : 'Valued Customer');
    final custPhone = receipt.customerPhone?.isNotEmpty == true
        ? receipt.customerPhone!
        : (userData['mobile']?.isNotEmpty == true ? userData['mobile']! : defaultWhatsAppNumber);

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>BBPS Bill Receipt - ${receipt.merchantTxnId}</title>
<style>
  body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    color: #1e293b;
    margin: 0;
    padding: 30px;
    background-color: #ffffff;
  }
  .receipt-container {
    max-width: 800px;
    margin: auto;
    border: 1px solid #cbd5e1;
    padding: 40px;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.05);
  }
  .header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    margin-bottom: 25px;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 20px;
  }
  .header h1 {
    font-size: 24px;
    margin: 0 0 6px 0;
    color: #0f172a;
    font-weight: 800;
  }
  .header p {
    margin: 0;
    font-size: 13px;
    color: #64748b;
  }
  .merchant-section {
    margin-bottom: 25px;
  }
  .section-title {
    font-size: 14px;
    font-weight: 700;
    color: #0d47a1;
    margin-bottom: 8px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  .merchant-name {
    font-size: 14px;
    font-weight: 700;
    color: #1e293b;
    margin: 0 0 4px 0;
  }
  .merchant-info {
    font-size: 13px;
    color: #475569;
    margin: 0;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 15px;
    margin-bottom: 30px;
  }
  th, td {
    border: 1px solid #cbd5e1;
    padding: 12px 14px;
    font-size: 12px;
    text-align: left;
  }
  th {
    background-color: #f1f5f9;
    font-weight: 700;
    color: #1e293b;
  }
  .status-badge {
    display: inline-block;
    padding: 4px 10px;
    border-radius: 6px;
    font-weight: 700;
    color: #15803d;
    background-color: #dcfce7;
  }
  .amount-col {
    text-align: right;
    font-weight: 700;
  }
  .notes {
    font-size: 12px;
    color: #64748b;
    line-height: 1.6;
    margin-top: 20px;
    padding-top: 15px;
    border-top: 1px dashed #cbd5e1;
  }
</style>
</head>
<body>
<div class="receipt-container">
  <div class="header">
    <div>
      <h1>Acknowledgement</h1>
      <p>Thank you for your transaction at DreamZone India Private Limited</p>
    </div>
  </div>

  <div class="merchant-section">
    <div class="section-title">Merchant Details</div>
    <div class="merchant-name">DREAM ZONE CAFE</div>
    <div class="merchant-info">Satish K &nbsp; | &nbsp; 9886653886</div>
  </div>

  <div class="merchant-section">
    <div class="section-title">Customer Details</div>
    <div class="merchant-info"><strong>Customer:</strong> $custName &nbsp; | &nbsp; <strong>Registered Mobile:</strong> $custPhone</div>
  </div>

  <table>
    <thead>
      <tr>
        <th>Time</th>
        <th>Service Details</th>
        <th>Account Number</th>
        <th>Txn ID</th>
        <th style="text-align:center;">Status</th>
        <th style="text-align:right;">Amt (₹)</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>${receipt.dateTimeStr}</td>
        <td><strong>${receipt.serviceCategory}</strong><br>${receipt.operatorName}</td>
        <td>${receipt.accountNumber}</td>
        <td>${receipt.merchantTxnId}</td>
        <td style="text-align:center;"><span class="status-badge">${receipt.status}</span></td>
        <td class="amount-col">₹${receipt.amount.toStringAsFixed(2)}</td>
      </tr>
    </tbody>
  </table>

  <div class="notes">
    <strong>Please Note:</strong><br>
    1. Customer Convenience Fee (CCF) = Rs. 0.00 inclusive of GST.<br>
    2. This is an official system generated BBPS acknowledgement receipt hence does not require any signature.<br>
    3. For support or queries, email <strong>$senderEmail</strong> or WhatsApp <strong>+91 $defaultWhatsAppNumber</strong>.
  </div>
</div>
</body>
</html>
''';
  }

  /// Generates vector PDF matching assets/BBPS.pdf
  static Future<Uint8List> generateReceiptPdf(BbpsReceiptModel receipt) async {
    final pdf = pw.Document();

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

    final userData = await getLoggedInUserData();
    final custName = receipt.customerName.isNotEmpty && receipt.customerName != 'Consumer Account'
        ? receipt.customerName
        : (userData['name']?.isNotEmpty == true ? userData['name']! : 'Valued Customer');
    final custPhone = receipt.customerPhone?.isNotEmpty == true
        ? receipt.customerPhone!
        : (userData['mobile']?.isNotEmpty == true ? userData['mobile']! : defaultWhatsAppNumber);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Acknowledgement', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: textDark)),
                      pw.Text('Thank you for transaction at DreamZone India Private Limited', style: pw.TextStyle(fontSize: 11, color: textMuted)),
                    ],
                  ),
                  pw.Row(children: [
                    if (logoImage != null) pw.Container(width: 50, height: 50, child: pw.Image(logoImage, fit: pw.BoxFit.contain)),
                    if (bbpsLogo != null) ...[pw.SizedBox(width: 8), pw.Container(width: 60, height: 40, child: pw.Image(bbpsLogo, fit: pw.BoxFit.contain)),]
                  ]),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 14),

              pw.Text('Merchant Details', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
              pw.SizedBox(height: 6),
              pw.Text('DREAM ZONE CAFE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textDark)),
              pw.Text('Satish K   9886653886', style: pw.TextStyle(fontSize: 11, color: textDark)),
              pw.SizedBox(height: 18),

              pw.Text('Customer Details', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: primaryBlue)),
              pw.SizedBox(height: 4),
              pw.Text('Customer: $custName   |   Mobile: $custPhone', style: pw.TextStyle(fontSize: 10.5, color: textDark)),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2), 1: const pw.FlexColumnWidth(4.0),
                  2: const pw.FlexColumnWidth(2.6), 3: const pw.FlexColumnWidth(3.4),
                  4: const pw.FlexColumnWidth(1.8), 5: const pw.FlexColumnWidth(2.0),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _buildTableCell('Time', isHeader: true), _buildTableCell('Service Details', isHeader: true),
                      _buildTableCell('Account\nNumber', isHeader: true), _buildTableCell('Txn ID', isHeader: true),
                      _buildTableCell('Status', isHeader: true, align: pw.TextAlign.center),
                      _buildTableCell('Amt', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _buildTableCell(receipt.dateTimeStr),
                      _buildTableCell('${receipt.serviceCategory}\n${receipt.operatorName}'),
                      _buildTableCell(receipt.accountNumber),
                      _buildTableCell(receipt.merchantTxnId, isBold: true),
                      _buildTableCell(receipt.status, isBold: true, textColor: successGreen, align: pw.TextAlign.center),
                      _buildTableCell(receipt.amount.toStringAsFixed(2), isBold: true, align: pw.TextAlign.right),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 25),

              pw.Text('Please Note:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: textDark)),
              pw.SizedBox(height: 6),
              pw.Text('1. Customer Convenience Fee (CCF) = Rs. 0.00 inclusive of GST.', style: pw.TextStyle(fontSize: 9.5, color: textMuted)),
              pw.SizedBox(height: 3),
              pw.Text('2. This is an official system generated receipt hence does not require any signature.', style: pw.TextStyle(fontSize: 9.5, color: textMuted)),
              pw.SizedBox(height: 3),
              pw.Text('3. For assistance, write to $senderEmail or WhatsApp +91 $defaultWhatsAppNumber', style: pw.TextStyle(fontSize: 9.5, color: textMuted)),
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
      alignment: align == pw.TextAlign.center ? pw.Alignment.center : align == pw.TextAlign.right ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
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
    final userData = await getLoggedInUserData();
    final userMobile = userData['mobile']?.trim() ?? '';
    final rawPhone = targetPhone ?? (userMobile.isNotEmpty ? userMobile : (receipt.customerPhone ?? defaultWhatsAppNumber));
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
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
  static Future<void> shareViaEmail(BbpsReceiptModel receipt, {String? targetEmail}) async {
    final userData = await getLoggedInUserData();
    final userEmail = userData['email']?.trim() ?? '';
    final destEmail = targetEmail ?? (userEmail.isNotEmpty ? userEmail : (receipt.customerEmail ?? senderEmail));

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
        path: destEmail,
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
