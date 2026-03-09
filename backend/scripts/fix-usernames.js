const mongoose = require('mongoose');
require('dotenv').config();

async function fixUsers() {
    await mongoose.connect(process.env.MONGODB_URI);
    const db = mongoose.connection.db;

    await db.collection('users').updateOne(
        { role: 'admin' },
        { $set: { username: 'admin' } }
    );

    await db.collection('users').updateOne(
        { role: 'staff' },
        { $set: { username: 'staff1' } }
    );

    console.log('Fixed admin and staff usernames on cloud DB!');
    process.exit(0);
}

fixUsers().catch(console.error);
