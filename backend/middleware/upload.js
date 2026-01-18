const multer = require('multer');
const path = require('path');

// Configure multer for temporary file storage
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, '/tmp');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'product-' + uniqueSuffix + path.extname(file.originalname));
    }
});

// File filter to only accept images
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
    // Allow octet-stream if extension is valid (common in some web/mobile upload scenarios)
    const ext = path.extname(file.originalname).toLowerCase();
    const isImageExt = ['.jpg', '.jpeg', '.png', '.gif', '.webp'].includes(ext);

    if (allowedTypes.includes(file.mimetype) || (file.mimetype === 'application/octet-stream' && isImageExt)) {
        cb(null, true);
    } else {
        console.log('Upload blocked:', file.mimetype, file.originalname);
        cb(new Error(`Invalid file type (${file.mimetype}). Only JPEG, PNG, GIF, and WebP are allowed.`), false);
    }
};

// Create multer instance
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB max file size
    }
});

// Error handling middleware for multer
const handleUploadError = (err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({
                success: false,
                message: 'File too large. Maximum size is 5MB.'
            });
        }
        return res.status(400).json({
            success: false,
            message: err.message
        });
    }

    if (err) {
        return res.status(400).json({
            success: false,
            message: err.message
        });
    }

    next();
};

module.exports = {
    upload,
    handleUploadError
};
