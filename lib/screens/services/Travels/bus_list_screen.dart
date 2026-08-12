import 'package:flutter/material.dart';
import '../../../services/bus_api_service.dart';
import 'bus_seat_layout_screen.dart';

class BusListScreen extends StatefulWidget {
  final String sourceCity;
  final String destinationCity;
  final String doj;

  const BusListScreen({
    super.key,
    required this.sourceCity,
    required this.destinationCity,
    required this.doj,
  });

  @override
  State<BusListScreen> createState() => _BusListScreenState();
}

class _BusListScreenState extends State<BusListScreen> {
  bool _isLoading = true;
  List<dynamic> _buses = [];

  // Filter & Sort State
  String _selectedPriceSort = 'All'; // 'All', 'Low to High', 'High to Low'
  String _selectedDepartureTime = 'All'; // 'All', 'Morning', 'Afternoon', 'Evening', 'Night'
  final List<String> _selectedBusTypes = [];

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    try {
      final data = await BusApiService.getAvailableBuses(
        sourceCity: widget.sourceCity,
        destinationCity: widget.destinationCity,
        doj: widget.doj,
      );
      setState(() {
        _buses = data['apiAvailableBuses'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      String cleanTime = timeString.toUpperCase().trim();
      final bool isPM = cleanTime.contains('PM');
      final bool isAM = cleanTime.contains('AM');
      cleanTime = cleanTime.replaceAll('AM', '').replaceAll('PM', '').trim();
      List<String> parts = cleanTime.split(':');
      if (parts.length != 2) return null;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);

      if (isPM && hour != 12) hour += 12;
      if (isAM && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  bool _matchesTime(String? timeStr, String filter) {
    if (filter == 'All' || timeStr == null || timeStr.isEmpty) return true;
    final time = _parseTime(timeStr);
    if (time == null) return true;

    final h = time.hour;
    if (filter == 'Morning') return h >= 6 && h < 12;
    if (filter == 'Afternoon') return h >= 12 && h < 17;
    if (filter == 'Evening') return h >= 17 && h < 21;
    if (filter == 'Night') return h >= 21 || h < 6;
    return true;
  }

  double _parsePrice(dynamic fare) {
    if (fare == null) return 0.0;
    try {
      final s = fare.toString().split(',').first.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.parse(s);
    } catch (_) {
      return 0.0;
    }
  }

  List<dynamic> _getFilteredBuses() {
    // 1. Filter
    List<dynamic> filtered = _buses.where((bus) {
      // Time Filter
      final timeStr = bus['departureTime']?.toString();
      if (!_matchesTime(timeStr, _selectedDepartureTime)) return false;

      // Bus Type Filter
      if (_selectedBusTypes.isNotEmpty) {
        final bType = bus['busType']?.toString().toLowerCase() ?? '';
        bool matchesType = false;
        for (final t in _selectedBusTypes) {
          if (bType.contains(t.toLowerCase().replaceAll(' ', ''))) {
            matchesType = true;
            break;
          }
        }
        // Fallback for more literal matches if space stripped doesn't work well
        if (!matchesType) {
            for (final t in _selectedBusTypes) {
                if (bType.contains(t.toLowerCase())) {
                    matchesType = true;
                    break;
                }
            }
        }
        if (!matchesType) return false;
      }
      return true;
    }).toList();

    // 2. Sort
    if (_selectedPriceSort == 'Low to High') {
      filtered.sort((a, b) => _parsePrice(a['fare']).compareTo(_parsePrice(b['fare'])));
    } else if (_selectedPriceSort == 'High to Low') {
      filtered.sort((a, b) => _parsePrice(b['fare']).compareTo(_parsePrice(a['fare'])));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredBuses = _getFilteredBuses();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF8B5CF6), size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          children: [
            Text(
              '${widget.sourceCity} to ${widget.destinationCity}',
              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(widget.doj, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Sticky Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildDropdown('PRICE', _selectedPriceSort, ['All', 'Low to High', 'High to Low'], (v) => setState(() => _selectedPriceSort = v!)),
                  const SizedBox(width: 16),
                  _buildDropdown('DEPARTURE TIME', _selectedDepartureTime, ['All', 'Morning', 'Afternoon', 'Evening', 'Night'], (v) => setState(() => _selectedDepartureTime = v!)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUS TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBusTypePill('AC Sleeper'),
                          const SizedBox(width: 8),
                          _buildBusTypePill('Non AC Sleeper'),
                          const SizedBox(width: 8),
                          _buildBusTypePill('AC Semi Sleeper'),
                          const SizedBox(width: 8),
                          _buildBusTypePill('Non AC Semi Sleeper'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 38,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPriceSort = 'All';
                          _selectedDepartureTime = 'All';
                          _selectedBusTypes.clear();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 16, color: Color(0xFF1E293B)),
                      label: const Text('Clear', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bus List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : filteredBuses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.directions_bus_filled_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              _buses.isEmpty ? 'No buses found for this route.' : 'No buses match your filters.',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredBuses.length,
                        itemBuilder: (context, index) {
                          final bus = filteredBuses[index];
                          return _buildBusCard(bus);
                        },
                      ),
          ),

          // Sticky Bottom "Safe & Secure Booking" Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_outlined, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Safe & Secure Booking',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.lock_outline, color: Colors.white, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusTypePill(String type) {
    final isSelected = _selectedBusTypes.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedBusTypes.remove(type);
          } else {
            _selectedBusTypes.add(type);
          }
        });
      },
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6).withValues(alpha: 0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(dynamic bus) {
    // Generate an operator initial
    String operatorInit = 'B';
    final opName = bus['operatorName']?.toString() ?? '';
    if (opName.isNotEmpty) {
      operatorInit = opName.trim().substring(0, 1).toUpperCase();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Logo, Name, Type, Rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo Placeholder
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      operatorInit,
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus['operatorName'] ?? 'Unknown Operator',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bus['busType'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Rating Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('4.5', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Timeline row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bus['departureTime'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.sourceCity,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      Text(
                        '${(bus['durationInMins'] ?? 0) ~/ 60}h ${(bus['durationInMins'] ?? 0) % 60}m',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFFF3B30), fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: Container(height: 1, color: Colors.grey.withValues(alpha: 0.3))),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFFF3B30).withValues(alpha: 0.5)),
                            ),
                            child: const Icon(Icons.directions_bus_filled_outlined, color: Color(0xFFFF3B30), size: 12),
                          ),
                          Expanded(child: Container(height: 1, color: Colors.grey.withValues(alpha: 0.3))),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        bus['arrivalTime'] ?? '',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.destinationCity,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Price and Button
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${(bus['fare'] ?? '0').toString().split(',').first}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BusSeatLayoutScreen(
                                  busDetails: bus,
                                  sourceCity: widget.sourceCity,
                                  destinationCity: widget.destinationCity,
                                  doj: widget.doj,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B30),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Select Seats', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            
            // Bottom row: Amenities & Seats
            Row(
              children: [
                const Icon(Icons.airline_seat_recline_extra, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                const Text('2+1', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(width: 12),
                Container(width: 1, height: 12, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                const Icon(Icons.ac_unit, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Icon(Icons.local_drink, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Icon(Icons.electrical_services, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Icon(Icons.wifi, size: 16, color: Color(0xFF64748B)),
                const Spacer(),
                Container(width: 1, height: 12, color: Colors.grey.withValues(alpha: 0.3)),
                const SizedBox(width: 12),
                const Icon(Icons.event_seat, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  '${bus['availableSeats']} Seats Left',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
