const express = require('express');
const router = express.Router();
const { addComment, getComments, deleteComment } = require('../controllers/commentController');
const { protect } = require('../middleware/authMiddleware');

router.post('/:recipeId', protect, addComment);
router.get('/:recipeId', getComments);
router.delete('/:id', protect, deleteComment);

module.exports = router;