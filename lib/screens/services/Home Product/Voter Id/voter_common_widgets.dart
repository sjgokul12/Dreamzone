import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/api_service.dart';
import '../../../home/home_screen.dart';

// ─── Premium Palette Theme Constants ─────────────────────────────────────────
const Color primaryPurple   = Color(0xFF5F33E1);
const Color secondaryPurple = Color(0xFF7C3AED);
const Color textDarkHeading = Color(0xFF1E1B4B);
const Color textLabelDark   = Color(0xFF312E81);
const Color textSubdued     = Color(0xFF6B7280);
const Color bgCanvas        = Color(0xFFF5F3FF);
const Color cardSurface     = Colors.white;

// ─── Utility Helpers ─────────────────────────────────────────────────────────
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 KB';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// ─── Top Navigation Bar ──────────────────────────────────────────────────────
class VoterTopNavBar extends StatelessWidget {
  final String title;

  const VoterTopNavBar({super.key, this.title = 'Voter ID Service'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, color: primaryPurple, size: 20),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryPurple.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.how_to_vote_outlined, color: primaryPurple, size: 16),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    color: primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Card Banner ────────────────────────────────────────────────────────
class VoterHeroCard extends StatelessWidget {
  const VoterHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth / 1.6;
        return Container(
          width: double.infinity,
          height: cardHeight,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/Voter card.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF3F0FF),
                  child: const Center(
                    child: Icon(Icons.how_to_vote_outlined, size: 70, color: primaryPurple),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Top 4 Category Cards (Uniform Height & Equal Proportions) ───────────────
class VoterCategoryTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onSelectTab;

  const VoterCategoryTabs({
    super.key,
    required this.selectedIndex,
    this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          _buildTabCard(0, 'New Voter', 'Apply fresh', Icons.person_add_outlined),
          const SizedBox(width: 8),
          _buildTabCard(1, 'Correction', 'Update info', Icons.edit_note_outlined),
          const SizedBox(width: 8),
          _buildTabCard(2, 'Hard Copy', 'Physical card', Icons.credit_card_outlined),
          const SizedBox(width: 8),
          _buildTabCard(3, 'Soft Copy', 'Digital PDF', Icons.picture_as_pdf_outlined),
        ],
      ),
    );
  }

  Widget _buildTabCard(int index, String title, String subtitle, IconData icon) {
    final isSelected = selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (onSelectTab != null) onSelectTab!(index);
        },
        child: Container(
          height: 110, // Guaranteed uniform equal height
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5F3FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? primaryPurple : const Color(0xFFE2E8F0),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? primaryPurple.withValues(alpha: 0.15) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? primaryPurple : textSubdued, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? primaryPurple : textDarkHeading,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: textSubdued,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Expandable Accordion Card ───────────────────────────────────────────────
class VoterAccordionSection extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Widget child;
  final ValueChanged<int> onToggle;

  const VoterAccordionSection({
    super.key,
    required this.index,
    required this.currentIndex,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.child,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = currentIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? primaryPurple.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded ? primaryPurple.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.01),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => onToggle(isExpanded ? -1 : index),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpanded ? primaryPurple.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                leadingIcon,
                color: isExpanded ? primaryPurple : textSubdued,
                size: 22,
              ),
            ),
            title: Text(
              title,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textDarkHeading),
            ),
            subtitle: Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: textSubdued),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: textSubdued,
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Sticky Bottom Action Bar ────────────────────────────────────────────────
class VoterStickyBottomBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const VoterStickyBottomBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primaryPurple, secondaryPurple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: primaryPurple.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, color: primaryPurple, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input & Dropdown Field Builders ─────────────────────────────────────────
Widget buildVoterInput(
  String label,
  TextEditingController controller, {
  bool isNum = false,
  String? placeholder,
  IconData? prefixIcon,
  String? helper,
  bool readOnly = false,
}) {
  final isReq = label.contains('*');
  final cleanLabel = label.replaceAll('*', '').trim();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: cleanLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark),
          children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: readOnly ? textSubdued : textDarkHeading),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
          counterText: helper,
          counterStyle: const TextStyle(fontSize: 10, color: primaryPurple, fontWeight: FontWeight.w600),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          fillColor: readOnly ? const Color(0xFFF1F5F9) : const Color(0xFFFAFAFA),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        ),
        validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    ],
  );
}

Widget buildVoterDateField(
  BuildContext context,
  String label,
  TextEditingController controller, {
  ValueChanged<DateTime>? onDatePicked,
}) {
  final isReq = label.contains('*');
  final cleanLabel = label.replaceAll('*', '').trim();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: cleanLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark),
          children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
        ),
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: DateTime(2000, 1, 1),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: primaryPurple,
                    onPrimary: Colors.white,
                    onSurface: textDarkHeading,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            controller.text = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
            if (onDatePicked != null) onDatePicked(date);
          }
        },
        child: IgnorePointer(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
            decoration: InputDecoration(
              hintText: 'DD/MM/YYYY',
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 20, color: primaryPurple),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              fillColor: const Color(0xFFFAFAFA),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
            ),
            validator: (v) => isReq && (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ),
      ),
    ],
  );
}

Widget buildVoterDropdown(
  String label,
  String? value,
  List<String> items,
  ValueChanged<String?> onChanged, {
  String? hint,
  IconData? prefixIcon,
}) {
  final isReq = label.contains('*');
  final cleanLabel = label.replaceAll('*', '').trim();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: cleanLabel,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textLabelDark),
          children: isReq ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
        ),
      ),
      const SizedBox(height: 6),
      DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        hint: hint != null ? Text(hint, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))) : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDarkHeading),
        decoration: InputDecoration(
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryPurple, size: 20) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          fillColor: const Color(0xFFFAFAFA),
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 2)),
        ),
        items: items.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: textDarkHeading), overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
        validator: (v) => isReq && (v == null || v.isEmpty) ? 'Required' : null,
      ),
    ],
  );
}

