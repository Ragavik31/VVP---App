const mongoose = require('mongoose');

const productSchema = new mongoose.Schema(
  {
    divisionName: {
      type: String,
      required: true,
      trim: true
    },

    productName: {
      type: String,
      required: true,
      trim: true
    },

    salesPrice: {
      type: Number,
      required: true,
      default: 0
    },

    mrp: {
      type: Number,
      required: true,
      default: 0
    },

    quantity: {
      type: Number,
      required: true,
      default: 0   // ⭐ NEW FIELD
    }
  },
  { timestamps: true }
);

module.exports = mongoose.model('Product', productSchema);
