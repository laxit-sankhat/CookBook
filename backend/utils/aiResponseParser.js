/**
 * aiResponseParser.js
 * 
 * PURPOSE:
 * This acts as an "Anti-Corruption Layer" (ACL) for our backend. We should never trust 
 * raw output from an AI model. This file cleans, validates, and parses the response 
 * before it ever reaches the user.
 */
const parseAndValidateAIResponse = (rawResponseText) => {
  let jsonString = rawResponseText;

  // Sometimes AI ignores instructions and wraps JSON in markdown blocks (e.g. ```json ... ```)
  // This regex extracts just the JSON part to prevent parse errors.
  if (jsonString.includes('```')) {
    const match = jsonString.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (match && match[1]) {
      jsonString = match[1];
    }
  }

  let parsedData;
  try {
    // Attempt to convert the string into a real JavaScript object
    parsedData = JSON.parse(jsonString);
  } catch (error) {
    throw new Error('AI_PARSE_ERROR');
  }

  // Ensure the AI actually returned the "recipes" array we asked for
  if (!parsedData || !Array.isArray(parsedData.recipes)) {
    throw new Error('AI_INVALID_STRUCTURE');
  }

  // Filter and map to application DTO (Data Transfer Object)
  // We strictly enforce data types so our Flutter app doesn't crash from unexpected types.
  const MAX_RECIPES = 3;
  const processedRecipes = parsedData.recipes
    .filter(recipe => recipe.name && recipe.instructions && recipe.instructions.length > 0)
    .slice(0, MAX_RECIPES)
    .map(recipe => {
      // Clamping matchPercentage between 0 and 100
      let matchPercentage = Number(recipe.matchPercentage);
      if (isNaN(matchPercentage)) matchPercentage = 0;
      matchPercentage = Math.max(0, Math.min(100, matchPercentage));

      // Converting estimatedCookingTime to a clean number
      let time = Number(recipe.estimatedCookingTime);
      if (isNaN(time)) time = 0;

      return {
        name: String(recipe.name || 'Unknown Recipe').trim(),
        description: String(recipe.description || '').trim(),
        matchPercentage: matchPercentage,
        availableIngredients: Array.isArray(recipe.availableIngredients) ? recipe.availableIngredients.map(String) : [],
        missingIngredients: Array.isArray(recipe.missingIngredients) ? recipe.missingIngredients.map(String) : [],
        estimatedCookingTime: Math.max(0, time),
        difficulty: String(recipe.difficulty || 'Medium').trim(),
        instructions: Array.isArray(recipe.instructions) ? recipe.instructions.map(String) : []
      };
    });

  if (processedRecipes.length === 0) {
    throw new Error('AI_NO_VALID_RECIPES');
  }

  return { recipes: processedRecipes };
};

module.exports = {
  parseAndValidateAIResponse
};
