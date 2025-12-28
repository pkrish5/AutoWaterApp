import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/forum.dart';

/// Forum API service extension
/// Add these methods to your existing ApiService class
/// 
/// Usage: Copy these methods into lib/services/api_service.dart

class ForumApiService {
  final String authToken;
  final String baseUrl;

  ForumApiService(this.authToken, this.baseUrl);

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $authToken',
    'Content-Type': 'application/json',
  };

  // ==================== SUBFORUMS ====================

  /// Get all subforums (optionally filtered by search query)
  Future<List<Subforum>> getSubforums({String? query}) async {
    final uri = Uri.parse('$baseUrl/forum/subforums').replace(
      queryParameters: query != null ? {'q': query} : null,
    );

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Subforum.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subforums: ${response.statusCode}');
    }
  }

  /// Get a specific subforum by species ID
  Future<Subforum> getSubforum(String speciesId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forum/subforums/$speciesId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Subforum.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load subforum: ${response.statusCode}');
    }
  }

  /// Get trending/popular subforums
  Future<List<Subforum>> getTrendingSubforums({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forum/subforums/trending?limit=$limit'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Subforum.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load trending subforums: ${response.statusCode}');
    }
  }

  /// Get subforums the user is subscribed to
  Future<List<Subforum>> getSubscribedSubforums(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/subscribed-forums'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => Subforum.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscribed subforums: ${response.statusCode}');
    }
  }

  /// Subscribe to a subforum
  Future<void> subscribeToSubforum(String userId, String subforumId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forum/subforums/$subforumId/subscribe'),
      headers: _headers,
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to subscribe: ${response.statusCode}');
    }
  }

  /// Unsubscribe from a subforum
  Future<void> unsubscribeFromSubforum(String userId, String subforumId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/forum/subforums/$subforumId/subscribe?userId=$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unsubscribe: ${response.statusCode}');
    }
  }

  // ==================== POSTS ====================

  /// Get posts from a subforum
  Future<PaginatedPosts> getSubforumPosts(
    String subforumId, {
    PostSortOrder sort = PostSortOrder.hot,
    String? lastKey,
    int limit = 20,
  }) async {
    final queryParams = {
      'sort': sort.name,
      'limit': limit.toString(),
      if (lastKey != null) 'lastKey': lastKey,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/forum/subforums/$subforumId/posts')
          .replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PaginatedPosts.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load posts: ${response.statusCode}');
    }
  }

  /// Get feed posts (from subscribed subforums)
  Future<PaginatedPosts> getFeedPosts(
    String userId, {
    PostSortOrder sort = PostSortOrder.hot,
    String? lastKey,
    int limit = 20,
  }) async {
    final queryParams = {
      'sort': sort.name,
      'limit': limit.toString(),
      if (lastKey != null) 'lastKey': lastKey,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId/feed')
          .replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PaginatedPosts.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load feed: ${response.statusCode}');
    }
  }

  /// Get a single post by ID
  Future<ForumPost> getPost(String postId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forum/posts/$postId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return ForumPost.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load post: ${response.statusCode}');
    }
  }

  /// Create a new post
  Future<ForumPost> createPost({
    required String subforumId,
    required String userId,
    required String title,
    required String body,
    List<String>? imageUrls,
    List<String>? tags,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forum/subforums/$subforumId/posts'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'body': body,
        if (imageUrls != null) 'imageUrls': imageUrls,
        if (tags != null) 'tags': tags,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumPost.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create post');
    }
  }

  /// Update a post
  Future<ForumPost> updatePost({
    required String postId,
    required String userId,
    String? title,
    String? body,
    List<String>? tags,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/forum/posts/$postId'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (tags != null) 'tags': tags,
      }),
    );

    if (response.statusCode == 200) {
      return ForumPost.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update post: ${response.statusCode}');
    }
  }

  /// Delete a post
  Future<void> deletePost(String postId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/forum/posts/$postId?userId=$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete post: ${response.statusCode}');
    }
  }

  /// Vote on a post
  Future<void> voteOnPost({
    required String postId,
    required String userId,
    required UserVote vote,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forum/posts/$postId/vote'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'vote': vote.name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to vote: ${response.statusCode}');
    }
  }

  // ==================== COMMENTS ====================

  /// Get comments for a post
  Future<PaginatedComments> getPostComments(
    String postId, {
    String? lastKey,
    int limit = 50,
  }) async {
    final queryParams = {
      'limit': limit.toString(),
      if (lastKey != null) 'lastKey': lastKey,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/forum/posts/$postId/comments')
          .replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PaginatedComments.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  /// Get replies to a comment
  Future<List<ForumComment>> getCommentReplies(String commentId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/forum/comments/$commentId/replies'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => ForumComment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load replies: ${response.statusCode}');
    }
  }

  /// Create a comment
  Future<ForumComment> createComment({
    required String postId,
    required String userId,
    required String body,
    String? parentCommentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forum/posts/$postId/comments'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'body': body,
        if (parentCommentId != null) 'parentCommentId': parentCommentId,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return ForumComment.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['error'] ?? 'Failed to create comment');
    }
  }

  /// Update a comment
  Future<ForumComment> updateComment({
    required String commentId,
    required String userId,
    required String body,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/forum/comments/$commentId'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'body': body,
      }),
    );

    if (response.statusCode == 200) {
      return ForumComment.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update comment: ${response.statusCode}');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId, String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/forum/comments/$commentId?userId=$userId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete comment: ${response.statusCode}');
    }
  }

  /// Vote on a comment
  Future<void> voteOnComment({
    required String commentId,
    required String userId,
    required UserVote vote,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forum/comments/$commentId/vote'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'vote': vote.name,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to vote: ${response.statusCode}');
    }
  }

  // ==================== SEARCH ====================

  /// Search posts across all subforums
  Future<PaginatedPosts> searchPosts(
    String query, {
    String? subforumId,
    String? lastKey,
    int limit = 20,
  }) async {
    final queryParams = {
      'q': query,
      'limit': limit.toString(),
      if (subforumId != null) 'subforumId': subforumId,
      if (lastKey != null) 'lastKey': lastKey,
    };

    final response = await http.get(
      Uri.parse('$baseUrl/forum/search')
          .replace(queryParameters: queryParams),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return PaginatedPosts.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to search: ${response.statusCode}');
    }
  }
}