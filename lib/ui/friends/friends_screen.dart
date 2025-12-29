import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import '../widgets/leaf_background.dart';
import 'friend_garden_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Friend> _friends = [];
  List<FriendRequest> _requests = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth.idToken!);

    try {
      final friends = await api.getFriends(auth.userId!);
      final requests = await api.getFriendRequests(auth.userId!);
      final leaderboard = await api.getLeaderboard(auth.userId!);
      if (mounted) setState(() { _friends = friends; _requests = requests; _leaderboard = leaderboard; _isLoading = false; });
    } catch (e) {
      debugPrint('Failed to load friends data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

// Replace _showAddFriendDialog in friends_screen.dart with this version
// Uses username instead of email for cleaner UX

void _showAddFriendDialog() {
  final usernameController = TextEditingController();
  bool isSending = false;
  
  showDialog(
    context: context, 
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.person_add, color: AppTheme.leafGreen), 
          const SizedBox(width: 12),
          Text('Add Friend', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: AppTheme.soilBrown))
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController, 
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter their @username',
                prefixIcon: Icon(Icons.alternate_email),
              ), 
              textCapitalization: TextCapitalization.none,
              autocorrect: false,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask your friend for their @username from their profile',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: AppTheme.soilBrown.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isSending ? null : () => Navigator.pop(ctx), 
            child: Text('Cancel', style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha: 0.7)))
          ),
          ElevatedButton(
            onPressed: isSending ? null : () async {
              // Strip @ if user included it
              String username = usernameController.text.trim();
              if (username.startsWith('@')) {
                username = username.substring(1);
              }
              
              if (username.isEmpty) {
                _showSnackBar('Please enter a username', isError: true);
                return;
              }
              
              setDialogState(() => isSending = true);
              
              try {
                final auth = Provider.of<AuthService>(context, listen: false);
                final api = ApiService(auth.idToken!);
                await api.sendFriendRequest(userId: auth.userId!, friendUsername: username);
                Navigator.pop(ctx);
                _showSnackBar('Friend request sent to @$username!');
                _loadData();
              } catch (e) { 
                setDialogState(() => isSending = false);
                _showSnackBar('$e', isError: true); 
              }
            }, 
            child: isSending 
              ? const SizedBox(
                  width: 16, 
                  height: 16, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                )
              : const Text('Send')
          ),
        ],
      ),
    ),
  );
}
  Future<void> _respondToRequest(String requestId, bool accept) async {
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = ApiService(auth.idToken!);
      await api.respondToFriendRequest(userId: auth.userId!, requestId: requestId, accept: accept);
      _showSnackBar(accept ? 'Friend added!' : 'Request declined');
      // Remove from local list immediately for responsive UI
      setState(() {
        _requests.removeWhere((r) => r.requestId == requestId);
      });
      // Then reload to get updated friends list
      await _loadData();
    } catch (e) { _showSnackBar('Failed: $e', isError: true); }
  }

  void _viewFriendGarden(Friend friend) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FriendGardenScreen(friend: friend)),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: isError ? AppTheme.terracotta : AppTheme.leafGreen,
      behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LeafBackground(leafCount: 4, child: SafeArea(child: Column(children: [
      _buildHeader(),
      _buildTabs(),
      Expanded(child: TabBarView(controller: _tabController, children: [
        _buildLeaderboardTab(),
        _buildFriendsTab(),
        _buildRequestsTab(),
      ])),
    ]))));
  }

  Widget _buildHeader() => Padding(padding: const EdgeInsets.all(20), child: Row(children: [
    Text('Friends', style: GoogleFonts.comfortaa(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.leafGreen)),
    const Spacer(),
    IconButton(onPressed: _showAddFriendDialog, icon: Container(padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: AppTheme.leafGreen, borderRadius: BorderRadius.circular(12)),
      child: const Icon(Icons.person_add, color: Colors.white, size: 20))),
  ]));

  Widget _buildTabs() => Container(margin: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: TabBar(controller: _tabController, indicator: BoxDecoration(color: AppTheme.leafGreen, borderRadius: BorderRadius.circular(12)),
      indicatorSize: TabBarIndicatorSize.tab, indicatorPadding: const EdgeInsets.all(4),
      labelColor: Colors.white, unselectedLabelColor: AppTheme.soilBrown,
      labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
      tabs: [
        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.leaderboard, size: 18), const SizedBox(width: 6), const Text('Ranks')])),
        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.people, size: 18), const SizedBox(width: 6), Text('${_friends.length}')])),
        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.mail, size: 18), const SizedBox(width: 6), Text('${_requests.length}')])),
      ]));

  Widget _buildLeaderboardTab() => _isLoading ? const Center(child: CircularProgressIndicator()) :
    _leaderboard.isEmpty ? _buildEmptyState('No leaderboard yet', 'Add friends to compete!') :
    RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _leaderboard.length,
      itemBuilder: (_, i) => _LeaderboardTile(entry: _leaderboard[i])));

  Widget _buildFriendsTab() => _isLoading ? const Center(child: CircularProgressIndicator()) :
    _friends.isEmpty ? _buildEmptyState('No friends yet', 'Tap + to add friends!') :
    RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _friends.length,
      itemBuilder: (_, i) => _FriendTile(
        friend: _friends[i],
        onViewGarden: () => _viewFriendGarden(_friends[i]),
      )));

  Widget _buildRequestsTab() => _isLoading ? const Center(child: CircularProgressIndicator()) :
    _requests.isEmpty ? _buildEmptyState('No pending requests', 'Friend requests will appear here') :
    RefreshIndicator(onRefresh: _loadData, child: ListView.builder(
      padding: const EdgeInsets.all(20), itemCount: _requests.length,
      itemBuilder: (_, i) => _RequestTile(request: _requests[i], onAccept: () => _respondToRequest(_requests[i].requestId, true),
        onDecline: () => _respondToRequest(_requests[i].requestId, false))));

  Widget _buildEmptyState(String title, String subtitle) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🌿', style: TextStyle(fontSize: 56)), const SizedBox(height: 16),
    Text(title, style: GoogleFonts.comfortaa(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.soilBrown)),
    const SizedBox(height: 8),
    Text(subtitle, style: GoogleFonts.quicksand(color: AppTheme.soilBrown.withValues(alpha:0.6))),
  ]));
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  const _LeaderboardTile({required this.entry});

  Color get _rankColor {
    switch (entry.rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFC0C0C0);
      case 3: return const Color(0xFFCD7F32);
      default: return AppTheme.soilBrown.withValues(alpha:0.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: entry.isCurrentUser ? AppTheme.leafGreen.withValues(alpha:0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16), border: entry.isCurrentUser ? Border.all(color: AppTheme.leafGreen, width: 2) : null),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: _rankColor.withValues(alpha:0.2), shape: BoxShape.circle),
          child: Center(child: entry.rank <= 3 ? Text(['🥇', '🥈', '🥉'][entry.rank - 1], style: const TextStyle(fontSize: 18)) :
            Text('${entry.rank}', style: GoogleFonts.comfortaa(fontWeight: FontWeight.bold, color: _rankColor)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(entry.odInname, style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          Text('${entry.plantCount} plants', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppTheme.streakOrange, AppTheme.streakYellow]), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.local_fire_department, color: Colors.white, size: 16), const SizedBox(width: 4),
            Text('${entry.streak}', style: GoogleFonts.quicksand(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
          ])),
      ]));
  }
}

