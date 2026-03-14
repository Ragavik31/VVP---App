const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../src/models/user.model');

async function setupStaff() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to DB');

    // Update existing staff user → Siva
    await User.updateOne(
        { role: 'staff' },
        { $set: { name: 'Siva', username: 'Siva' } }
    );
    console.log('Updated existing staff → Siva (username: Siva)');

    // Create Satish if not already there
    const exists = await User.findOne({ username: 'Satish' });
    if (!exists) {
        const hash = await bcrypt.hash('staff123', 10);
        await User.create({
            name: 'Satish',
            email: 'satish@stocksync.com',
            username: 'Satish',
            passwordHash: hash,
            role: 'staff',
        });
        console.log('Created Satish (username: Satish, password: staff123)');
    } else {
        await User.updateOne({ username: 'Satish' }, { $set: { name: 'Satish' } });
        console.log('Satish already exists — name updated');
    }

    console.log('\nDone! Staff login credentials:');
    console.log('  Siva   → username: Siva    password: staff123');
    console.log('  Satish → username: Satish  password: staff123');
    process.exit(0);
}

setupStaff().catch(err => { console.error(err); process.exit(1); });
