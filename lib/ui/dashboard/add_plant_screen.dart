import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _nameController = TextEditingController();
  String _selectedArchetype = 'Bushy';
  bool _isLoading = false;

  final List<Map<String, String>> _archetypes = [
    {'name': 'Bushy', 'emoji': '🪴', 'desc': 'Full and leafy'},
    {'name': 'Vine', 'emoji': '🌿', 'desc': 'Trailing and climbing'},
    {'name': 'Spiky', 'emoji': '🌵', 'desc': 'Succulent or cactus'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _savePlant() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please give your plant a name'),
          backgroundColor: AppTheme.terracotta,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.addPlant(
        userId: auth.userId!,
        nickname: _nameController.text.trim(),
        archetype: _selectedArchetype,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${_nameController.text} added!', style: GoogleFonts.quicksand()),
              ],
            ),
            backgroundColor: AppTheme.leafGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add plant: $e'),
            backgroundColor: AppTheme.terracotta,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LeafBackground(
        leafCount: 6,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
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
                        child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'New Plant',
                      style: GoogleFonts.comfortaa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.leafGreen,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
                const SizedBox(height: 40),
                // Plant icon
                Center(
                  child: Container(
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
                    child: Text(
                      _archetypes.firstWhere((a) => a['name'] == _selectedArchetype)['emoji']!,
                      style: const TextStyle(fontSize: 64),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                // Name field
                Text(
                  'Plant Name',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.soilBrown,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Fernie Sanders',
                    prefixIcon: Icon(Icons.eco, color: AppTheme.leafGreen.withOpacity(0.7)),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 28),
                // Archetype selector
                Text(
                  'Plant Type',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.soilBrown,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: _archetypes.map((arch) {
                    final isSelected = _selectedArchetype == arch['name'];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedArchetype = arch['name']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.leafGreen : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.leafGreen.withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            children: [
                              Text(arch['emoji']!, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(
                                arch['name']!,
                                style: GoogleFonts.quicksand(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.soilBrown,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                arch['desc']!,
                                style: GoogleFonts.quicksand(
                                  fontSize: 10,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : AppTheme.soilBrown.withOpacity(0.6),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 48),
                // Add button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _savePlant,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                'Add to Garden',
                                style: GoogleFonts.quicksand(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
