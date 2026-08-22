const express = require('express');
const { createRecipe, getRecipes, getRecipeById, updateRecipe, deleteRecipe} = require('../controllers/recipeController');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.post('/', protect, createRecipe);   // only logged-in users can create
router.get('/', getRecipes);               // anyone can view
router.get('/:id', getRecipeById);
router.put('/:id', protect, updateRecipe);
router.delete('/:id', protect, deleteRecipe);

module.exports = router;