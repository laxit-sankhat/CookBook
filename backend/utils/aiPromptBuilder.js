/**
 * aiPromptBuilder.js
 * 
 * PURPOSE:
 * This file is responsible for taking the raw user inputs (ingredients, mood, time, etc.)
 * and converting them into a highly specific, structured prompt for the Gemini AI.
 * 
 * WHY THIS IS IMPORTANT:
 * AI models are unpredictable. If we just ask "Give me a recipe", it might reply with 
 * a paragraph of chat text, which our Flutter app cannot parse. By defining a strict
 * JSON schema in the prompt, we force the AI to return data that matches our frontend models!
 */

const buildRecipePrompt = ({ ingredients, instructions, dietaryPreferences, maxTime }) => {
  // Convert the array of ingredients into a single comma-separated string
  const ingredientsList = Array.isArray(ingredients) ? ingredients.join(', ') : ingredients;
  
  // Return the strict prompt string. 
  // Notice how we explicitly tell the AI NOT to use Markdown formatting 
  // and provide a literal JSON template for it to fill in.
  return `You are a professional chef. I need recipe suggestions based on the following available ingredients and preferences.

Available Ingredients: ${ingredientsList || 'Any'}
Additional Instructions: ${instructions || 'None'}
Dietary Preferences: ${dietaryPreferences || 'None'}
Maximum Cooking Time: ${maxTime ? maxTime + ' minutes' : 'Any'}

Generate 1 to 3 recipe suggestions that can be realistically prepared using mainly the available ingredients. You may assume basic pantry staples (salt, pepper, oil, water, flour, sugar) are available.

Return your response strictly as a JSON object matching the following schema. Do NOT wrap the JSON in Markdown formatting (no \`\`\`json) or include any extra text.

{
  "recipes": [
    {
      "name": "String",
      "description": "String (A short mouth-watering description)",
      "matchPercentage": "Number (0 to 100, representing how well the recipe matches the available ingredients and preferences)",
      "availableIngredients": ["String"],
      "missingIngredients": ["String"],
      "estimatedCookingTime": "Number (in minutes)",
      "difficulty": "String (Easy, Medium, or Hard)",
      "instructions": ["String (Step by step)"]
    }
  ]
}
`;
};

module.exports = {
  buildRecipePrompt
};
