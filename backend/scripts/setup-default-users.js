const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../src/models/user.model');

async function setupDefaultUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Clear existing users (optional - comment out if you want to keep existing users)
    // await User.deleteMany({});
    // console.log('Cleared existing users');

    const defaultUsers = [
      {
        name: 'Admin User',
        email: 'admin@stocksync.com',
        password: 'admin123',
        role: 'admin'
      },
      {
        name: 'Staff User',
        email: 'staff@stocksync.com', 
        password: 'staff123',
        role: 'staff'
      }
    ];

    for (const userData of defaultUsers) {
      const existing = await User.findOne({ email: userData.email });
      if (existing) {
        console.log(`User ${userData.email} already exists`);
        continue;
      }

      const passwordHash = await bcrypt.hash(userData.password, 10);
      
      const user = await User.create({
        name: userData.name,
        email: userData.email,
        passwordHash,
        role: userData.role
      });

      console.log(`Created ${userData.role} user: ${userData.email}`);
      console.log(`Password: ${userData.password}`);
    }

    console.log('\nDefault users setup complete!');
    console.log('Login credentials:');
    console.log('Admin - Role: admin, Password: admin123');
    console.log('Staff - Role: staff1 or staff2, Password: staff123');

  } catch (error) {
    console.error('Setup error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

setupDefaultUsers();
