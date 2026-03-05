const express = require('express');
const router = express.Router();

const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middlewares/auth.middleware');

router.post('/register', authController.register);
router.post('/login', authController.login);
router.get('/me', authenticate, authController.me);
router.get('/users', authenticate, authController.getAllUsers);
router.get('/users/by-role', authenticate, authController.getUsersByRole);

module.exports = router;
