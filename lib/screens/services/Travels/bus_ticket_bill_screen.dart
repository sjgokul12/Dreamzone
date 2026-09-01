import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:open_filex/open_filex.dart';
import '../../../services/bus_invoice_pdf_service.dart';

class BusTicketBillScreen extends StatefulWidget {
  final BusInvoiceModel invoice;

  const BusTicketBillScreen({
    super.key,
    required this.invoice,
  });

  @override
  State<BusTicketBillScreen> createState() => _BusTicketBillScreenState();
}

class _BusTicketBillScreenState extends State<BusTicketBillScreen> with SingleTickerProviderStateMixin {
  bool _isSharing = false;
  Uint8List? _pdfBytes;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPdf();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    final bytes = await BusInvoicePdfService.generateInvoicePdf(widget.invoice);
    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
      });
    }
  }

  Future<void> _handleWhatsAppShare() async {
    setState(() => _isSharing = true);
    try {
      await BusInvoicePdfService.shareToWhatsApp(widget.invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share to WhatsApp: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleEmailShare() async {
    setState(() => _isSharing = true);
    try {
      await BusInvoicePdfService.shareViaEmail(widget.invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share via Email: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isSharing = true);
    try {
      final file = await BusInvoicePdfService.saveInvoiceLocally(widget.invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice saved: ${file.path.split('/').last}'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () => OpenFilex.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handlePrintPdf() async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async =>
            _pdfBytes ?? await BusInvoicePdfService.generateInvoicePdf(widget.invoice),
        name: 'Bus_Ticket_${widget.invoice.pnr}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        title: const Text(
          'Booking Confirmation & Bill',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Share to WhatsApp',
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
            onPressed: _handleWhatsAppShare,
          ),
          IconButton(
            tooltip: 'Share via Email',
            icon: const Icon(Icons.mail_outline_rounded, color: Color(0xFF3B82F6)),
            onPressed: _handleEmailShare,
          ),
          IconButton(
            tooltip: 'Download PDF',
            icon: const Icon(Icons.download_rounded, color: Color(0xFF8B5CF6)),
            onPressed: _handleDownloadPdf,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF003D99),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF003D99),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 20), text: 'Tax Invoice PDF'),
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'Ticket Details'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: PDF Viewer & Quick Actions
          _buildPdfPreviewTab(),

          // Tab 2: Mobile Card Summary
          _buildTicketDetailsTab(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(color: Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _isSharing ? null : _handleWhatsAppShare,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003D99),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text(
                    'Download PDF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: _isSharing ? null : _handleDownloadPdf,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreviewTab() {
    return Column(
      children: [
        // Quick Action Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                label: 'WhatsApp',
                icon: Icons.chat_rounded,
                color: const Color(0xFF25D366),
                onTap: _handleWhatsAppShare,
              ),
              _buildActionButton(
                label: 'Email',
                icon: Icons.mail_rounded,
                color: const Color(0xFF2563EB),
                onTap: _handleEmailShare,
              ),
              _buildActionButton(
                label: 'Download',
                icon: Icons.file_download_outlined,
                color: const Color(0xFF7C3AED),
                onTap: _handleDownloadPdf,
              ),
              _buildActionButton(
                label: 'Print',
                icon: Icons.print_rounded,
                color: const Color(0xFF0284C7),
                onTap: _handlePrintPdf,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Embedded PDF Preview
        Expanded(
          child: _pdfBytes == null
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF003D99)))
              : PdfPreview(
                  build: (format) => _pdfBytes!,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  canDebug: false,
                  dynamicLayout: false,
                  pdfFileName: 'Bus_Ticket_${widget.invoice.pnr}.pdf',
                  previewPageMargin: const EdgeInsets.all(12),
                  scrollViewDecoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketDetailsTab() {
    final inv = widget.invoice;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003D99), Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF003D99).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Booking Confirmed!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'PNR: ${inv.pnr}  |  Booking ID: ${inv.bookingId}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Journey Card
          _buildCard(
            title: 'Journey Details',
            icon: Icons.directions_bus_rounded,
            iconColor: const Color(0xFFEA580C),
            children: [
              _buildDetailRow('Route', '${inv.fromCity} ➔ ${inv.toCity}', isBold: true),
              _buildDetailRow('Journey Date', inv.journeyDate),
              _buildDetailRow('Boarding Point', inv.boardingPoint),
              _buildDetailRow('Boarding Time', inv.boardingTime),
              _buildDetailRow('Dropping Point', inv.droppingPoint),
              _buildDetailRow('Dropping Time', inv.droppingTime),
            ],
          ),
          const SizedBox(height: 16),

          // Passenger Details Card
          _buildCard(
            title: 'Passenger Details',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF8B5CF6),
            children: [
              ...inv.passengers.map((p) {
                final title = p['title'] ?? (p['sex'] == 'F' ? 'Ms' : 'Mr');
                final name = '$title ${p['name'] ?? ''} ${p['lastName'] ?? ''}'.trim();
                final seat = p['seatNbr']?.toString() ?? '-';
                final gender = p['sex'] == 'F' ? 'Female' : 'Male';
                final age = p['age']?.toString() ?? '-';

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003D99),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Seat $seat',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('$gender • $age yrs', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Summary Card
          _buildCard(
            title: 'Payment Breakup',
            icon: Icons.payment_rounded,
            iconColor: const Color(0xFF10B981),
            children: [
              _buildDetailRow('Bus Fare', '₹${inv.baseFare.toStringAsFixed(2)}'),
              _buildDetailRow('GST / Service Tax', '₹${inv.gstAmount.toStringAsFixed(2)}'),
              _buildDetailRow('Other Charges', '₹${inv.otherCharges.toStringAsFixed(2)}'),
              const Divider(height: 20),
              _buildDetailRow('Total Paid', '₹${inv.totalAmount.toStringAsFixed(2)}', isBold: true, isTotal: true),
            ],
          ),
          const SizedBox(height: 16),

          // Merchant Details Card
          _buildCard(
            title: 'Merchant Details',
            icon: Icons.storefront_rounded,
            iconColor: const Color(0xFF64748B),
            children: [
              _buildDetailRow('Retailer Name', 'SATISH K'),
              _buildDetailRow('Shop Name', 'DREAM ZONE CAFE'),
              _buildDetailRow('Mobile', '9986682688'),
              _buildDetailRow('Address', 'NO 79 5TH CROSS , BANGALORE , KARANATAKA - 560037'),
            ],
          ),
          const SizedBox(height: 24),

          // Back to Home Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E293B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home Screen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? const Color(0xFF003D99) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: isTotal ? 17 : 13,
                fontWeight: isBold || isTotal ? FontWeight.bold : FontWeight.w600,
                color: isTotal ? const Color(0xFF003D99) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
