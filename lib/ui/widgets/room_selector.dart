import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import 'package:flutter/services.dart';

class RoomLocation {
  final String room;
  final String? spot;
  final String? sunExposure;
  final double? luxLevel;  // ADD THIS

  RoomLocation({
    required this.room,
    this.spot,
    this.sunExposure,
    this.luxLevel,  // ADD THIS
  });

  bool get isSet => room != 'Not set';

  String get displayName {
    if (!isSet) return '📍 Not set';
    final parts = <String>[room];
    if (spot != null && spot!.isNotEmpty) parts.add(spot!);
    if (luxLevel != null) {
      final lightInfo = _getLightCategoryFromLux(luxLevel!);
      parts.add(lightInfo);
    }
    return parts.join(' • ');
  }

  String _getLightCategoryFromLux(double lux) {
    if (lux < 1000) return '🌑 ${lux.toInt()} lux';
    if (lux < 10000) return '☁️ ${lux.toInt()} lux';
    if (lux < 25000) return '⛅ ${lux.toInt()} lux';
    return '☀️ ${lux.toInt()} lux';
  }

  Map<String, dynamic> toJson() {
    return {
      'room': room,
      if (spot != null) 'windowProximity': spot,
      if (sunExposure != null) 'sunExposure': sunExposure,
      if (luxLevel != null) 'luxLevel': luxLevel,  // ADD THIS
    };
  }
}
class RoomSelector extends StatelessWidget {
  final RoomLocation? selectedLocation;
  final ValueChanged<RoomLocation> onLocationChanged;

  const RoomSelector({
    super.key,
    this.selectedLocation,
    required this.onLocationChanged,
  });

  static const List<RoomOption> predefinedRooms = [
    RoomOption(name: 'Living Room', emoji: '🛋️', spots: ['By window', 'Corner', 'Shelf', 'Coffee table']),
    RoomOption(name: 'Kitchen', emoji: '🍳', spots: ['Windowsill', 'Counter', 'Above cabinets', 'Herb shelf']),
    RoomOption(name: 'Bedroom', emoji: '🛏️', spots: ['Nightstand', 'Windowsill', 'Dresser', 'Hanging']),
    RoomOption(name: 'Bathroom', emoji: '🚿', spots: ['Windowsill', 'Shelf', 'Counter']),
    RoomOption(name: 'Office', emoji: '💻', spots: ['Desk', 'Windowsill', 'Bookshelf', 'Corner']),
    RoomOption(name: 'Balcony', emoji: '🌅', spots: ['Railing', 'Floor', 'Hanging', 'Table']),
    RoomOption(name: 'Patio', emoji: '☀️', spots: ['Sunny spot', 'Shaded area', 'Table', 'Planter box']),
    RoomOption(name: 'Back Garden', emoji: '🌳', spots: ['Flower bed', 'Vegetable patch', 'Along fence', 'Under tree']),
    RoomOption(name: 'Front Yard', emoji: '🏡', spots: ['Porch', 'Garden bed', 'Pathway', 'Planter']),
    RoomOption(name: 'Greenhouse', emoji: '🌱', spots: ['Bench', 'Hanging', 'Floor', 'Shelf']),
  ];

