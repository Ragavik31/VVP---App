const express = require('express');
const router = express.Router();

const clientController = require('../controllers/client.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');

router.use(authenticate);

// Public routes (authenticated users)
router.get('/', clientController.getClients);
router.get('/:id', clientController.getClient);

// Admin only routes
router.post('/', authorize('admin'), clientController.createClient);
router.put('/:id', authorize('admin'), clientController.updateClient);
router.delete('/:id', authorize('admin'), clientController.deleteClient);

module.exports = router;
