const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../src/models/user.model');

async function setupStaff() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    // Update existing staff user → Staff 1 / staff1
    await User.updateOne(
        { role: 'staff' },
        { $set: { name: 'Staff 1', username: 'staff1' } }
    );
    console.log('Updated existing staff → Staff 1 (username: staff1)');

    // Create Staff 2 if not already there
    const exists = await User.findOne({ username: 'staff2' });
    if (!exists) {
        const hash = await bcrypt.hash('staff123', 10);
        await User.create({
            name: 'Staff 2',
            email: 'staff2@stocksync.com',
            username: 'staff2',
            passwordHash: hash,
            role: 'staff',
        });
        console.log('Created Staff 2 (username: staff2, password: staff123)');
    } else {
        await User.updateOne({ username: 'staff2' }, { $set: { name: 'Staff 2' } });
        console.log('Staff 2 already exists — name updated');
    }

    console.log('\nDone! Staff login credentials:');
    console.log('  Staff 1 → username: staff1  password: staff123');
    console.log('  Staff 2 → username: staff2  password: staff123');
    process.exit(0);
}

setupStaff().catch(err => { console.error(err); process.exit(1); });
