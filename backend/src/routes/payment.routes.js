const express = require("express");
const router = express.Router();
const { authenticate } = require("../middlewares/auth.middleware");

const paymentController = require("../controllers/payment.controller");

router.post("/create-order", authenticate, paymentController.createPaymentOrder);
router.post("/verify", authenticate, paymentController.verifyPayment);

module.exports = router;
