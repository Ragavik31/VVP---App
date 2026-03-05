const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema({
  vaccineId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Product',
    required: true,
  },
  vaccineName: {
    type: String,
    required: true,
  },
  batchNumber: {
    type: String,
  },
  quantity: {
    type: Number,
    required: true,
    min: 1,
  },
  sellingPrice: {
    type: Number,
    required: true,
    min: 0,
  },
  itemTotal: {
    type: Number,
    required: true,
    min: 0,
  },
}, { _id: true });

const orderSchema = new mongoose.Schema(
  {
    items: [orderItemSchema],
    totalQuantity: {
      type: Number,
      required: true,
      min: 1,
    },
    totalPrice: {
      type: Number,
      required: true,
      min: 0,
    },
    status: {
      type: String,
      enum: ['pending', 'assigned', 'accepted', 'completed', 'rejected'],
      default: 'pending',
    },
    orderDate: {
      type: Date,
      default: Date.now,
    },
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    clientName: {
      type: String,
      required: true,
    },
    clientEmail: {
      type: String,
      required: true,
    },
    clientContact: {
      type: String,
      default: '—',
    },
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    assignedStaffName: {
      type: String,
      default: null,
    },
    acceptedAt: {
      type: Date,
      default: null,
    },
    completedAt: {
      type: Date,
      default: null,
    },
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Order', orderSchema);
