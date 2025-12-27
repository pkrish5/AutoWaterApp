import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../models/plant_profile.dart';

class SearchableSpeciesSelector extends StatefulWidget {
  final List<PlantProfile> profiles;
  final PlantProfile? selectedProfile;
  final bool isCustomSpecies;
  final String? customSpeciesText;
  final ValueChanged<PlantProfile?> onProfileSelected;
  final ValueChanged<String> onCustomSpeciesChanged;
  final VoidCallback onCustomSelected;
  final bool isLoading;

  const SearchableSpeciesSelector({
    super.key,
    required this.profiles,
    this.selectedProfile,
    this.isCustomSpecies = false,
    this.customSpeciesText,
    required this.onProfileSelected,
    required this.onCustomSpeciesChanged,
    required this.onCustomSelected,
    this.isLoading = false,
  });

  @override
  State<SearchableSpeciesSelector> createState() => _SearchableSpeciesSelectorState();
}

class _SearchableSpeciesSelectorState extends State<SearchableSpeciesSelector> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softSage, width: 2),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.leafGreen,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading plant types...',
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showSpeciesSearchSheet(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softSage, width: 2),
        ),
        child: Row(
          children: [
            Text(
              _getDisplayEmoji(),
              style: const TextStyle(fontSize: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayName(),
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _hasSelection()
                          ? AppTheme.soilBrown
                          : AppTheme.soilBrown.withValues(alpha: 0.5),
                    ),
                  ),
                  if (widget.selectedProfile != null && !widget.isCustomSpecies)
                    Text(
                      widget.selectedProfile!.species,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                  if (widget.isCustomSpecies)
                    Text(
                      'Custom plant type',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.mossGreen,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.search,
              color: AppTheme.soilBrown.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayEmoji() {
    if (widget.isCustomSpecies) return '🪴';
    return widget.selectedProfile?.emoji ?? '🌱';
  }

  String _getDisplayName() {
    if (widget.isCustomSpecies) {
      return widget.customSpeciesText?.isNotEmpty == true
          ? widget.customSpeciesText!
          : 'Custom Species';
    }
    return widget.selectedProfile?.displayName ?? 'Search for a species...';
  }

  bool _hasSelection() {
    return widget.selectedProfile != null || 
           (widget.isCustomSpecies && widget.customSpeciesText?.isNotEmpty == true);
  }

  void _showSpeciesSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SpeciesSearchSheet(
        profiles: widget.profiles,
        selectedProfile: widget.selectedProfile,
        onProfileSelected: (profile) {
          widget.onProfileSelected(profile);
          Navigator.pop(context);
        },
        onCustomSelected: () {
          widget.onCustomSelected();
          Navigator.pop(context);
          _showCustomSpeciesDialog(context);
        },
      ),
    );
  }

  void _showCustomSpeciesDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.customSpeciesText);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.edit_note, color: AppTheme.mossGreen),
          const SizedBox(width: 12),
          Text(
            'Custom Species',
            style: GoogleFonts.comfortaa(
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Species Name',
                labelStyle: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7)),
                prefixIcon: Icon(Icons.eco, color: AppTheme.mossGreen),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.mossGreen.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.mossGreen, width: 2),
                ),
                filled: true,
                fillColor: AppTheme.mossGreen.withValues(alpha: 0.05),
                hintText: 'e.g., Cherry Tomato',
              ),
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown,
                fontWeight: FontWeight.w600,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Text(
              'Custom plants use default watering settings. You can adjust them later.',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: AppTheme.soilBrown.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onProfileSelected(null);
              widget.onCustomSpeciesChanged('');
              Navigator.pop(ctx);
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Please enter a species name')),
                );
                return;
              }
              widget.onCustomSpeciesChanged(controller.text.trim());
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.mossGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeciesSearchSheet extends StatefulWidget {
  final List<PlantProfile> profiles;
  final PlantProfile? selectedProfile;
  final ValueChanged<PlantProfile> onProfileSelected;
  final VoidCallback onCustomSelected;

  const _SpeciesSearchSheet({
    required this.profiles,
    this.selectedProfile,
    required this.onProfileSelected,
    required this.onCustomSelected,
  });

  @override
  State<_SpeciesSearchSheet> createState() => _SpeciesSearchSheetState();
}

class _SpeciesSearchSheetState extends State<_SpeciesSearchSheet> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  List<PlantProfile> _filteredProfiles = [];

  @override
  void initState() {
    super.initState();
    _filteredProfiles = widget.profiles;
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterProfiles(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProfiles = widget.profiles;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredProfiles = widget.profiles.where((profile) {
          return profile.commonName.toLowerCase().contains(lowerQuery) ||
                 profile.species.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            child: Text(
              'Select Plant Species',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.leafGreen,
              ),
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              focusNode: _focusNode,
              onChanged: _filterProfiles,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                hintStyle: GoogleFonts.quicksand(
                  color: AppTheme.soilBrown.withValues(alpha: 0.4),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppTheme.leafGreen.withValues(alpha: 0.7),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterProfiles('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.softSage.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.leafGreen, width: 2),
                ),
              ),
              style: GoogleFonts.quicksand(
                color: AppTheme.soilBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${_filteredProfiles.length} species found',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: AppTheme.soilBrown.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Species list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredProfiles.length + 1, // +1 for custom option
              itemBuilder: (context, index) {
                // Custom option at the end
                if (index == _filteredProfiles.length) {
                  return _buildCustomOption();
                }

                final profile = _filteredProfiles[index];
                final isSelected = widget.selectedProfile?.species == profile.species;

                return _buildProfileTile(profile, isSelected);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTile(PlantProfile profile, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onProfileSelected(profile),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.leafGreen.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Emoji
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.softSage.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  profile.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Name and species
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  Text(
                    profile.species,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Care info preview
            if (profile.careProfile != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.waterBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.water_drop, size: 12, color: AppTheme.waterBlue),
                    const SizedBox(width: 2),
                    Text(
                      '${profile.careProfile!.watering.frequencyDays}d',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.waterBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Check icon if selected
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, color: AppTheme.leafGreen),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomOption() {
    return GestureDetector(
      onTap: widget.onCustomSelected,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.mossGreen.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.mossGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: AppTheme.mossGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Other (Custom)',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mossGreen,
                    ),
                  ),
                  Text(
                    'Enter your own plant species',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.mossGreen,
            ),
          ],
        ),
      ),
    );
  }
}