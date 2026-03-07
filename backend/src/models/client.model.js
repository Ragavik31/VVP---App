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
    code: {
      type: String,
      unique: true,
      sparse: true,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Auto-generate code like WP001, WP002...
clientSchema.pre('save', async function (next) {
  if (this.isNew && !this.code) {
    const count = await mongoose.model('Client').countDocuments();
    const num = String(count + 1).padStart(3, '0');
    this.code = `WP${num}`;
  }
  next();
});

module.exports = mongoose.model('Client', clientSchema);
