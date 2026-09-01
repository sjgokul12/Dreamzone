import 'package:flutter/material.dart';
import '../services/bbps_api_service.dart';

class BbpsFetchedBillCard extends StatelessWidget {
  final BbpsBillDetails? bill;
  final bool isFetching;
  final VoidCallback onFetchBill;
  final Color primaryColor;

  const BbpsFetchedBillCard({
    super.key,
    required this.bill,
    required this.isFetching,
    required this.onFetchBill,
    this.primaryColor = const Color(0xFF8B5CF6),
  });

  @override
  Widget build(BuildContext context) {
    if (isFetching) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Fetching Live Bill Details from BBPS...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connecting with the official operator server',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (bill == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        child: Material(
          color: primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onFetchBill,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withValues(alpha: 0.8), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Get Bill / Fetch Bill Details',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF003D99),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BBPS',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // When Fetch Bill Failed or Notice
    if (!bill!.isSuccess && bill!.dueAmount <= 0) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline_rounded, color: Color(0xFFE11D48), size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Bill Fetch Status',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF9F1239)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              bill!.message,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF881337), fontWeight: FontWeight.w600, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                    ),
                  ),
                  onPressed: onFetchBill,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFE11D48)),
                  label: const Text(
                    'Retry Fetch',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFFE11D48)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // When Bill is Fetched Successfully
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Bill Details Fetched',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              // Refresh / Re-fetch button
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                tooltip: 'Re-fetch Bill',
                onPressed: onFetchBill,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Customer Name
          if (bill!.customerName.isNotEmpty && bill!.customerName != 'Consumer Account')
            _buildRow('Customer Name', bill!.customerName, isBold: true),

          // Bill Number
          if (bill!.billNumber.isNotEmpty)
            _buildRow('Bill Number', bill!.billNumber),

          // Due Date
          if (bill!.dueDate.isNotEmpty)
            _buildRow('Due Date', bill!.dueDate, highlightColor: const Color(0xFFDC2626)),

          // Bill Date
          if (bill!.billDate.isNotEmpty)
            _buildRow('Bill Date', bill!.billDate),

          // Bill Period
          if (bill!.billPeriod.isNotEmpty)
            _buildRow('Bill Period', bill!.billPeriod),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Due Amount Highlight Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill Due Amount',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                ),
                Text(
                  '₹${bill!.dueAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF047857),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: highlightColor ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
