const Like = require('../models/Like');
const Recipe = require('../models/Recipe');

// @desc  Toggle like/unlike on a recipe
// @route POST /api/likes/:recipeId
const toggleLike = async (req, res) => {
  try {
    const { recipeId } = req.params;
    const userId = req.user._id;

    const recipe = await Recipe.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    const existingLike = await Like.findOne({ recipe: recipeId, user: userId });

    if (existingLike) {
      // already liked → remove it (unlike)
      await existingLike.deleteOne();
      recipe.likesCount = Math.max(0, recipe.likesCount - 1);
      await recipe.save();

      return res.status(200).json({ liked: false, likesCount: recipe.likesCount });

    } else {
      // not liked yet → create it
      await Like.create({ recipe: recipeId, user: userId });
      recipe.likesCount += 1;
      await recipe.save();

      return res.status(200).json({ liked: true, likesCount: recipe.likesCount });
    }

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { toggleLike };