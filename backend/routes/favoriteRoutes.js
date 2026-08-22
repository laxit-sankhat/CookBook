const express = require('express');
const router = express.Router();
const { toggleFavorite, getFavorites } = require('../controllers/favoriteController');
const { protect } = require('../middleware/authMiddleware');

router.post('/:recipeId', protect, toggleFavorite);
router.get('/', protect, getFavorites);

module.exports = router;