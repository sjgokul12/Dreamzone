import 'package:flutter/material.dart';
import '../../../services/bus_api_service.dart';
import 'bus_checkout_screen.dart';

class BusSeatLayoutScreen extends StatefulWidget {
  final Map<String, dynamic> busDetails;
  final String sourceCity;
  final String destinationCity;
  final String doj;

  const BusSeatLayoutScreen({
    super.key,
    required this.busDetails,
    required this.sourceCity,
    required this.destinationCity,
    required this.doj,
  });

  @override
  State<BusSeatLayoutScreen> createState() => _BusSeatLayoutScreenState();
}

class _BusSeatLayoutScreenState extends State<BusSeatLayoutScreen> {
  bool _isLoading = true;
  List<dynamic> _seats = [];
  Map<String, dynamic>? _layoutData;
  final List<dynamic> _selectedSeats = [];
  int _activeTab = 0; // 0 = Select Seats, 1 = Boarding & Dropping
  dynamic _selectedBoardingPoint;
  dynamic _selectedDroppingPoint;

  @override
  void initState() {
    super.initState();
    _fetchLayout();
  }

  Future<void> _fetchLayout() async {
    try {
      final data = await BusApiService.getBusLayout(
        sourceCity: widget.sourceCity,
        destinationCity: widget.destinationCity,
        doj: widget.doj,
        inventoryType: widget.busDetails['inventoryType'] ?? 0,
        routeScheduleId: widget.busDetails['routeScheduleId'].toString(),
      );
      if (mounted) {
        setState(() {
          _layoutData = data;
          _seats = data['seats'] ?? [];
          final bpList = (data['boardingPoints'] as List?) ?? [];
          final dpList = (data['droppingPoints'] as List?) ?? [];
          if (bpList.isNotEmpty) _selectedBoardingPoint = bpList.first;
          if (dpList.isNotEmpty) _selectedDroppingPoint = dpList.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading layout: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSeat(dynamic seat) {
    if (seat['available'] != true) return;

    setState(() {
      final isSelected = _selectedSeats.any((s) => s['id'] == seat['id']);
      if (isSelected) {
        _selectedSeats.removeWhere((s) => s['id'] == seat['id']);
      } else {
        if (_selectedSeats.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 6 seats allowed per booking.')),
          );
          return;
        }
        _selectedSeats.add(seat);
      }
    });
  }

  double get _totalFare {
    double total = 0;
    for (var seat in _selectedSeats) {
      final fareVal = seat['fare'] ?? seat['totalFareWithTaxes'] ?? 0;
      if (fareVal is num) {
        total += fareVal.toDouble();
      } else {
        total += double.tryParse(fareVal.toString()) ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final operatorName = widget.busDetails['operatorName']?.toString() ?? 'Select Seats';
    final busType = widget.busDetails['busType']?.toString() ?? '';
    final seatsLeft = widget.busDetails['availableSeats']?.toString() ?? '0';
    final depTime = widget.busDetails['departureTime']?.toString() ?? '--:--';
    final arrTime = widget.busDetails['arrivalTime']?.toString() ?? '--:--';
    final rawFare = widget.busDetails['fare'] ?? widget.busDetails['fares'] ?? '0';
    final fareStr = rawFare.toString().split(',').first.replaceAll(RegExp(r'[^0-9.]'), '');
    final ratingVal = (widget.busDetails['rating'] ?? widget.busDetails['busRating'] ?? '4.4').toString();

    final hasUpperDeck = _seats.any((s) => s['zIndex'] == 1);
    final boardingPoints = (_layoutData?['boardingPoints'] as List?) ?? [];
    final droppingPoints = (_layoutData?['droppingPoints'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          children: [
            Text(
              '${widget.sourceCity} to ${widget.destinationCity}',
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(widget.doj, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                // Top Bus Card Summary
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        operatorName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('($seatsLeft Seats left)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(busType, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 11),
                                const SizedBox(width: 2),
                                Text(ratingVal, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('From', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                              Text('₹$fareStr', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(depTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Row(
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF0F172A), shape: BoxShape.circle)),
                                Expanded(child: Container(height: 1, color: const Color(0xFFCBD5E1))),
                                Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF94A3B8)))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(arrTime, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tabs: [✔ Select Seats]  |  [Boarding & Dropping]
                Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _activeTab == 0 ? Colors.black : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_activeTab == 0)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_circle, size: 16, color: Colors.black),
                                  ),
                                Text(
                                  'Select Seats',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                    color: _activeTab == 0 ? Colors.black : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _activeTab == 1 ? Colors.black : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_activeTab == 1)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 6),
                                    child: Icon(Icons.check_circle, size: 16, color: Colors.black),
                                  ),
                                Text(
                                  'Boarding & Dropping',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                    color: _activeTab == 1 ? Colors.black : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body based on active tab
                Expanded(
                  child: _activeTab == 0
                      ? SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              _buildLegendBar(),
                              const SizedBox(height: 20),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDeckCapsule(
                                      title: 'Lower Deck',
                                      deckSeats: _seats.where((s) => (s['zIndex'] ?? 0) == 0).toList(),
                                      showSteering: true,
                                    ),
                                    if (hasUpperDeck) ...[
                                      const SizedBox(width: 24),
                                      _buildDeckCapsule(
                                        title: 'Upper Deck',
                                        deckSeats: _seats.where((s) => (s['zIndex'] ?? 0) == 1).toList(),
                                        showSteering: false,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Boarding Point',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 10),
                              for (var bp in boardingPoints)
                                _buildPointItemCard(
                                  title: bp['location']?.toString() ?? '',
                                  subtitle: bp['address']?.toString() ?? bp['landMark']?.toString() ?? '',
                                  time: bp['time']?.toString() ?? '',
                                  isSelected: _selectedBoardingPoint != null && _selectedBoardingPoint['id'] == bp['id'],
                                  onTap: () => setState(() => _selectedBoardingPoint = bp),
                                ),
                              const SizedBox(height: 20),
                              const Text(
                                'Dropping Point',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 10),
                              for (var dp in droppingPoints)
                                _buildPointItemCard(
                                  title: dp['location']?.toString() ?? '',
                                  subtitle: dp['address']?.toString() ?? dp['landMark']?.toString() ?? '',
                                  time: dp['time']?.toString() ?? '',
                                  isSelected: _selectedDroppingPoint != null && _selectedDroppingPoint['id'] == dp['id'],
                                  onTap: () => setState(() => _selectedDroppingPoint = dp),
                                ),
                            ],
                          ),
                        ),
                ),

                // Bottom Summary Bar
                _buildBottomBar(boardingPoints, droppingPoints),
              ],
            ),
    );
  }

  Widget _buildLegendBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Available', Colors.white, const Color(0xFFCBD5E1)),
          const SizedBox(width: 14),
          _buildLegendItem('Booked', const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)),
          const SizedBox(width: 14),
          _buildLegendItem('Selected', Colors.black, Colors.black),
          const SizedBox(width: 14),
          _buildLegendItem('Ladies', Colors.white, const Color(0xFFF43F5E), borderWidth: 1.5),
          const SizedBox(width: 14),
          _buildLegendItem('Gents', Colors.white, const Color(0xFF3B82F6), borderWidth: 1.5),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color fillColor, Color borderColor, {double borderWidth = 1.0}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildDeckCapsule({required String title, required List<dynamic> deckSeats, required bool showSteering}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showSteering)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 4),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                      ),
                      child: Center(
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 36),
              _buildDeckSeatGrid(deckSeats),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeckSeatGrid(List<dynamic> deckSeats) {
    if (deckSeats.isEmpty) return const Text('No seats on this deck', style: TextStyle(color: Color(0xFF94A3B8)));

    int maxRow = 0;
    int maxCol = 0;
    for (var s in deckSeats) {
      final r = (s['row'] as num?)?.toInt() ?? 0;
      final c = (s['column'] as num?)?.toInt() ?? 0;
      if (r > maxRow) maxRow = r;
      if (c > maxCol) maxCol = c;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int r = 0; r <= maxRow; r++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int c = 0; c <= maxCol; c++) ...[
                _buildSeatWidget(
                  deckSeats.firstWhere(
                    (s) => ((s['row'] as num?)?.toInt() ?? -1) == r && ((s['column'] as num?)?.toInt() ?? -1) == c,
                    orElse: () => null,
                  ),
                ),
                if (c < maxCol) const SizedBox(width: 6),
              ],
            ],
          ),
          if (r < maxRow) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildSeatWidget(dynamic seat) {
    if (seat == null) return const SizedBox(width: 44, height: 44);

    final bool isSelected = _selectedSeats.any((s) => s['id'] == seat['id']);
    final bool isAvailable = seat['available'] == true;
    final bool isLadies = seat['ladiesSeat'] == true;
    final bool isGents = seat['malesSeat'] == true || seat['isGents'] == true;
    final bool isSleeper = seat['sleeper'] == true || seat['length'] == 2 || seat['width'] == 2;

    final double width = 44;
    final double height = isSleeper ? 68 : 44;

    final fareNum = seat['fare'] ?? seat['totalFareWithTaxes'] ?? 0;
    final fareText = '₹${fareNum.toString().split('.').first}';

    Color bgColor = Colors.white;
    Color borderColor = const Color(0xFFCBD5E1);
    Color textColor = const Color(0xFF0F172A);

    if (!isAvailable) {
      bgColor = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
      textColor = const Color(0xFF94A3B8);
    } else if (isSelected) {
      bgColor = Colors.black;
      borderColor = Colors.black;
      textColor = Colors.white;
    } else if (isLadies) {
      bgColor = Colors.white;
      borderColor = const Color(0xFFF43F5E);
      textColor = const Color(0xFFF43F5E);
    } else if (isGents) {
      bgColor = Colors.white;
      borderColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF3B82F6);
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: (isSelected || (isAvailable && (isLadies || isGents))) ? 2 : 1.2),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: !isAvailable
              ? const Text('x', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)))
              : Text(fareText, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: textColor)),
        ),
      ),
    );
  }

  Widget _buildPointItemCard({
    required String title,
    required String subtitle,
    required String time,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w400), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (time.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(time, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<dynamic> boardingPoints, List<dynamic> droppingPoints) {
    final seatCount = _selectedSeats.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹${_totalFare.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const Text('(Tax Excluded)', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: const Color(0xFFE2E8F0)),
          const SizedBox(width: 16),
          Text('$seatCount ${seatCount == 1 ? 'Seat' : 'Seats'}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              if (_selectedSeats.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 seat')));
                return;
              }
              if (_activeTab == 0) {
                setState(() => _activeTab = 1);
                return;
              }
              if (_selectedBoardingPoint == null || _selectedDroppingPoint == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select boarding and dropping points')));
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusCheckoutScreen(
                    busDetails: widget.busDetails,
                    selectedSeats: _selectedSeats,
                    sourceCity: widget.sourceCity,
                    destinationCity: widget.destinationCity,
                    doj: widget.doj,
                    boardingPoints: boardingPoints,
                    droppingPoints: droppingPoints,
                    initialBoardingPointId: _selectedBoardingPoint?['id']?.toString(),
                    initialDroppingPointId: _selectedDroppingPoint?['id']?.toString(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              _activeTab == 0 ? 'Select Points' : 'Proceed to Book',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
