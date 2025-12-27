import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../services/timezone_service.dart';

class TimezonePickerDialog extends StatefulWidget {
  final String? currentTimezone;
  final ValueChanged<String> onTimezoneSelected;

  const TimezonePickerDialog({
    super.key,
    this.currentTimezone,
    required this.onTimezoneSelected,
  });

  /// Show the timezone picker as a bottom sheet
  static Future<String?> show(BuildContext context, {String? currentTimezone}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TimezonePickerSheet(currentTimezone: currentTimezone),
    );
  }

  /// Show as a blocking dialog that requires timezone selection
  static Future<String?> showRequired(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _RequiredTimezoneDialog(),
    );
  }

  @override
  State<TimezonePickerDialog> createState() => _TimezonePickerDialogState();
}

class _TimezonePickerDialogState extends State<TimezonePickerDialog> {
  final _searchController = TextEditingController();
  List<String> _filteredTimezones = [];

  @override
  void initState() {
    super.initState();
    _filteredTimezones = TimezoneService.commonTimezones;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTimezones(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTimezones = TimezoneService.commonTimezones;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTimezones = TimezoneService.commonTimezones.where((tz) {
          final displayName = TimezoneService.getDisplayName(tz).toLowerCase();
          return displayName.contains(lowerQuery) || tz.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.schedule, color: AppTheme.leafGreen),
          const SizedBox(width: 12),
          Text(
            'Select Timezone',
            style: GoogleFonts.comfortaa(
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterTimezones,
              decoration: InputDecoration(
                hintText: 'Search timezone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTimezones.length,
                itemBuilder: (ctx, index) {
                  final tz = _filteredTimezones[index];
                  final isSelected = tz == widget.currentTimezone;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.access_time,
                      color: isSelected ? AppTheme.leafGreen : AppTheme.soilBrown.withValues(alpha: 0.5),
                    ),
                    title: Text(
                      TimezoneService.getDisplayName(tz),
                      style: GoogleFonts.quicksand(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppTheme.leafGreen : AppTheme.soilBrown,
                      ),
                    ),
                    subtitle: Text(
                      tz,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                    selected: isSelected,
                    onTap: () {
                      widget.onTimezoneSelected(tz);
                      Navigator.pop(context, tz);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

class _TimezonePickerSheet extends StatefulWidget {
  final String? currentTimezone;

  const _TimezonePickerSheet({this.currentTimezone});

  @override
  State<_TimezonePickerSheet> createState() => _TimezonePickerSheetState();
}

class _TimezonePickerSheetState extends State<_TimezonePickerSheet> {
  final _searchController = TextEditingController();
  List<String> _filteredTimezones = [];
  String? _detectedTimezone;
  bool _isDetecting = true;

  @override
  void initState() {
    super.initState();
    _filteredTimezones = TimezoneService.commonTimezones;
    _detectTimezone();
  }

  Future<void> _detectTimezone() async {
    final detected = await TimezoneService().getDeviceTimezone();
    if (mounted) {
      setState(() {
        _detectedTimezone = detected;
        _isDetecting = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTimezones(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTimezones = TimezoneService.commonTimezones;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredTimezones = TimezoneService.commonTimezones.where((tz) {
          final displayName = TimezoneService.getDisplayName(tz).toLowerCase();
          return displayName.contains(lowerQuery) || tz.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.leafGreen),
                const SizedBox(width: 12),
                Text(
                  'Select Timezone',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
              ],
            ),
          ),

          // Detected timezone suggestion
          if (!_isDetecting && _detectedTimezone != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => Navigator.pop(context, _detectedTimezone),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.leafGreen),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: AppTheme.leafGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected Timezone',
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                color: AppTheme.leafGreen,
                              ),
                            ),
                            Text(
                              TimezoneService.getDisplayName(_detectedTimezone!),
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.soilBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Use This',
                        style: GoogleFonts.quicksand(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.leafGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: _filterTimezones,
              decoration: InputDecoration(
                hintText: 'Search by city or region...',
                prefixIcon: Icon(Icons.search, color: AppTheme.leafGreen.withValues(alpha: 0.7)),
                filled: true,
                fillColor: AppTheme.softSage.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Timezone list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredTimezones.length,
              itemBuilder: (ctx, index) {
                final tz = _filteredTimezones[index];
                final isSelected = tz == widget.currentTimezone;
                final isDetected = tz == _detectedTimezone;

                return GestureDetector(
                  onTap: () => Navigator.pop(context, tz),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.leafGreen.withValues(alpha: 0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_circle : Icons.access_time,
                          color: isSelected ? AppTheme.leafGreen : AppTheme.soilBrown.withValues(alpha: 0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    TimezoneService.getDisplayName(tz),
                                    style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.soilBrown,
                                    ),
                                  ),
                                  if (isDetected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.waterBlue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Detected',
                                        style: GoogleFonts.quicksand(
                                          fontSize: 10,
                                          color: AppTheme.waterBlue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                tz,
                                style: GoogleFonts.quicksand(
                                  fontSize: 12,
                                  color: AppTheme.soilBrown.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequiredTimezoneDialog extends StatefulWidget {
  const _RequiredTimezoneDialog();

  @override
  State<_RequiredTimezoneDialog> createState() => _RequiredTimezoneDialogState();
}

class _RequiredTimezoneDialogState extends State<_RequiredTimezoneDialog> {
  String? _detectedTimezone;
  bool _isDetecting = true;

  @override
  void initState() {
    super.initState();
    _detectTimezone();
  }

  Future<void> _detectTimezone() async {
    final detected = await TimezoneService().getDeviceTimezone();
    if (mounted) {
      setState(() {
        _detectedTimezone = detected;
        _isDetecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.schedule, color: AppTheme.leafGreen),
          const SizedBox(width: 12),
          Text(
            'Set Your Timezone',
            style: GoogleFonts.comfortaa(
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We need your timezone to send watering reminders and track your streak at the right times.',
            style: GoogleFonts.quicksand(
              color: AppTheme.soilBrown.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          if (_isDetecting)
            const CircularProgressIndicator()
          else if (_detectedTimezone != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.leafGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: AppTheme.leafGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detected:',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          TimezoneService.getDisplayName(_detectedTimezone!),
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.soilBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Text(
              'Could not detect timezone automatically.',
              style: GoogleFonts.quicksand(
                color: AppTheme.terracotta,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            final selected = await TimezonePickerDialog.show(context);
            if (selected != null && context.mounted) {
              Navigator.pop(context, selected);
            }
          },
          child: Text(
            'Choose Different',
            style: GoogleFonts.quicksand(
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
        ),
        if (_detectedTimezone != null)
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _detectedTimezone),
            child: const Text('Use Detected'),
          ),
      ],
    );
  }
}