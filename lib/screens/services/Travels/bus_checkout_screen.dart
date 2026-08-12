import 'package:flutter/material.dart';
import '../../../services/bus_api_service.dart';

class BusCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> busDetails;
  final List<dynamic> selectedSeats;
  final String sourceCity;
  final String destinationCity;
  final String doj;
  final List<dynamic> boardingPoints;
  final List<dynamic> droppingPoints;

  const BusCheckoutScreen({
    super.key,
    required this.busDetails,
    required this.selectedSeats,
    required this.sourceCity,
    required this.destinationCity,
    required this.doj,
    required this.boardingPoints,
    required this.droppingPoints,
  });

  @override
  State<BusCheckoutScreen> createState() => _BusCheckoutScreenState();
}

class _BusCheckoutScreenState extends State<BusCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _idNumberController = TextEditingController();

  String? _selectedGender; // 'M' or 'F'
  String? _selectedIdType; // PAN, Aadhar, Passport, Voter ID, Driving License

  final List<String> _idTypes = const ['PAN', 'Aadhar', 'Passport', 'Voter ID', 'Driving License'];

  String? _selectedBoardingPoint;
  String? _selectedDroppingPoint;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBoardingPoint == null || _selectedDroppingPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select boarding and dropping points')));
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select gender')));
      return;
    }
    if (_selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an ID type')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bp = widget.boardingPoints.firstWhere((element) => element['id'] == _selectedBoardingPoint);
      final dp = widget.droppingPoints.firstWhere((element) => element['id'] == _selectedDroppingPoint);

      final List<Map<String, dynamic>> paxDetails = widget.selectedSeats.map((seat) {
        return {
          "age": _ageController.text.trim(),
          "name": _nameController.text,
          "seatNbr": seat['id'],
          "sex": _selectedGender,
          "fare": seat['fare'].toString(),
          "serviceTaxAmount": seat['serviceTaxAmount'] ?? 0,
          "operatorServiceChargeAbsolute": seat['operatorServiceChargeAbsolute'] ?? 0,
          "totalFareWithTaxes": (seat['totalFareWithTaxes'] ?? seat['fare']).toString(),
          "ladiesSeat": seat['ladiesSeat'] ?? false,
          "lastName": _lastNameController.text,
          "mobile": _phoneController.text,
          "title": _selectedGender == 'F' ? "Ms" : "Mr",
          "email": _emailController.text,
          "idType": _selectedIdType,
          "idNumber": _idNumberController.text.trim(),
          "nameOnId": _nameController.text,
          "primary": widget.selectedSeats.indexOf(seat) == 0,
          "ac": seat['ac'] ?? true,
          "sleeper": seat['sleeper'] ?? false,
        };
      }).toList();

      final request = {
        "sourceCity": widget.sourceCity,
        "destinationCity": widget.destinationCity,
        "doj": widget.doj,
        "routeScheduleId": widget.busDetails['routeScheduleId'],
        "inventoryType": widget.busDetails['inventoryType'] ?? 0,
        "customerName": _nameController.text,
        "customerLastName": _lastNameController.text,
        "customerEmail": _emailController.text,
        "customerPhone": _phoneController.text,
        "emergencyPhNumber": _phoneController.text,
        "customerAddress": _addressController.text.trim(),
        "boardingPoint": bp,
        "droppingPoint": dp,
        "blockSeatPaxDetails": paxDetails
      };

      // 1. Block Ticket
      final blockResponse = await BusApiService.blockTicket(request);
      final blockKey = blockResponse['blockTicketKey'];

      if (blockKey != null) {
        // 2. Confirm Booking
        final bookResponse = await BusApiService.seatBooking(blockKey);
        if (bookResponse['apiStatus']['success'] == true) {
          if (!mounted) return;
          _showSuccessDialog(bookResponse['etstnumber']);
        } else {
          throw Exception("Seat Booking Failed");
        }
      } else {
         throw Exception("Failed to block ticket");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String etsNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Booking Confirmed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Ticket Number: $etsNumber', style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalFare = widget.selectedSeats.fold(0, (sum, seat) => sum + ((seat['totalFareWithTaxes'] ?? seat['fare']) as num).toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle('Journey Details'),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.busDetails['operatorName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text('${widget.sourceCity} → ${widget.destinationCity}'),
                        Text('Date: ${widget.doj}'),
                        Text('Seats: ${widget.selectedSeats.map((s) => s['id']).join(', ')}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Boarding & Dropping'),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Boarding Point', border: OutlineInputBorder()),
                  items: widget.boardingPoints.map((bp) => DropdownMenuItem<String>(value: bp['id'].toString(), child: Text('${bp['location']} - ${bp['time']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedBoardingPoint = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Dropping Point', border: OutlineInputBorder()),
                  items: widget.droppingPoints.map((dp) => DropdownMenuItem<String>(value: dp['id'].toString(), child: Text('${dp['location']} - ${dp['time']}', overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setState(() => _selectedDroppingPoint = v),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle('Passenger Details'),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'First Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final age = int.tryParse(v.trim());
                          if (age == null || age <= 0 || age > 120) return 'Invalid age';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
                        initialValue: _selectedGender,
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()),
                  maxLines: 2,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'ID Type', border: OutlineInputBorder()),
                  initialValue: _selectedIdType,
                  items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _selectedIdType = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _idNumberController,
                  decoration: const InputDecoration(labelText: 'ID Number', border: OutlineInputBorder()),
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFFF5500),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Pay ₹${totalFare.toStringAsFixed(2)} & Book', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}