require('dotenv').config();
const mongoose = require('mongoose');
const User = require('./src/models/user.model');

mongoose.connect(process.env.MONGODB_URI).then(async () => {
    const clients = await User.find({ role: 'client' }).select('name username email');
    clients.forEach(c => {
        console.log(`Name: ${c.name}`);
        console.log(`  Username: ${c.username}`);
        console.log(`  Email:    ${c.email}`);
        console.log(`  Password: 123 (default)`);
        console.log('---');
    });
    process.exit(0);
}).catch(e => { console.error(e.message); process.exit(1); });
