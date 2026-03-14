/**
 * Seed Staff Accounts – Run once from the backend directory:
 *   node seed_staff.js
 *
 * Creates/upserts Siva and Satish staff accounts.
 * Username = Name, Default Password = Name  (e.g. username: Siva, password: Siva)
 * Update phone numbers below before running!
 */

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./src/models/user.model');

const STAFF = [
  { name: 'Siva',   username: 'Siva',   password: 'Siva',   phone: '9999999991' },
  { name: 'Satish', username: 'Satish', password: 'Satish', phone: '9999999992' },
];

(async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('✅ Connected to MongoDB');

  for (const s of STAFF) {
    const hash = await bcrypt.hash(s.password, 10);
    const result = await User.findOneAndUpdate(
      { username: s.username },
      {
        $set: {
          name:         s.name,
          username:     s.username,
          email:        `${s.username.toLowerCase()}@vvp.internal`,
          passwordHash: hash,
          phone:        s.phone,
          role:         'staff',
        },
      },
      { upsert: true, new: true }
    );
    console.log(`✅ Upserted: ${result.name}  (username: ${result.username}, phone: ${result.phone})`);
  }

  await mongoose.disconnect();
  console.log('🎉 Done. Staff accounts ready.');
})();
