import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../models/forum.dart';
import '../../services/auth_service.dart';
import '../../services/forum_api_service.dart';
import '../../core/constants.dart';
import '../widgets/leaf_background.dart';
import 'subforum_screen.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _feedScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Feed state
  List<ForumPost> _feedPosts = [];
  String? _feedNextKey;
  bool _isLoadingFeed = true;
  bool _isLoadingMoreFeed = false;
  PostSortOrder _feedSort = PostSortOrder.hot;

  // Discover state
  List<Subforum> _trendingSubforums = [];
  List<Subforum> _allSubforums = [];
  List<Subforum> _filteredSubforums = [];
  bool _isLoadingDiscover = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    _loadFeed();
    _loadDiscover();

    _feedScrollController.addListener(_onFeedScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _feedScrollController.dispose();
    _discoverScrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ForumApiService _getApi() {
    final auth = Provider.of<AuthService>(context, listen: false);
    return ForumApiService(auth.idToken!, AppConstants.forumBaseUrl);
  }

  void _onFeedScroll() {
    if (_feedScrollController.position.pixels >=
            _feedScrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMoreFeed &&
        _feedNextKey != null) {
      _loadMoreFeed();
    }
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoadingFeed = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();
      final result = await api.getFeedPosts(
        auth.userId!,
        sort: _feedSort,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _feedPosts = result.items;
          _feedNextKey = result.nextKey;
          _isLoadingFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load feed: $e');
      if (mounted) setState(() => _isLoadingFeed = false);
    }
  }

  Future<void> _loadMoreFeed() async {
    if (_feedNextKey == null) return;
    setState(() => _isLoadingMoreFeed = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();
      final result = await api.getFeedPosts(
        auth.userId!,
        sort: _feedSort,
        lastKey: _feedNextKey,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _feedPosts.addAll(result.items);
          _feedNextKey = result.nextKey;
          _isLoadingMoreFeed = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load more feed: $e');
      if (mounted) setState(() => _isLoadingMoreFeed = false);
    }
  }

  Future<void> _loadDiscover() async {
    setState(() => _isLoadingDiscover = true);

    try {
      final api = _getApi();
      final trending = await api.getTrendingSubforums(limit: 6);
      final all = await api.getSubforums();

      if (mounted) {
        setState(() {
          _trendingSubforums = trending;
          _allSubforums = all;
          _filteredSubforums = all;
          _isLoadingDiscover = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load discover: $e');
      if (mounted) setState(() => _isLoadingDiscover = false);
    }
  }

  void _filterSubforums(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredSubforums = _allSubforums;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredSubforums = _allSubforums.where((sf) {
          return sf.name.toLowerCase().contains(lowerQuery) ||
              sf.description?.toLowerCase().contains(lowerQuery) == true;
        }).toList();
      }
    });
  }

  void _navigateToSubforum(Subforum subforum) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubforumScreen(subforum: subforum),
      ),
    );
    
    // Refresh feed in case user subscribed/unsubscribed
    if (mounted) {
      _loadFeed();
    }
  }

  void _navigateToPost(ForumPost post) async {
    final result = await Navigator.push<ForumPost?>(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );

    // Update the post in the feed list with fresh data if returned
    if (result != null && mounted) {
      setState(() {
        final index = _feedPosts.indexWhere((p) => p.postId == result.postId);
        if (index != -1) {
          _feedPosts[index] = result;
        }
      });
    }
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    );

    if (result == true) {
      _loadFeed();
    }
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
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildFeedTab(),
                    _buildDiscoverTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppTheme.terracotta,
        elevation: 4,
        icon: const Icon(Icons.edit),
        label: Text(
          'Post',
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
            child: const Text('🌿', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: GoogleFonts.comfortaa(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.leafGreen,
                  ),
                ),
                Text(
                  'Connect with plant lovers',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    color: AppTheme.soilBrown.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to notifications
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.soilBrown,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: AppTheme.leafGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.soilBrown,
        labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.dynamic_feed, size: 18),
                SizedBox(width: 6),
                Text('Feed'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.explore, size: 18),
                SizedBox(width: 6),
                Text('Discover'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedTab() {
    return Column(
      children: [
        _buildSortBar(),
        Expanded(
          child: _isLoadingFeed
              ? const Center(child: CircularProgressIndicator())
              : _feedPosts.isEmpty
                  ? _buildEmptyFeed()
                  : RefreshIndicator(
                      onRefresh: _loadFeed,
                      color: AppTheme.leafGreen,
                      child: ListView.builder(
                        controller: _feedScrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _feedPosts.length + (_isLoadingMoreFeed ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _feedPosts.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _PostCard(
                            post: _feedPosts[index],
                            onTap: () => _navigateToPost(_feedPosts[index]),
                            onSubforumTap: () {
                              // Navigate to subforum
                            },
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: PostSortOrder.values.map((sort) {
          final isSelected = _feedSort == sort;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                if (_feedSort != sort) {
                  setState(() => _feedSort = sort);
                  _loadFeed();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.leafGreen : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.leafGreen : AppTheme.softSage,
                  ),
                ),
                child: Row(
                  children: [
                    Text(sort.icon, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      sort.label,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.soilBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyFeed() {
    return Center(
      child: Padding(
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
            const SizedBox(height: 24),
            Text(
              'Your feed is empty',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Join some plant communities to see posts here!',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: const Icon(Icons.explore),
              label: const Text('Discover Communities'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return _isLoadingDiscover
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadDiscover,
            color: AppTheme.leafGreen,
            child: CustomScrollView(
              controller: _discoverScrollController,
              slivers: [
                // Search bar
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterSubforums,
                      decoration: InputDecoration(
                        hintText: 'Search communities...',
                        hintStyle: GoogleFonts.quicksand(
                          color: AppTheme.soilBrown.withValues(alpha: 0.4),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppTheme.leafGreen.withValues(alpha: 0.7),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: AppTheme.soilBrown.withValues(alpha: 0.5),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterSubforums('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.quicksand(
                        color: AppTheme.soilBrown,
                      ),
                    ),
                  ),
                ),

                // Trending section (only when not searching)
                if (!_isSearching && _trendingSubforums.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            'Trending',
                            style: GoogleFonts.comfortaa(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.soilBrown,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _trendingSubforums.length,
                        itemBuilder: (context, index) {
                          return _TrendingSubforumCard(
                            subforum: _trendingSubforums[index],
                            onTap: () =>
                                _navigateToSubforum(_trendingSubforums[index]),
                          );
                        },
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],

                // All communities header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          _isSearching ? 'Results' : 'All Communities',
                          style: GoogleFonts.comfortaa(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.soilBrown,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_filteredSubforums.length} communities',
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subforum list
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= _filteredSubforums.length) return null;
                      return _SubforumListTile(
                        subforum: _filteredSubforums[index],
                        onTap: () =>
                            _navigateToSubforum(_filteredSubforums[index]),
                      );
                    },
                    childCount: _filteredSubforums.length,
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
  }
}

// ============ Widget Components ============

class _PostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;
  final VoidCallback? onSubforumTap;

  const _PostCard({
    required this.post,
    required this.onTap,
    this.onSubforumTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.06),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Author avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.softSage.withValues(alpha: 0.5),
                  backgroundImage: post.authorProfileImage != null
                      ? NetworkImage(post.authorProfileImage!)
                      : null,
                  child: post.authorProfileImage == null
                      ? Text(
                          post.authorUsername[0].toUpperCase(),
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.leafGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorUsername,
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.soilBrown,
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (post.isPinned)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.sunYellow.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin,
                            size: 12, color: AppTheme.sunYellow),
                        const SizedBox(width: 2),
                        Text(
                          'Pinned',
                          style: GoogleFonts.quicksand(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.sunYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              post.title,
              style: GoogleFonts.comfortaa(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            // Body preview
            Text(
              post.body,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.8),
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Image preview if available
            if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls!.first,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: AppTheme.softSage.withValues(alpha: 0.3),
                    child: const Center(
                      child: Icon(Icons.image, color: AppTheme.softSage),
                    ),
                  ),
                ),
              ),
            ],

            // Tags
            if (post.tags != null && post.tags!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: post.tags!.take(3).map((tag) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#$tag',
                      style: GoogleFonts.quicksand(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.leafGreen,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 12),

            // Footer actions
            Row(
              children: [
                // Votes
                _VoteWidget(
                  score: post.score,
                  userVote: post.userVote,
                  compact: true,
                ),
                const SizedBox(width: 16),
                // Comments
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 18,
                      color: AppTheme.soilBrown.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentCount}',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Share
                Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: AppTheme.soilBrown.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteWidget extends StatelessWidget {
  final int score;
  final UserVote? userVote;
  final bool compact;
  final VoidCallback? onUpvote;
  final VoidCallback? onDownvote;

  const _VoteWidget({
    required this.score,
    this.userVote,
    this.compact = false,
    this.onUpvote,
    this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    final isUpvoted = userVote == UserVote.up;
    final isDownvoted = userVote == UserVote.down;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: isUpvoted
            ? AppTheme.leafGreen.withValues(alpha: 0.1)
            : isDownvoted
                ? AppTheme.terracotta.withValues(alpha: 0.1)
                : AppTheme.softSage.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onUpvote,
            child: Icon(
              isUpvoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
              size: compact ? 16 : 20,
              color: isUpvoted
                  ? AppTheme.leafGreen
                  : AppTheme.soilBrown.withValues(alpha: 0.5),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 8),
            child: Text(
              score.toString(),
              style: GoogleFonts.quicksand(
                fontSize: compact ? 13 : 14,
                fontWeight: FontWeight.bold,
                color: isUpvoted
                    ? AppTheme.leafGreen
                    : isDownvoted
                        ? AppTheme.terracotta
                        : AppTheme.soilBrown,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDownvote,
            child: Icon(
              isDownvoted ? Icons.arrow_downward : Icons.arrow_downward_outlined,
              size: compact ? 16 : 20,
              color: isDownvoted
                  ? AppTheme.terracotta
                  : AppTheme.soilBrown.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendingSubforumCard extends StatelessWidget {
  final Subforum subforum;
  final VoidCallback onTap;

  const _TrendingSubforumCard({
    required this.subforum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.leafGreen.withValues(alpha: 0.9),
              AppTheme.mintGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subforum.emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const Spacer(),
            Text(
              subforum.name,
              style: GoogleFonts.comfortaa(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  subforum.formattedMemberCount,
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SubforumListTile extends StatelessWidget {
  final Subforum subforum;
  final VoidCallback onTap;

  const _SubforumListTile({
    required this.subforum,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.softSage.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  subforum.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subforum.name,
                    style: GoogleFonts.comfortaa(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.soilBrown,
                    ),
                  ),
                  if (subforum.description != null)
                    Text(
                      subforum.description!,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: AppTheme.soilBrown.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${subforum.formattedMemberCount} members',
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: AppTheme.soilBrown.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${subforum.postCount} posts',
                        style: GoogleFonts.quicksand(
                          fontSize: 11,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(
              Icons.chevron_right,
              color: AppTheme.soilBrown.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}