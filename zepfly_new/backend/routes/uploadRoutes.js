const express =
require("express");

const router =
express.Router();

const multer =
require("multer");

const path =
require("path");

// STORAGE

const storage =
multer.diskStorage({

  destination:
  (req, file, cb) => {

    cb(
      null,
      "uploads/"
    );

  },

  filename:
  (req, file, cb) => {

    cb(

      null,

      Date.now() +

      path.extname(
        file.originalname
      )

    );

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

  (req, res) => {

    try {

      const imageUrl =

      `${req.protocol}://${req.get("host")}/uploads/${req.file.filename}`;

      res.json({

        success: true,

        imageUrl,

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