const razorpay = require("../config/razorpay");
const crypto = require("crypto");

// CREATE RAZORPAY ORDER
exports.createPaymentOrder = async (req, res) => {
  try {
    const { amount } = req.body;

    if (!amount) {
      return res.status(400).json({ success: false, message: "Amount required" });
    }

    const options = {
      amount: amount * 100, // Razorpay expects paise
      currency: "INR",
      receipt: "receipt_" + Date.now(),
    };

    const order = await razorpay.orders.create(options);

    res.json({
      success: true,
      order,
      key: process.env.RAZORPAY_KEY_ID,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// VERIFY PAYMENT SIGNATURE
exports.verifyPayment = async (req, res) => {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      orderId   // your DB order id
    } = req.body;

    const sign = razorpay_order_id + "|" + razorpay_payment_id;

    const expectedSign = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(sign.toString())
      .digest("hex");

    if (expectedSign !== razorpay_signature) {
      return res.status(400).json({ success: false, message: "Payment verification failed" });
    }

    // ✅ MARK ORDER AS PAID
    const Order = require("../models/order.model");
    await Order.findByIdAndUpdate(orderId, {
      paymentStatus: "paid",
      razorpayPaymentId: razorpay_payment_id,
    });

    res.json({ success: true, message: "Payment verified" });

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
