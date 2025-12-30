import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/plant.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../widgets/leaf_background.dart';
import 'package:flutter/services.dart';

class LinkDeviceScreen extends StatefulWidget {
  final Plant plant;

  const LinkDeviceScreen({super.key, required this.plant});

  @override
  State<LinkDeviceScreen> createState() => _LinkDeviceScreenState();
}

class _LinkDeviceScreenState extends State<LinkDeviceScreen> {
  final _deviceIdController = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    super.dispose();
  }

  Future<void> _linkDevice() async {
    final deviceId = _deviceIdController.text.trim();
    if (deviceId.isEmpty) {
      _showSnackBar('Please enter a device ID', isError: true);
      return;
    }

    setState(() => _isLinking = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);

      await api.linkDevice(
        plantId: widget.plant.plantId,
        userId: auth.userId!,
        esp32DeviceId: deviceId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        _showSnackBar('Device linked successfully!');
      }
    } catch (e) {
      _showSnackBar('Failed to link device: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      _buildIllustration(),
                      const SizedBox(height: 32),
                      _buildInstructions(),
                      const SizedBox(height: 32),
                      _buildDeviceIdField(),
                      const SizedBox(height: 24),
                      _buildLinkButton(),
                      const SizedBox(height: 32),
                      _buildHelpSection(),
                    ],
                  ),
                ),
              ),
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
          const Spacer(),
          Text(
            'Link Device',
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.leafGreen,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha:0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const Text('🌱', style: TextStyle(fontSize: 56)),
              Positioned(
                right: -8,
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.waterBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.sensors, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        Text(
          'Connect Your Sensor',
          style: GoogleFonts.comfortaa(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.leafGreen,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the Device ID printed on your ESP32 sensor module or scan the QR code on the device.',
          style: GoogleFonts.quicksand(
            fontSize: 15,
            color: AppTheme.soilBrown.withValues(alpha:0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeviceIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Device ID',
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.soilBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _deviceIdController,
          decoration: InputDecoration(
            hintText: 'e.g., plant-001 or ESP32-ABC123',
            prefixIcon: Icon(Icons.qr_code, color: AppTheme.leafGreen.withValues(alpha:0.7)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.leafGreen),
              onPressed: () {
                // TODO: Implement QR code scanner
                _showSnackBar('QR scanner coming soon!');
              },
            ),
          ),
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
        ),
      ],
    );
  }

  Widget _buildLinkButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLinking ? null : _linkDevice,
        child: _isLinking
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.link),
                  const SizedBox(width: 8),
                  Text(
                    'Link Device',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.softSage.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, color: AppTheme.leafGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Where to find Device ID',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.leafGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildHelpItem('1.', 'Look for a label on your ESP32 module'),
          _buildHelpItem('2.', 'Check the QR code sticker on the device'),
          _buildHelpItem('3.', 'Find it in the device\'s serial output during setup'),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.soilBrown,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppTheme.soilBrown.withValues(alpha:0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
