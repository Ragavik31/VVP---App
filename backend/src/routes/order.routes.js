const express = require('express');
const router = express.Router();

const {
  createOrder,
  getOrders,
  updateOrderStatus,
  deleteOrder,
  assignOrder,
  acceptOrder,
  getPendingOrders,
} = require('../controllers/order.controller');

const { authenticate, authorize } = require('../middlewares/auth.middleware');

router.use(authenticate);

// 🟢 CLIENT
router.post('/', authorize('client'), createOrder);
router.get('/', getOrders);

// 🟢 ADMIN
router.get('/pending', authorize('admin'), getPendingOrders);
router.patch('/:id/status', authorize('admin'), updateOrderStatus);
router.delete('/:id', authorize('admin'), deleteOrder);
router.patch('/:id/assign', authorize('admin'), assignOrder);

// 🟢 STAFF
router.patch('/:id/accept', authorize('staff'), acceptOrder);

module.exports = router;
