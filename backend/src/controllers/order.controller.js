const Order = require('../models/order.model');
const Product = require('../models/product.model');
const User = require('../models/user.model');
const Client = require('../models/client.model');
const socketUtil = require('../utils/socket');


// ======================================================
// CREATE ORDER (CLIENT)
// ======================================================
const createOrder = async (req, res) => {
  try {
    const items = req.body.items;

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: 'Items array is required' });
    }

    const user = await User.findById(req.user._id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    const client = await Client.findOne({ name: user.name });
    const clientContact = client?.contact || '—';
    const clientCode = client?.code || null;

    // 🔥 CHECK + DEDUCT STOCK
    const updatedProducts = [];

    for (const item of items) {
      const product = await Product.findById(item.vaccineId);

      if (!product) {
        return res.status(404).json({
          success: false,
          message: `Product not found for ${item.vaccineName}`
        });
      }

      if (product.quantity < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Not enough stock for ${item.vaccineName}`
        });
      }

      product.quantity -= item.quantity;
      await product.save();
      updatedProducts.push(product);
    }

    // calculate totals
    let totalQuantity = 0;
    let totalPrice = 0;
    for (const item of items) {
      totalQuantity += item.quantity;
      totalPrice += item.itemTotal;
    }

    const paymentMethod = req.body.paymentMethod || 'cash';
    const paymentDueDate = paymentMethod === 'cash'
      ? new Date(Date.now() + 30 * 24 * 60 * 60 * 1000)
      : null;
    const paymentStatus = paymentMethod === 'online' ? 'paid' : 'unpaid';

    const order = await Order.create({
      items,
      totalQuantity,
      totalPrice,
      clientId: req.user._id,
      clientName: user.name,
      clientEmail: user.email,
      clientContact,
      clientCode,
      notes: req.body.notes || '',
      status: 'pending',
      paymentMethod,
      paymentDueDate,
      paymentStatus,
    });

    // 🔌 SOCKET EVENTS
    try {
      const io = socketUtil.getIO();
      if (io) {
        io.emit('order:created', order);
        updatedProducts.forEach(p => io.emit('product:updated', p));
      }
    } catch (e) { }

    res.status(201).json({ success: true, data: order });

  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, message: 'Failed to create order' });
  }
};


// ======================================================
// GET ORDERS (ADMIN / STAFF / CLIENT)
// ======================================================
const getOrders = async (req, res) => {
  try {
    let filter = {};
    if (req.user.role === 'client') filter.clientId = req.user._id;
    if (req.user.role === 'staff') filter.assignedTo = req.user._id;

    const orders = await Order.find(filter)
      .populate('items.vaccineId')
      .sort({ createdAt: -1 });

    res.json({ success: true, data: orders });

  } catch {
    res.status(500).json({ success: false, message: 'Failed to fetch orders' });
  }
};


// ======================================================
// ADMIN: ASSIGN ORDER TO STAFF
// ======================================================
const assignOrder = async (req, res) => {
  try {
    const { id } = req.params;
    const { staffId, staffName } = req.body;

    if (!staffId || !staffName) {
      return res.status(400).json({ success: false, message: 'staffId and staffName are required' });
    }

    const order = await Order.findById(id);
    if (!order) return res.status(404).json({ success: false, message: 'Order not found' });

    // Look up staff phone so clients can contact them
    const staffUser = await User.findById(staffId).select('phone');
    const staffPhone = staffUser?.phone || null;

    order.assignedTo = staffId;
    order.assignedStaffName = staffName;
    order.assignedStaffPhone = staffPhone;
    order.status = 'assigned';
    await order.save();

    socketUtil.getIO().emit('order:assigned', order);
    res.json({ success: true, data: order });

  } catch (err) {
    console.error('assignOrder error:', err.message, err);
    res.status(400).json({ success: false, message: err.message });
  }
};


// ======================================================
// STAFF ACCEPT ORDER
// ======================================================
const acceptOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    order.status = 'accepted';
    order.acceptedAt = new Date();
    await order.save();

    socketUtil.getIO().emit('order:accepted', order);
    res.json({ success: true, data: order });

  } catch {
    res.status(400).json({ success: false });
  }
};


// ======================================================
// UPDATE ORDER STATUS (COMPLETED / REJECTED)
// ======================================================
const updateOrderStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const order = await Order.findById(req.params.id);

    // 🔥 RESTORE STOCK IF REJECTED
    if (status === 'rejected' && order.status !== 'rejected') {
      for (const item of order.items) {
        await Product.findByIdAndUpdate(
          item.vaccineId,
          { $inc: { quantity: item.quantity } }
        );
      }
    }

    if (status === 'completed') order.completedAt = new Date();
    if (status === 'delivered') order.deliveredAt = new Date();

    order.status = status;
    await order.save();

    socketUtil.getIO().emit('order:status_changed', { ...order.toObject(), statusLabel: status });
    res.json({ success: true, data: order });

  } catch {
    res.status(400).json({ success: false });
  }
};


// ======================================================
// DELETE ORDER (RESTORE STOCK)
// ======================================================
const deleteOrder = async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);

    for (const item of order.items) {
      await Product.findByIdAndUpdate(
        item.vaccineId,
        { $inc: { quantity: item.quantity } }
      );
    }

    await Order.findByIdAndDelete(req.params.id);
    socketUtil.getIO().emit('order:deleted', { id: req.params.id });

    res.json({ success: true });

  } catch {
    res.status(500).json({ success: false });
  }
};

// ⭐ GET PENDING ORDERS (ADMIN)
const getPendingOrders = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 50;
    const skip = (page - 1) * limit;

    const filter = { status: { $in: ['pending', 'assigned', 'accepted', 'delivered'] } };

    const [orders, total] = await Promise.all([
      Order.find(filter)
        .populate('clientId', 'name email')
        .populate('items.vaccineId', 'vaccineName manufacturer')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      Order.countDocuments(filter)
    ]);

    res.json({
      success: true,
      data: orders,
      page,
      limit,
      total
    });

  } catch (error) {
    console.error('Error fetching pending orders:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch pending orders'
    });
  }
};

// ======================================================
// GET DUE-SOON CASH ORDERS (CLIENT)
// ======================================================
const getDueSoonOrders = async (req, res) => {
  try {
    const now = new Date();
    const sevenDaysFromNow = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    // Also mark overdue orders
    await Order.updateMany(
      {
        paymentMethod: 'cash',
        paymentStatus: 'unpaid',
        paymentDueDate: { $lt: now },
      },
      { $set: { paymentStatus: 'overdue' } }
    );

    const filter = {
      clientId: req.user._id,
      paymentMethod: 'cash',
      paymentStatus: { $in: ['unpaid', 'overdue'] },
      paymentDueDate: { $ne: null },
    };

    const orders = await Order.find(filter).sort({ paymentDueDate: 1 });
    res.json({ success: true, data: orders });
  } catch (error) {
    console.error('Error fetching due-soon orders:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch due-soon orders' });
  }
};

// ======================================================
module.exports = {
  createOrder,
  getOrders,
  updateOrderStatus,
  deleteOrder,
  assignOrder,
  acceptOrder,
  getPendingOrders,
  getDueSoonOrders,
};
