const Product = require('../models/product.model');

const createProduct = async (req, res) => {
  try {
    const { divisionName, productName, salesPrice, mrp, quantity } = req.body;

    const product = await Product.create({
      divisionName,
      productName,
      salesPrice,
      mrp,
      quantity
    });

    res.status(201).json({ success: true, data: product });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};


const getProducts = async (req, res) => {
  try {
    // Return ALL products without pagination
    const products = await Product.find().sort({ createdAt: -1 });

    res.json({
      success: true,
      data: products,
      total: products.length
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to fetch products',
      error: error.message
    });
  }
};


const getProductById = async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }
    res.json({ success: true, data: product });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch product', error: error.message });
  }
};

const updateProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    res.json({ success: true, data: product });
  } catch (error) {
    res.status(400).json({ success: false, message: error.message });
  }
};

const adjustStock = async (req, res) => {
  try {
    const delta = Number(req.body.delta);
    if (Number.isNaN(delta)) {
      return res.status(400).json({ success: false, message: 'delta must be a number' });
    }

    const product = await Product.findById(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    const newStock = product.quantity + delta;
    if (newStock < 0) {
      return res.status(400).json({ success: false, message: 'Stock cannot be negative' });
    }

    product.quantity = newStock;
    await product.save();

    res.json({ success: true, data: product });
  } catch (error) {
    res.status(400).json({ success: false, message: 'Failed to adjust stock', error: error.message });
  }
};

const deleteProduct = async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({ success: true, message: 'Product deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete product', error: error.message });
  }
};

module.exports = {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  adjustStock,
  deleteProduct
};
