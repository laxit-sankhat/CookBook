const Favorite = require('../models/Favorite');
const Recipe = require('../models/Recipe');

// @desc  Toggle save/unsave a recipe
// @route POST /api/favorites/:recipeId
const toggleFavorite = async (req, res) => {
  try {
    const { recipeId } = req.params;
    const userId = req.user._id;

    const recipe = await Recipe.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    const existingFavorite = await Favorite.findOne({ recipe: recipeId, user: userId });

    if (existingFavorite) {
      await existingFavorite.deleteOne();
      return res.status(200).json({ favorited: false });
    } else {
      await Favorite.create({ recipe: recipeId, user: userId });
      return res.status(200).json({ favorited: true });
    }

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Get all recipes the logged-in user has saved
// @route GET /api/favorites
const getFavorites = async (req, res) => {
  try {
    const favorites = await Favorite.find({ user: req.user._id })
      .populate({
        path: 'recipe',
        populate: { path: 'createdBy', select: 'name' }
      })
      .sort({ createdAt: -1 });

    res.status(200).json(favorites);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { toggleFavorite, getFavorites };