// ─── Upload Card Builder ─────────────────────────────────────────────────────
Widget buildVoterDocUploadCard({
  required String title,
  required String docKey,
  required Map<String, List<Map<String, dynamic>>> uploadedDocs,
  required VoidCallback onPick,
  required VoidCallback onRemove,
}) {
  final docs = uploadedDocs[docKey] ?? [];
  final hasFile = docs.isNotEmpty;
  final file = hasFile ? docs.first : null;
  final fileName = file != null ? (file['name'] ?? '') : '';
  final fileSize = file != null ? (file['size'] as int? ?? 0) : 0;
  
  final isReq = title.contains('*');
  final cleanTitle = title.replaceAll('*', '').trim();

  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: hasFile ? primaryPurple.withValues(alpha: 0.5) : const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: docKey.contains('photo') ? const [Color(0xFF6366F1), Color(0xFF3B82F6)] :
                      docKey.contains('id') ? const [Color(0xFF8B5CF6), Color(0xFF7C3AED)] :
                      docKey.contains('address') ? const [Color(0xFF10B981), Color(0xFF059669)] :
                      const [Color(0xFFEF4444), Color(0xFFDC2626)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            docKey.contains('photo') ? Icons.person : Icons.description_outlined,
            color: Colors.white, size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: hasFile ? fileName : cleanTitle,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textDarkHeading),
                  children: (!hasFile && isReq) ? [const TextSpan(text: ' *', style: TextStyle(color: Color(0xFFEF4444)))] : [],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                hasFile ? 'Uploaded • ${formatBytes(fileSize)}' : 'PDF, PNG, JPG up to 2MB',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: textSubdued),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        if (hasFile)
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFF94A3B8), size: 24),
            tooltip: 'Remove file',
          )
        else
          ElevatedButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.upload_rounded, size: 16),
            label: const Text('Upload', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple.withValues(alpha: 0.1),
              foregroundColor: primaryPurple,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    ),
  );
}

// ─── Responsive Row Helpers ──────────────────────────────────────────────────
Widget buildVoterResponsiveRow(BuildContext context, Widget child1, Widget child2) {
  return LayoutBuilder(
    builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 650;
      return isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: child1),
                const SizedBox(width: 14),
                Expanded(child: child2),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child1,
                const SizedBox(height: 14),
                child2,
              ],
            );
    },
  );
}

Widget buildVoterThreeColumnRow(BuildContext context, Widget c1, Widget c2, Widget c3) {
  return LayoutBuilder(
    builder: (context, constraints) {
      bool isWide = constraints.maxWidth > 750;
      return isWide
          ? Row(
              children: [
                Expanded(child: c1),
                const SizedBox(width: 10),
                Expanded(child: c2),
                const SizedBox(width: 10),
                Expanded(child: c3),
              ],
            )
          : Column(
              children: [
                c1,
                const SizedBox(height: 12),
                c2,
                const SizedBox(height: 12),
                c3,
              ],
            );
    },
  );
}

// ─── Payment Step Box ────────────────────────────────────────────────────────
Widget buildVoterPaymentStepBox({
  required String title,
  required String subtitle,
  required double amount,
}) {
  return Column(
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textDarkHeading)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: textSubdued)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: primaryPurple),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payments are secure and encrypted.',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ],
  );
}

// ─── Success Submission View ─────────────────────────────────────────────────
class VoterSuccessView extends StatelessWidget {
  final String title;
  final String? trackingId;
  final VoidCallback onBack;

  const VoterSuccessView({
    super.key,
    required this.title,
    this.trackingId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(26.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: primaryPurple, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 42),
              ),
              const SizedBox(height: 20),
              const Text(
                'Application Submitted!',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: textDarkHeading),
              ),
              const SizedBox(height: 8),
              Text(
                'Your $title request has been received successfully.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textSubdued, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryPurple.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    const Text('Tracking Reference ID', style: TextStyle(fontSize: 11, color: textSubdued, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      trackingId ?? '',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: primaryPurple, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HomeScreen(initialIndex: 2),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.assignment_outlined, size: 20),
                  label: const Text('View My Orders / Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.home_outlined, size: 18, color: primaryPurple),
                  label: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: primaryPurple)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryPurple.withValues(alpha: 0.3), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Login Modal ─────────────────────────────────────────────────────────────
class VoterLoginModal extends StatefulWidget {
  final VoidCallback onSuccess;
  const VoterLoginModal({super.key, required this.onSuccess});

  @override
  State<VoterLoginModal> createState() => _VoterLoginModalState();
}

class _VoterLoginModalState extends State<VoterLoginModal> {
  final _idController   = TextEditingController();
  final _passController = TextEditingController();
  final ApiService _api = ApiService();
  bool _loading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 22,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 22,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Login Required', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: textDarkHeading)),
              const SizedBox(height: 4),
              const Text('Please login to submit your Voter application.', style: TextStyle(color: textSubdued, fontSize: 12.5)),
              const SizedBox(height: 16),
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Mobile or Email',
                  labelStyle: TextStyle(color: textSubdued, fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: textSubdued, fontSize: 13),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Login & Continue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    final res = await _api.login(_idController.text.trim(), _passController.text.trim());
    if (mounted) {
      setState(() => _loading = false);
      if (res['success'] == true) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        auth.login(_idController.text.trim(), _passController.text.trim());
        widget.onSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Login failed')),
        );
      }
    }
  }
}
