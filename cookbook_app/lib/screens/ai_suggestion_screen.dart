/**
 * ai_suggestion_screen.dart
 * 
 * PURPOSE:
 * The frontend user interface for the AI Magic feature. 
 * It collects ingredients and preferences, sends them to the provider,
 * and handles the dynamic loading states (the cycling text messages).
 * When recipes arrive, it displays them as beautiful cards.
 */
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_suggestion_provider.dart';
import '../providers/auth_provider.dart';
import '../models/ai_suggestion_model.dart';

class AiSuggestionScreen extends StatefulWidget {
  const AiSuggestionScreen({super.key});

  @override
  State<AiSuggestionScreen> createState() => _AiSuggestionScreenState();
}

class _AiSuggestionScreenState extends State<AiSuggestionScreen> {
  final _ingredientsController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _preferencesController = TextEditingController();
  final _maxTimeController = TextEditingController();
  
  @override
  void dispose() {
    _ingredientsController.dispose();
    _instructionsController.dispose();
    _preferencesController.dispose();
    _maxTimeController.dispose();
    super.dispose();
  }

  void _generateRecipes() {
    final ingredients = _ingredientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least one ingredient')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final suggestionProvider = Provider.of<AiSuggestionProvider>(context, listen: false);

    final maxTime = int.tryParse(_maxTimeController.text.trim());

    suggestionProvider.fetchSuggestions(
      token: authProvider.user?.token ?? '',
      ingredients: ingredients,
      instructions: _instructionsController.text.trim(),
      dietaryPreferences: _preferencesController.text.trim(),
      maxTime: maxTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recipe Magic'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<AiSuggestionProvider>(context, listen: false).clearSuggestions();
              _ingredientsController.clear();
              _instructionsController.clear();
              _preferencesController.clear();
              _maxTimeController.clear();
            },
          )
        ],
      ),
      body: Consumer<AiSuggestionProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              if (provider.suggestions.isEmpty && !provider.isLoading)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          "What's in your fridge?",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _ingredientsController,
                          decoration: const InputDecoration(
                            labelText: 'Ingredients (comma separated)',
                            hintText: 'e.g., potato, tomato, onion',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.kitchen),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _instructionsController,
                          decoration: const InputDecoration(
                            labelText: 'Any specific mood? (Optional)',
                            hintText: 'e.g., something spicy and quick',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.restaurant_menu),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _preferencesController,
                          decoration: const InputDecoration(
                            labelText: 'Dietary Preferences (Optional)',
                            hintText: 'e.g., vegan, gluten-free',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.health_and_safety),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _maxTimeController,
                          decoration: const InputDecoration(
                            labelText: 'Max Time in minutes (Optional)',
                            hintText: 'e.g., 30',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.timer),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _generateRecipes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Generate Magic Recipe',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        if (provider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              provider.error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

              if (provider.isLoading)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        _LoadingStepsWidget(),
                      ],
                    ),
                  ),
                ),

              if (provider.suggestions.isNotEmpty && !provider.isLoading)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.suggestions.length,
                    itemBuilder: (context, index) {
                      final suggestion = provider.suggestions[index];
                      return _buildSuggestionCard(suggestion);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSuggestionCard(AiSuggestionModel suggestion) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    suggestion.name,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Chip(
                  label: Text('${suggestion.matchPercentage}% Match'),
                  backgroundColor: Colors.green.shade100,
                  labelStyle: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              suggestion.description,
              style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${suggestion.estimatedCookingTime} mins'),
                const SizedBox(width: 16),
                Icon(Icons.assessment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(suggestion.difficulty),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...suggestion.instructions.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${entry.key + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class _LoadingStepsWidget extends StatefulWidget {
  const _LoadingStepsWidget();

  @override
  State<_LoadingStepsWidget> createState() => _LoadingStepsWidgetState();
}

class _LoadingStepsWidgetState extends State<_LoadingStepsWidget> {
  final List<String> _steps = [
    'Analyzing your ingredients...',
    'Connecting to Chef AI...',
    'Drafting the perfect recipe...',
    'Adding a pinch of magic...',
    'Server is busy, retrying in background...',
    'Almost there...',
  ];
  
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          if (_currentIndex < _steps.length - 1) {
            _currentIndex++;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Text(
        _steps[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }
}
