const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller');
const { protect, restrictTo } = require('../middlewares/auth.middleware');

// Only Admins can access analytics
router.use(protect);
router.use(restrictTo('admin'));

router.get('/', analyticsController.getAnalyticsDashboard);

module.exports = router;
