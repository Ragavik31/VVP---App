const express = require('express');
const cors = require('cors');

const productRoutes = require('./routes/product.routes');
const authRoutes = require('./routes/auth.routes');
const vaccineRoutes = require('./routes/vaccine.routes');
const clientRoutes = require('./routes/client.routes');
const orderRoutes = require('./routes/order.routes');

const app = express();
app.use("/api/v1/payments", require("./routes/payment.routes"));
app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ message: 'Inventory API' });
});

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/products', productRoutes);
app.use('/api/v1/vaccines', vaccineRoutes);
app.use('/api/v1/clients', clientRoutes);
app.use('/api/v1/orders', orderRoutes);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Not found' });
});

module.exports = app;
