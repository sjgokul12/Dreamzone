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
  int _currentDeck = 0; // 0 for Lower, 1 for Upper

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
      setState(() {
        _layoutData = data;
        _seats = data['seats'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading layout: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _toggleSeat(dynamic seat) {
    if (!seat['available']) return;

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
      total += (seat['totalFareWithTaxes'] ?? seat['fare'] ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final hasUpperDeck = _seats.any((s) => s['zIndex'] == 1);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.busDetails['operatorName'] ?? 'Select Seats', style: const TextStyle(color: Colors.black87, fontSize: 16)),
            Text('${widget.sourceCity} to ${widget.destinationCity}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
          : Column(
              children: [
                if (hasUpperDeck)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Lower Deck')),
                        ButtonSegment(value: 1, label: Text('Upper Deck')),
                      ],
                      selected: {_currentDeck},
                      onSelectionChanged: (set) => setState(() => _currentDeck = set.first),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                          ),
                          child: _buildSeatGrid(),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildSeatGrid() {
    final deckSeats = _seats.where((s) => s['zIndex'] == _currentDeck).toList();
    if (deckSeats.isEmpty) return const Text('No seats on this deck');

    int maxRow = 0;
    int maxCol = 0;
    for (var s in deckSeats) {
      if (s['row'] > maxRow) maxRow = s['row'];
      if (s['column'] > maxCol) maxCol = s['column'];
    }

    return Column(
      children: [
        if (_currentDeck == 0) // Steering wheel
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24, right: 8),
              child: Icon(Icons.panorama_horizontal, color: Colors.grey[400], size: 32),
            ),
          ),
        for (int r = 0; r <= maxRow; r++)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int c = 0; c <= maxCol; c++)
                _buildSeatWidget(deckSeats.firstWhere((s) => s['row'] == r && s['column'] == c, orElse: () => null)),
            ],
          ),
      ],
    );
  }

  Widget _buildSeatWidget(dynamic seat) {
    if (seat == null) {
      return const SizedBox(width: 44, height: 44, child: Padding(padding: EdgeInsets.all(4))); // Empty space / Aisle
    }

    bool isSelected = _selectedSeats.any((s) => s['id'] == seat['id']);
    bool isAvailable = seat['available'];
    bool isLadies = seat['ladiesSeat'] ?? false;
    bool isSleeper = seat['length'] == 2 || seat['width'] == 2;
    double width = (seat['length'] == 2) ? 88 : 44;
    double height = (seat['width'] == 2) ? 88 : 44;
    Color seatColor = isAvailable ? Colors.white : Colors.grey[300]!;
    if (isSelected) {
      seatColor = const Color(0xFFFF5500);
    } else if (isAvailable && isLadies) seatColor = Colors.pink[50]!;

    Color borderColor = isAvailable ? Colors.grey[400]! : Colors.grey[300]!;
    if (isSelected) {
      borderColor = const Color(0xFFFF5500);
    } else if (isAvailable && isLadies) borderColor = Colors.pink;

    return GestureDetector(
      onTap: () => _toggleSeat(seat),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(isSleeper ? 8 : 6),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: (seat['length'] == 2 || seat['width'] == 2)
              ? RotatedBox(
                  quarterTurns: (seat['length'] == 2) ? 0 : 1, 
                  child: Icon(
                    Icons.bed,
                    color: isSelected ? Colors.white : (isAvailable ? (isLadies ? Colors.pink : Colors.grey[600]) : Colors.grey[400]),
                    size: 20,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: isSelected ? Colors.white : borderColor, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${_selectedSeats.length} Seats Selected', style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text('₹${_totalFare.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
          ElevatedButton(
            onPressed: _selectedSeats.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusCheckoutScreen(
                          busDetails: widget.busDetails,
                          selectedSeats: _selectedSeats,
                          sourceCity: widget.sourceCity,
                          destinationCity: widget.destinationCity,
                          doj: widget.doj,
                          boardingPoints: _layoutData?['boardingPoints'] ?? [],
                          droppingPoints: _layoutData?['droppingPoints'] ?? [],
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
