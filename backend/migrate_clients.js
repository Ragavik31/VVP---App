require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Client = require('./src/models/client.model');
const User = require('./src/models/user.model');

async function migrate() {
    try {
        const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017/stocksync';
        await mongoose.connect(mongoUri, {
            useNewUrlParser: true,
            useUnifiedTopology: true,
        });
        console.log('Connected to MongoDB');

        const clients = await Client.find({});
        console.log(`Found ${clients.length} clients to migrate.`);

        const defaultPassword = '123';
        const passwordHash = await bcrypt.hash(defaultPassword, 10);

        for (let client of clients) {
            if (!client.code) {
                console.warn(`Skipping client ${client._id} without a code...`);
                continue;
            }

            // Check if user already exists
            const existingUser = await User.findOne({ username: client.code });
            if (existingUser) {
                console.log(`User for ${client.code} already exists.`);
                continue;
            }

            await User.create({
                name: client.name,
                email: `${client.code.toLowerCase()}@example.com`,
                username: client.code,
                passwordHash,
                role: 'client',
            });
            console.log(`Migrated ${client.code} into User collection.`);
        }

        console.log('Migration complete!');
        process.exit(0);
    } catch (e) {
        console.error('Migration failed:', e);
        process.exit(1);
    }
}

migrate();
