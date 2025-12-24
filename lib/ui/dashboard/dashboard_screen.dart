import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/plant.dart';
import '../widgets/leaf_background.dart';
import '../widgets/loading_indicator.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  void _loadPlants() {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);
    _plantsFuture = api.getPlants(auth.userId!);
  }

  Future<void> _refreshPlants() async {
    setState(() {
      _loadPlants();
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
    );
    if (result == true) {
      _refreshPlants();
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppTheme.terracotta),
            const SizedBox(width: 12),
            Text(
              'Leave Garden?',
              style: GoogleFonts.comfortaa(
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
          ],
        ),
        content: Text(
          'Your plants will miss you!',
          style: GoogleFonts.quicksand(color: AppTheme.soilBrown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Stay',
              style: GoogleFonts.quicksand(
                color: AppTheme.leafGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthService>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.terracotta,
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        leafCount: 5,
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              Padding(
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
                            color: AppTheme.leafGreen.withOpacity(0.1),
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
                              color: AppTheme.soilBrown.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showLogoutDialog,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: AppTheme.soilBrown.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Plant grid
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
                                  '${snapshot.error}',
                                  style: GoogleFonts.quicksand(
                                    fontSize: 14,
                                    color: AppTheme.soilBrown.withOpacity(0.7),
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

                      final plants = snapshot.data ?? [];

                      if (plants.isEmpty) {
                        return _buildEmptyState();
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
                    color: AppTheme.leafGreen.withOpacity(0.15),
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
                color: AppTheme.soilBrown.withOpacity(0.7),
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
