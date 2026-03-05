const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    // Provide explicit options and longer server selection timeout to surface
    // clearer errors when the network or Atlas IP access is blocking connections.
    const opts = {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      // increase timeout to allow slow or blocked networks to surface errors
      serverSelectionTimeoutMS: 30000,
    };

    await mongoose.connect(process.env.MONGODB_URI, opts);
    console.log('MongoDB connected');
  } catch (error) {
    console.error('MongoDB connection error');
    console.error(error && error.stack ? error.stack : error);
    // Do NOT immediately exit so the developer can inspect logs locally if needed.
    // Exit if running in production.
    if (process.env.NODE_ENV === 'production') process.exit(1);
  }
};

module.exports = connectDB;
