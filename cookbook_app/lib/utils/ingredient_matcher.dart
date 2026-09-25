import '../data/ingredient_suggestions.dart';

/// Returns up to five likely ingredient matches for the word being typed.
/// Exact prefixes rank first; edit distance allows for small spelling mistakes.
List<String> findIngredientSuggestions(String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.length < 3) return const [];

  final maxEdits = normalizedQuery.length < 5 ? 1 : 2;
  final rankedSuggestions = <MapEntry<int, String>>[];
  for (final ingredient in ingredientSuggestions) {
    if (ingredient.toLowerCase() == normalizedQuery) continue;

    final score = _ingredientMatchScore(ingredient, normalizedQuery, maxEdits);
    if (score <= maxEdits) rankedSuggestions.add(MapEntry(score, ingredient));
  }

  rankedSuggestions.sort((a, b) {
    final scoreOrder = a.key.compareTo(b.key);
    return scoreOrder != 0 ? scoreOrder : a.value.compareTo(b.value);
  });
  return rankedSuggestions.take(5).map((entry) => entry.value).toList();
}

int _ingredientMatchScore(String ingredient, String query, int maxEdits) {
  final words = ingredient.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
  var bestScore = maxEdits + 1;

  for (final word in words) {
    if (word.startsWith(query)) return 0;

    final shortestPrefix = query.length - maxEdits < 1 ? 1 : query.length - maxEdits;
    final longestPrefix = query.length + maxEdits > word.length
        ? word.length
        : query.length + maxEdits;
    for (var length = shortestPrefix; length <= longestPrefix; length++) {
      final score = _editDistance(query, word.substring(0, length));
      if (score < bestScore) bestScore = score;
      if (bestScore == 0) return 0;
    }
  }

  return bestScore;
}

int _editDistance(String first, String second) {
  var previousRow = List<int>.generate(second.length + 1, (index) => index);

  for (var row = 1; row <= first.length; row++) {
    final currentRow = List<int>.filled(second.length + 1, 0);
    currentRow[0] = row;
    for (var column = 1; column <= second.length; column++) {
      final substitutionCost = first.codeUnitAt(row - 1) == second.codeUnitAt(column - 1) ? 0 : 1;
      currentRow[column] = [
        currentRow[column - 1] + 1,
        previousRow[column] + 1,
        previousRow[column - 1] + substitutionCost,
      ].reduce((a, b) => a < b ? a : b);
    }
    previousRow = currentRow;
  }

  return previousRow[second.length];
}
