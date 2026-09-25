const Recipe = require('../models/Recipe');
const Like = require('../models/Like');
const Favorite = require('../models/Favorite');
const Comment = require('../models/Comment');

const categories = ['Breakfast', 'Lunch', 'Dinner', 'Dessert', 'Snacks'];
const difficulties = ['Easy', 'Medium', 'Hard'];

const validateRecipeInput = (input, { partial = false } = {}) => {
  const required = ['title', 'category', 'imageUrl', 'ingredients', 'instructions', 'cookingTime', 'difficulty'];
  if (!partial && required.some((field) => input[field] === undefined || input[field] === null)) {
    return 'Please fill all required fields';
  }
  if (input.title !== undefined && (typeof input.title !== 'string' || !input.title.trim())) return 'Recipe name is required';
  if (input.category !== undefined && !categories.includes(input.category)) return 'Please select a valid category';
  if (input.imageUrl !== undefined && (typeof input.imageUrl !== 'string' || !input.imageUrl.trim())) return 'Please provide a recipe image';
  if (input.ingredients !== undefined && (!Array.isArray(input.ingredients) || input.ingredients.length === 0 ||
      input.ingredients.some((item) => typeof item !== 'string' || !item.trim()))) {
    return 'Please provide at least one valid ingredient';
  }
  if (input.instructions !== undefined && (typeof input.instructions !== 'string' || !input.instructions.trim())) return 'Please provide instructions';
  if (input.cookingTime !== undefined && (!Number.isInteger(Number(input.cookingTime)) || Number(input.cookingTime) < 1 || Number(input.cookingTime) > 300)) {
    return 'Cooking time must be a whole number between 1 and 300 minutes';
  }
  if (input.difficulty !== undefined && !difficulties.includes(input.difficulty)) return 'Please select a valid difficulty';
  return null;
};

// @desc  Create a new recipe
// @route POST /api/recipes
const createRecipe = async (req, res) => {
  try {
    const { title, category, imageUrl, ingredients, instructions, cookingTime, difficulty } = req.body;

    const validationError = validateRecipeInput(req.body);
    if (validationError) return res.status(400).json({ message: validationError });

    const recipe = await Recipe.create({
      title,
      category,
      imageUrl,
      ingredients,
      instructions,
      cookingTime,
      difficulty,
      createdBy: req.user._id   // ← comes from auth middleware, not the request body
    });

    const populatedRecipe = await recipe.populate('createdBy', 'name');

    res.status(201).json(recipe);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Get all recipes, with optional search or category filter
// @route GET /api/recipes?search=pasta  OR  GET /api/recipes?category=Dinner
const getRecipes = async (req, res) => {
  try {
    const { search, category } = req.query;
    let query = {};

    if (search) {
      query.title = { $regex: search, $options: 'i' };
    }
    if (category) {
      query.category = category;
    }

    const recipes = await Recipe.find(query)
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json(recipes);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Get single recipe by ID
// @route GET /api/recipes/:id
const getRecipeById = async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id).populate('createdBy', 'name');

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }



    res.status(200).json(recipe);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Update own recipe
// @route PUT /api/recipes/:id
const updateRecipe = async (req, res) => {
  try {
    const validationError = validateRecipeInput(req.body, { partial: true });
    if (validationError) return res.status(400).json({ message: validationError });

    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    // Ownership check — critical
    if (recipe.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to edit this recipe' });
    }

    const updatedRecipe = await Recipe.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true, runValidators: true }
    ).populate('createdBy', 'name');   // ← add this

    res.status(200).json(updatedRecipe);

  } catch (error) {
    if (error.name === 'ValidationError' || error.name === 'CastError') {
      return res.status(400).json({ message: 'Recipe fields are invalid' });
    }
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Delete own recipe
// @route DELETE /api/recipes/:id
const deleteRecipe = async (req, res) => {
  try {
    const recipe = await Recipe.findById(req.params.id);

    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    if (recipe.createdBy.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this recipe' });
    }

    await Promise.all([
      recipe.deleteOne(),
      Like.deleteMany({ recipe: req.params.id }),
      Favorite.deleteMany({ recipe: req.params.id }),
      Comment.deleteMany({ recipe: req.params.id }),
    ]);

    res.status(200).json({ message: 'Recipe deleted successfully' });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

const getMyRecipes = async (req, res) => {
  try {
    const recipes = await Recipe.find({ createdBy: req.user._id })
      .populate('createdBy', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json(recipes);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { createRecipe, getRecipes, getRecipeById, updateRecipe, deleteRecipe, getMyRecipes };
