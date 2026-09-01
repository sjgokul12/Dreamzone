import 'dart:async';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../services/bus_api_service.dart';
import '../../../services/bus_invoice_pdf_service.dart';
import '../../../core/payment/razorpay_service.dart';
import 'bus_ticket_bill_screen.dart';

class BusCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> busDetails;
  final List<dynamic> selectedSeats;
  final String sourceCity;
  final String destinationCity;
  final String doj;
  final List<dynamic> boardingPoints;
  final List<dynamic> droppingPoints;
  final String? initialBoardingPointId;
  final String? initialDroppingPointId;

  const BusCheckoutScreen({
    super.key,
    required this.busDetails,
    required this.selectedSeats,
    required this.sourceCity,
    required this.destinationCity,
    required this.doj,
    required this.boardingPoints,
    required this.droppingPoints,
    this.initialBoardingPointId,
    this.initialDroppingPointId,
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

  String? _selectedGender = 'M';
  String? _selectedIdType = 'Aadhar';

  final List<String> _idTypes = const ['Aadhar', 'PAN', 'Passport', 'Voter ID', 'Driving License'];

  String? _selectedBoardingPoint;
  String? _selectedDroppingPoint;
  bool _isLoading = false;

  // 10-minute seat hold timer
  int _secondsRemaining = 600; // 10 minutes = 600 seconds
  Timer? _holdTimer;

  final RazorpayService _razorpayService = RazorpayService();

  @override
  void initState() {
    super.initState();
    _razorpayService.init();
    _startHoldTimer();

    _selectedBoardingPoint = widget.initialBoardingPointId ??
        (widget.boardingPoints.isNotEmpty ? widget.boardingPoints.first['id']?.toString() : null);
    _selectedDroppingPoint = widget.initialDroppingPointId ??
        (widget.droppingPoints.isNotEmpty ? widget.droppingPoints.first['id']?.toString() : null);
  }

  void _startHoldTimer() {
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        if (mounted) {
          setState(() {
            _secondsRemaining--;
          });
        }
      } else {
        _holdTimer?.cancel();
        _handleHoldExpired();
      }
    });
  }

  void _handleHoldExpired() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: const [
              Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text('Seat Hold Expired', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: const Text(
            'Your 10-minute hold window for these seats has expired. The seats have been released. Please search and select your seats again.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003D99),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to bus list
              },
              child: const Text('OK, Select Seats Again'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _razorpayService.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBoardingPoint == null || _selectedDroppingPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select boarding and dropping points'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender'), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (_selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an ID type'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    double totalFare = widget.selectedSeats.fold(0.0, (sum, seat) {
      final val = seat['totalFareWithTaxes'] ?? seat['fare'] ?? 0;
      if (val is num) return sum + val.toDouble();
      return sum + (double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);
    });

    _razorpayService.openPaymentGateway(
      amount: totalFare,
      description: 'Bus Ticket: ${widget.sourceCity} to ${widget.destinationCity}',
      name: 'DZI Infinity',
      contact: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      onSuccess: (PaymentSuccessResponse response) {
        _doSubmitBooking(razorpayPaymentId: response.paymentId ?? '');
      },
      onFailure: (PaymentFailureResponse response) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
    );
  }

  Future<void> _doSubmitBooking({required String razorpayPaymentId}) async {
    setState(() => _isLoading = true);

    try {
      final bp = widget.boardingPoints.firstWhere(
        (element) => element['id'].toString() == _selectedBoardingPoint.toString(),
        orElse: () => {
          'id': _selectedBoardingPoint,
          'location': widget.sourceCity,
          'time': widget.busDetails['departureTime'] ?? '10:00 AM',
        },
      );
      final dp = widget.droppingPoints.firstWhere(
        (element) => element['id'].toString() == _selectedDroppingPoint.toString(),
        orElse: () => {
          'id': _selectedDroppingPoint,
          'location': widget.destinationCity,
          'time': widget.busDetails['arrivalTime'] ?? '06:00 PM',
        },
      );

      final List<Map<String, dynamic>> paxDetails = widget.selectedSeats.map((seat) {
        return {
          "age": _ageController.text.trim(),
          "name": _nameController.text.trim(),
          "seatNbr": seat['id']?.toString() ?? seat['seatName']?.toString() ?? '1',
          "sex": _selectedGender,
          "fare": (seat['fare'] ?? seat['totalFareWithTaxes'] ?? 0).toString(),
          "serviceTaxAmount": seat['serviceTaxAmount'] ?? 0,
          "operatorServiceChargeAbsolute": seat['operatorServiceChargeAbsolute'] ?? 0,
          "totalFareWithTaxes": (seat['totalFareWithTaxes'] ?? seat['fare']).toString(),
          "ladiesSeat": seat['ladiesSeat'] ?? false,
          "lastName": _lastNameController.text.trim(),
          "mobile": _phoneController.text.trim(),
          "title": _selectedGender == 'F' ? "Ms" : "Mr",
          "email": _emailController.text.trim(),
          "idType": _selectedIdType,
          "idNumber": _idNumberController.text.trim(),
          "nameOnId": _nameController.text.trim(),
          "primary": widget.selectedSeats.indexOf(seat) == 0,
          "ac": seat['ac'] ?? true,
          "sleeper": seat['sleeper'] ?? false,
        };
      }).toList();

      final request = {
        "sourceCity": widget.sourceCity,
        "destinationCity": widget.destinationCity,
        "doj": widget.doj,
        "routeScheduleId": widget.busDetails['routeScheduleId'] ?? '1',
        "inventoryType": widget.busDetails['inventoryType'] ?? 0,
        "customerName": _nameController.text.trim(),
        "customerLastName": _lastNameController.text.trim(),
        "customerEmail": _emailController.text.trim(),
        "customerPhone": _phoneController.text.trim(),
        "emergencyPhNumber": _phoneController.text.trim(),
        "customerAddress": _addressController.text.trim(),
        "boardingPoint": bp,
        "droppingPoint": dp,
        "blockSeatPaxDetails": paxDetails,
        "razorpayPaymentId": razorpayPaymentId,
        "paymentStatus": "paid",
      };

      // 1. Block Ticket
      final blockResponse = await BusApiService.blockTicket(request);
      final blockKey = blockResponse['blockTicketKey'];

      if (blockKey != null) {
        // 2. Confirm Booking
        final bookResponse = await BusApiService.seatBooking(blockKey);
        if (bookResponse['apiStatus']?['success'] == true || bookResponse['etstnumber'] != null) {
          _holdTimer?.cancel();

          final etsTicketNo = bookResponse['etstnumber']?.toString() ?? 'ETS${DateTime.now().millisecondsSinceEpoch}';
          final opPnr = bookResponse['opPNR']?.toString() ?? etsTicketNo;

          // Compute fare breakdown
          double totalFare = widget.selectedSeats.fold(0.0, (sum, seat) {
            final val = seat['totalFareWithTaxes'] ?? seat['fare'] ?? 0;
            if (val is num) return sum + val.toDouble();
            return sum + (double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);
          });
          double gst = totalFare * 0.05;
          double other = 0.0;
          double base = totalFare - gst;
          if (base < 0) base = totalFare;

          final now = DateTime.now();
          final formattedInvoiceDate =
              '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

          final invoice = BusInvoiceModel(
            invoiceNo: etsTicketNo,
            invoiceDate: formattedInvoiceDate,
            pnr: opPnr,
            bookingId: etsTicketNo,
            status: 'Confirmed',
            customerName: '${_nameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
            customerEmail: _emailController.text.trim(),
            customerPhone: _phoneController.text.trim(),
            fromCity: widget.sourceCity,
            toCity: widget.destinationCity,
            journeyDate: widget.doj,
            boardingPoint: bp['pointName'] ?? bp['locationName'] ?? bp['location'] ?? widget.sourceCity,
            boardingTime: bp['time'] ?? widget.busDetails['departureTime'] ?? '10:00 AM',
            droppingPoint: dp['pointName'] ?? dp['locationName'] ?? dp['location'] ?? widget.destinationCity,
            droppingTime: dp['time'] ?? widget.busDetails['arrivalTime'] ?? '06:00 PM',
            operatorName: widget.busDetails['operatorName'] ?? 'DZI Travels',
            busType: widget.busDetails['busType'] ?? 'AC Sleeper / Seater',
            passengers: paxDetails,
            baseFare: base,
            gstAmount: gst,
            otherCharges: other,
            totalAmount: totalFare,
          );

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BusTicketBillScreen(invoice: invoice),
            ),
          );
        } else {
          throw Exception(bookResponse['apiStatus']?['message'] ?? "Seat Booking Failed");
        }
      } else {
        throw Exception(blockResponse['apiStatus']?['message'] ?? "Failed to block ticket");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalFare = widget.selectedSeats.fold(0.0, (sum, seat) {
      final val = seat['totalFareWithTaxes'] ?? seat['fare'] ?? 0;
      if (val is num) return sum + val.toDouble();
      return sum + (double.tryParse(val.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0);
    });

    final isUrgent = _secondsRemaining < 120;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Review & Passenger Details',
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(color: Color(0xFF003D99)),
                  SizedBox(height: 16),
                  Text(
                    'Confirming Your Bus Ticket...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. STICKY HOLD TIMER CARD (10:00 -> 00:00)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUrgent ? const Color(0xFFFCA5A5) : const Color(0xFFBFDBFE),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF003D99),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seat Hold Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isUrgent ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                                ),
                              ),
                              const Text(
                                'Seats are reserved for 10 minutes',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF003D99),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatTimer(_secondsRemaining),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. JOURNEY DETAILS CARD
                  _buildSectionHeader('Journey Details', Icons.directions_bus_rounded),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.busDetails['operatorName'] ?? 'Bus Operator',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF003D99).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.busDetails['busType'] ?? 'AC',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF003D99)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF8B5CF6), size: 16),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.sourceCity} ➔ ${widget.destinationCity}',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Date: ${widget.doj}',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: widget.selectedSeats.map((s) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF5500).withValues(alpha: 0.1),
                                  border: Border.all(color: const Color(0xFFFF5500)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Seat: ${s['id'] ?? s['seatName']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5500)),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. BOARDING & DROPPING POINTS
                  _buildSectionHeader('Boarding & Dropping Points', Icons.pin_drop_rounded),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedBoardingPoint,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Boarding Point',
                            prefixIcon: const Icon(Icons.departure_board_rounded, color: Color(0xFF003D99), size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: widget.boardingPoints.map((bp) {
                            final title = (bp['pointName'] ?? bp['locationName'] ?? bp['location'] ?? '').toString();
                            final time = (bp['time'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: bp['id'].toString(),
                              child: Text(time.isNotEmpty ? '$title ($time)' : title, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedBoardingPoint = v),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDroppingPoint,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Dropping Point',
                            prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFEA580C), size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: widget.droppingPoints.map((dp) {
                            final title = (dp['pointName'] ?? dp['locationName'] ?? dp['location'] ?? '').toString();
                            final time = (dp['time'] ?? '').toString();
                            return DropdownMenuItem<String>(
                              value: dp['id'].toString(),
                              child: Text(time.isNotEmpty ? '$title ($time)' : title, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _selectedDroppingPoint = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. PASSENGER & CONTACT DETAILS
                  _buildSectionHeader('Passenger & Contact Details', Icons.person_rounded),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  labelText: 'First Name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText: 'Last Name',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(Icons.email_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Mobile Phone Number',
                            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().length < 10 ? 'Valid 10-digit phone required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Address',
                            prefixIcon: const Icon(Icons.home_outlined, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'ID Type',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                initialValue: _selectedIdType,
                                items: _idTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                onChanged: (v) => setState(() => _selectedIdType = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _idNumberController,
                                decoration: InputDecoration(
                                  labelText: 'ID Number',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 5. PRICE BREAKUP & PAY BUTTON
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Seats Selected:', style: TextStyle(color: Color(0xFF64748B))),
                            Text('${widget.selectedSeats.length} Seat(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
                            Text(
                              '₹${totalFare.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF003D99)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitBooking,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF5500),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFFFF5500).withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.lock_outline_rounded, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Proceed to Pay ₹${totalFare.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF003D99)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
        ],
      ),
    );
  }
}