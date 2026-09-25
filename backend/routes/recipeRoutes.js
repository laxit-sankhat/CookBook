const express = require('express');
const rateLimit = require('express-rate-limit');
const { createRecipe, getRecipes, getRecipeById, updateRecipe, deleteRecipe, getMyRecipes, getRecipeSuggestions } = require('../controllers/recipeController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Rate limiter specifically for AI suggestions to prevent abuse
const suggestionsLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Limit each IP to 10 requests per windowMs
  message: { message: 'Too many suggestion requests from this IP, please try again after an hour.' }
});

router.post('/suggestions', protect, suggestionsLimiter, getRecipeSuggestions);
router.post('/', protect, createRecipe);   // only logged-in users can create
router.get('/', getRecipes);               // anyone can view
router.get('/user/mine', protect, getMyRecipes);
router.get('/:id', getRecipeById);
router.put('/:id', protect, updateRecipe);
router.delete('/:id', protect, deleteRecipe);

module.exports = router;