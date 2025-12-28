import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/forum.dart';
import '../../services/auth_service.dart';
import '../../services/forum_api_service.dart';
import '../widgets/leaf_background.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

class SubforumScreen extends StatefulWidget {
  final Subforum subforum;
  final String? speciesId; // Alternative: pass speciesId to load subforum

  const SubforumScreen({
    super.key,
    required this.subforum,
    this.speciesId,
  });

  /// Constructor for navigating from plant details
  factory SubforumScreen.fromSpeciesId({
    Key? key,
    required String speciesId,
    required String speciesName,
    required String emoji,
  }) {
    return SubforumScreen(
      key: key,
      subforum: Subforum(
        subforumId: speciesId,
        speciesId: speciesId,
        name: speciesName,
        emoji: emoji,
        memberCount: 0,
        postCount: 0,
        createdAt: DateTime.now(),
      ),
      speciesId: speciesId,
    );
  }

  @override
  State<SubforumScreen> createState() => _SubforumScreenState();
}

class _SubforumScreenState extends State<SubforumScreen> {
  final ScrollController _scrollController = ScrollController();

  late Subforum _subforum;
  List<ForumPost> _posts = [];
  String? _nextKey;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSubscribed = false;
  bool _isTogglingSubscription = false;
  PostSortOrder _sortOrder = PostSortOrder.hot;

  @override
  void initState() {
    super.initState();
    _subforum = widget.subforum;
    _loadSubforum();
    _loadPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  ForumApiService _getApi() {
    final auth = Provider.of<AuthService>(context, listen: false);
    return ForumApiService(auth.idToken!, AppConstants.forumBaseUrl);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _nextKey != null) {
      _loadMorePosts();
    }
  }

