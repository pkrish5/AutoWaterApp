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

      await api.uploadPlantImage(
        plantId: widget.plant.plantId,
        userId: auth.userId!,
        base64Image: base64Image,
        imageType: 'health-check',
      );

      _showSnackBar('Photo uploaded successfully! 📸\nCome back soon to see the AI analysis ⚙️');
      _loadInitialImages();
    } catch (e) {
      _showSnackBar('Upload failed: $e', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage(PlantImage image) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.deletePlantImage(widget.plant.plantId, image.imageId);
      
      _showSnackBar('Photo deleted');
      _loadInitialImages();
    } catch (e) {
      _showSnackBar('Delete failed: $e', isError: true);
    }
  }

  void _confirmDeleteImage(PlantImage image) {
    Navigator.pop(context); // Close the detail dialog first
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Delete Photo?',
          style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This will permanently delete this photo and any AI analysis.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      color: AppTheme.soilBrown.withValues(alpha: 0.6),
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

  Widget _buildAnalysisCard(PlantImageAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ],
          ),
          if (analysis.healthStatus != null) ...[
            const SizedBox(height: 8),
            Text('Status: ${analysis.healthStatus}'),
          ],
          if (analysis.healthScore != null) ...[
            Text('Health score: ${(analysis.healthScore! * 100).round()}%'),
          ],
          if (analysis.issues != null && analysis.issues!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...analysis.issues!.map((issue) => Text('• $issue')),
          ],
          if (analysis.recommendations != null && analysis.recommendations!.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...analysis.recommendations!.map((rec) => Text('✓ $rec')),
          ],
        ],
      ),
    );
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
              Stack(
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
                  Positioned(
                    top: 8,
                    left: 8,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => _confirmDeleteImage(image),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.5),
                      ),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
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
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                    if (image.analysis != null) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(image.analysis!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

class _DateBadge extends StatelessWidget {
  final String text;
  const _DateBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
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