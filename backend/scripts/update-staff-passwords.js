const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const User = require('../src/models/user.model');

async function updatePasswords() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('Connected to DB');

        const hash = await bcrypt.hash('123456', 10);

        const sivaResult = await User.updateOne(
            { username: 'Siva' },
            { $set: { passwordHash: hash } }
        );
        console.log('Update Siva:', sivaResult.modifiedCount);

        const satishResult = await User.updateOne(
            { username: 'Satish' },
            { $set: { passwordHash: hash } }
        );
        console.log('Update Satish:', satishResult.modifiedCount);

        console.log('\nDone! Passwords changed to 123456.');
        process.exit(0);
    } catch (error) {
        console.error(error);
        process.exit(1);
    }
}

updatePasswords();