  Future<void> _loadSubforum() async {
    try {
      final api = _getApi();
      final subforum = await api.getSubforum(_subforum.speciesId);
      if (mounted) {
        setState(() {
          _subforum = subforum;
          // API returns isSubscribed field
          _isSubscribed = subforum.isSubscribed ?? false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load subforum details: $e');
    }
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);

    try {
      final api = _getApi();
      final result = await api.getSubforumPosts(
        _subforum.speciesId,
        sort: _sortOrder,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _posts = result.items;
          _nextKey = result.nextKey;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load posts: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (_nextKey == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final api = _getApi();
      final result = await api.getSubforumPosts(
        _subforum.speciesId,
        sort: _sortOrder,
        lastKey: _nextKey,
        limit: 20,
      );

      if (mounted) {
        setState(() {
          _posts.addAll(result.items);
          _nextKey = result.nextKey;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load more posts: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleSubscription() async {
    setState(() => _isTogglingSubscription = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();

      if (_isSubscribed) {
        await api.unsubscribeFromSubforum(auth.userId!, _subforum.subforumId);
      } else {
        await api.subscribeToSubforum(auth.userId!, _subforum.subforumId);
      }

      if (mounted) {
        setState(() {
          _isSubscribed = !_isSubscribed;
          // Update local member count
          _subforum = Subforum(
            subforumId: _subforum.subforumId,
            speciesId: _subforum.speciesId,
            name: _subforum.name,
            description: _subforum.description,
            emoji: _subforum.emoji,
            memberCount: _subforum.memberCount + (_isSubscribed ? 1 : -1),
            postCount: _subforum.postCount,
            bannerUrl: _subforum.bannerUrl,
            createdAt: _subforum.createdAt,
            latestPost: _subforum.latestPost,
            isSubscribed: _isSubscribed,
          );
          _isTogglingSubscription = false;
        });
        _showSnackBar(_isSubscribed ? 'Joined community!' : 'Left community');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTogglingSubscription = false);
        _showSnackBar('Failed: $e', isError: true);
      }
    }
  }

  void _navigateToPost(ForumPost post) async {
    final result = await Navigator.push<ForumPost?>(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(post: post),
      ),
    );

    // Update the post in the list with fresh data if returned
    if (result != null && mounted) {
      setState(() {
        final index = _posts.indexWhere((p) => p.postId == result.postId);
        if (index != -1) {
          _posts[index] = result;
        }
      });
    }
  }

  void _navigateToCreatePost() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostScreen(
          preselectedSubforum: _subforum,
        ),
      ),
    );

    if (result == true) {
      _loadPosts();
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
          child: NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxScrolled) => [
              _buildSliverAppBar(),
              SliverToBoxAdapter(child: _buildSubforumHeader()),
              SliverToBoxAdapter(child: _buildSortBar()),
            ],
            body: _buildPostsList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreatePost,
        backgroundColor: AppTheme.terracotta,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: AppTheme.leafGreen),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            // TODO: Share subforum
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.share, color: AppTheme.soilBrown, size: 20),
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: More options
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Icons.more_vert, color: AppTheme.soilBrown, size: 20),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSubforumHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.leafGreen.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Emoji and name
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.softSage.withValues(alpha: 0.5),
                      AppTheme.mintGreen.withValues(alpha: 0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _subforum.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _subforum.name,
                      style: GoogleFonts.comfortaa(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.soilBrown,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_subforum.formattedMemberCount} members',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            color: AppTheme.soilBrown.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.article,
                          size: 16,
                          color: AppTheme.soilBrown.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_subforum.postCount} posts',
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
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

          // Description
          if (_subforum.description != null) ...[
            const SizedBox(height: 16),
            Text(
              _subforum.description!,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Join button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isTogglingSubscription ? null : _toggleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isSubscribed ? AppTheme.softSage : AppTheme.leafGreen,
                foregroundColor:
                    _isSubscribed ? AppTheme.soilBrown : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isTogglingSubscription
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isSubscribed ? Icons.check : Icons.add,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isSubscribed ? 'Joined' : 'Join Community',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            'Posts',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.soilBrown,
            ),
          ),
          const Spacer(),
          ...PostSortOrder.values.map((sort) {
            final isSelected = _sortOrder == sort;
            return Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: () {
                  if (_sortOrder != sort) {
                    setState(() => _sortOrder = sort);
                    _loadPosts();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.leafGreen : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppTheme.leafGreen : AppTheme.softSage,
                    ),
                  ),
                  child: Text(
                    sort.label,
                    style: GoogleFonts.quicksand(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.soilBrown,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPostsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      color: AppTheme.leafGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _SubforumPostCard(
            post: _posts[index],
            onTap: () => _navigateToPost(_posts[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_subforum.emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: GoogleFonts.comfortaa(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to share something about ${_subforum.name}!',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToCreatePost,
              icon: const Icon(Icons.edit),
              label: const Text('Create First Post'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubforumPostCard extends StatelessWidget {
  final ForumPost post;
  final VoidCallback onTap;

  const _SubforumPostCard({
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = post.score < 0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: post.isPinned
              ? Border.all(color: AppTheme.sunYellow, width: 2)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
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
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  post.authorUsername,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.soilBrown,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${post.timeAgo}',
                  style: GoogleFonts.quicksand(
                    fontSize: 12,
                    color: AppTheme.soilBrown.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                if (post.isPinned)
                  Icon(Icons.push_pin, size: 16, color: AppTheme.sunYellow),
              ],
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              post.title,
              style: GoogleFonts.comfortaa(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.soilBrown,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Body preview
            Text(
              post.body,
              style: GoogleFonts.quicksand(
                fontSize: 13,
                color: AppTheme.soilBrown.withValues(alpha: 0.7),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Image thumbnail
            if (post.imageUrls != null && post.imageUrls!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  post.imageUrls!.first,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Footer
            Row(
              children: [
                // Votes - with negative score styling
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isNegative 
                        ? AppTheme.terracotta.withValues(alpha: 0.15)
                        : AppTheme.softSage.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 14,
                        color: isNegative 
                            ? AppTheme.terracotta
                            : AppTheme.soilBrown.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.score}',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isNegative 
                              ? AppTheme.terracotta
                              : AppTheme.soilBrown,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Comments
                Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: AppTheme.soilBrown.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  '${post.commentCount}',
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
    );
  }
}