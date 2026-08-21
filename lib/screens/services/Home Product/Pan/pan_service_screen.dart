import 'package:flutter/material.dart';
import 'new_pan/new_pan_screen.dart';
import 'correction_pan/correction_pan_screen.dart';
import 'foreign_pan/foreign_pan_screen.dart';
import 'find_pan/find_pan_screen.dart';

export 'new_pan/new_pan_screen.dart' show NewPanScreen;
export 'correction_pan/correction_pan_screen.dart' show CorrectionPanScreen;
export 'foreign_pan/foreign_pan_screen.dart' show ForeignPanScreen;
export 'find_pan/find_pan_screen.dart' show FindPanScreen;

/// Main PAN Service screen router that seamlessly delegates to individual
/// service screens (New PAN, Correction PAN, Foreign PAN, Find PAN).
class PanServiceScreen extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isGuest;
  final int? preselectedSectionId;
  final Map<String, dynamic>? preselectedSectionData;

  const PanServiceScreen({
    super.key,
    required this.service,
    this.isGuest = false,
    this.preselectedSectionId,
    this.preselectedSectionData,
  });

  @override
  State<PanServiceScreen> createState() => _PanServiceScreenState();
}

class _PanServiceScreenState extends State<PanServiceScreen> {
  late int _selectedTabIndex;

  @override
  void initState() {
    super.initState();
    // Default routing: 201 -> New PAN (0), 202 -> Correction PAN (1), 203 -> Foreign (2), 204 -> Find PAN (3)
    final secId = widget.preselectedSectionId ?? 201;
    if (secId == 201) {
      _selectedTabIndex = 0;
    } else if (secId == 202) {
      _selectedTabIndex = 1;
    } else if (secId == 203) {
      _selectedTabIndex = 2;
    } else if (secId == 204) {
      _selectedTabIndex = 3;
    } else {
      _selectedTabIndex = 0;
    }
  }

  void _onSelectTab(int index) {
    if (_selectedTabIndex != index) {
      setState(() {
        _selectedTabIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_selectedTabIndex) {
      case 0:
        return NewPanScreen(
          key: const ValueKey('new_pan_screen'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 1:
        return CorrectionPanScreen(
          key: const ValueKey('correction_pan_screen'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 2:
        return ForeignPanScreen(
          key: const ValueKey('foreign_pan_screen'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      case 3:
        return FindPanScreen(
          key: const ValueKey('find_pan_screen'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
      default:
        return NewPanScreen(
          key: const ValueKey('new_pan_screen_default'),
          service: widget.service,
          isGuest: widget.isGuest,
          onSelectTab: _onSelectTab,
        );
    }
  }
}
