/// Forum models for the Buddi community feature
library;

class Subforum {
  final String subforumId;
  final String speciesId;
  final String name;
  final String? description;
  final String emoji;
  final int memberCount;
  final int postCount;
  final String? bannerUrl;
  final DateTime createdAt;
  final ForumPost? latestPost;
  final bool? isSubscribed;

  Subforum({
    required this.subforumId,
    required this.speciesId,
    required this.name,
    this.description,
    required this.emoji,
    required this.memberCount,
    required this.postCount,
    this.bannerUrl,
    required this.createdAt,
    this.latestPost,
    this.isSubscribed,
  });

  factory Subforum.fromJson(Map<String, dynamic> json) {
    return Subforum(
      subforumId: json['subforumId'] ?? json['speciesId'] ?? '',
      speciesId: json['speciesId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      emoji: json['emoji'] ?? '🪴',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      bannerUrl: json['bannerUrl'],
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['createdAt'] < 1000000000000
                  ? json['createdAt'] * 1000
                  : json['createdAt'],
            )
          : DateTime.now(),
      latestPost: json['latestPost'] != null
          ? ForumPost.fromJson(json['latestPost'])
          : null,
      isSubscribed: json['isSubscribed'] as bool?,
    );
  }

  String get formattedMemberCount {
    if (memberCount >= 1000000) {
      return '${(memberCount / 1000000).toStringAsFixed(1)}M';
    } else if (memberCount >= 1000) {
      return '${(memberCount / 1000).toStringAsFixed(1)}K';
    }
    return '$memberCount';
  }
}

class ForumPost {
  final String postId;
  final String subforumId;
  final String authorId;
  final String authorUsername;
  final String? authorProfileImage;
  final String title;
  final String body;
  final List<String>? imageUrls;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;
  final List<String>? tags;
  final UserVote? userVote;

  ForumPost({
    required this.postId,
    required this.subforumId,
    required this.authorId,
    required this.authorUsername,
    this.authorProfileImage,
    required this.title,
    required this.body,
    this.imageUrls,
    required this.upvotes,
    required this.downvotes,
    required this.commentCount,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.tags,
    this.userVote,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      postId: json['postId'] ?? '',
      subforumId: json['subforumId'] ?? '',
      authorId: json['authorId'] ?? '',
      authorUsername: json['authorUsername'] ?? 'Anonymous',
      authorProfileImage: json['authorProfileImage'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : null,
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? _parseDateTime(json['updatedAt'])
          : null,
      isPinned: json['isPinned'] ?? false,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      userVote: json['userVote'] != null
          ? UserVote.values.firstWhere(
              (v) => v.name == json['userVote'],
              orElse: () => UserVote.none,
            )
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value < 1000000000000 ? value * 1000 : value,
      );
    }
    return DateTime.now();
  }

  int get score => upvotes - downvotes;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[createdAt.month - 1]} ${createdAt.day}, ${createdAt.year}';
  }
}

class ForumComment {
  final String commentId;
  final String postId;
  final String? parentCommentId;
  final String authorId;
  final String authorUsername;
  final String? authorProfileImage;
  final String body;
  final int upvotes;
  final int downvotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ForumComment>? replies;
  final int replyCount;
  final UserVote? userVote;

  ForumComment({
    required this.commentId,
    required this.postId,
    this.parentCommentId,
    required this.authorId,
    required this.authorUsername,
    this.authorProfileImage,
    required this.body,
    required this.upvotes,
    required this.downvotes,
    required this.createdAt,
    this.updatedAt,
    this.replies,
    this.replyCount = 0,
    this.userVote,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      commentId: json['commentId'] ?? '',
      postId: json['postId'] ?? '',
      parentCommentId: json['parentCommentId'],
      authorId: json['authorId'] ?? '',
      authorUsername: json['authorUsername'] ?? 'Anonymous',
      authorProfileImage: json['authorProfileImage'],
      body: json['body'] ?? '',
      upvotes: (json['upvotes'] as num?)?.toInt() ?? 0,
      downvotes: (json['downvotes'] as num?)?.toInt() ?? 0,
      createdAt: ForumPost._parseDateTime(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? ForumPost._parseDateTime(json['updatedAt'])
          : null,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((r) => ForumComment.fromJson(r))
              .toList()
          : null,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      userVote: json['userVote'] != null
          ? UserVote.values.firstWhere(
              (v) => v.name == json['userVote'],
              orElse: () => UserVote.none,
            )
          : null,
    );
  }

  int get score => upvotes - downvotes;

  String get timeAgo {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }
}

enum UserVote { none, up, down }

enum PostSortOrder { hot, newest, top }

extension PostSortOrderExtension on PostSortOrder {
  String get label {
    switch (this) {
      case PostSortOrder.hot:
        return 'Hot';
      case PostSortOrder.newest:
        return 'New';
      case PostSortOrder.top:
        return 'Top';
    }
  }

  String get icon {
    switch (this) {
      case PostSortOrder.hot:
        return '🔥';
      case PostSortOrder.newest:
        return '✨';
      case PostSortOrder.top:
        return '🏆';
    }
  }
}

class PaginatedPosts {
  final List<ForumPost> items;
  final String? nextKey;
  final int totalCount;

  PaginatedPosts({
    required this.items,
    this.nextKey,
    this.totalCount = 0,
  });

  factory PaginatedPosts.fromJson(Map<String, dynamic> json) {
    return PaginatedPosts(
      items: (json['items'] as List?)
              ?.map((e) => ForumPost.fromJson(e))
              .toList() ??
          [],
      nextKey: json['nextKey'],
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaginatedComments {
  final List<ForumComment> items;
  final String? nextKey;

  PaginatedComments({
    required this.items,
    this.nextKey,
  });

  factory PaginatedComments.fromJson(Map<String, dynamic> json) {
    return PaginatedComments(
      items: (json['items'] as List?)
              ?.map((e) => ForumComment.fromJson(e))
              .toList() ??
          [],
      nextKey: json['nextKey'],
    );
  }
}