import 'package:flutter/material.dart';
import '../../../../services/money_transfer_service.dart';

class MainMoneyTransferScreen extends StatefulWidget {
  final Map<String, dynamic>? remitterData;
  final List<Map<String, dynamic>>? initialBeneficiaries;
  final String referenceKey;

  const MainMoneyTransferScreen({
    super.key,
    this.remitterData,
    this.initialBeneficiaries,
    this.referenceKey = '',
  });

  @override
  State<MainMoneyTransferScreen> createState() => _MainMoneyTransferScreenState();
}

class _MainMoneyTransferScreenState extends State<MainMoneyTransferScreen> {
  // Theme Colors
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color bgSoft = Color(0xFFF4F6FA);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color borderCol = Color(0xFFE2E8F0);
  static const Color dangerRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);



  late Map<String, dynamic> _remitterData;
  late List<Map<String, dynamic>> _beneficiaries;
  late String _referenceKey;
  List<Map<String, dynamic>> _banksList = [];
  bool _isLoadingBanks = false;
  String _bankStatusMsg = '';

  final TextEditingController _searchBeneficiaryCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remitterData = widget.remitterData ?? {
      'firstName': 'P',
      'lastName': 'KRISHNAN',
      'mobileNumber': '9677146918',
      'limitTotal': '25000.00',
      'limitAvailable': '25000.00',
    };
    _beneficiaries = widget.initialBeneficiaries != null
        ? List<Map<String, dynamic>>.from(widget.initialBeneficiaries!)
        : [
            {
              'id': '1',
              'name': 'MRS ASMA KHATUN',
              'account': '37924925435',
              'bank': 'STATE BANK OF INDIA',
              'ifsc': 'SBIN0015044',
            },
            {
              'id': '2',
              'name': 'FULBABU',
              'account': '38677225934',
              'bank': 'STATE BANK OF INDIA',
              'ifsc': 'SBIN0002106',
            },
            {
              'id': '3',
              'name': 'KRISHNAN P',
              'account': '5312253335',
              'bank': 'KOTAK MAHINDRA BANK',
              'ifsc': 'KKBK0008485',
            },
          ];
    _referenceKey = widget.referenceKey;
    _loadBanks();
  }

  @override
  void dispose() {
    _searchBeneficiaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBanks({StateSetter? modalSetState}) async {
    if (mounted) setState(() => _isLoadingBanks = true);
    if (modalSetState != null) modalSetState(() => _isLoadingBanks = true);

    final res = await MoneyTransferService.fetchBanksResponse();
    final loaded = res['banks'] as List<Map<String, dynamic>>;
    final msg = res['message'] ?? '';

    if (mounted) {
      setState(() {
        _banksList = loaded;
        _bankStatusMsg = msg;
        _isLoadingBanks = false;
      });
    }

    if (modalSetState != null) {
      modalSetState(() {
        _banksList = loaded;
        _bankStatusMsg = msg;
        _isLoadingBanks = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredBeneficiaries {
    final query = _searchBeneficiaryCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _beneficiaries;
    return _beneficiaries.where((b) {
      final name = (b['name'] ?? '').toString().toLowerCase();
      final acc = (b['account'] ?? '').toString().toLowerCase();
      final bank = (b['bank'] ?? '').toString().toLowerCase();
      final ifsc = (b['ifsc'] ?? '').toString().toLowerCase();
      return name.contains(query) || acc.contains(query) || bank.contains(query) || ifsc.contains(query);
    }).toList();
  }

  // ─── Searchable Bank Selector Modal ───────────────────────────────────────
  void _openSearchableBankPicker({
    required BuildContext context,
    required Function(Map<String, dynamic> selectedBank) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            if (_banksList.isEmpty && !_isLoadingBanks) {
              _loadBanks(modalSetState: setModalState);
            }

            final activeBanks = _banksList;
            final filteredBanks = activeBanks.where((b) {
              final name = (b['name'] ?? b['bankName'] ?? '').toString().toLowerCase();
              final ifsc = (b['ifscAlias'] ?? b['ifscGlobal'] ?? b['ifscPrefix'] ?? '').toString().toLowerCase();
              return name.contains(searchQuery.toLowerCase()) || ifsc.contains(searchQuery.toLowerCase());
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Select Bank',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark),
                            ),
                            if (activeBanks.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primaryPurple.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${activeBanks.length} Banks',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryPurple),
                                ),
                              ),
                            ],
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: textMuted),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: TextField(
                      autofocus: false,
                      onChanged: (val) => setModalState(() => searchQuery = val),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textDark),
                      decoration: InputDecoration(
                        hintText: 'Search bank by name or IFSC (e.g. SBI, HDFC)...',
                        hintStyle: const TextStyle(fontSize: 13, color: textLight),
                        prefixIcon: const Icon(Icons.search_rounded, color: primaryPurple, size: 20),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderCol)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
                      ),
                    ),
                  ),
                  const Divider(color: borderCol, height: 1),
                  Expanded(
                    child: _isLoadingBanks && activeBanks.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(color: primaryPurple),
                                SizedBox(height: 12),
                                Text('Connecting to InstantPay Bank API...', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600, fontSize: 13)),
                              ],
                            ),
                          )
                        : activeBanks.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_off_rounded, color: textMuted, size: 44),
                                      const SizedBox(height: 12),
                                      const Text('No Bank Data Returned', style: TextStyle(color: textDark, fontWeight: FontWeight.w800, fontSize: 15)),
                                      const SizedBox(height: 6),
                                      if (_bankStatusMsg.isNotEmpty)
                                        Text(
                                          _bankStatusMsg,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(color: dangerRed, fontSize: 12, fontWeight: FontWeight.w600),
                                        ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryPurple,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        ),
                                        icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                                        label: const Text('Reload Banks List', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        onPressed: () => _loadBanks(modalSetState: setModalState),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : filteredBanks.isEmpty
                                ? const Center(
                                    child: Text('No banks match your search query', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
                                  )
                                : ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: filteredBanks.length,
                                    separatorBuilder: (ctx, i) => const Divider(color: Color(0xFFF1F5F9), height: 1),
                                    itemBuilder: (ctx, idx) {
                                      final bank = filteredBanks[idx];
                                      final bName = (bank['name'] ?? bank['bankName'] ?? 'Bank').toString().toUpperCase();
                                      final ifsc = bank['ifscAlias'] ?? bank['ifscGlobal'] ?? bank['ifscPrefix'] ?? '';
                                      final imps = bank['impsEnabled'] == 1 || bank['imps'] == true;
                                      final neft = bank['neftEnabled'] == 1 || bank['neft'] == true;

                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                        leading: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: primaryPurple.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.account_balance_rounded, color: primaryPurple, size: 20),
                                        ),
                                        title: Text(
                                          bName,
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textDark),
                                        ),
                                        subtitle: Row(
                                          children: [
                                            if (ifsc.isNotEmpty)
                                              Text(
                                                'IFSC: $ifsc',
                                                style: const TextStyle(fontSize: 11.5, color: textMuted, fontWeight: FontWeight.w600),
                                              ),
                                            const SizedBox(width: 8),
                                            if (imps)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('IMPS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                                              ),
                                            if (neft) ...[
                                              const SizedBox(width: 4),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text('NEFT', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: const Icon(Icons.chevron_right_rounded, color: textLight, size: 20),
                                        onTap: () {
                                          Navigator.pop(ctx);
                                          onSelect(bank);
                                        },
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Add Beneficiary Dialog ───────────────────────────────────────────────
  void _showAddBeneficiaryDialog() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController(text: _remitterData['mobileNumber'] ?? '');
    final accCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    Map<String, dynamic>? selectedBank;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final bankDisplayName = selectedBank != null
              ? (selectedBank!['name'] ?? selectedBank!['bankName'] ?? 'Selected Bank').toString().toUpperCase()
              : 'Select Bank from API';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Add New Beneficiary',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter beneficiary details to proceed.',
                      style: TextStyle(fontSize: 13, color: textMuted, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 20),

                    _formLabel('Beneficiary Name'),
                    _formInput(controller: nameCtrl, hint: 'Enter name', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),

                    _formLabel('Mobile Number'),
                    _formInput(controller: mobileCtrl, hint: 'Enter mobile', icon: Icons.phone_android_rounded, isPhone: true),
                    const SizedBox(height: 14),

                    _formLabel('Bank (API)'),
                    InkWell(
                      onTap: () {
                        _openSearchableBankPicker(
                          context: dialogCtx,
                          onSelect: (bank) {
                            setDialogState(() {
                              selectedBank = bank;
                              final ifscGlobal = (bank['ifscGlobal'] ?? '').toString();
                              final ifscAlias = (bank['ifscAlias'] ?? bank['ifscPrefix'] ?? '').toString();
                              if (ifscGlobal.isNotEmpty) {
                                ifscCtrl.text = ifscGlobal;
                              } else if (ifscAlias.isNotEmpty) {
                                ifscCtrl.text = '${ifscAlias}0000001';
                              }
                            });
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selectedBank != null ? primaryPurple : borderCol,
                            width: selectedBank != null ? 1.5 : 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, color: primaryPurple, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bankDisplayName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: selectedBank != null ? FontWeight.w800 : FontWeight.w600,
                                  color: selectedBank != null ? textDark : textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded, color: primaryPurple, size: 22),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _formLabel('Account Number'),
                    _formInput(controller: accCtrl, hint: 'Enter account number', icon: Icons.account_balance_wallet_outlined, isNumber: true),
                    const SizedBox(height: 14),

                    _formLabel('IFSC Code'),
                    _formInput(
                      controller: ifscCtrl,
                      hint: 'Enter IFSC (e.g. SBIN0000001)',
                      icon: Icons.pin_outlined,
                      isUpper: true,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () => Navigator.pop(dialogCtx),
                              child: const Text('CANCEL', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w800)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: dangerRed,
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              ),
                              onPressed: () async {
                                final name = nameCtrl.text.trim();
                                final mob = mobileCtrl.text.trim();
                                final acc = accCtrl.text.trim();
                                final ifsc = ifscCtrl.text.trim();
                                final bankName = selectedBank?['name'] ?? selectedBank?['bankName'] ?? 'Bank';
                                final bankId = (selectedBank?['bankId'] ?? selectedBank?['id'] ?? '').toString();

                                if (name.isEmpty || mob.isEmpty || acc.isEmpty || ifsc.isEmpty) {
                                  _showToast('Please fill all fields', isError: true);
                                  return;
                                }

                                Navigator.pop(dialogCtx);
                                _showLoadingOverlay();

                                final res = await MoneyTransferService.addBeneficiary(
                                  remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                                  beneficiaryMobileNumber: mob,
                                  accountNumber: acc,
                                  ifsc: ifsc,
                                  name: name,
                                  bankId: bankId,
                                  bankName: bankName,
                                );

                                _hideLoadingOverlay();

                                if (res['statuscode'] == 'OTP') {
                                  final benId = res['data']?['beneficiaryId'] ?? '';
                                  final refKey = res['data']?['referenceKey'] ?? '';
                                  _showOtpDialog(
                                    title: 'Verify Beneficiary OTP',
                                    subtitle: 'Enter OTP sent to +91 ${_remitterData['mobileNumber']}',
                                    onVerify: (otp) async {
                                      _showLoadingOverlay();
                                      final verifyRes = await MoneyTransferService.verifyBeneficiaryRegistration(
                                        remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                                        beneficiaryId: benId,
                                        otp: otp,
                                        referenceKey: refKey,
                                      );
                                      _hideLoadingOverlay();
                                      if (verifyRes['statuscode'] == 'TXN' || verifyRes['status'] == 'Success') {
                                        _addNewBeneficiaryLocally(name, acc, bankName, ifsc);
                                      } else {
                                        _showToast(verifyRes['status'] ?? 'Verification failed', isError: true);
                                      }
                                    },
                                  );
                                } else {
                                  _addNewBeneficiaryLocally(name, acc, bankName, ifsc);
                                }
                              },
                              child: const Text('SUBMIT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addNewBeneficiaryLocally(String name, String acc, String bank, String ifsc) {
    setState(() {
      _beneficiaries.insert(0, {
        'id': '${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'account': acc,
        'bank': bank,
        'ifsc': ifsc,
      });
    });
    _showToast('Beneficiary added successfully!');
  }

  // ─── Transfer Dialog ────────────────────────────────────────────────────────
  void _showTransferDialog(Map<String, dynamic> beneficiary) {
    String transferMode = 'IMPS';
    final amtCtrl = TextEditingController(text: '500');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: primaryPurple.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.send_rounded, color: primaryPurple, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Send Money',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark),
                                ),
                                Text(
                                  'To: ${beneficiary['name']}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: textMuted),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          _summaryRow('Account No.', beneficiary['account'] ?? ''),
                          _summaryRow('Bank Name', beneficiary['bank'] ?? ''),
                          _summaryRow('IFSC Code', beneficiary['ifsc'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Transfer Mode'),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => transferMode = 'IMPS'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: transferMode == 'IMPS' ? primaryPurple : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: transferMode == 'IMPS' ? primaryPurple : borderCol),
                              ),
                              child: Center(
                                child: Text(
                                  'IMPS (Instant)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: transferMode == 'IMPS' ? Colors.white : textDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setDialogState(() => transferMode = 'NEFT'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: transferMode == 'NEFT' ? primaryPurple : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: transferMode == 'NEFT' ? primaryPurple : borderCol),
                              ),
                              child: Center(
                                child: Text(
                                  'NEFT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: transferMode == 'NEFT' ? Colors.white : textDark,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _formLabel('Amount (₹)'),
                    TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryPurple),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurple,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final amt = amtCtrl.text.trim();
                          if (amt.isEmpty || (double.tryParse(amt) ?? 0) <= 0) {
                            _showToast('Please enter a valid transfer amount', isError: true);
                            return;
                          }

                          Navigator.pop(dialogCtx);
                          _showLoadingOverlay();

                          final res = await MoneyTransferService.generateTransactionOtp(
                            remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                            amount: amt,
                            referenceKey: _referenceKey,
                          );

                          _hideLoadingOverlay();

                          final refKey = res['data']?['referenceKey'] ?? _referenceKey;

                          _showOtpDialog(
                            title: 'Transaction Verification',
                            subtitle: 'Enter OTP sent to +91 ${_remitterData['mobileNumber']} for ₹$amt',
                            onVerify: (otp) async {
                              _showLoadingOverlay();
                              final txnRes = await MoneyTransferService.executeTransaction(
                                remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                                accountNumber: beneficiary['account'] ?? '',
                                ifsc: beneficiary['ifsc'] ?? '',
                                transferMode: transferMode,
                                transferAmount: amt,
                                referenceKey: refKey,
                                otp: otp,
                              );
                              _hideLoadingOverlay();

                              if (txnRes['statuscode'] == 'TXN' || txnRes['status'] == 'Success' || txnRes['status'] == 'Transaction Successful') {
                                _showPaymentSuccessReceipt(
                                  beneficiary: beneficiary,
                                  amount: amt,
                                  mode: transferMode,
                                  txnId: txnRes['data']?['orderid'] ?? txnRes['orderid'] ?? txnRes['ipay_uuid'] ?? 'TXN${DateTime.now().millisecondsSinceEpoch}',
                                );
                              } else {
                                _showToast(txnRes['status'] ?? 'Transaction failed.', isError: true);
                              }
                            },
                          );
                        },
                        child: const Text('PROCEED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Delete Beneficiary Dialog ──────────────────────────────────────────────
  void _showDeleteBeneficiaryDialog(Map<String, dynamic> beneficiary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: dangerRed, size: 26),
            SizedBox(width: 10),
            Text('Delete Beneficiary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete beneficiary "${beneficiary['name']}" (${beneficiary['account']})?',
          style: const TextStyle(color: textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              _showLoadingOverlay();

              final res = await MoneyTransferService.deleteBeneficiary(
                remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                beneficiaryId: (beneficiary['id'] ?? '').toString(),
              );

              _hideLoadingOverlay();

              if (res['statuscode'] == 'OTP') {
                final benId = res['data']?['beneficiaryId'] ?? beneficiary['id'];
                final refKey = res['data']?['referenceKey'] ?? '';
                _showOtpDialog(
                  title: 'Confirm Delete Beneficiary',
                  subtitle: 'Enter OTP sent to +91 ${_remitterData['mobileNumber']}',
                  onVerify: (otp) async {
                    _showLoadingOverlay();
                    final verifyRes = await MoneyTransferService.verifyDeleteBeneficiary(
                      remitterMobileNumber: _remitterData['mobileNumber'] ?? '',
                      beneficiaryId: benId,
                      otp: otp,
                      referenceKey: refKey,
                    );
                    _hideLoadingOverlay();
                    if (verifyRes['statuscode'] == 'TXN' || verifyRes['status'] == 'Success') {
                      setState(() => _beneficiaries.removeWhere((b) => b['id'] == beneficiary['id']));
                      _showToast('Beneficiary deleted successfully!');
                    } else {
                      _showToast(verifyRes['status'] ?? 'Delete failed', isError: true);
                    }
                  },
                );
              } else {
                setState(() => _beneficiaries.removeWhere((b) => b['id'] == beneficiary['id']));
                _showToast('Beneficiary deleted successfully!');
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── OTP Dialog ───────────────────────────────────────────────────────────
  void _showOtpDialog({
    required String title,
    required String subtitle,
    required Function(String otp) onVerify,
  }) {
    final otpCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_rounded, color: primaryPurple, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textDark),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: textMuted),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 6),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '• • • • • •',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: primaryPurple, width: 2)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPurple,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () {
                        final otp = otpCtrl.text.trim();
                        if (otp.length < 4) {
                          _showToast('Please enter a valid OTP', isError: true);
                          return;
                        }
                        Navigator.pop(ctx);
                        onVerify(otp);
                      },
                      child: const Text('VERIFY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Payment Success Receipt ──────────────────────────────────────────────
  void _showPaymentSuccessReceipt({
    required Map<String, dynamic> beneficiary,
    required String amount,
    required String mode,
    required String txnId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: successGreen, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textDark),
            ),
            const SizedBox(height: 6),
            Text(
              '₹$amount',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryPurple),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                children: [
                  _summaryRow('Beneficiary', beneficiary['name'] ?? ''),
                  _summaryRow('Account No.', beneficiary['account'] ?? ''),
                  _summaryRow('Bank Name', beneficiary['bank'] ?? ''),
                  _summaryRow('Mode', mode),
                  _summaryRow('Txn ID', txnId),
                  _summaryRow('Status', 'SUCCESS ($mode)'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('DONE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSoft,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopBar(),

            // Body Area (Manage Beneficiary Content)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: _buildManageBeneficiaryScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP APP BAR (With Heading 'Money Transfer' & Compact LOGOUT) ─────────
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gradient Circular Icon Badge
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF818CF8), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),

          // Heading: Money Transfer | Subtitle: Dashboard > Money Transfer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Money Transfer',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textDark),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Dashboard', style: TextStyle(fontSize: 11.5, color: textMuted, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 3),
                    const Icon(Icons.chevron_right_rounded, size: 13, color: textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Manage Beneficiary',
                        style: TextStyle(fontSize: 11.5, color: textMuted.withValues(alpha: 0.9), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Logout Button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF87171), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'LOGOUT',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MANAGE BENEFICIARY MAIN SCREEN (Exact Match of Screenshot) ───────────
  Widget _buildManageBeneficiaryScreen() {
    final senderName = '${_remitterData['firstName'] ?? 'P'} ${_remitterData['lastName'] ?? 'KRISHNAN'}'.trim();
    final mobile = _remitterData['mobileNumber'] ?? '';
    final totalLimit = _remitterData['limitTotal'] ?? '25000.00';
    final availLimit = _remitterData['limitAvailable'] ?? '25000.00';
    final filtered = _filteredBeneficiaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Money Transfer Details Section
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_rounded, color: primaryPurple, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Money Transfer Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Stat Cards in 2x2 Grid with individual white card styling
        Row(
          children: [
            Expanded(
              child: _screenshotStatCard(
                icon: Icons.person_rounded,
                iconColor: primaryPurple,
                iconBg: const Color(0xFFEEF2FF),
                label: 'SENDER NAME',
                value: senderName,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _screenshotStatCard(
                icon: Icons.phone_rounded,
                iconColor: primaryPurple,
                iconBg: const Color(0xFFEEF2FF),
                label: 'MOBILE NUMBER',
                value: mobile,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _screenshotStatCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: primaryPurple,
                iconBg: const Color(0xFFEEF2FF),
                label: 'TOTAL LIMIT',
                hasInfo: true,
                value: '₹ $totalLimit',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _screenshotStatCard(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: primaryPurple,
                iconBg: const Color(0xFFEEF2FF),
                label: 'AVAILABLE LIMIT',
                value: '₹ $availLimit',
                suffix: ' TODAY',
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Beneficiary List Section
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_rounded, color: primaryPurple, size: 16),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Beneficiary List',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                ),
                SizedBox(height: 1),
                Text(
                  'Manage, transfer & delete beneficiaries securely',
                  style: TextStyle(fontSize: 11.5, color: textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Search Bar & Filter Button
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchBeneficiaryCtrl,
                  onChanged: (v) => setState(() {}),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    hintText: 'Search beneficiary...',
                    hintStyle: TextStyle(fontSize: 13, color: textLight),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: textMuted),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.filter_alt_rounded, color: Colors.white, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // + ADD BENEFICIARY Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryPurple,
              elevation: 4,
              shadowColor: primaryPurple.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _showAddBeneficiaryDialog,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 6),
                Text(
                  '+ ADD BENEFICIARY',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Beneficiary Cards List (Matching Screenshot 01, 02, 03 Cards)
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderCol),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.person_off_outlined, color: textMuted.withValues(alpha: 0.6), size: 44),
                const SizedBox(height: 10),
                const Text('No Beneficiaries Found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: textDark)),
                const SizedBox(height: 4),
                const Text('Click "+ ADD BENEFICIARY" to add a new recipient.', style: TextStyle(color: textMuted, fontSize: 12.5)),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 14),
            itemBuilder: (ctx, index) {
              final b = filtered[index];
              return _buildScreenshotBeneficiaryCard(index + 1, b);
            },
          ),

        const SizedBox(height: 16),

        // Pagination Bar: Page 1 | X records + 1 < >
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Page 1 | ${_beneficiaries.length} records',
              style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('1', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: const Icon(Icons.chevron_left_rounded, size: 18, color: textMuted),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol),
                  ),
                  child: const Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ─── STAT CARD (Matching Screenshot Top 4 Cards) ──────────────────────────
  Widget _screenshotStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    String? suffix,
    bool hasInfo = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 0.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasInfo) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.info_rounded, size: 12, color: primaryPurple),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: value,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: accentBlue),
                    children: [
                      if (suffix != null)
                        TextSpan(
                          text: suffix,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted),
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

  // ─── BENEFICIARY CARD (Matching Screenshot Cards: 01, 02, 03) ────────────
  Widget _buildScreenshotBeneficiaryCard(int sNo, Map<String, dynamic> b) {
    final numStr = sNo.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number Badge (01, 02, 03)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  numStr,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: primaryPurple),
                ),
              ),
              const SizedBox(width: 12),

              // Details & Verified Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            (b['name'] ?? '').toString().toUpperCase(),
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 3 Columns: ACCOUNT NO. | BANK NAME | IFSC
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ACCOUNT NO.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                b['account'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('BANK NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                b['bank'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: accentBlue),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('IFSC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                b['ifsc'] ?? '',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),

          // Bottom Action Row: Transfer (Blue ↗) and Delete (Red 🗑️)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () => _showTransferDialog(b),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.north_east_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text('Transfer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              InkWell(
                onTap: () => _showDeleteBeneficiaryDialog(b),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(height: 4),
                    const Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── FORM HELPERS ─────────────────────────────────────────────────────────
  Widget _formLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textDark),
        ),
      ),
    );
  }

  Widget _formInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isPhone = false,
    bool isUpper = false,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber || isPhone ? TextInputType.number : TextInputType.text,
      maxLength: isPhone ? 10 : (isNumber ? 20 : null),
      textCapitalization: isUpper ? TextCapitalization.characters : TextCapitalization.words,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textDark),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13.5, color: textLight),
        prefixIcon: Icon(icon, color: primaryPurple, size: 20),
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: borderCol, width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryPurple, width: 1.8)),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: textDark)),
        ],
      ),
    );
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: isError ? dangerRed : successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: primaryPurple),
      ),
    );
  }

  void _hideLoadingOverlay() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
