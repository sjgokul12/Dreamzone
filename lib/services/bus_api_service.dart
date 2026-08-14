import 'dart:convert';
import 'package:http/http.dart' as http;

class BusApiService {
  // Production URL — update this if your Render backend URL changes.
  static const String _productionBaseUrl = 'https://dzi-backend.onrender.com/etsAPI/api';

  // Same fallback strategy as ApiService: try local network IPs first
  // (works on Chrome web + physical phones on the same WiFi), then
  // 127.0.0.1/localhost (Chrome web on this machine), then 10.0.2.2
  // (Android emulator), then finally the production Render URL.
  

  /// Tries each candidate base URL in order for a GET request with the
  /// given path (including query string). Any HTTP response (even an
  /// error status like 500) means that base URL is reachable, so it is
  /// decoded and returned immediately — only connection-level failures
  /// (timeout, DNS error, refused) move on to the next candidate.
  static Future<Map<String, dynamic>> _get(String pathWithQuery, {int timeoutSeconds = 30}) async {
    try {
      final res = await http
          .get(Uri.parse('$_productionBaseUrl$pathWithQuery'))
          .timeout(Duration(seconds: timeoutSeconds));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  /// Same reachability logic as _get, but for POST requests.
  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body, {int timeoutSeconds = 30}) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_productionBaseUrl$path'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(Duration(seconds: timeoutSeconds));
      return json.decode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }

  // 1. Stations/City Info
  static Future<Map<String, dynamic>> getStations() async {
    return _get('/getStations');
  }

  // 2. AvailableBuses
  static Future<Map<String, dynamic>> getAvailableBuses({
    required String sourceCity,
    required String destinationCity,
    required String doj, // yyyy-MM-dd
  }) async {
    return _get(
      '/getAvailableBuses?sourceCity=${Uri.encodeComponent(sourceCity)}&destinationCity=${Uri.encodeComponent(destinationCity)}&doj=$doj',
    );
  }

  // 3. BusLayout
  static Future<Map<String, dynamic>> getBusLayout({
    required String sourceCity,
    required String destinationCity,
    required String doj,
    required int inventoryType,
    required String routeScheduleId,
  }) async {
    return _get(
      '/getBusLayout?sourceCity=${Uri.encodeComponent(sourceCity)}&destinationCity=${Uri.encodeComponent(destinationCity)}&doj=$doj&inventoryType=$inventoryType&routeScheduleId=$routeScheduleId',
    );
  }

  // 4. BlockTicket
  static Future<Map<String, dynamic>> blockTicket(Map<String, dynamic> requestBody) async {
    return _post('/blockTicket', requestBody);
  }

  // 5. Get RTC Updated Fare
  static Future<Map<String, dynamic>> getRtcUpdatedFare(String blockTicketKey) async {
    return _get('/getRtcUpdatedFare?blockTicketKey=$blockTicketKey');
  }

  // 6. Seat Booking
  static Future<Map<String, dynamic>> seatBooking(String blockTicketKey) async {
    return _get('/seatBooking?blockTicketKey=$blockTicketKey');
  }

  // 7. Get Booked Ticket
  static Future<Map<String, dynamic>> getTicketByETSTNumber(String etstNumber) async {
    return _get('/getTicketByETSTNumber?ETSTNumber=$etstNumber');
  }

  // 8. Cancel Ticket Confirmation
  static Future<Map<String, dynamic>> cancelTicketConfirmation(Map<String, dynamic> requestBody) async {
    return _post('/cancelTicketConfirmation', requestBody);
  }

  // 9. Cancel Ticket
  static Future<Map<String, dynamic>> cancelTicket(Map<String, dynamic> requestBody) async {
    return _post('/cancelTicket', requestBody);
  }

  // 10. Cancelled Buses Information API
  static Future<List<dynamic>> cancelledBusesInfo(String fromDate, String toDate) async {
    try {
      final res = await http
          .get(Uri.parse('$_productionBaseUrl/cancelledBusesInfo?fromDate=$fromDate&toDate=$toDate'))
          .timeout(const Duration(seconds: 60));
      return json.decode(res.body) as List<dynamic>;
    } catch (e) {
      throw Exception('Server unreachable: $e');
    }
  }


  // 11. MyPlan and Current Balance
  static Future<Map<String, dynamic>> getMyPlanAndBalance() async {
    return _get('/getMyPlanAndBalance');
  }
}