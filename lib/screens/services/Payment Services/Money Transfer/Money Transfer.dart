import 'package:flutter/material.dart';
import 'find_remitter/find_remitter_screen.dart';

/// Entry Screen for Money Transfer Service
/// Directs initially to FindRemitterScreen, which handles the remitter lookup
/// and then transitions cleanly to MainMoneyTransferScreen.
class MoneyTransferScreen extends StatelessWidget {
  const MoneyTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FindRemitterScreen();
  }
}
