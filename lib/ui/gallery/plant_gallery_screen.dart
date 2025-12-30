import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../models/plant_image.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';

class PlantGalleryScreen extends StatefulWidget {
  final Plant plant;
  const PlantGalleryScreen({super.key, required this.plant});

  @override
  State<PlantGalleryScreen> createState() => _PlantGalleryScreenState();
}

class _PlantGalleryScreenState extends State<PlantGalleryScreen> {
  final ScrollController _scrollController = ScrollController();

  List<PlantImage> _images = [];
  String? _nextKey;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isUploading = false;
  
  // Track if streak was updated and new value
  int? _updatedStreak;

  @override
  void initState() {
    super.initState();
    _loadInitialImages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _nextKey != null) {
        _loadMoreImages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialImages() async {
    setState(() {
      _isLoading = true;
      _nextKey = null;
      _images = [];
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final result = await api.getPlantImagesPaginated(widget.plant.plantId);

      setState(() {
        _images = result.items;
        _nextKey = result.nextKey;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load images: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreImages() async {
    if (_nextKey == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final result = await api.getPlantImagesPaginated(
        widget.plant.plantId,
        lastKey: _nextKey,
      );

      setState(() {
        _images.addAll(result.items);
        _nextKey = result.nextKey;
        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('Pagination failed: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploading = true);

      final bytes = await File(pickedFile.path).readAsBytes();
      final base64Image = base64Encode(bytes);

      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final result = await api.uploadPlantImage(
        plantId: widget.plant.plantId,
        userId: auth.userId!,
        base64Image: base64Image,
        imageType: 'health-check',
      );

      // Show streak toast if updated and store new value
      if (result['streakUpdated'] == true && result['streak'] != null) {
        _updatedStreak = result['streak'];
        _showStreakToast(result['streak']);
      } else {
        _showSnackBar('Photo uploaded');
      }
      _loadInitialImages();
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showStreakToast(int streak) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(milliseconds: 2500), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.streakOrange, AppTheme.streakYellow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.streakOrange.withValues(alpha:0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 12),
                Text(
                  '$streak Day Streak!',
                  style: GoogleFonts.comfortaa(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  streak == 1 ? 'Great start! Keep it going!' : 'Amazing dedication! 🌱',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.pop(context, _updatedStreak);
        }
      },
      child: Scaffold(
        body: LeafBackground(
          leafCount: 4,
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _images.isEmpty
                          ? _buildEmptyState()
                          : _buildGalleryGrid(),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isUploading ? null : _showImageOptions,
          backgroundColor: AppTheme.terracotta,
          icon: _isUploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.add_a_photo),
          label: Text(
            _isUploading ? 'Uploading...' : 'Add Photo',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid() => GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(2),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: _images.length,
        itemBuilder: (_, index) {
          final image = _images[index];
          return GestureDetector(
            onTap: () => _showImageDetail(image),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(image.imageUrl, fit: BoxFit.cover),
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: _DateBadge(image.dateLabel),
                ),
                if (image.analysis?.healthStatus != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _HealthDot(image.analysis!.healthStatus!),
                  ),
              ],
            ),
          );
        },
      );

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context, _updatedStreak),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    "${widget.plant.nickname}'s Gallery",
                    style: GoogleFonts.comfortaa(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.leafGreen,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "${_images.length} photos",
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      color: AppTheme.soilBrown.withValues(alpha:0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📸', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'No photos yet!',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
          ],
        ),
      );

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text('Gallery'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Condensed analysis summary card (collapsed by default)
  Widget _buildAnalysisSummaryCard(PlantImageAnalysis analysis) {
    final healthColor = _getHealthColor(analysis.healthStatus);
    final trendIcon = _getTrendIcon(analysis.trend);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with key metrics
          Row(
            children: [
              const Icon(Icons.psychology, size: 16, color: AppTheme.leafGreen),
              const SizedBox(width: 6),
              Text(
                'AI Analysis',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.leafGreen,
                ),
              ),
              const Spacer(),
              if (analysis.confidence != null)
                Text(
                  '${(analysis.confidence! * 100).round()}% confident',
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    color: AppTheme.soilBrown.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Key metrics row
          Row(
            children: [
              // Health score
              _MetricChip(
                icon: Icons.favorite,
                label: 'Health',
                value: analysis.healthScore != null 
                    ? '${(analysis.healthScore! * 100).round()}%' 
                    : '--',
                color: healthColor,
              ),
              const SizedBox(width: 8),
              
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: healthColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  analysis.healthStatus?.toUpperCase() ?? 'UNKNOWN',
                  style: GoogleFonts.quicksand(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Trend indicator
              if (analysis.trend != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, size: 14, color: _getTrendColor(analysis.trend)),
                    const SizedBox(width: 2),
                    Text(
                      analysis.trend!,
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        color: _getTrendColor(analysis.trend),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Issues count (if any)
          if (analysis.issues != null && analysis.issues!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.warning_amber, size: 14, color: AppTheme.terracotta),
                const SizedBox(width: 4),
                Text(
                  '${analysis.issues!.length} issue${analysis.issues!.length > 1 ? 's' : ''} detected',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: AppTheme.terracotta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Full expandable analysis card
  Widget _buildFullAnalysisCard(PlantImageAnalysis analysis) {
    return _ExpandableAnalysisCard(analysis: analysis);
  }

  Color _getHealthColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
      case 'warning':
        return Colors.orange;
      case 'poor':
      case 'critical':
        return Colors.red;
      default:
        return AppTheme.soilBrown;
    }
  }

  IconData _getTrendIcon(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return AppTheme.soilBrown;
    }
  }

  void _showImageDetail(PlantImage image) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  image.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      image.dateLabel,
                      style: GoogleFonts.comfortaa(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      image.imageType,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha:0.6),
                      ),
                    ),
                    if (image.analysis != null) ...[
                      const SizedBox(height: 16),
                      _buildFullAnalysisCard(image.analysis!),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _confirmDeleteImage(image),
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.terracotta,
                      tooltip: 'Delete photo',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteImage(PlantImage image) {
    Navigator.pop(context); // Close detail dialog first
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Photo?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete this photo and its analysis data.',
          style: GoogleFonts.quicksand(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(image);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.terracotta),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteImage(PlantImage image) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      final success = await api.deletePlantImage(widget.plant.plantId, image.imageId);

      if (success) {
        setState(() {
          _images.removeWhere((img) => img.imageId == image.imageId);
        });
        _showSnackBar('Photo deleted');
      } else {
        _showSnackBar('Failed to delete photo', isError: true);
      }
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      ),
    );
  }
}

// Small metric chip widget
class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Expandable analysis card with collapsed/expanded states
class _ExpandableAnalysisCard extends StatefulWidget {
  final PlantImageAnalysis analysis;
  const _ExpandableAnalysisCard({required this.analysis});

  @override
  State<_ExpandableAnalysisCard> createState() => _ExpandableAnalysisCardState();
}

class _ExpandableAnalysisCardState extends State<_ExpandableAnalysisCard> {
  bool _isExpanded = false;

  Color _getHealthColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
      case 'warning':
        return Colors.orange;
      case 'poor':
      case 'critical':
        return Colors.red;
      default:
        return AppTheme.soilBrown;
    }
  }

  IconData _getTrendIcon(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'improving':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Color _getTrendColor(String? trend) {
    switch (trend?.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'declining':
        return Colors.red;
      default:
        return AppTheme.soilBrown;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.analysis;
    final healthColor = _getHealthColor(analysis.healthStatus);

    return Container(
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: healthColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always visible summary
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology, size: 16, color: healthColor),
                    const SizedBox(width: 6),
                    Text(
                      'AI Health Analysis',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: healthColor,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isExpanded ? 'Less' : 'More',
                            style: GoogleFonts.quicksand(
                              fontSize: 11,
                              color: AppTheme.leafGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(
                            _isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 16,
                            color: AppTheme.leafGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                
                // Key metrics row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Health score
                    _MetricChip(
                      icon: Icons.favorite,
                      label: 'Health',
                      value: analysis.healthScore != null 
                          ? '${(analysis.healthScore! * 100).round()}%' 
                          : '--',
                      color: healthColor,
                    ),
                    
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: healthColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        analysis.healthStatus?.toUpperCase() ?? 'UNKNOWN',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Trend indicator
                    if (analysis.trend != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getTrendColor(analysis.trend).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getTrendIcon(analysis.trend), size: 12, color: _getTrendColor(analysis.trend)),
                            const SizedBox(width: 2),
                            Text(
                              analysis.trend!,
                              style: GoogleFonts.quicksand(
                                fontSize: 10,
                                color: _getTrendColor(analysis.trend),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                    // Growth stage
                    if (analysis.growthStage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.leafGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          analysis.growthStage!,
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            color: AppTheme.leafGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                
                // Issues preview (collapsed)
                if (!_isExpanded && analysis.issues != null && analysis.issues!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.warning_amber, size: 14, color: AppTheme.terracotta),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${analysis.issues!.length} issue${analysis.issues!.length > 1 ? 's' : ''} • Tap "More" for details',
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            color: AppTheme.terracotta,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Expanded details
          if (_isExpanded) ...[
            Divider(height: 1, color: healthColor.withValues(alpha: 0.2)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall notes
                  if (analysis.overallNotes != null) ...[
                    Text(
                      'Summary',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      analysis.overallNotes!,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Issues
                  if (analysis.issues != null && analysis.issues!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.warning_amber, size: 14, color: AppTheme.terracotta),
                        const SizedBox(width: 4),
                        Text(
                          'Issues Detected',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.terracotta,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...analysis.issues!.take(5).map((issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: TextStyle(color: AppTheme.terracotta, fontSize: 12)),
                          Expanded(
                            child: Text(
                              issue,
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: AppTheme.soilBrown.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (analysis.issues!.length > 5)
                      Text(
                        '+${analysis.issues!.length - 5} more issues',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 12),
                  ],
                  
                  // Recommendations
                  if (analysis.recommendations != null && analysis.recommendations!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.leafGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Recommendations',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.leafGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...analysis.recommendations!.take(3).map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('✓ ', style: TextStyle(color: AppTheme.leafGreen, fontSize: 12)),
                          Expanded(
                            child: Text(
                              rec,
                              style: GoogleFonts.quicksand(
                                fontSize: 11,
                                color: AppTheme.soilBrown.withValues(alpha: 0.8),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (analysis.recommendations!.length > 3)
                      Text(
                        '+${analysis.recommendations!.length - 3} more recommendations',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                  
                  // Leaf condition
                  if (analysis.leafCondition != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Leaf Condition',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (analysis.leafCondition!.browning == true)
                          _ConditionTag('Browning', Colors.brown),
                        if (analysis.leafCondition!.yellowing == true)
                          _ConditionTag('Yellowing', Colors.amber),
                        if (analysis.leafCondition!.spotting == true)
                          _ConditionTag('Spotting', Colors.orange),
                        if (analysis.leafCondition!.color != null)
                          _ConditionTag(analysis.leafCondition!.color!, AppTheme.leafGreen),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConditionTag extends StatelessWidget {
  final String label;
  final Color color;
  const _ConditionTag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final String text;
  const _DateBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha:0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}

class _HealthDot extends StatelessWidget {
  final String status;
  const _HealthDot(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'healthy':
        color = Colors.green;
        break;
      case 'warning':
        color = Colors.orange;
        break;
      default:
        color = Colors.red;
    }
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}