class _FriendTile extends StatelessWidget {
  final Friend friend;
  final VoidCallback onViewGarden;
  const _FriendTile({required this.friend, required this.onViewGarden});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.5), shape: BoxShape.circle),
          child: const Center(child: Text('🌱', style: TextStyle(fontSize: 24)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(friend.odInname, style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          Row(children: [const Icon(Icons.local_fire_department, size: 14, color: AppTheme.streakOrange), const SizedBox(width: 4),
            Text('${friend.streak} day streak', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6)))]),
        ])),
        IconButton(icon: const Icon(Icons.visibility, color: AppTheme.leafGreen), onPressed: onViewGarden),
      ]));
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RequestTile({required this.request, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.softSage.withValues(alpha:0.5), shape: BoxShape.circle),
          child: const Center(child: Text('👋', style: TextStyle(fontSize: 24)))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(request.fromUsername, style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.soilBrown)),
          Text('🔥 ${request.streak} day streak', style: GoogleFonts.quicksand(fontSize: 12, color: AppTheme.soilBrown.withValues(alpha:0.6))),
        ])),
        IconButton(icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.leafGreen, shape: BoxShape.circle),
          child: const Icon(Icons.check, color: Colors.white, size: 18)), onPressed: onAccept),
        IconButton(icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.terracotta.withValues(alpha:0.2), shape: BoxShape.circle),
          child: const Icon(Icons.close, color: AppTheme.terracotta, size: 18)), onPressed: onDecline),
      ]));
  }
}