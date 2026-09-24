import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/recipe_model.dart';
import '../providers/auth_provider.dart';
import '../providers/recipe_provider.dart';
import '../services/upload_service.dart';
import 'package:http_parser/http_parser.dart';

class AddRecipeScreen extends StatefulWidget {
  final VoidCallback? onSuccess;
  final RecipeModel? existingRecipe; // ← null = Add mode, non-null = Edit mode

  const AddRecipeScreen({super.key, this.onSuccess, this.existingRecipe});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _ingredientsController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _cookingTimeController;

  late String _category;
  late String _difficulty;
  File? _selectedImage;
  bool _isUploading = false;
  String? _uploadError;

  final List<String> _categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snacks'];
  final List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  bool get _isEditMode => widget.existingRecipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.existingRecipe;
    _titleController = TextEditingController(text: r?.title ?? '');
    _ingredientsController = TextEditingController(text: r?.ingredients.join('\n') ?? '');
    _instructionsController = TextEditingController(text: r?.instructions ?? '');
    _cookingTimeController = TextEditingController(text: r?.cookingTime.toString() ?? '');
    _category = r?.category ?? 'Dinner';
    _difficulty = r?.difficulty ?? 'Easy';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _cookingTimeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditMode && _selectedImage == null) {
      setState(() => _uploadError = 'Please select an image');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final token = context.read<AuthProvider>().user!.token;

      String imageUrl = widget.existingRecipe?.imageUrl ?? '';
      if (_selectedImage != null) {
        imageUrl = await UploadService().uploadImage(_selectedImage!, token);
      }

      final ingredients = _ingredientsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      bool success;

      if (_isEditMode) {
        success = await context.read<RecipeProvider>().updateRecipe(
          token,
          widget.existingRecipe!.id,
          {
            'title': _titleController.text.trim(),
            'category': _category,
            'imageUrl': imageUrl,
            'ingredients': ingredients,
            'instructions': _instructionsController.text.trim(),
            'cookingTime': int.parse(_cookingTimeController.text.trim()),
            'difficulty': _difficulty,
          },
        );
      } else {
        success = await context.read<RecipeProvider>().createRecipe(
          token: token,
          title: _titleController.text.trim(),
          category: _category,
          imageUrl: imageUrl,
          ingredients: ingredients,
          instructions: _instructionsController.text.trim(),
          cookingTime: int.parse(_cookingTimeController.text.trim()),
          difficulty: _difficulty,
        );
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditMode ? 'Recipe updated!' : 'Recipe published!')),
        );
        if (_isEditMode) {
          Navigator.pop(context, true); // tell the previous screen it changed
        } else {
          _titleController.clear();
          _ingredientsController.clear();
          _instructionsController.clear();
          _cookingTimeController.clear();
          setState(() => _selectedImage = null);
          widget.onSuccess?.call();
        }
      } else {
        setState(() => _uploadError = context.read<RecipeProvider>().errorMessage);
      }
    } catch (e) {
      setState(() => _uploadError = e.toString().replaceAll('Exception: ', ''));
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? 'Edit Recipe' : 'Add Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: kIsWeb ? null : _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Recipe Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a recipe name' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _ingredientsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Ingredients', hintText: 'One ingredient per line', border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter at least one ingredient' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _instructionsController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Instructions', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter instructions' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cookingTimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cooking Time (minutes)', border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter cooking time';
                  final n = int.tryParse(v);
                  if (n == null) return 'Enter a valid number';
                  if (n < 1 || n > 300) return 'Must be between 1 and 300 minutes';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                items: _difficulties.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (value) => setState(() => _difficulty = value!),
              ),
              const SizedBox(height: 24),

              if (_uploadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_uploadError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),

              ElevatedButton(
                onPressed: _isUploading ? null : _handleSubmit,
                child: _isUploading
                    ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isEditMode ? 'Update' : 'Publish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage != null) {
      return ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(_selectedImage!, fit: BoxFit.cover));
    }
    if (_isEditMode && widget.existingRecipe!.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          widget.existingRecipe!.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      );
    }
    return Center(
      child: kIsWeb
          ? const Text('Image upload only works on\nAndroid Emulator / real device', textAlign: TextAlign.center)
          : const Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Tap to select an image'),
      ]),
    );
  }
}