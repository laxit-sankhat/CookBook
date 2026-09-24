import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/auth_provider.dart';
import '../services/recipe_service.dart';
import '../services/favorite_service.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RecipeService _recipeService = RecipeService();
  final FavoriteService _favoriteService = FavoriteService();

  List<RecipeModel> _myRecipes = [];
  List<RecipeModel> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _hasError = false;

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    final token = context.read<AuthProvider>().user!.token;

    try {
      final results = await Future.wait([
        _recipeService.getMyRecipes(token),
        _favoriteService.getFavorites(token),
      ]);
      setState(() {
        _myRecipes = results[0];
        _favorites = results[1];
      });
    } catch (e) {
      print('Profile load error: $e');
      setState(() => _hasError = true);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _deleteRecipe(RecipeModel recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recipe'),
        content: Text('Are you sure you want to delete "${recipe.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final token = context.read<AuthProvider>().user!.token;
    try {
      await _recipeService.deleteRecipe(recipe.id, token);
      setState(() => _myRecipes.removeWhere((r) => r.id == recipe.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _editRecipe(RecipeModel recipe) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => AddRecipeScreen(existingRecipe: recipe)),
    );
    if (changed == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'My Recipes'), Tab(text: 'Favorites')],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  child: Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.name ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user?.email ?? '', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Failed to load your data. Check your connection.'),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                      ],
                    ),
                  )
                : TabBarView(
              controller: _tabController,
              children: [
                _buildMyRecipesTab(),
                _buildFavoritesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRecipesTab() {
    if (_myRecipes.isEmpty) {
      return const Center(child: Text('You haven\'t posted any recipes yet.'));
    }
    return ListView.builder(
      itemCount: _myRecipes.length,
      itemBuilder: (context, index) {
        final recipe = _myRecipes[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              recipe.imageUrl,
              width: 50, height: 50, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50, height: 50, color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          title: Text(recipe.title),
          subtitle: Text(recipe.category),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') _editRecipe(recipe);
              if (value == 'delete') _deleteRecipe(recipe);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return const Center(child: Text('No saved recipes yet.'));
    }
    return ListView.builder(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final recipe = _favorites[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              recipe.imageUrl,
              width: 50, height: 50, fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 50, height: 50, color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
          title: Text(recipe.title),
          subtitle: Text('by ${recipe.createdByName}'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
          ),
        );
      },
    );
  }
}