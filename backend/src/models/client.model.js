const mongoose = require('mongoose');

const clientSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
    },
    specialization: {
      type: String,
      required: true,
      trim: true,
    },
    contact: {
      type: String,
      trim: true,
      default: '—',
    },
    address: {
      type: String,
      required: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Client', clientSchema);
