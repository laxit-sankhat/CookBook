const express = require('express');
const router = express.Router();
const { toggleLike, getLikeStatus  } = require('../controllers/likeController');
const { protect } = require('../middleware/authMiddleware');

router.post('/:recipeId', protect, toggleLike);

router.get('/status/:recipeId', protect, getLikeStatus);

module.exports = router;