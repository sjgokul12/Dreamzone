import 'package:flutter/material.dart';
import 'prepaid_recharge_screen.dart';
import 'postpaid_recharge_screen.dart';

export 'prepaid_recharge_screen.dart';
export 'postpaid_recharge_screen.dart';

/// Legacy / Universal router for Mobile Recharge.
/// If `initialIsPostpaid == true`, directly renders `PostpaidRechargeScreen`.
/// Otherwise renders `PrepaidRechargeScreen`.
class RechargeScreen extends StatelessWidget {
  final bool initialIsPostpaid;

  const RechargeScreen({
    super.key,
    this.initialIsPostpaid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (initialIsPostpaid) {
      return const PostpaidRechargeScreen();
    }
    return const PrepaidRechargeScreen();
  }
}
