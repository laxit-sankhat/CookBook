/**
 * aiService.js
 * 
 * PURPOSE:
 * This file handles the actual network communication with Google's Gemini API.
 * It contains logic to dynamically import the SDK (because of Node compatibility)
 * and includes a retry loop to handle temporary server overloads.
 */
const fetchRecipeSuggestions = async (promptText, retries = 3, delayMs = 2000) => {
  try {
    const { GoogleGenAI } = await import('@google/genai');
    const ai = new GoogleGenAI({ apiKey: (process.env.GEMINI_API_KEY || '').trim() });

    for (let attempt = 1; attempt <= retries; attempt++) {
      try {
        const response = await ai.models.generateContent({
          model: 'gemini-3.5-flash-lite',
          contents: promptText,
          config: {
            responseMimeType: "application/json",
          }
        });
        return response.text;
      } catch (error) {
        console.error(`AI Service Attempt ${attempt} Failed:`, error.message);
        
        // If it's the last attempt, throw the error
        if (attempt === retries) throw error;
        
        // Otherwise wait before retrying (exponential backoff)
        console.log(`Retrying in ${delayMs * attempt}ms...`);
        await new Promise(res => setTimeout(res, delayMs * attempt));
      }
    }
  } catch (error) {
    console.error('Final AI Service Error:', error);
    throw new Error('AI_PROVIDER_ERROR');
  }
};

module.exports = {
  fetchRecipeSuggestions
};