  static const List<String> sunExposureOptions = [
    'Full sun',
    'Partial sun',
    'Bright indirect',
    'Low light',
    'Shade',
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLocationPicker(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softSage, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.softSage.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getEmoji(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    selectedLocation?.displayName ?? 'Tap to set room',
                    style: GoogleFonts.quicksand(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: selectedLocation?.isSet == true
                          ? AppTheme.soilBrown
                          : AppTheme.soilBrown.withValues(alpha: 0.5),
                    ),
                  ),
                  if (selectedLocation?.sunExposure != null)
                    Text(
                      selectedLocation!.sunExposure!,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.sunYellow,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.soilBrown.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji() {
    if (selectedLocation == null || !selectedLocation!.isSet) return '📍';
    final room = predefinedRooms.where((r) => r.name == selectedLocation!.room).firstOrNull;
    return room?.emoji ?? '📍';
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(
        initialLocation: selectedLocation,
        onLocationSelected: onLocationChanged,
      ),
    );
  }
}

class RoomOption {
  final String name;
  final String emoji;
  final List<String> spots;

  const RoomOption({required this.name, required this.emoji, required this.spots});
}

class _LocationPickerSheet extends StatefulWidget {
  final RoomLocation? initialLocation;
  final ValueChanged<RoomLocation> onLocationSelected;

  const _LocationPickerSheet({
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  String? _selectedRoom;
  String? _selectedSpot;
  String? _selectedSunExposure;
  final _customRoomController = TextEditingController();
  final _customSpotController = TextEditingController();
  bool _isCustomRoom = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null && widget.initialLocation!.isSet) {
      final matchingRoom = RoomSelector.predefinedRooms
          .where((r) => r.name == widget.initialLocation!.room)
          .firstOrNull;
      
      if (matchingRoom != null) {
        _selectedRoom = matchingRoom.name;
        _selectedSpot = widget.initialLocation!.spot;
      } else {
        _isCustomRoom = true;
        _customRoomController.text = widget.initialLocation!.room;
        _customSpotController.text = widget.initialLocation!.spot ?? '';
      }
      _selectedSunExposure = widget.initialLocation!.sunExposure;
    }
  }

  @override
  void dispose() {
    _customRoomController.dispose();
    _customSpotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Set Plant Location',
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onLocationSelected(RoomLocation(room: 'Not set'));
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Clear',
                    style: GoogleFonts.quicksand(color: AppTheme.terracotta),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Room',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...RoomSelector.predefinedRooms.map((room) => _RoomChip(
                        room: room,
                        isSelected: _selectedRoom == room.name && !_isCustomRoom,
                        onTap: () => setState(() {
                          _selectedRoom = room.name;
                          _selectedSpot = null;
                          _isCustomRoom = false;
                          _customRoomController.clear();
                        }),
                      )),
                      _CustomRoomChip(
                        isSelected: _isCustomRoom,
                        onTap: () => setState(() {
                          _isCustomRoom = true;
                          _selectedRoom = null;
                          _selectedSpot = null;
                        }),
                      ),
                    ],
                  ),
                  
                  if (_isCustomRoom) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customRoomController,
                      decoration: InputDecoration(
                        labelText: 'Custom Room Name',
                        hintText: 'e.g., Sunroom, Garage',
                        prefixIcon: Icon(Icons.edit, color: AppTheme.leafGreen),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customSpotController,
                      decoration: InputDecoration(
                        labelText: 'Spot (optional)',
                        hintText: 'e.g., Near window',
                        prefixIcon: Icon(Icons.place, color: AppTheme.leafGreen.withValues(alpha: 0.7)),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],

                  if (_selectedRoom != null && !_isCustomRoom) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Spot in $_selectedRoom',
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: RoomSelector.predefinedRooms
                          .firstWhere((r) => r.name == _selectedRoom)
                          .spots
                          .map((spot) => _SpotChip(
                            spot: spot,
                            isSelected: _selectedSpot == spot,
                            onTap: () => setState(() => _selectedSpot = spot),
                          ))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 24),
                  Text(
                    'Sun Exposure',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: RoomSelector.sunExposureOptions.map((exposure) => _SunChip(
                      exposure: exposure,
                      isSelected: _selectedSunExposure == exposure,
                      onTap: () => setState(() => _selectedSunExposure = exposure),
                    )).toList(),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _canSave() ? _saveLocation : null,
                child: Text(
                  'Save Location',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    if (_isCustomRoom) {
      return _customRoomController.text.trim().isNotEmpty;
    }
    return _selectedRoom != null;
  }

  void _saveLocation() {
    final location = RoomLocation(
      room: _isCustomRoom ? _customRoomController.text.trim() : _selectedRoom!,
      spot: _isCustomRoom ? _customSpotController.text.trim() : _selectedSpot,
      sunExposure: _selectedSunExposure,
    );
    widget.onLocationSelected(location);
    Navigator.pop(context);
  }
}

class _RoomChip extends StatelessWidget {
  final RoomOption room;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoomChip({required this.room, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(room.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              room.name,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.soilBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomRoomChip extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomRoomChip({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.mossGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.mossGreen : AppTheme.softSage,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.mossGreen,
            ),
            const SizedBox(width: 6),
            Text(
              'Other',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.mossGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotChip extends StatelessWidget {
  final String spot;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpotChip({required this.spot, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.waterBlue : AppTheme.waterBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.waterBlue : AppTheme.waterBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          spot,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.waterBlue,
          ),
        ),
      ),
    );
  }
}

class _SunChip extends StatelessWidget {
  final String exposure;
  final bool isSelected;
  final VoidCallback onTap;

  const _SunChip({required this.exposure, required this.isSelected, required this.onTap});

  IconData get _icon {
    switch (exposure) {
      case 'Full sun': return Icons.wb_sunny;
      case 'Partial sun': return Icons.wb_sunny_outlined;
      case 'Bright indirect': return Icons.light_mode;
      case 'Low light': return Icons.nights_stay;
      case 'Shade': return Icons.cloud;
      default: return Icons.wb_sunny;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.sunYellow : AppTheme.sunYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.sunYellow : AppTheme.sunYellow.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: isSelected ? Colors.white : AppTheme.sunYellow),
            const SizedBox(width: 4),
            Text(
              exposure,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.soilBrown.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}