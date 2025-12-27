import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/plant.dart';
import '../widgets/leaf_background.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/streak_widget.dart';
import '../plant_detail/plant_detail_screen.dart';
import './plant_card.dart';
import 'add_plant_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Plant>> _plantsFuture;
  final GlobalKey<RefreshIndicatorState> _refreshKey = GlobalKey();
  int _userStreak = 0;
  
  // Room filter
  String? _selectedRoom; // null = All rooms
  List<String> _availableRooms = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);
    _plantsFuture = api.getPlants(auth.userId!).then((plants) {
      _updateAvailableRooms(plants);
      return plants;
    });
    _loadStreak();
  }

  void _updateAvailableRooms(List<Plant> plants) {
    final rooms = <String>{};
    for (final plant in plants) {
      final room = plant.environment?.location?.room;
      if (room != null && room.isNotEmpty && room != 'Not set') {
        rooms.add(room);
      }
    }
    setState(() {
      _availableRooms = rooms.toList()..sort();
    });
  }

  List<Plant> _filterPlants(List<Plant> plants) {
    if (_selectedRoom == null) return plants;
    return plants.where((p) => p.environment?.location?.room == _selectedRoom).toList();
  }

  Future<void> _loadStreak() async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final streakData = await api.getUserStreak(auth.userId!);
      if (mounted) {
        setState(() => _userStreak = streakData['streak'] ?? 0);
      }
    } catch (e) {
      debugPrint('Failed to load streak: $e');
    }
  }

  Future<void> _refreshPlants() async {
    setState(() {
      _loadData();
    });
  }

  void _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true) {
      _refreshPlants();
    }
  }

  void _navigateToPlantDetail(Plant plant) async {
    final result = await Navigator.push<PlantDetailResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PlantDetailScreen(plant: plant),
      ),
    );

    if (result?.updatedStreak != null) {
      setState(() => _userStreak = result!.updatedStreak!);
    }

    if (result?.needsRefresh == true) {
      _refreshPlants();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        leafCount: 5,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_availableRooms.isNotEmpty) _buildRoomFilter(),
              Expanded(
                child: RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refreshPlants,
                  color: AppTheme.leafGreen,
                  child: FutureBuilder<List<Plant>>(
                    future: _plantsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: PlantLoadingIndicator(message: 'Growing your garden...'),
                        );
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(snapshot.error);
                      }

                      final allPlants = snapshot.data ?? [];
                      final plants = _filterPlants(allPlants);

                      if (allPlants.isEmpty) {
                        return _buildEmptyState();
                      }

                      if (plants.isEmpty && _selectedRoom != null) {
                        return _buildNoRoomPlantsState();
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.78,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: plants.length,
                        itemBuilder: (context, index) => PlantCard(
                          plant: plants[index],
                          onTap: () => _navigateToPlantDetail(plants[index]),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddPlant,
        backgroundColor: AppTheme.terracotta,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Plant',
          style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.leafGreen.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text('🪴', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Garden',
                  style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                Text(
                  'Your plant twins await',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppTheme.soilBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          AnimatedStreakWidget(
            streak: _userStreak,
            showLabel: false,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomFilter() {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'All',
            emoji: '🏠',
            isSelected: _selectedRoom == null,
            onTap: () => setState(() => _selectedRoom = null),
          ),
          ..._availableRooms.map((room) => _buildFilterChip(
            label: room,
            emoji: _getRoomEmoji(room),
            isSelected: _selectedRoom == room,
            onTap: () => setState(() => _selectedRoom = room),
          )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.leafGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.soilBrown,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoomEmoji(String room) {
    final r = room.toLowerCase();
    if (r.contains('living')) return '🛋️';
    if (r.contains('kitchen')) return '🍳';
    if (r.contains('bedroom')) return '🛏️';
    if (r.contains('bathroom')) return '🚿';
    if (r.contains('office')) return '💻';
    if (r.contains('balcony')) return '🌅';
    if (r.contains('patio')) return '☀️';
    if (r.contains('garden')) return '🌳';
    if (r.contains('yard')) return '🏡';
    if (r.contains('greenhouse')) return '🌱';
    return '📍';
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😵', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.comfortaa(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPlants,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRoomPlantsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_getRoomEmoji(_selectedRoom!), style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No plants in $_selectedRoom',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a plant or change the room filter',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => setState(() => _selectedRoom = null),
            child: Text(
              'Show all plants',
              style: GoogleFonts.quicksand(
                color: AppTheme.leafGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.leafGreen.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Text('🌱', style: TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 28),
            Text(
              'Your garden is empty!',
              style: GoogleFonts.comfortaa(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.leafGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap the button below to add\nyour first digital plant twin',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToAddPlant,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(
                'Plant Your First Twin',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}