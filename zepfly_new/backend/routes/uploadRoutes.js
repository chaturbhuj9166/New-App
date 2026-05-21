const express =
require("express");

const router =
express.Router();

const multer =
require("multer");

const {
  CloudinaryStorage
} = require(
  "multer-storage-cloudinary"
);

const cloudinary =
require("../config/cloudinary");

// =========================
// CLOUDINARY STORAGE
// =========================

const storage =
new CloudinaryStorage({

  cloudinary,

  params: {

    folder:
    "profile_images",

    allowed_formats: [

      "jpg",
      "jpeg",
      "png",

    ],

  },

});

// =========================
// MULTER
// =========================

const upload =
multer({

  storage,

});

// =========================
// UPLOAD ROUTE
// =========================

router.post(

  "/profile",

  upload.single("image"),

  async (req, res) => {

    try {

      res.json({

        success: true,

        imageUrl:
        req.file.path,

      });

    }

    catch(error){

      res.status(500).json({

        success: false,

        message:
        error.message,

      });

    }

  }

);

module.exports =
router;