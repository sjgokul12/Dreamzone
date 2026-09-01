import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BusInvoiceModel {
  final String invoiceNo;
  final String invoiceDate;
  final String pnr;
  final String bookingId;
  final String status;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String fromCity;
  final String toCity;
  final String journeyDate;
  final String boardingPoint;
  final String boardingTime;
  final String droppingPoint;
  final String droppingTime;
  final String operatorName;
  final String busType;
  final List<Map<String, dynamic>> passengers;
  final double baseFare;
  final double gstAmount;
  final double otherCharges;
  final double totalAmount;

  BusInvoiceModel({
    required this.invoiceNo,
    required this.invoiceDate,
    required this.pnr,
    required this.bookingId,
    this.status = 'Confirmed',
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.fromCity,
    required this.toCity,
    required this.journeyDate,
    required this.boardingPoint,
    required this.boardingTime,
    required this.droppingPoint,
    required this.droppingTime,
    this.operatorName = '',
    this.busType = '',
    required this.passengers,
    required this.baseFare,
    required this.gstAmount,
    required this.otherCharges,
    required this.totalAmount,
  });
}

class BusInvoicePdfService {
  static const PdfColor headerNavy = PdfColor.fromInt(0xFF003D99);
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFFEBF3FC);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFCCCCCC);
  static const PdfColor textColor = PdfColor.fromInt(0xFF222222);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF9FAFB);

  /// Generates the complete vector PDF Document matching 'Bus Bill.pdf'
  static Future<Uint8List> generateInvoicePdf(BusInvoiceModel invoice) async {
    final pdf = pw.Document();

    // Load Logo image from assets
    pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/dzi_logo.jpeg');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      try {
        final logoBytes = await rootBundle.load('assets/Round.png');
        logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
      } catch (_) {}
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. TOP HEADER BANNER
              pw.Container(
                color: headerNavy,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'TAX INVOICE',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 2. HEADER DETAILS ROW (Logo + Invoice Metadata)
              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 0.8),
                    right: pw.BorderSide(color: borderColor, width: 0.8),
                    bottom: pw.BorderSide(color: borderColor, width: 0.8),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Logo Box
                    pw.Expanded(
                      flex: 4,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        alignment: pw.Alignment.center,
                        child: logoImage != null
                            ? pw.Image(logoImage, height: 75, fit: pw.BoxFit.contain)
                            : pw.Text(
                                'DZI INFINITY',
                                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerNavy),
                              ),
                      ),
                    ),

                    // Middle Table: Invoice No, Date, Doc
                    pw.Expanded(
                      flex: 3,
                      child: pw.Container(
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            left: pw.BorderSide(color: borderColor, width: 0.8),
                            right: pw.BorderSide(color: borderColor, width: 0.8),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _buildMetaCell('Invoice No', invoice.invoiceNo),
                            _buildMetaCell('Invoice Date', invoice.invoiceDate),
                            _buildMetaCell('Document', 'Tax Invoice', isLast: true),
                          ],
                        ),
                      ),
                    ),

                    // Right Table: PNR, Booking ID, Status
                    pw.Expanded(
                      flex: 3,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _buildMetaCell('PNR', invoice.pnr),
                          _buildMetaCell('Booking ID', invoice.bookingId),
                          _buildMetaCell('Status', invoice.status, isLast: true, isStatus: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 3. BOOKING DETAILS SECTION
              pw.Container(
                color: headerNavy,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'BOOKING DETAILS',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    // Row 1: Customer, Email, Phone
                    pw.Row(
                      children: [
                        _buildGridCell('Customer', invoice.customerName, flex: 4),
                        _buildGridCell('Email', invoice.customerEmail, flex: 4),
                        _buildGridCell('Phone', invoice.customerPhone, flex: 3, isLastCol: true),
                      ],
                    ),
                    _buildDivider(),

                    // Row 2: From, To, Journey Date
                    pw.Row(
                      children: [
                        _buildGridCell('From', invoice.fromCity, flex: 4),
                        _buildGridCell('To', invoice.toCity, flex: 4),
                        _buildGridCell('Journey Date', invoice.journeyDate, flex: 3, isLastCol: true),
                      ],
                    ),
                    _buildDivider(),

                    // Row 3: Boarding, Boarding Time, Dropping Time
                    pw.Row(
                      children: [
                        _buildGridCell('Boarding', invoice.boardingPoint, flex: 4),
                        _buildGridCell('Boarding Time', invoice.boardingTime, flex: 4),
                        _buildGridCell('Dropping Time', invoice.droppingTime, flex: 3, isLastCol: true),
                      ],
                    ),
                    _buildDivider(),

                    // Row 4: Dropping Point
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Dropping Point', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                          pw.SizedBox(height: 2),
                          pw.Text(invoice.droppingPoint, style: const pw.TextStyle(fontSize: 8.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // 4. MERCHANT DETAILS SECTION (No change as requested)
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      color: tableHeaderBg,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: pw.Text(
                        'Merchant Details',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: headerNavy),
                      ),
                    ),
                    _buildMerchantRow('Retailer Name', 'SATISH K'),
                    _buildMerchantRow('Shop Name', 'DREAM ZONE CAFE'),
                    _buildMerchantRow('Mobile', '9986682688'),
                    _buildMerchantRow('Address', 'NO 79 5TH CROSS , BANGALORE , KARANATAKA - 560037', isLast: true),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // 5. PASSENGER DETAILS SECTION
              pw.Container(
                color: headerNavy,
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                alignment: pw.Alignment.center,
                child: pw.Text(
                  'PASSENGER DETAILS',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              pw.Container(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: borderColor, width: 0.8),
                    right: pw.BorderSide(color: borderColor, width: 0.8),
                    bottom: pw.BorderSide(color: borderColor, width: 0.8),
                  ),
                ),
                child: pw.Table(
                  border: const pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: borderColor, width: 0.8),
                    verticalInside: pw.BorderSide(color: borderColor, width: 0.8),
                  ),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(4),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(4),
                  },
                  children: [
                    // Table Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: tableHeaderBg),
                      children: [
                        _buildTableHeaderCell('Name'),
                        _buildTableHeaderCell('Seat'),
                        _buildTableHeaderCell('Details'),
                      ],
                    ),
                    // Table Rows
                    ...invoice.passengers.map((p) {
                      final title = p['title'] ?? (p['sex'] == 'F' ? 'Ms' : 'Mr');
                      final name = '$title ${p['name'] ?? ''} ${p['lastName'] ?? ''}'.trim();
                      final seatNbr = p['seatNbr']?.toString() ?? '-';
                      final gender = p['sex'] == 'F' ? 'F' : 'M';
                      final age = p['age']?.toString() ?? '-';
                      final berth = p['sleeper'] == true ? 'Sleeper' : 'Seater';

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: pw.Text(name, style: const pw.TextStyle(fontSize: 8.5)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: pw.Center(
                              child: pw.Text(seatNbr, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('Gender : $gender', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('Age : $age', style: const pw.TextStyle(fontSize: 8)),
                                pw.Text('Berth : $berth', style: const pw.TextStyle(fontSize: 8)),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // 6. BOTTOM SECTION (Payment Breakup & Terms side by side)
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column: Payment Breakup
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Container(
                            color: headerNavy,
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'Payment Breakup',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          _buildPaymentRow('Bus Fare', invoice.baseFare.toStringAsFixed(2)),
                          _buildPaymentRow('GST / Service Tax', invoice.gstAmount.toStringAsFixed(2)),
                          _buildPaymentRow('Other Charges', invoice.otherCharges.toStringAsFixed(2)),
                          pw.Container(
                            color: tableHeaderBg,
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text('Total', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                                pw.Text(invoice.totalAmount.toStringAsFixed(2), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  pw.SizedBox(width: 8),

                  // Right Column: Terms & Conditions
                  pw.Expanded(
                    flex: 5,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: borderColor, width: 0.8),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          pw.Container(
                            color: headerNavy,
                            padding: const pw.EdgeInsets.symmetric(vertical: 5),
                            alignment: pw.Alignment.center,
                            child: pw.Text(
                              'Terms and Conditions',
                              style: pw.TextStyle(color: PdfColors.white, fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _buildBulletPoint('The operator is not responsible for delays caused by traffic, weather, road conditions, government restrictions or unforeseen circumstances.'),
                                pw.SizedBox(height: 3),
                                _buildBulletPoint('Smoking, alcohol consumption and use of prohibited substances inside the bus are strictly prohibited.'),
                                pw.SizedBox(height: 3),
                                _buildBulletPoint('Please report at the boarding point at least 30 minutes before departure.'),
                                pw.SizedBox(height: 3),
                                _buildBulletPoint('Valid Government ID proof must be carried during travel.'),
                                pw.SizedBox(height: 3),
                                _buildBulletPoint('This is a computer-generated invoice. No signature is required.'),
                                pw.SizedBox(height: 8),
                                pw.Text('Bon voyage!', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: headerNavy)),
                                pw.Text('Stay safe and enjoy your trip.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --- Helper Widget Builders ---

  static pw.Widget _buildMetaCell(String title, String value, {bool isLast = false, bool isStatus = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: isLast ? null : const pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: tableHeaderBg,
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
            child: pw.Text(title, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: headerNavy)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2.5, horizontal: 6),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: isStatus ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isStatus ? PdfColors.green800 : textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGridCell(String title, String value, {required int flex, bool isLastCol = false}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: isLastCol ? null : const pw.Border(right: pw.BorderSide(color: borderColor, width: 0.8)),
        ),
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: headerNavy)),
            pw.SizedBox(height: 1.5),
            pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(height: 0.8, color: borderColor);
  }

  static pw.Widget _buildMerchantRow(String label, String value, {bool isLast = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: const pw.Border(top: pw.BorderSide(color: borderColor, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 110,
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(right: pw.BorderSide(color: borderColor, width: 0.8)),
            ),
            child: pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: textColor)),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Center(
        child: pw.Text(text, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: headerNavy)),
      ),
    );
  }

  static pw.Widget _buildPaymentRow(String label, String amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: borderColor, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(amount, style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  static pw.Widget _buildBulletPoint(String text) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('• ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        pw.Expanded(
          child: pw.Text(text, style: const pw.TextStyle(fontSize: 6.8, height: 1.15)),
        ),
      ],
    );
  }

  /// Saves the generated PDF locally and returns the File
  static Future<File> saveInvoiceLocally(BusInvoiceModel invoice) async {
    final bytes = await generateInvoicePdf(invoice);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Bus_Ticket_${invoice.pnr.isNotEmpty ? invoice.pnr : invoice.bookingId}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Share PDF invoice to WhatsApp with a pre-filled formatted message
  static Future<void> shareToWhatsApp(BusInvoiceModel invoice, {String? targetPhone}) async {
    try {
      final file = await saveInvoiceLocally(invoice);

      final message = '🚌 *Bus Ticket Booking Confirmation*\n\n'
          '📌 *Booking ID:* ${invoice.bookingId}\n'
          '🎫 *PNR:* ${invoice.pnr}\n'
          '👤 *Passenger:* ${invoice.customerName}\n'
          '📍 *Route:* ${invoice.fromCity} ➔ ${invoice.toCity}\n'
          '📅 *Journey Date:* ${invoice.journeyDate}\n'
          '⏰ *Boarding Time:* ${invoice.boardingTime}\n'
          '🚏 *Boarding Point:* ${invoice.boardingPoint}\n'
          '💵 *Total Fare:* ₹${invoice.totalAmount.toStringAsFixed(2)}\n\n'
          'Your tax invoice ticket is attached below. Have a pleasant and safe journey with DZI Infinity!';

      // Share file + text via system share (which can target WhatsApp directly)
      await Share.shareXFiles(
        [XFile(file.path, name: 'Bus_Ticket_${invoice.pnr}.pdf', mimeType: 'application/pdf')],
        text: message,
        subject: 'Bus Ticket Invoice - ${invoice.pnr}',
      );
    } catch (e) {
      // Fallback: open WhatsApp link directly
      final phone = (targetPhone ?? invoice.customerPhone).replaceAll(RegExp(r'[^0-9]'), '');
      final fullPhone = phone.length == 10 ? '91$phone' : phone;
      final text = Uri.encodeComponent(
        '🚌 *Bus Ticket Booking - ${invoice.pnr}*\n'
        'Booking ID: ${invoice.bookingId}\n'
        'Route: ${invoice.fromCity} to ${invoice.toCity}\n'
        'Date: ${invoice.journeyDate}\n'
        'Boarding: ${invoice.boardingPoint} (${invoice.boardingTime})\n'
        'Total: ₹${invoice.totalAmount.toStringAsFixed(2)}',
      );
      final uri = Uri.parse('https://wa.me/$fullPhone?text=$text');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Share PDF invoice via Email
  static Future<void> shareViaEmail(BusInvoiceModel invoice) async {
    try {
      final file = await saveInvoiceLocally(invoice);
      final subject = 'Bus Ticket Confirmation - PNR: ${invoice.pnr}';
      final body = 'Dear ${invoice.customerName},\n\n'
          'Thank you for booking your bus tickets with DZI Infinity.\n\n'
          'Booking Details:\n'
          '-----------------------------------------\n'
          'Booking ID: ${invoice.bookingId}\n'
          'PNR Number: ${invoice.pnr}\n'
          'From: ${invoice.fromCity}\n'
          'To: ${invoice.toCity}\n'
          'Journey Date: ${invoice.journeyDate}\n'
          'Boarding Point: ${invoice.boardingPoint}\n'
          'Boarding Time: ${invoice.boardingTime}\n'
          'Dropping Point: ${invoice.droppingPoint}\n'
          'Dropping Time: ${invoice.droppingTime}\n'
          'Total Fare: Rs. ${invoice.totalAmount.toStringAsFixed(2)}\n'
          '-----------------------------------------\n\n'
          'Your tax invoice ticket is attached with this email.\n\n'
          'Wishing you a safe and comfortable journey!\n\n'
          'Warm regards,\n'
          'Dream Zone Cafe / DZI Infinity Team';

      await Share.shareXFiles(
        [XFile(file.path, name: 'Bus_Ticket_${invoice.pnr}.pdf', mimeType: 'application/pdf')],
        text: body,
        subject: subject,
      );
    } catch (_) {
      final uri = Uri(
        scheme: 'mailto',
        path: invoice.customerEmail,
        queryParameters: {
          'subject': 'Bus Ticket Confirmation - PNR: ${invoice.pnr}',
          'body': 'Booking ID: ${invoice.bookingId}\nRoute: ${invoice.fromCity} to ${invoice.toCity}\nDate: ${invoice.journeyDate}\nBoarding: ${invoice.boardingPoint} (${invoice.boardingTime})',
        },
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
