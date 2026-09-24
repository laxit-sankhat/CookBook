const Comment = require('../models/Comment');
const Recipe = require('../models/Recipe');

// @desc  Add a comment to a recipe
// @route POST /api/comments/:recipeId
const addComment = async (req, res) => {
  try {
    const { recipeId } = req.params;
    const { text } = req.body;

    if (!text || text.trim() === '') {
      return res.status(400).json({ message: 'Comment text is required' });
    }

    const recipe = await Recipe.findById(recipeId);
    if (!recipe) {
      return res.status(404).json({ message: 'Recipe not found' });
    }

    const comment = await Comment.create({
      text,
      recipe: recipeId,
      user: req.user._id
    });

    recipe.commentsCount += 1;
    await recipe.save();

    // send back comment with commenter's name attached
    const populatedComment = await comment.populate('user', 'name');

    res.status(201).json(populatedComment);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Get all comments for a recipe
// @route GET /api/comments/:recipeId
const getComments = async (req, res) => {
  try {
    const comments = await Comment.find({ recipe: req.params.recipeId })
      .populate('user', 'name')
      .sort({ createdAt: -1 });

    res.status(200).json(comments);

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

// @desc  Delete own comment
// @route DELETE /api/comments/:id
const deleteComment = async (req, res) => {
  try {
    const comment = await Comment.findById(req.params.id);

    if (!comment) {
      return res.status(404).json({ message: 'Comment not found' });
    }

    if (comment.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({ message: 'Not authorized to delete this comment' });
    }

    await comment.deleteOne();

    const recipe = await Recipe.findById(comment.recipe);   // ← add this
    if (recipe) {
      recipe.commentsCount = Math.max(0, recipe.commentsCount - 1);
      await recipe.save();
    }

    res.status(200).json({ message: 'Comment deleted successfully' });

  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
};

module.exports = { addComment, getComments, deleteComment };