import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant_profile.dart';

class SpeciesSelector extends StatefulWidget {
  final List<PlantProfile> profiles;
  final String? initialSpecies;
  final ValueChanged<String> onSpeciesChanged;
  final bool isLoading;

  const SpeciesSelector({
    super.key,
    required this.profiles,
    this.initialSpecies,
    required this.onSpeciesChanged,
    this.isLoading = false,
  });

  @override
  State<SpeciesSelector> createState() => _SpeciesSelectorState();
}

class _SpeciesSelectorState extends State<SpeciesSelector> {
  late bool _isCustom;
  String? _selectedSpecies;
  final _customController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    if (widget.initialSpecies != null && widget.initialSpecies!.isNotEmpty) {
      // Check if initial species is in the profiles list
      final matchingProfile = widget.profiles.where((p) => 
        p.species == widget.initialSpecies || p.commonName == widget.initialSpecies
      ).firstOrNull;
      
      if (matchingProfile != null) {
        _isCustom = false;
        _selectedSpecies = matchingProfile.species;
      } else {
        _isCustom = true;
        _customController.text = widget.initialSpecies!;
      }
    } else {
      _isCustom = false;
      _selectedSpecies = null;
    }
  }

  @override
  void didUpdateWidget(SpeciesSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profiles.length != widget.profiles.length) {
      _initializeSelection();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.mossGreen.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mossGreen.withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.mossGreen,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading plant types...',
              style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.7)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _isCustom ? 'custom' : _selectedSpecies,
          decoration: InputDecoration(
            labelText: 'Species',
            labelStyle: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.7)),
            prefixIcon: Icon(Icons.eco, color: AppTheme.mossGreen),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.mossGreen.withValues(alpha:0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.mossGreen, width: 2),
            ),
            filled: true,
            fillColor: AppTheme.mossGreen.withValues(alpha:0.05),
          ),
          style: GoogleFonts.quicksand(
            color: AppTheme.soilBrown,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Colors.white,
          isExpanded: true,
          hint: Text(
            'Select a plant type',
            style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.5)),
          ),
          items: [
            ...widget.profiles.map((profile) => DropdownMenuItem(
              value: profile.species,
              child: Text(
                profile.displayName,
                overflow: TextOverflow.ellipsis,
              ),
            )),
            DropdownMenuItem(
              value: 'custom',
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 18, color: AppTheme.leafGreen),
                  const SizedBox(width: 8),
                  Text(
                    'Other (Custom)...',
                    style: GoogleFonts.quicksand(
                      color: AppTheme.leafGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              if (value == 'custom') {
                _isCustom = true;
                _selectedSpecies = null;
              } else {
                _isCustom = false;
                _selectedSpecies = value;
                _customController.clear();
                widget.onSpeciesChanged(value ?? '');
              }
            });
          },
        ),
        
        // Custom species text field
        if (_isCustom) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            decoration: InputDecoration(
              labelText: 'Enter Species Name',
              labelStyle: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.7)),
              prefixIcon: Icon(Icons.edit_note, color: AppTheme.mossGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.mossGreen.withValues(alpha:0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.mossGreen, width: 2),
              ),
              filled: true,
              fillColor: AppTheme.mossGreen.withValues(alpha:0.05),
              hintText: 'e.g., Cherry Tomato',
              hintStyle: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.4)),
            ),
            style: GoogleFonts.quicksand(
              color: AppTheme.soilBrown,
              fontWeight: FontWeight.w600,
            ),
            onChanged: (value) {
              widget.onSpeciesChanged(value);
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Custom plants use default watering settings. You can adjust them later.',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              color: AppTheme.soilBrown.withValues(alpha:0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}