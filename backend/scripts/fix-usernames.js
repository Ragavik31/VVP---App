const mongoose = require('mongoose');
require('dotenv').config();

async function fixUsers() {
    await mongoose.connect(process.env.MONGODB_URI);
    const db = mongoose.connection.db;

    // Fix admin username
    await db.collection('users').updateOne(
        { role: 'admin' },
        { $set: { username: 'admin' } }
    );

    // Find all staff users
    const staffUsers = await db.collection('users').find({ role: 'staff' }).toArray();
    console.log(`Found ${staffUsers.length} staff user(s):`);
    staffUsers.forEach(u => console.log(`  - ${u.name} (username: ${u.username}, email: ${u.email}, _id: ${u._id})`));

    // Delete old staff1 / Staff 1 users
    const deleted1 = await db.collection('users').deleteMany({
        role: 'staff',
        username: { $in: ['staff1', 'staff2'] }
    });
    console.log(`Deleted ${deleted1.deletedCount} old staff1/staff2 user(s)`);

    // Now ensure Siva and Satish exist and have correct usernames
    const siva = await db.collection('users').findOne({ role: 'staff', name: 'Siva' });
    if (siva) {
        await db.collection('users').updateOne(
            { _id: siva._id },
            { $set: { username: 'Siva', name: 'Siva' } }
        );
        console.log('Siva → username set to Siva');
    } else {
        console.log('WARNING: No staff user named Siva found');
    }

    const satish = await db.collection('users').findOne({ role: 'staff', name: 'Satish' });
    if (satish) {
        await db.collection('users').updateOne(
            { _id: satish._id },
            { $set: { username: 'Satish', name: 'Satish' } }
        );
        console.log('Satish → username set to Satish');
    } else {
        console.log('WARNING: No staff user named Satish found');
    }

    // Final check
    const remaining = await db.collection('users').find({ role: 'staff' }).toArray();
    console.log(`\nFinal staff users (${remaining.length}):`);
    remaining.forEach(u => console.log(`  - ${u.name} (username: ${u.username})`));

    process.exit(0);
}

fixUsers().catch(console.error);
