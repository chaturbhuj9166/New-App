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

// STORAGE

const storage =
new CloudinaryStorage({

  cloudinary,

  params: {

    folder:
    "profile_images",

    allowed_formats: [

      "jpg",
      "png",
      "jpeg",

    ],

  },

});

const upload =
multer({

  storage,

});

// UPLOAD ROUTE

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

      res.json({

        success: false,

        message:
        error.message,

      });

    }

  }

);

module.exports =
router;