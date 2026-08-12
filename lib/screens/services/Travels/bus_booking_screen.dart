import 'package:flutter/material.dart';
import 'bus_list_screen.dart';
import '../../../services/bus_api_service.dart';

/// Travels Services List
final List<Map<String, dynamic>> travelsServicesList = [
  {
    'id': 'travel_irtc',
    'name': 'IRTC',
    'category': 'Travels',
    'asset_image': 'assets/IRCTC.png',
    'icon': 'train',
    'color': '#0284C7',
    'desc': 'Train ticket booking portal',
  },
  {
    'id': 'travel_flight',
    'name': 'Flight Booking',
    'category': 'Travels',
    'asset_image': 'assets/Flight Booking.png',
    'icon': 'flight',
    'color': '#2563EB',
    'desc': 'Domestic & international flight tickets',
  },
  {
    'id': 'travel_bus',
    'name': 'Bus booking',
    'category': 'Travels',
    'asset_image': 'assets/Bus booking.png',
    'icon': 'directions_bus',
    'color': '#EA580C',
    'desc': 'Online bus ticket reservation',
  },
];

/// Premium "Coming Soon" Modal Dialog matching User Theme
void showComingSoonDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 12,
        backgroundColor: Colors.white,
        child: Container(
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Orange Hourglass Icon Container
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E6),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: Color(0xFFFF5500),
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title: Coming Soon
              const Text(
                'Coming Soon',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF003D99),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle
              const Text(
                "We're crafting something amazing for you.\nStay tuned!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // OK Button
              SizedBox(
                width: 140,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5500),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFFFF5500).withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Standalone Responsive Bus Booking Screen
class BusBookingScreen extends StatefulWidget {
  const BusBookingScreen({super.key});

  @override
  State<BusBookingScreen> createState() => _BusBookingScreenState();
}

class _BusBookingScreenState extends State<BusBookingScreen> {
  static const Color primaryNavy = Color.fromARGB(255, 50, 199, 202);
  static const Color accentOrange = Color(0xFFFF5500);
  static const Color bgGrey = Color(0xFFF8FAFC);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color.fromARGB(255, 71, 93, 180);

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destController = TextEditingController();
  DateTime _journeyDate = DateTime.now().add(const Duration(days: 1));

  List<String> _stationList = [];
  bool _isLoadingStations = true;
  String? _stationError;

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    try {
      final data = await BusApiService.getStations();
      if (data['stationList'] != null) {
        if (mounted) {
          setState(() {
            _stationList = (data['stationList'] as List)
                .map((s) => s['stationName'].toString())
                .toList();
            _isLoadingStations = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stationError = 'Failed to load stations';
          _isLoadingStations = false;
        });
      }
    }
  }



  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _journeyDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: accentOrange,
              onPrimary: Colors.white,
              onSurface: textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _journeyDate) {
      setState(() {
        _journeyDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final isDesktop = width > 900;
    final isTablet = width > 600 && width <= 900;

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
            icon: const Icon(
              Icons.arrow_back,
              color: Color(0xFF8B5CF6),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Bus Ticket Booking',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Banner
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/Bus.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),

              // Search Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildSourceField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDestField()),
                          const SizedBox(width: 16),
                          Expanded(child: _buildDateField(context)),
                          const SizedBox(width: 16),
                          _buildSearchButton(),
                        ],
                      )
                    : Column(
                        children: [
                          _buildSourceField(),
                          const SizedBox(height: 16),
                          _buildDestField(),
                          const SizedBox(height: 16),
                          _buildDateField(context),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: _buildSearchButton(),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // Features Row
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildFeatureItem(Icons.verified_user_rounded, 'Safe & Secure', 'Your safety is\nour priority', const Color(0xFF3B82F6))),
                    Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(child: _buildFeatureItem(Icons.local_activity_rounded, 'Best Prices', 'Get the best deals\non every booking', const Color(0xFF8B5CF6))),
                    Container(height: 40, width: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(child: _buildFeatureItem(Icons.headset_mic_rounded, '24/7 Support', "We're here for you\nanytime, anywhere", const Color(0xFF8B5CF6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), height: 1.2),
        ),
      ],
    );
  }

  Widget _buildInputFieldTemplate({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildSourceField() {
    return _buildInputFieldTemplate(
      label: 'Source City',
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _sourceController.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _stationList.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          _sourceController.text = selection;
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 64),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            _sourceController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search Source City',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.location_on_outlined, color: Color(0xFF8B5CF6), size: 18),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDestField() {
    return _buildInputFieldTemplate(
      label: 'Destination City',
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: _destController.text),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _stationList.where((String option) {
            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          _destController.text = selection;
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 200, maxWidth: MediaQuery.of(context).size.width - 64),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          controller.addListener(() {
            _destController.text = controller.text;
          });
          return TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: 'Search Destination City',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.near_me_outlined, color: Color(0xFF8B5CF6), size: 18),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateField(BuildContext context) {
    final dateStr =
        '${_journeyDate.day.toString().padLeft(2, '0')}/${_journeyDate.month.toString().padLeft(2, '0')}/${_journeyDate.year}';

    return _buildInputFieldTemplate(
      label: 'Journey Date',
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                ),
              ),
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          final dateStr = '${_journeyDate.year}-${_journeyDate.month.toString().padLeft(2, '0')}-${_journeyDate.day.toString().padLeft(2, '0')}';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusListScreen(
                sourceCity: _sourceController.text,
                destinationCity: _destController.text,
                doj: dateStr,
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            const Text(
              'Search Buses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
