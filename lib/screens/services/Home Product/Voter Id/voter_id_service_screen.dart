import 'package:flutter/material.dart';
import 'new_voter/new_voter_screen.dart';
import 'correction_voter/correction_voter_screen.dart';
import 'hard_copy/hard_copy_screen.dart';
import 'soft_copy/soft_copy_screen.dart';

class VoterIdServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const VoterIdServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<VoterIdServiceScreen> createState() => _VoterIdServiceScreenState();
}

class _VoterIdServiceScreenState extends State<VoterIdServiceScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    final preId = widget.preselectedSectionId ?? 101;
    _selectedTab = (preId >= 101 && preId <= 104) ? (preId - 101) : 0;
  }

  void _onSelectTab(int index) {
    setState(() {
      _selectedTab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedTab) {
      case 0:
        return NewVoterScreen(
          key: const ValueKey('new_voter'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 1:
        return CorrectionVoterScreen(
          key: const ValueKey('correction_voter'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 2:
        return HardCopyScreen(
          key: const ValueKey('hard_copy'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 3:
        return SoftCopyScreen(
          key: const ValueKey('soft_copy'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      default:
        return NewVoterScreen(
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
    }
  }
}
