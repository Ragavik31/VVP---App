const mongoose = require('mongoose');
require('dotenv').config();

const User = require('../src/models/user.model');

async function updateUserRoleToClient() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Update Dr. Balaji's role to 'client'
    const updatedUser = await User.findOneAndUpdate(
      { username: 'drbalaji' },
      { role: 'client' },
      { new: true }
    );

    if (updatedUser) {
      console.log(`✓ Updated user: ${updatedUser.name}`);
      console.log(`  Username: ${updatedUser.username}`);
      console.log(`  New Role: ${updatedUser.role}`);
    } else {
      console.log('✗ User with username "drbalaji" not found');
    }

    console.log('\nRole update complete!');

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await mongoose.disconnect();
  }
}

updateUserRoleToClient();
