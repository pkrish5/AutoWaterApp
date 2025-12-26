import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../models/user.dart';
import '../widgets/leaf_background.dart';
import '../widgets/streak_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  bool _isLoading = true;
  bool _isEditingUsername = false;
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      final user = await api.getUserProfile(auth.userId!);
      if (mounted) setState(() { _user = user; _isLoading = false; });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.updateUserProfile(userId: auth.userId!, name: newUsername);
      _showSnackBar('Username updated!');
      setState(() => _isEditingUsername = false);
      _loadProfile();
    } catch (e) { _showSnackBar('Failed: $e', isError: true); }
  }

  Future<void> _updateLocation() async {
    final results = await showModalBottomSheet<UserLocation>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const LocationPickerSheet());
    if (results != null) {
      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final api = ApiService(auth.idToken!);
        await api.updateUserLocation(userId: auth.userId!, location: results);
        _showSnackBar('Location updated!');
        _loadProfile();
      } catch (e) { _showSnackBar('Failed: $e', isError: true); }
    }
  }

  void _showChangePasswordDialog() {
    final oldPwController = TextEditingController();
    final newPwController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Change Password', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: oldPwController, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 12),
        TextField(controller: newPwController, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.7)))),
        ElevatedButton(onPressed: () async {
          final auth = Provider.of<AuthService>(context, listen: false);
          final error = await auth.changePassword(oldPwController.text, newPwController.text);
          Navigator.pop(ctx);
          if (error != null) _showSnackBar(error, isError: true); else _showSnackBar('Password changed!');
        }, child: const Text('Change')),
      ],
    ));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [const Icon(Icons.logout, color: AppTheme.terracotta), const SizedBox(width: 12),
        Text('Leave Garden?', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown))]),
      content: Text('Your plants will miss you!', style: GoogleFonts.quicksand(color: AppTheme.soilBrown)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Stay', style: GoogleFonts.quicksand(color: AppTheme.leafGreen, fontWeight: FontWeight.w600))),
        ElevatedButton(onPressed: () { Navigator.pop(ctx); Provider.of<AuthService>(context, listen: false).logout(); },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.terracotta), child: const Text('Logout')),
      ],
    ));
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return Scaffold(body: LeafBackground(leafCount: 4, child: SafeArea(child: _isLoading
      ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildProfileCard(auth),
          const SizedBox(height: 20),
          _buildStreakCard(),
          const SizedBox(height: 20),
          _buildLocationCard(),
          const SizedBox(height: 20),
          _buildSettingsCard(),
          const SizedBox(height: 20),
          _buildDangerZone(),
          const SizedBox(height: 40),
        ])))));
  }

  Widget _buildHeader() => Row(children: [
    const SizedBox(width: 16),
    Text('Profile', style: GoogleFonts.comfortaa(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
  ]);

  Widget _buildProfileCard(AuthService auth) => Container(padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
    child: Column(children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.3), shape: BoxShape.circle),
        child: const Text('🌱', style: TextStyle(fontSize: 48))),
      const SizedBox(height: 16),
      if (_isEditingUsername) Row(children: [
        Expanded(child: TextField(controller: _usernameController, autofocus: true, decoration: const InputDecoration(hintText: 'Username'))),
        IconButton(icon: const Icon(Icons.check, color: AppTheme.leafGreen), onPressed: _updateUsername),
        IconButton(icon: const Icon(Icons.close, color: AppTheme.terracotta), onPressed: () => setState(() => _isEditingUsername = false)),
      ]) else Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_user?.displayName ?? auth.userEmail?.split('@').first ?? 'User', style: GoogleFonts.comfortaa(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        IconButton(icon: Icon(Icons.edit, size: 18, color: AppTheme.soilBrown.withValues(alpha:0.5)), onPressed: () {
          _usernameController.text = _user?.username ?? '';
          setState(() => _isEditingUsername = true);
        }),
      ]),
      const SizedBox(height: 4),
      Text(auth.userEmail ?? '', style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      const SizedBox(height: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.3), borderRadius: BorderRadius.circular(12)),
        child: Text('Member since ${_user?.memberSince ?? 'Unknown'}', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.7)))),
      const SizedBox(height: 12),
      Text('User ID: ${auth.userId ?? 'N/A'}', style: GoogleFonts.quicksand(fontSize: 11, color: AppTheme.soilBrown.withValues(alpha:0.4))),
    ]));

  Widget _buildStreakCard() => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      StreakWidget(streak: _user?.streak ?? 0),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Current Streak', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
        Text('Longest: ${_user?.longestStreak ?? 0} days', style: GoogleFonts.quicksand(fontSize: 13, color: AppTheme.soilBrown.withValues(alpha:0.6))),
      ])),
    ]));

  Widget _buildLocationCard() => Container(padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.location_on, color: AppTheme.leafGreen), const SizedBox(width: 8),
        Text('Location', style: GoogleFonts.comfortaa(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.soilBrown))]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Text(_user?.location?.displayLocation ?? 'Not set', style: GoogleFonts.quicksand(fontSize: 14, color: AppTheme.soilBrown.withValues(alpha:0.8)))),
        TextButton.icon(onPressed: _updateLocation, icon: const Icon(Icons.edit_location_alt, size: 18), label: Text('Update', style: GoogleFonts.quicksand())),
      ]),
      if (_user?.location?.timezone != null) Text('Timezone: ${_user!.location!.timezone}', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.5))),
    ]));

  Widget _buildSettingsCard() => Container(padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      _SettingsTile(icon: Icons.lock_outline, title: 'Change Password', onTap: _showChangePasswordDialog),
      _SettingsTile(icon: Icons.notifications_outlined, title: 'Notifications', trailing: Switch(value: _user?.settings?.pushNotificationsEnabled ?? true, onChanged: (_) {}, activeColor: AppTheme.leafGreen)),
      _SettingsTile(icon: Icons.public, title: 'Public Profile', trailing: Switch(value: _user?.isPublicProfile ?? false, onChanged: (_) {}, activeColor: AppTheme.leafGreen)),
    ]));

  Widget _buildDangerZone() => Container(padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
    child: Column(children: [
      _SettingsTile(icon: Icons.logout, title: 'Logout', iconColor: AppTheme.terracotta, onTap: _showLogoutDialog),
    ]));
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  const _SettingsTile({required this.icon, required this.title, this.trailing, this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon, color: iconColor ?? AppTheme.leafGreen), title: Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.soilBrown), onTap: onTap);
  }
}

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});
  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final _searchController = TextEditingController();
  List<LocationSearchResult> _results = [];
  bool _isSearching = false;

  Future<void> _search(String query) async {
    if (query.length < 2) { setState(() => _results = []); return; }
    setState(() => _isSearching = true);
    final results = await LocationService.searchLocations(query);
    if (mounted) setState(() { _results = results; _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Container(height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Text('Set Location', style: GoogleFonts.comfortaa(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
          const SizedBox(height: 16),
          TextField(controller: _searchController, decoration: InputDecoration(hintText: 'Search city...', prefixIcon: const Icon(Icons.search), suffixIcon: _isSearching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))) : null),
            onChanged: _search),
        ])),
        Expanded(child: ListView.builder(itemCount: _results.length, itemBuilder: (_, i) {
          final r = _results[i];
          return ListTile(leading: const Icon(Icons.location_on, color: AppTheme.leafGreen), title: Text(r.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.quicksand()),
            onTap: () => Navigator.pop(context, LocationService.searchResultToLocation(r)));
        })),
      ]));
  }
}