import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';

class FriendGardenScreen extends StatefulWidget {
  final Friend friend;

  const FriendGardenScreen({super.key, required this.friend});

  @override
  State<FriendGardenScreen> createState() => _FriendGardenScreenState();
}

class _FriendGardenScreenState extends State<FriendGardenScreen> {
  List<Plant>? _plants;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFriendPlants();
  }

  Future<void> _loadFriendPlants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final plants = await api.getFriendPlants(auth.userId!, widget.friend.odIn);

      if (mounted) {
        setState(() {
          _plants = plants;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
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
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${widget.friend.odInname}'s Garden",
                  style: GoogleFonts.comfortaa(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: AppTheme.streakOrange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.friend.streak} day streak',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_plants == null || _plants!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFriendPlants,
      color: AppTheme.leafGreen,
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemCount: _plants!.length,
        itemBuilder: (context, index) => _FriendPlantCard(
          plant: _plants![index],
          onTap: () => _showPlantInfo(_plants![index]),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final isPrivate = _error?.contains('private') ?? false;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isPrivate ? '🔒' : '😵',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 16),
            Text(
              isPrivate ? 'Private Garden' : 'Something went wrong',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPrivate
                  ? "${widget.friend.odInname}'s garden is set to private"
                  : _error ?? 'Failed to load garden',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (!isPrivate) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFriendPlants,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🌱', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            'No plants yet',
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "${widget.friend.odInname} hasn't added any plants",
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.soilBrown.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlantInfo(Plant plant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plant.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 12),
            Text(
              plant.nickname,
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              plant.species,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (plant.hasDevice ? AppTheme.leafGreen : AppTheme.soilBrown).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    plant.hasDevice ? Icons.sensors : Icons.touch_app,
                    size: 16,
                    color: plant.hasDevice ? AppTheme.leafGreen : AppTheme.soilBrown,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plant.hasDevice ? 'Sensor Connected' : 'Manual Care',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: plant.hasDevice ? AppTheme.leafGreen : AppTheme.soilBrown,
                    ),
                  ),
                ],
              ),
            ),
            if (plant.environment?.location != null) ...[
              const SizedBox(height: 12),
              Text(
                plant.environment!.location!.displayName,
                style: GoogleFonts.quicksand(
                  fontSize: 13,
                  color: AppTheme.mossGreen,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
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
}

/// Plant card for friend's garden - hides sensor data, shows "Sensor" or "Manual" badge
class _FriendPlantCard extends StatelessWidget {
  final Plant plant;
  final VoidCallback? onTap;

  const _FriendPlantCard({required this.plant, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTopRow(),
              const SizedBox(height: 12),
              Text(
                plant.nickname,
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.soilBrown,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Center(
                  child: Text(plant.emoji, style: const TextStyle(fontSize: 48)),
                ),
              ),
              const SizedBox(height: 8),
              _buildBottomBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.softSage.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              plant.species,
              style: GoogleFonts.quicksand(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.leafGreen,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (plant.streak > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.sunYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${plant.streak}',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBadge() {
    final hasSensor = plant.hasDevice;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (hasSensor ? AppTheme.leafGreen : AppTheme.soilBrown).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSensor ? Icons.sensors : Icons.touch_app,
            size: 14,
            color: hasSensor ? AppTheme.leafGreen : AppTheme.soilBrown,
          ),
          const SizedBox(width: 4),
          Text(
            hasSensor ? 'Sensor' : 'Manual',
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasSensor ? AppTheme.leafGreen : AppTheme.soilBrown,
            ),
          ),
        ],
      ),
    );
  }
}