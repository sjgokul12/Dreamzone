import 'package:flutter/material.dart';
import '../../../services/bus_api_service.dart';
import 'bus_checkout_screen.dart';

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
  String? _errorMessage;
  List<dynamic> _buses = [];

  // Filter & Sort State
  String _selectedPriceSort = 'All';
  String _selectedDepartureTime = 'All';
  final List<String> _selectedBusTypes = [];

  // Expanded bus state
  String? _expandedBusId;
  final Map<String, dynamic> _cachedLayouts = {};
  final Map<String, bool> _layoutLoading = {};
  final Map<String, List<dynamic>> _busSelectedSeats = {};
  final Map<String, int> _busActiveTab = {}; // 0 = Select Seats, 1 = Boarding & Dropping
  final Map<String, int> _busActiveDeck = {}; // 0 = Lower Deck, 1 = Upper Deck
  final Map<String, dynamic> _busSelectedBoarding = {};
  final Map<String, dynamic> _busSelectedDropping = {};

  @override
  void initState() {
    super.initState();
    _fetchBuses();
  }

  Future<void> _fetchBuses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await BusApiService.getAvailableBuses(
        sourceCity: widget.sourceCity,
        destinationCity: widget.destinationCity,
        doj: widget.doj,
      );

      List<dynamic> parsedList = [];
      for (var key in [
        'apiAvailableBuses',
        'availableBuses',
        'apiAvailableBusList',
        'busList',
        'buses',
        'data',
        'apiAvailableBus'
      ]) {
        if (data[key] != null) {
          if (data[key] is List) {
            parsedList = List<dynamic>.from(data[key]);
            break;
          } else if (data[key] is Map) {
            parsedList = [data[key]];
            break;
          }
        }
      }

      if (parsedList.isEmpty) {
        for (var entry in data.entries) {
          if (entry.value is List &&
              (entry.value as List).isNotEmpty &&
              (entry.value as List).first is Map) {
            parsedList = List<dynamic>.from(entry.value);
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _buses = parsedList;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load buses: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBusLayout(dynamic bus) async {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    if (busId.isEmpty || _cachedLayouts.containsKey(busId)) return;

    setState(() {
      _layoutLoading[busId] = true;
    });

    try {
      final data = await BusApiService.getBusLayout(
        sourceCity: widget.sourceCity,
        destinationCity: widget.destinationCity,
        doj: widget.doj,
        inventoryType: bus['inventoryType'] ?? 0,
        routeScheduleId: busId,
      );

      if (mounted) {
        setState(() {
          _cachedLayouts[busId] = data;
          _layoutLoading[busId] = false;

          final bpList = (data['boardingPoints'] as List?) ?? [];
          final dpList = (data['droppingPoints'] as List?) ?? [];
          if (bpList.isNotEmpty && _busSelectedBoarding[busId] == null) {
            _busSelectedBoarding[busId] = bpList.first;
          }
          if (dpList.isNotEmpty && _busSelectedDropping[busId] == null) {
            _busSelectedDropping[busId] = dpList.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _layoutLoading[busId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seats: $e')),
        );
      }
    }
  }

  void _toggleBusExpansion(dynamic bus) {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    setState(() {
      if (_expandedBusId == busId) {
        _expandedBusId = null;
      } else {
        _expandedBusId = busId;
        _busActiveTab[busId] = _busActiveTab[busId] ?? 0;
        _busActiveDeck[busId] = 0;
        _busSelectedSeats[busId] = _busSelectedSeats[busId] ?? [];
      }
    });

    if (_expandedBusId == busId) {
      _loadBusLayout(bus);
    }
  }

  void _toggleSeatSelection(String busId, dynamic seat) {
    if (seat['available'] != true) return;

    setState(() {
      _busSelectedSeats[busId] = _busSelectedSeats[busId] ?? [];
      final list = _busSelectedSeats[busId]!;
      final isSelected = list.any((s) => s['id'] == seat['id']);

      if (isSelected) {
        list.removeWhere((s) => s['id'] == seat['id']);
      } else {
        if (list.length >= 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 6 seats allowed per booking.')),
          );
          return;
        }
        list.add(seat);
      }
    });
  }

  double _getBusTotalFare(String busId) {
    final seats = _busSelectedSeats[busId] ?? [];
    double total = 0;
    for (var seat in seats) {
      final fareVal = seat['fare'] ?? seat['totalFareWithTaxes'] ?? 0;
      if (fareVal is num) {
        total += fareVal.toDouble();
      } else {
        total += double.tryParse(fareVal.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
      }
    }
    return total;
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      String cleanTime = timeString.toUpperCase().trim();
      final bool isPM = cleanTime.contains('PM');
      final bool isAM = cleanTime.contains('AM');
      cleanTime = cleanTime
          .replaceAll(RegExp(r'\([^)]*\)'), '')
          .replaceAll('AM', '')
          .replaceAll('PM', '')
          .trim();
      List<String> parts = cleanTime.split(':');
      if (parts.length < 2) return null;
      int hour = int.parse(parts[0].trim());
      int minute = int.parse(parts[1].trim().split(RegExp(r'\s+'))[0]);

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
    List<dynamic> filtered = _buses.where((bus) {
      if (bus is! Map) return false;

      if (_selectedDepartureTime != 'All') {
        final timeStr = bus['departureTime']?.toString();
        if (!_matchesTime(timeStr, _selectedDepartureTime)) return false;
      }

      if (_selectedBusTypes.isNotEmpty) {
        final bType = bus['busType']?.toString().toLowerCase() ?? '';
        bool matchesType = false;
        for (final t in _selectedBusTypes) {
          final cleanT = t.toLowerCase().replaceAll(' ', '');
          if (bType.replaceAll(' ', '').contains(cleanT)) {
            matchesType = true;
            break;
          }
        }
        if (!matchesType) return false;
      }
      return true;
    }).toList();

    if (_selectedPriceSort == 'Low to High') {
      filtered.sort((a, b) => _parsePrice(a['fare']).compareTo(_parsePrice(b['fare'])));
    } else if (_selectedPriceSort == 'High to Low') {
      filtered.sort((a, b) => _parsePrice(b['fare']).compareTo(_parsePrice(a['fare'])));
    }

    return filtered;
  }

  String _formatDuration(dynamic bus) {
    if (bus['duration'] != null && bus['duration'].toString().trim().isNotEmpty) {
      return bus['duration'].toString().toUpperCase();
    }
    final mins = bus['durationInMins'];
    if (mins != null && mins is num && mins > 0) {
      final h = mins ~/ 60;
      final m = mins % 60;
      return '${h}H ${m}M';
    }
    final dep = _parseTime(bus['departureTime']?.toString() ?? '');
    final arr = _parseTime(bus['arrivalTime']?.toString() ?? bus['dpTimeDate']?.toString() ?? '');
    if (dep != null && arr != null) {
      int depMins = dep.hour * 60 + dep.minute;
      int arrMins = arr.hour * 60 + arr.minute;
      if (arrMins < depMins) arrMins += 24 * 60;
      final diff = arrMins - depMins;
      return '${diff ~/ 60}H ${diff % 60}M';
    }
    return '4H 40M';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(widget.doj, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildDropdown('PRICE', _selectedPriceSort, ['All', 'Low to High', 'High to Low'], (v) => setState(() => _selectedPriceSort = v!)),
                  const SizedBox(width: 10),
                  _buildDropdown('DEPARTURE TIME', _selectedDepartureTime, ['All', 'Morning', 'Afternoon', 'Evening', 'Night'], (v) => setState(() => _selectedDepartureTime = v!)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('BUS TYPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBusTypePill('AC Sleeper'),
                          const SizedBox(width: 6),
                          _buildBusTypePill('Non AC Sleeper'),
                          const SizedBox(width: 6),
                          _buildBusTypePill('AC Semi Sleeper'),
                          const SizedBox(width: 6),
                          _buildBusTypePill('Non AC Semi Sleeper'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedPriceSort = 'All';
                          _selectedDepartureTime = 'All';
                          _selectedBusTypes.clear();
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF0F172A)),
                      label: const Text('Clear', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          // Bus List Body
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchBuses,
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filteredBuses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.directions_bus_filled_outlined, size: 48, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 14),
                                Text(
                                  _buses.isEmpty ? 'No buses found for this route.' : 'No buses match your filters.',
                                  style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            physics: const BouncingScrollPhysics(),
                            itemCount: filteredBuses.length,
                            itemBuilder: (context, index) {
                              final bus = filteredBuses[index];
                              return _buildBusCardItem(bus);
                            },
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
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF64748B)),
              items: options.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))))).toList(),
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
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? Colors.black : Colors.transparent),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildBusCardItem(dynamic bus) {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    final isExpanded = _expandedBusId == busId;
    final operatorName = (bus['operatorName'] ?? bus['travelsName'] ?? bus['operator'] ?? 'Bus Operator').toString();
    final busType = (bus['busType'] ?? bus['busTypeName'] ?? bus['category'] ?? '').toString().trim();
    
    final rawSeats = bus['availableSeats'] ?? bus['seatsAvailable'] ?? bus['availableSeatCount'];
    final seatsLeft = (rawSeats != null && rawSeats.toString() != '0') ? '$rawSeats Seats left' : 'Seats available';
    
    final depTime = (bus['departureTime'] ?? bus['depTime'] ?? '--:--').toString();

    String arrTime = (bus['arrivalTime'] ?? bus['arrTime'] ?? '').toString();
    if (arrTime.isEmpty || arrTime == '--:--') {
      if (bus['dpTimeDate'] != null) {
        final dp = bus['dpTimeDate'].toString().trim();
        final match = RegExp(r'\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)').firstMatch(dp);
        if (match != null) {
          arrTime = match.group(0)!;
        } else {
          arrTime = dp;
        }
      } else if (bus['droppingPoints'] is List && (bus['droppingPoints'] as List).isNotEmpty) {
        arrTime = bus['droppingPoints'].last['time']?.toString() ?? '--:--';
      } else {
        arrTime = '--:--';
      }
    }
    final durationStr = _formatDuration(bus);

    final rawFare = bus['fare'] ?? bus['fares'] ?? bus['totalFare'] ?? bus['baseFare'] ?? '0';
    final fareStr = rawFare.toString().split(',').first.replaceAll(RegExp(r'[^0-9.]'), '');

    // Rating & Review Count (prioritize API data, fallback to dynamic operator-based values)
    final apiRating = bus['rating'] ?? bus['avgRating'] ?? bus['starRating'] ?? bus['busRating'];
    final apiReviews = bus['totalRatings'] ?? bus['reviewCount'] ?? bus['ratingsCount'] ?? bus['reviews'];
    
    final String ratingVal = (apiRating != null && apiRating.toString().isNotEmpty)
        ? apiRating.toString()
        : (4.1 + (((operatorName + busId).hashCode.abs() % 8) / 10.0)).toStringAsFixed(1);
        
    final String reviewCount = (apiReviews != null && apiReviews.toString().isNotEmpty)
        ? apiReviews.toString()
        : (180 + ((operatorName + busId).hashCode.abs() % 720)).toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 14, right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Operator Name + Rating Badge + Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Operator name & Type
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                operatorName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '($seatsLeft)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          if (busType.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              busType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Compact Two-Tier Rating Badge
                    Container(
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D783E),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, color: Colors.white, size: 9.5),
                                const SizedBox(width: 2.5),
                                Text(
                                  ratingVal,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, bottom: 1),
                            child: Text(
                              reviewCount,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1E293B),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'From',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '₹$fareStr',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Middle Row: Departure, Timeline Connector, Arrival
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Departure
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          depTime,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.sourceCity,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 10),

                    // Timeline (• ── 4H 40M ── ○)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            durationStr,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 1.5,
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Arrival
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          arrTime,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.destinationCity,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Row: Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildDetailsButton(bus),
                    const SizedBox(width: 8),
                    _buildViewSeatsButton(bus, isExpanded),
                  ],
                ),
              ],
            ),
          ),

          // Inline Expanded Section
          if (isExpanded) _buildExpandedBusContent(bus),
        ],
      ),
    );
  }

  Widget _buildDetailsButton(dynamic bus) {
    return InkWell(
      onTap: () => _showBusDetailsBottomSheet(bus),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Details',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF0F172A)),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSeatsButton(dynamic bus, bool isExpanded) {
    return ElevatedButton(
      onPressed: () => _toggleBusExpansion(bus),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        isExpanded ? 'Hide Seats' : 'View Seats',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildExpandedBusContent(dynamic bus) {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    final isLoading = _layoutLoading[busId] == true;
    final layoutData = _cachedLayouts[busId];
    final activeTab = _busActiveTab[busId] ?? 0;

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: isLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: Colors.black),
                    SizedBox(height: 12),
                    Text(
                      'Loading seats & boarding points...',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          : layoutData == null
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Unable to load seat layout. Please try again.')),
                )
              : Column(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _busActiveTab[busId] = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: activeTab == 0 ? Colors.black : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (activeTab == 0)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.check_circle, size: 15, color: Colors.black),
                                      ),
                                    Text(
                                      'Select Seats',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: activeTab == 0 ? FontWeight.w800 : FontWeight.w600,
                                        color: activeTab == 0 ? Colors.black : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _busActiveTab[busId] = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: activeTab == 1 ? Colors.black : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (activeTab == 1)
                                      const Padding(
                                        padding: EdgeInsets.only(right: 6),
                                        child: Icon(Icons.check_circle, size: 15, color: Colors.black),
                                      ),
                                    Text(
                                      'Boarding & Dropping',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: activeTab == 1 ? FontWeight.w800 : FontWeight.w600,
                                        color: activeTab == 1 ? Colors.black : const Color(0xFF64748B),
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
                    activeTab == 0
                        ? _buildSeatsTabContent(bus, layoutData)
                        : _buildBoardingDroppingTabContent(bus, layoutData),
                  ],
                ),
    );
  }

  Widget _buildSeatsTabContent(dynamic bus, Map<String, dynamic> layoutData) {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    final seats = (layoutData['seats'] as List?) ?? [];
    final selectedSeats = _busSelectedSeats[busId] ?? [];
    final totalFare = _getBusTotalFare(busId);
    final hasUpperDeck = seats.any((s) => (s['zIndex'] ?? 0) == 1);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Column(
      children: [
        const SizedBox(height: 14),
        _buildLegendBar(),
        const SizedBox(height: 16),

        if (hasUpperDeck && !isWide) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDeckSwitchButton(busId, 0, 'Lower Deck'),
                const SizedBox(width: 10),
                _buildDeckSwitchButton(busId, 1, 'Upper Deck'),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (isWide) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeckCapsule(
                  title: 'Lower Deck',
                  deckSeats: seats.where((s) => (s['zIndex'] ?? 0) == 0).toList(),
                  busId: busId,
                  showSteering: true,
                ),
                if (hasUpperDeck) ...[
                  const SizedBox(width: 24),
                  _buildDeckCapsule(
                    title: 'Upper Deck',
                    deckSeats: seats.where((s) => (s['zIndex'] ?? 0) == 1).toList(),
                    busId: busId,
                    showSteering: false,
                  ),
                ],
              ],
            ),
          ),
        ] else ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDeckCapsule(
                title: (_busActiveDeck[busId] ?? 0) == 1 ? 'Upper Deck' : 'Lower Deck',
                deckSeats: seats.where((s) => (s['zIndex'] ?? 0) == (_busActiveDeck[busId] ?? 0)).toList(),
                busId: busId,
                showSteering: (_busActiveDeck[busId] ?? 0) == 0,
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        _buildBottomSelectionBar(
          bus: bus,
          selectedSeats: selectedSeats,
          totalFare: totalFare,
          onActionPressed: () {
            if (selectedSeats.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least 1 seat')),
              );
              return;
            }
            setState(() {
              _busActiveTab[busId] = 1;
            });
          },
          actionLabel: 'Select Points',
        ),
      ],
    );
  }

  Widget _buildDeckSwitchButton(String busId, int deckIndex, String title) {
    final isSelected = (_busActiveDeck[busId] ?? 0) == deckIndex;
    return GestureDetector(
      onTap: () => setState(() => _busActiveDeck[busId] = deckIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Available', Colors.white, const Color(0xFFCBD5E1)),
          const SizedBox(width: 14),
          _buildLegendItem('Booked', const Color(0xFFE2E8F0), const Color(0xFFE2E8F0)),
          const SizedBox(width: 14),
          _buildLegendItem('Selected', Colors.black, Colors.black),
          const SizedBox(width: 14),
          _buildLegendItem('Ladies', Colors.white, const Color(0xFFE11D48), borderWidth: 1.5),
          const SizedBox(width: 14),
          _buildLegendItem('Gents', Colors.white, const Color(0xFF2563EB), borderWidth: 1.5),
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
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildDeckCapsule({
    required String title,
    required List<dynamic> deckSeats,
    required String busId,
    required bool showSteering,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showSteering)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12, right: 4),
                    child: _buildSteeringWheelIcon(),
                  ),
                )
              else
                const SizedBox(height: 28),

              _buildDeckSeatGrid(deckSeats, busId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSteeringWheelIcon() {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.8),
      ),
      child: Center(
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: Center(
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeckSeatGrid(List<dynamic> deckSeats, String busId) {
    if (deckSeats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text('No seats on this deck', style: TextStyle(color: Color(0xFF94A3B8))),
      );
    }

    final uniqueCols = deckSeats.map((s) => (s['column'] as num?)?.toInt() ?? 0).toSet().toList()..sort();
    final uniqueRows = deckSeats.map((s) => (s['row'] as num?)?.toInt() ?? 0).toSet().toList()..sort();

    // The larger dimension is the length along the bus (front to back)
    final bool colIsLength = uniqueCols.length >= uniqueRows.length;
    final List<int> lengthSteps = colIsLength ? uniqueCols : uniqueRows;
    final int minAcross = colIsLength ? uniqueRows.first : uniqueCols.first;
    final int maxAcross = colIsLength ? uniqueRows.last : uniqueCols.last;

    final hasSleeper = deckSeats.any((s) => s['sleeper'] == true || s['length'] == 2 || s['width'] == 2);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < lengthSteps.length; i++) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int a = minAcross; a <= maxAcross; a++) ...[
                _buildSeatWidget(
                  deckSeats.firstWhere(
                    (s) {
                      final cVal = (colIsLength ? s['column'] : s['row']) as num?;
                      final aVal = (colIsLength ? s['row'] : s['column']) as num?;
                      return (cVal?.toInt() ?? -1) == lengthSteps[i] && (aVal?.toInt() ?? -1) == a;
                    },
                    orElse: () => null,
                  ),
                  busId,
                  hasSleeper: hasSleeper,
                ),
                if (a < maxAcross) const SizedBox(width: 5),
              ],
            ],
          ),
          if (i < lengthSteps.length - 1) const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildSeatWidget(dynamic seat, String busId, {bool hasSleeper = false}) {
    final double width = 38;
    final bool isThisSeatSleeper = seat != null && (seat['sleeper'] == true || seat['length'] == 2 || seat['width'] == 2);
    final double height = (isThisSeatSleeper || hasSleeper) ? 58 : 38;

    if (seat == null) {
      return SizedBox(width: width, height: height);
    }

    final selectedSeats = _busSelectedSeats[busId] ?? [];
    final bool isSelected = selectedSeats.any((s) => s['id'] == seat['id']);
    final bool isAvailable = seat['available'] == true;
    final bool isLadies = seat['ladiesSeat'] == true;
    final bool isGents = seat['malesSeat'] == true || seat['isGents'] == true;

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
      borderColor = const Color(0xFFE11D48);
      textColor = const Color(0xFFE11D48);
    } else if (isGents) {
      bgColor = Colors.white;
      borderColor = const Color(0xFF2563EB);
      textColor = const Color(0xFF2563EB);
    }

    return GestureDetector(
      onTap: () => _toggleSeatSelection(busId, seat),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: (isSelected || (isAvailable && (isLadies || isGents))) ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: !isAvailable
              ? const Text(
                  'x',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                )
              : Text(
                  fareText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.3,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBoardingDroppingTabContent(dynamic bus, Map<String, dynamic> layoutData) {
    final busId = (bus['routeScheduleId'] ?? bus['id'] ?? '').toString();
    final boardingPoints = (layoutData['boardingPoints'] as List?) ?? [];
    final droppingPoints = (layoutData['droppingPoints'] as List?) ?? [];
    final selectedSeats = _busSelectedSeats[busId] ?? [];
    final totalFare = _getBusTotalFare(busId);
    final selectedBp = _busSelectedBoarding[busId];
    final selectedDp = _busSelectedDropping[busId];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Boarding Point',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (boardingPoints.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No boarding points available', style: TextStyle(color: Color(0xFF94A3B8))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: boardingPoints.length,
            itemBuilder: (context, index) {
              final bp = boardingPoints[index];
              final isChosen = selectedBp != null && selectedBp['id'] == bp['id'];
              final pointTitle = (bp['pointName'] ?? bp['location'] ?? '').toString();
              final pointSub = (bp['landmark'] ?? bp['landMark'] ?? bp['address'] ?? '').toString();
              return _buildPointItemCard(
                title: pointTitle.isNotEmpty ? pointTitle : 'Boarding Point',
                subtitle: pointSub,
                time: bp['time']?.toString() ?? '',
                isSelected: isChosen,
                onTap: () => setState(() => _busSelectedBoarding[busId] = bp),
              );
            },
          ),

        const SizedBox(height: 18),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Dropping Point',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 8),

        if (droppingPoints.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No dropping points available', style: TextStyle(color: Color(0xFF94A3B8))),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: droppingPoints.length,
            itemBuilder: (context, index) {
              final dp = droppingPoints[index];
              final isChosen = selectedDp != null && selectedDp['id'] == dp['id'];
              final pointTitle = (dp['pointName'] ?? dp['location'] ?? '').toString();
              final pointSub = (dp['landmark'] ?? dp['landMark'] ?? dp['address'] ?? '').toString();
              return _buildPointItemCard(
                title: pointTitle.isNotEmpty ? pointTitle : 'Dropping Point',
                subtitle: pointSub,
                time: dp['time']?.toString() ?? '',
                isSelected: isChosen,
                onTap: () => setState(() => _busSelectedDropping[busId] = dp),
              );
            },
          ),

        const SizedBox(height: 20),

        _buildBottomSelectionBar(
          bus: bus,
          selectedSeats: selectedSeats,
          totalFare: totalFare,
          onActionPressed: () {
            if (selectedSeats.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select at least 1 seat first')),
              );
              return;
            }
            if (_busSelectedBoarding[busId] == null || _busSelectedDropping[busId] == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please select both boarding and dropping points')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusCheckoutScreen(
                  busDetails: bus,
                  selectedSeats: selectedSeats,
                  sourceCity: widget.sourceCity,
                  destinationCity: widget.destinationCity,
                  doj: widget.doj,
                  boardingPoints: boardingPoints,
                  droppingPoints: droppingPoints,
                  initialBoardingPointId: _busSelectedBoarding[busId]?['id']?.toString(),
                  initialDroppingPointId: _busSelectedDropping[busId]?['id']?.toString(),
                ),
              ),
            );
          },
          actionLabel: 'Proceed to Book',
        ),
      ],
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (time.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF334155),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSelectionBar({
    required dynamic bus,
    required List<dynamic> selectedSeats,
    required double totalFare,
    required VoidCallback onActionPressed,
    required String actionLabel,
  }) {
    final seatCount = selectedSeats.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                '₹${totalFare.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const Text(
                '(Tax Excluded)',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 24,
            color: const Color(0xFFE2E8F0),
          ),
          const SizedBox(width: 12),
          Text(
            '$seatCount ${seatCount == 1 ? 'Seat' : 'Seats'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: onActionPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBusDetailsBottomSheet(dynamic bus) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      (bus['operatorName'] ?? bus['travelsName'] ?? 'Bus Details').toString(),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                bus['busType'] ?? '',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
              const Divider(height: 28),
              const Text('Amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildAmenityBadge(Icons.ac_unit, 'Air Conditioned'),
                  _buildAmenityBadge(Icons.power, 'Charging Point'),
                  _buildAmenityBadge(Icons.wifi, 'Free Wi-Fi'),
                  _buildAmenityBadge(Icons.local_drink, 'Water Bottle'),
                  _buildAmenityBadge(Icons.light_mode_outlined, 'Reading Light'),
                  _buildAmenityBadge(Icons.airline_seat_recline_extra, 'Emergency Exit'),
                ],
              ),
              const Divider(height: 28),
              const Text('Cancellation Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text(
                '• 0-12 hours before departure: No refund\n• 12-24 hours before departure: 50% refund\n• > 24 hours before departure: 90% refund',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmenityBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF334155)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }
}
