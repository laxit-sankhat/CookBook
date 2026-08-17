const mongoose = require('mongoose');

const likeSchema = new mongoose.Schema({
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

// prevents the same user from liking the same recipe twice
likeSchema.index({ recipe: 1, user: 1 }, { unique: true });

module.exports = mongoose.model('Like', likeSchema);