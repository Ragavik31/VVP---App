const express = require('express');
const router = express.Router();

const vaccineController = require('../controllers/vaccine.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');

router.use(authenticate);

// Admin-only routes
router.post('/', authorize('admin'), vaccineController.createVaccine);
router.put('/:id', authorize('admin'), vaccineController.updateVaccine);
router.delete('/:id', authorize('admin'), vaccineController.deleteVaccine);

// Shared (admin + staff)
router.get('/', vaccineController.getVaccines);
router.get('/:batchNumber', vaccineController.getVaccineByBatchNumber);

module.exports = router;
