const cloudinary = require('../config/cloudinary');

const uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No image file provided' });
    }

    // convert buffer to a format Cloudinary accepts
    const b64 = Buffer.from(req.file.buffer).toString('base64');
    const dataURI = `data:${req.file.mimetype};base64,${b64}`;

    const result = await cloudinary.uploader.upload(dataURI, {
      folder: 'cookbook_recipes'
    });

    res.status(200).json({ imageUrl: result.secure_url });

  } catch (error) {
    res.status(500).json({ message: 'Image upload failed', error: error.message });
  }
};

module.exports = { uploadImage };