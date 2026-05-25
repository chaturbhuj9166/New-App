const mongoose =
require("mongoose");

const announcementSchema =
new mongoose.Schema({

  title: {

    type: String,

    required: true,

    trim: true,

  },

  description: {

    type: String,

    default: "",

  },

  assignedTo: {

    type:
    mongoose.Schema.Types.ObjectId,

    ref: "User",

  },

  assignedBy: {

    type:
    mongoose.Schema.Types.ObjectId,

    ref: "User",

    required: true,

  },

  sendToAll: {

    type: Boolean,

    default: false,

  },

  status: {

    type: String,

    enum: [

      "Unread",

      "Seen",

      "Replied",

    ],

    default: "Unread",

  },

  // =========================================
  // MULTIPLE REPLIES
  // =========================================

  replies: [

    {

      user: {

        type:
        mongoose.Schema.Types.ObjectId,

        ref: "User",

      },

      message: {

        type: String,

        required: true,

      },

      createdAt: {

        type: Date,

        default: Date.now,

      },

    },

  ],

  // =========================================
  // SEEN USERS
  // =========================================

  seenBy: [

    {

      type:
      mongoose.Schema.Types.ObjectId,

      ref: "User",

    },

  ],

}, {

  timestamps: true,

});

module.exports =
mongoose.model(

  "Announcement",

  announcementSchema

);