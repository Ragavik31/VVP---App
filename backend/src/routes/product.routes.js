const express = require('express');
const router = express.Router();
const productController = require('../controllers/product.controller');
const { authenticate, authorize } = require('../middlewares/auth.middleware');

router.use(authenticate);

router.post('/', authorize('admin'), productController.createProduct);
router.get('/', productController.getProducts);
router.get('/:id', productController.getProductById);
router.put('/:id', authorize('admin'), productController.updateProduct);
router.patch('/:id/stock', authorize('admin'), productController.adjustStock);
router.delete('/:id', authorize('admin'), productController.deleteProduct);

module.exports = router;
