const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');

// Only Admins can access analytics
router.use(authenticate);
router.use(authorize('admin'));

router.get('/', analyticsController.getAnalyticsDashboard);

module.exports = router;
