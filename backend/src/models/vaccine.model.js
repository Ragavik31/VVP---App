const mongoose = require('mongoose');

const vaccineSchema = new mongoose.Schema(
  {
    vaccineName: {
      type: String,
      required: true,
      minlength: 2,
      trim: true,
      match: [/^[A-Za-z0-9 ]+$/, 'Vaccine name must contain only letters, numbers and spaces'],
    },
    manufacturer: {
      type: String,
      required: true,
      minlength: 2,
      trim: true,
      match: [/^[A-Za-z0-9 ]+$/, 'Manufacturer must contain only letters, numbers and spaces'],
    },
    vaccineType: {
      type: String,
      required: true,
      enum: ['Live', 'Inactivated', 'mRNA', 'Subunit'],
    },
    doseVolumeMl: {
      type: Number,
      required: true,
      min: [0.000001, 'Dose volume must be greater than 0'],
    },
    boosterRequired: {
      type: Boolean,
      required: true,
    },
    batchNumber: {
      type: String,
      required: true,
      unique: true,
      minlength: 3,
      trim: true,
      match: [/^[A-Za-z0-9]+$/, 'Batch number must be alphanumeric only'],
    },
    expiryDate: {
      type: Date,
      required: true,
    },
    quantity: {
      type: Number,
      required: true,
      min: [0, 'Quantity must be >= 0'],
      validate: {
        validator: Number.isInteger,
        message: 'Quantity must be an integer',
      },
    },
    purchasePrice: {
      type: Number,
      required: true,
      min: [0, 'Purchase price must be >= 0'],
    },
    sellingPrice: {
      type: Number,
      required: true,
      min: [0, 'Selling price must be >= 0'],
    },
  },
  {
    timestamps: true,
  }
);

vaccineSchema.pre('validate', function (next) {
  if (this.expiryDate) {
    const now = new Date();
    if (this.expiryDate <= now) {
      return next(new Error('Expiry date must be a future date'));
    }
  }
  
  // Auto-calculate selling price as purchase price + 3%
  if (this.purchasePrice && !this.isModified('sellingPrice')) {
    this.sellingPrice = this.purchasePrice * 1.03;
  }
  
  next();
});

module.exports = mongoose.model('Vaccine', vaccineSchema);
