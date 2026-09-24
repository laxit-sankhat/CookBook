const Recipe = require('../models/Recipe');
const Like = require('../models/Like');
const Favorite = require('../models/Favorite');
const Comment = require('../models/Comment');

// @desc  Create a new recipe
// @route POST /api/recipes
const createRecipe = async (req, res) => {
  try {
    const { title, category, imageUrl, ingredients, instructions, cookingTime, difficulty } = req.body;

    if (!title || !category || !imageUrl || !ingredients || !instructions || !cookingTime || !difficulty) {
      return res.status(400).json({ message: 'Please fill all required fields' });
    }

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