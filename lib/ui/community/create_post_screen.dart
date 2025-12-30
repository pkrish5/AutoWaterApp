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

class CreatePostScreen extends StatefulWidget {
  final Subforum? preselectedSubforum;

  const CreatePostScreen({
    super.key,
    this.preselectedSubforum,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _tagController = TextEditingController();

  String? _selectedSubforumId;
  List<Subforum> _subforums = [];
  final List<String> _tags = [];
  bool _isLoadingSubforums = true;
  bool _isSubmitting = false;

  Subforum? get _selectedSubforum => _subforums.isEmpty 
      ? null 
      : _subforums.cast<Subforum?>().firstWhere(
          (s) => s?.subforumId == _selectedSubforumId,
          orElse: () => null,
        );

  @override
  void initState() {
    super.initState();
    _selectedSubforumId = widget.preselectedSubforum?.subforumId;
    _loadSubforums();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  ForumApiService _getApi() {
    final auth = Provider.of<AuthService>(context, listen: false);
    return ForumApiService(auth.idToken!, AppConstants.forumBaseUrl);
  }

  Future<void> _loadSubforums() async {
    try {
      final api = _getApi();
      final subforums = await api.getSubforums();

      if (mounted) {
        setState(() {
          _subforums = subforums;
          _isLoadingSubforums = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load subforums: $e');
      if (mounted) setState(() => _isLoadingSubforums = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim().toLowerCase().replaceAll(' ', '-');
    if (tag.isNotEmpty && !_tags.contains(tag) && _tags.length < 5) {
      setState(() {
        _tags.add(tag);
        _tagController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSubforum == null) {
      _showSnackBar('Please select a community', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final api = _getApi();

      await api.createPost(
        subforumId: _selectedSubforum!.subforumId,
        userId: auth.userId!,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        tags: _tags.isNotEmpty ? _tags : null,
      );

      _showSnackBar('Post created!');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Failed to create post: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
      backgroundColor: AppTheme.softSage.withValues(alpha:0.3),
      body: LeafBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubforumSelector(),
                        const SizedBox(height: 20),
                        _buildTitleField(),
                        const SizedBox(height: 20),
                        _buildBodyField(),
                        const SizedBox(height: 20),
                        _buildTagsSection(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
              icon: const Icon(Icons.close, color: AppTheme.darkBrown),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Create Post',
            style: GoogleFonts.comfortaa(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBrown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubforumSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community',
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
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
          child: _isLoadingSubforums
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.leafGreen,
                      ),
                    ),
                  ),
                )
              : DropdownButtonFormField<String>(
                  initialValue: _selectedSubforumId,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  hint: Text(
                    'Select a community',
                    style: GoogleFonts.quicksand(color: Colors.grey[500]),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down),
                  isExpanded: true,
                  items: _subforums.map((subforum) {
                    return DropdownMenuItem<String>(
                      value: subforum.subforumId,
                      child: Row(
                        children: [
                          Text(
                            subforum.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              subforum.name,
                              style: GoogleFonts.quicksand(
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedSubforumId = value);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.quicksand(fontSize: 16),
          maxLength: 200,
          decoration: InputDecoration(
            hintText: 'Give your post a title',
            hintStyle: GoogleFonts.quicksand(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: GoogleFonts.quicksand(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a title';
            }
            if (value.trim().length < 5) {
              return 'Title must be at least 5 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBodyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body',
          style: GoogleFonts.comfortaa(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkBrown,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _bodyController,
          textCapitalization: TextCapitalization.sentences,
          style: GoogleFonts.quicksand(fontSize: 15),
          maxLines: 8,
          minLines: 5,
          maxLength: 5000,
          decoration: InputDecoration(
            hintText: 'Share your thoughts, questions, or experiences...',
            hintStyle: GoogleFonts.quicksand(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            counterStyle: GoogleFonts.quicksand(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter some content';
            }
            if (value.trim().length < 20) {
              return 'Body must be at least 20 characters';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: GoogleFonts.comfortaa(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBrown,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(optional, up to 5)',
              style: GoogleFonts.quicksand(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Tags display
        if (_tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.leafGreen.withValues(alpha:0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$tag',
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.leafGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _removeTag(tag),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.leafGreen.withValues(alpha:0.7),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Tag input
        if (_tags.length < 5)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  style: GoogleFonts.quicksand(fontSize: 14),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addTag(),
                  decoration: InputDecoration(
                    hintText: 'Add a tag',
                    hintStyle: GoogleFonts.quicksand(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: '#',
                    prefixStyle: GoogleFonts.quicksand(
                      color: AppTheme.leafGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addTag,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.leafGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitPost,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.leafGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Post',
                style: GoogleFonts.comfortaa(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}