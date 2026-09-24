const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const { toggleFavorite, getFavorites, getFavoriteStatus } = require('../controllers/favoriteController');

router.post('/:recipeId', protect, toggleFavorite);
router.get('/status/:recipeId', protect, getFavoriteStatus);
router.get('/', protect, getFavorites);


module.exports = router;