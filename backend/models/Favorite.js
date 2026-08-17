const mongoose = require('mongoose');

const favoriteSchema = new mongoose.Schema({
  recipe: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Recipe',
    required: true
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }
}, { timestamps: true });

favoriteSchema.index({ recipe: 1, user: 1 }, { unique: true });

module.exports = mongoose.model('Favorite', favoriteSchema);