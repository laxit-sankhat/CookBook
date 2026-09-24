import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../models/comment_model.dart';
import '../providers/auth_provider.dart';
import '../services/like_service.dart';
import '../services/comment_service.dart';
import '../services/favorite_service.dart';

class RecipeDetailScreen extends StatefulWidget {
  final RecipeModel recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  final LikeService _likeService = LikeService();
  final CommentService _commentService = CommentService();
  final _commentController = TextEditingController();
  final FavoriteService _favoriteService = FavoriteService();

  bool _isFavorited = false;
  bool _isTogglingFavorite = false;

  bool _isLiked = false;
  late int _likesCount;
  bool _isTogglingLike = false;

  List<CommentModel> _comments = [];
  late int _commentsCount;
  bool _isLoadingComments = true;
  bool _isPostingComment = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.recipe.likesCount;
    _commentsCount = widget.recipe.commentsCount;
    _fetchLikeStatus();
    _fetchComments();
    _fetchFavoriteStatus();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchLikeStatus() async {
    final token = context.read<AuthProvider>().user!.token;
    try {
      final liked = await _likeService.checkLikeStatus(widget.recipe.id, token);
      if (mounted) setState(() => _isLiked = liked);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    if (_isTogglingLike) return;
    setState(() => _isTogglingLike = true);

    final token = context.read<AuthProvider>().user!.token;
    try {
      final result = await _likeService.toggleLike(widget.recipe.id, token);
      setState(() {
        _isLiked = result['liked'];
        _likesCount = result['likesCount'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    setState(() => _isTogglingLike = false);
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await _commentService.getComments(widget.recipe.id);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {
      // fails silently, same reasoning as like status — non-critical to the screen loading
    }
    if (mounted) setState(() => _isLoadingComments = false);
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPostingComment) return;

    setState(() => _isPostingComment = true);
    final token = context.read<AuthProvider>().user!.token;

    try {
      final newComment = await _commentService.addComment(widget.recipe.id, text, token);
      setState(() {
        _comments.insert(0, newComment);
        _commentsCount += 1;
        _commentController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    setState(() => _isPostingComment = false);
  }

  Future<void> _deleteComment(CommentModel comment) async {
    final token = context.read<AuthProvider>().user!.token;
    try {
      await _commentService.deleteComment(comment.id, token);
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
        _commentsCount = _commentsCount > 0 ? _commentsCount - 1 : 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _fetchFavoriteStatus() async {
    final token = context.read<AuthProvider>().user!.token;
    try {
      final favorited = await _favoriteService.checkFavoriteStatus(widget.recipe.id, token);
      if (mounted) setState(() => _isFavorited = favorited);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    setState(() => _isTogglingFavorite = true);

    final token = context.read<AuthProvider>().user!.token;
    try {
      final favorited = await _favoriteService.toggleFavorite(widget.recipe.id, token);
      setState(() => _isFavorited = favorited);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
    setState(() => _isTogglingFavorite = false);
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final currentUserId = context.watch<AuthProvider>().user?.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('by ${recipe.createdByName}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Chip(label: Text(recipe.category)),
                      const SizedBox(width: 8),
                      Chip(label: Text(recipe.difficulty)),
                      const SizedBox(width: 8),
                      Chip(label: Text('${recipe.cookingTime} min')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('$_likesCount likes'),
                      const SizedBox(width: 20),
                      const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('$_commentsCount comments'),
                    ],
                  ),
                  const Divider(height: 32),

                  const Text('Ingredients',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map(
                        (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item, style: const TextStyle(fontSize: 16))),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 32),

                  const Text('Instructions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(recipe.instructions, style: const TextStyle(fontSize: 16, height: 1.5)),
                  const Divider(height: 32),

                  const Text('Comments',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isPostingComment
                          ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _postComment,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator())
                  else if (_comments.isEmpty)
                    const Text('No comments yet. Be the first!', style: TextStyle(color: Colors.grey))
                  else
                    ..._comments.map(
                          (comment) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(comment.userName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(comment.text, style: const TextStyle(fontSize: 15)),
                                ],
                              ),
                            ),
                            if (comment.userId == currentUserId)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                                onPressed: () => _deleteComment(comment),
                              ),
                          ],
                        ),
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
}