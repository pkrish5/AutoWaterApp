import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/forum.dart';
import '../../services/auth_service.dart';
import '../../services/forum_api_service.dart';
import '../widgets/leaf_background.dart';
import 'package:flutter/services.dart';

class PostDetailScreen extends StatefulWidget {
  final ForumPost post;
  final String? postId;

  const PostDetailScreen({
    super.key,
    required this.post,
    this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  late ForumPost _post;
  List<ForumComment> _comments = [];
  String? _nextKey;
  bool _isLoadingComments = true;
  bool _isLoadingMore = false;
  bool _isSubmittingComment = false;
  String? _replyingToCommentId;
  String? _replyingToUsername;
  bool _hasInteracted = false; // Track if user voted or commented

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _commentController.dispose();
    _commentFocusNode.dispose();
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
      _loadMoreComments();
    }
  }

  Future<void> _loadComments() async {
    setState(() => _isLoadingComments = true);

    try {
      final api = _getApi();
      final result = await api.getPostComments(_post.postId, limit: 50);

      if (mounted) {
        setState(() {
          _comments = result.items;
          _nextKey = result.nextKey;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_nextKey == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final api = _getApi();
      final result = await api.getPostComments(
        _post.postId,
        lastKey: _nextKey,
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _comments.addAll(result.items);
          _nextKey = result.nextKey;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load more comments: $e');
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _startReply(String commentId, String username) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyingToUsername = username;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUsername = null;
    });
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSubmittingComment = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();

      await api.createComment(
        postId: _post.postId,
        userId: auth.userId!,
        body: body,
        parentCommentId: _replyingToCommentId,
      );

      _commentController.clear();
      _cancelReply();
      
      // Update local comment count
      setState(() {
        _hasInteracted = true;
        _post = ForumPost(
          postId: _post.postId,
          subforumId: _post.subforumId,
          authorId: _post.authorId,
          authorUsername: _post.authorUsername,
          authorProfileImage: _post.authorProfileImage,
          title: _post.title,
          body: _post.body,
          imageUrls: _post.imageUrls,
          upvotes: _post.upvotes,
          downvotes: _post.downvotes,
          commentCount: _post.commentCount + 1,
          createdAt: _post.createdAt,
          updatedAt: _post.updatedAt,
          isPinned: _post.isPinned,
          tags: _post.tags,
          userVote: _post.userVote,
        );
      });
      
      _loadComments();
      _showSnackBar('Comment posted!');
    } catch (e) {
      _showSnackBar('Failed to post comment: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmittingComment = false);
    }
  }

  Future<void> _voteOnPost(UserVote vote) async {
    final currentVote = _post.userVote;
    final newVote = vote == currentVote ? UserVote.none : vote;

    // Optimistic update
    setState(() {
      _hasInteracted = true;
      int newUpvotes = _post.upvotes;
      int newDownvotes = _post.downvotes;

      if (currentVote == UserVote.up) newUpvotes--;
      if (currentVote == UserVote.down) newDownvotes--;
      if (newVote == UserVote.up) newUpvotes++;
      if (newVote == UserVote.down) newDownvotes++;

      _post = ForumPost(
        postId: _post.postId,
        subforumId: _post.subforumId,
        authorId: _post.authorId,
        authorUsername: _post.authorUsername,
        authorProfileImage: _post.authorProfileImage,
        title: _post.title,
        body: _post.body,
        imageUrls: _post.imageUrls,
        upvotes: newUpvotes,
        downvotes: newDownvotes,
        commentCount: _post.commentCount,
        createdAt: _post.createdAt,
        updatedAt: _post.updatedAt,
        isPinned: _post.isPinned,
        tags: _post.tags,
        userVote: newVote,
      );
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();
      await api.voteOnPost(
        postId: _post.postId,
        userId: auth.userId!,
        vote: newVote,
      );
    } catch (e) {
      _showSnackBar('Failed to vote', isError: true);
    }
  }

  Future<void> _voteOnComment(ForumComment comment, UserVote vote) async {
    final currentVote = comment.userVote;
    final newVote = vote == currentVote ? UserVote.none : vote;

    // Find and update comment in list
    setState(() {
      _hasInteracted = true;
      final index = _comments.indexWhere((c) => c.commentId == comment.commentId);
      if (index != -1) {
        int newUpvotes = comment.upvotes;
        int newDownvotes = comment.downvotes;

        if (currentVote == UserVote.up) newUpvotes--;
        if (currentVote == UserVote.down) newDownvotes--;
        if (newVote == UserVote.up) newUpvotes++;
        if (newVote == UserVote.down) newDownvotes++;

        _comments[index] = ForumComment(
          commentId: comment.commentId,
          postId: comment.postId,
          parentCommentId: comment.parentCommentId,
          authorId: comment.authorId,
          authorUsername: comment.authorUsername,
          authorProfileImage: comment.authorProfileImage,
          body: comment.body,
          upvotes: newUpvotes,
          downvotes: newDownvotes,
          createdAt: comment.createdAt,
          updatedAt: comment.updatedAt,
          replies: comment.replies,
          replyCount: comment.replyCount,
          userVote: newVote,
        );
      }
    });

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();
      await api.voteOnComment(
        commentId: comment.commentId,
        userId: auth.userId!,
        vote: newVote,
      );
    } catch (e) {
      _showSnackBar('Failed to vote', isError: true);
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

  void _goBack() {
    Navigator.pop(context, _hasInteracted ? _post : null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.softSage.withValues(alpha:0.3),
        body: LeafBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadComments,
                    color: AppTheme.leafGreen,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(child: _buildPostCard()),
                        SliverToBoxAdapter(child: _buildCommentsHeader()),
                        if (_isLoadingComments)
                          const SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: CircularProgressIndicator(
                                  color: AppTheme.leafGreen,
                                ),
                              ),
                            ),
                          )
                        else if (_comments.isEmpty)
                          SliverToBoxAdapter(child: _buildEmptyComments())
                        else
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if (index == _comments.length) {
                                  return _isLoadingMore
                                      ? const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.leafGreen,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink();
                                }
                                return _buildCommentCard(_comments[index]);
                              },
                              childCount: _comments.length + 1,
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  ),
                ),
                _buildCommentInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.darkBrown),
              onPressed: _goBack,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined, color: AppTheme.darkBrown),
              onPressed: () {
                // Share functionality
              },
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppTheme.darkBrown),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'report') {
                  _showSnackBar('Post reported');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 20),
                      SizedBox(width: 12),
                      Text('Report Post'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard() {
    final isNegative = _post.score < 0;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.leafGreen.withValues(alpha:0.2),
                backgroundImage: _post.authorProfileImage != null
                    ? NetworkImage(_post.authorProfileImage!)
                    : null,
                child: _post.authorProfileImage == null
                    ? Text(
                        _post.authorUsername[0].toUpperCase(),
                        style: GoogleFonts.comfortaa(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.leafGreen,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _post.authorUsername,
                      style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.darkBrown,
                      ),
                    ),
                    Text(
                      _post.timeAgo,
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_post.isPinned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.push_pin, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        'Pinned',
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber[800],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            _post.title,
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBrown,
            ),
          ),
          const SizedBox(height: 12),

          // Body
          Text(
            _post.body,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              color: AppTheme.darkBrown.withValues(alpha:0.8),
              height: 1.5,
            ),
          ),

          // Images
          if (_post.imageUrls != null && _post.imageUrls!.isNotEmpty) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _post.imageUrls!.first,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
          ],

          // Tags
          if (_post.tags != null && _post.tags!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _post.tags!.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreen.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '#$tag',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.leafGreen,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Voting and stats row
          Row(
            children: [
              _buildVoteButton(
                icon: Icons.arrow_upward,
                isActive: _post.userVote == UserVote.up,
                activeColor: AppTheme.leafGreen,
                onTap: () => _voteOnPost(UserVote.up),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${_post.score}',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _post.userVote == UserVote.up
                        ? AppTheme.leafGreen
                        : _post.userVote == UserVote.down || isNegative
                            ? AppTheme.terracotta
                            : AppTheme.darkBrown,
                  ),
                ),
              ),
              _buildVoteButton(
                icon: Icons.arrow_downward,
                isActive: _post.userVote == UserVote.down,
                activeColor: AppTheme.terracotta,
                onTap: () => _voteOnPost(UserVote.down),
              ),
              const SizedBox(width: 24),
              Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${_post.commentCount}',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha:0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive ? activeColor : Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildCommentsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'Comments',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBrown,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.leafGreen.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_post.commentCount}',
              style: GoogleFonts.quicksand(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.leafGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Text(
            '💬',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'No comments yet',
            style: GoogleFonts.comfortaa(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your thoughts!',
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(ForumComment comment, {int depth = 0}) {
    final maxDepth = 3;
    final indent = depth.clamp(0, maxDepth) * 16.0;
    final isNegative = comment.score < 0;

    return Container(
      margin: EdgeInsets.only(
        left: 16 + indent,
        right: 16,
        top: 8,
        bottom: 8,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: depth > 0
            ? Border(
                left: BorderSide(
                  color: AppTheme.leafGreen.withValues(alpha:0.3),
                  width: 2,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author row
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.leafGreen.withValues(alpha:0.2),
                backgroundImage: comment.authorProfileImage != null
                    ? NetworkImage(comment.authorProfileImage!)
                    : null,
                child: comment.authorProfileImage == null
                    ? Text(
                        comment.authorUsername[0].toUpperCase(),
                        style: GoogleFonts.comfortaa(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.leafGreen,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                comment.authorUsername,
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppTheme.darkBrown,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                comment.timeAgo,
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Body
          Text(
            comment.body,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              color: AppTheme.darkBrown.withValues(alpha:0.85),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          // Actions row
          Row(
            children: [
              GestureDetector(
                onTap: () => _voteOnComment(comment, UserVote.up),
                child: Icon(
                  Icons.arrow_upward,
                  size: 18,
                  color: comment.userVote == UserVote.up
                      ? AppTheme.leafGreen
                      : Colors.grey[400],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${comment.score}',
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: comment.userVote == UserVote.up
                        ? AppTheme.leafGreen
                        : comment.userVote == UserVote.down || isNegative
                            ? AppTheme.terracotta
                            : Colors.grey[600],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _voteOnComment(comment, UserVote.down),
                child: Icon(
                  Icons.arrow_downward,
                  size: 18,
                  color: comment.userVote == UserVote.down
                      ? AppTheme.terracotta
                      : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _startReply(comment.commentId, comment.authorUsername),
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 18, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Reply',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nested replies
          if (comment.replies != null && comment.replies!.isNotEmpty)
            Column(
              children: comment.replies!
                  .map((reply) => _buildCommentCard(reply, depth: depth + 1))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyingToUsername != null)
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Replying to ',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '@$_replyingToUsername',
                    style: GoogleFonts.quicksand(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.leafGreen,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: Icon(Icons.close, size: 18, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: GoogleFonts.quicksand(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: _replyingToUsername != null
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: GoogleFonts.quicksand(color: Colors.grey[400]),
                    filled: true,
                    fillColor: AppTheme.softSage.withValues(alpha:0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isSubmittingComment ? null : _submitComment,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppTheme.leafGreen,
                    shape: BoxShape.circle,
                  ),
                  child: _isSubmittingComment
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}