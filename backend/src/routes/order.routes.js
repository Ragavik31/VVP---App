const express = require('express');
const router = express.Router();

const {
  createOrder,
  getOrders,
  updateOrderStatus,
  updatePaymentStatus,
  cancelOrder,
  deleteOrder,
  assignOrder,
  acceptOrder,
  getPendingOrders,
  getDueSoonOrders,
} = require('../controllers/order.controller');

const { authenticate, authorize } = require('../middlewares/auth.middleware');

router.use(authenticate);

// 🟢 CLIENT
router.post('/', authorize('client'), createOrder);
router.get('/due-soon', authorize('client'), getDueSoonOrders);
router.get('/', getOrders);
router.patch('/:id/cancel', authorize('client'), cancelOrder);

// 🟢 ADMIN
router.get('/pending', authorize('admin'), getPendingOrders);
router.patch('/:id/status', authorize('admin', 'staff'), updateOrderStatus);
router.patch('/:id/payment', authorize('admin', 'staff'), updatePaymentStatus);
router.delete('/:id', authorize('admin'), deleteOrder);
router.patch('/:id/assign', authorize('admin'), assignOrder);

// 🟢 STAFF
router.patch('/:id/accept', authorize('staff'), acceptOrder);

module.exports = router;
