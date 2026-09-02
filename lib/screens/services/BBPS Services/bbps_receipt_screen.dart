import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:open_filex/open_filex.dart';
import '../../../services/bbps_invoice_pdf_service.dart';

class BbpsReceiptScreen extends StatefulWidget {
  final BbpsReceiptModel receipt;

  const BbpsReceiptScreen({
    super.key,
    required this.receipt,
  });

  @override
  State<BbpsReceiptScreen> createState() => _BbpsReceiptScreenState();
}

class _BbpsReceiptScreenState extends State<BbpsReceiptScreen> with SingleTickerProviderStateMixin {
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF1E1B3A);
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF1E1B3A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color successGreen = Color(0xFF10B981);

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
    final bytes = await BbpsInvoicePdfService.generateReceiptPdf(widget.receipt);
    if (mounted) {
      setState(() {
        _pdfBytes = bytes;
      });
    }
  }

  Future<void> _handleWhatsAppShare() async {
    setState(() => _isSharing = true);
    try {
      await BbpsInvoicePdfService.shareToWhatsApp(widget.receipt);
    } catch (e) {
      if (mounted) {
        _snack('Failed to share to WhatsApp: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleEmailShare() async {
    setState(() => _isSharing = true);
    try {
      await BbpsInvoicePdfService.shareViaEmail(widget.receipt);
    } catch (e) {
      if (mounted) {
        _snack('Failed to share via Email: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isSharing = true);
    try {
      final file = await BbpsInvoicePdfService.saveReceiptLocally(widget.receipt);
      if (mounted) {
        _snack('Receipt saved to: ${file.path}');
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        _snack('Failed to save receipt: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FF),
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BBPS Bill Receipt',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              'Txn: ${widget.receipt.merchantTxnId}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'Receipt Details'),
            Tab(icon: Icon(Icons.picture_as_pdf_rounded, size: 20), text: 'PDF Invoice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(),
          _buildPdfPreviewTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // ── Status Banner ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 18,
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
                  child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Payment Successful',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${widget.receipt.amount.toStringAsFixed(2)} Paid Successfully',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Auto-Email Notification Banner ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.mark_email_read_rounded, color: Color(0xFF16A34A), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bill receipt copy has been automatically emailed to your registered email from satishurs.urs@gmail.com',
                    style: TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Receipt Data Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.receipt_rounded, color: primaryPurple, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Transaction Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDataRow('Service', widget.receipt.serviceCategory),
                _buildDataRow('Operator', widget.receipt.operatorName),
                _buildDataRow('Account / Consumer ID', widget.receipt.accountNumber),
                if (widget.receipt.customerName.isNotEmpty && widget.receipt.customerName != 'Consumer Account')
                  _buildDataRow('Customer Name', widget.receipt.customerName),
                _buildDataRow('Transaction ID', widget.receipt.merchantTxnId),
                _buildDataRow('Date & Time', widget.receipt.dateTimeStr),
                _buildDataRow('Status', widget.receipt.status, isSuccess: true),
                const Divider(height: 24),
                _buildDataRow(
                  'Total Amount',
                  '₹${widget.receipt.amount.toStringAsFixed(2)}',
                  isBold: true,
                  valueColor: primaryPurple,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Merchant Details Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.storefront_rounded, color: primaryPurple, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DREAM ZONE CAFE',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Merchant ID: Satish K (9886653886)',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                      Text(
                        'DreamZone India Private Limited',
                        style: TextStyle(fontSize: 11, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isBold = false, bool isSuccess = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 4,
            child: Text(label, style: const TextStyle(fontSize: 13, color: textMuted)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold || isSuccess ? FontWeight.bold : FontWeight.w600,
                color: isSuccess ? successGreen : valueColor ?? textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPreviewTab() {
    if (_pdfBytes == null) {
      return const Center(
        child: CircularProgressIndicator(color: primaryPurple),
      );
    }

    return PdfPreview(
      build: (format) => _pdfBytes!,
      allowPrinting: true,
      allowSharing: true,
      canChangeOrientation: false,
      canChangePageFormat: false,
      canDebug: false,
      pdfFileName: 'BBPS_Receipt_${widget.receipt.merchantTxnId}.pdf',
      loadingWidget: const Center(
        child: CircularProgressIndicator(color: primaryPurple),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // WhatsApp Share
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSharing ? null : _handleWhatsAppShare,
              icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 18),
              label: const Text('WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Email Share
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSharing ? null : _handleEmailShare,
              icon: const Icon(Icons.email_outlined, color: primaryPurple, size: 18),
              label: const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryPurple,
                side: const BorderSide(color: primaryPurple),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Download PDF Button
          Expanded(
            flex: 1,
            child: ElevatedButton.icon(
              onPressed: _isSharing ? null : _handleDownloadPdf,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
