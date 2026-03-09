const axios = require('axios');
require('dotenv').config();

const BASE_URL = 'https://stocksync-backend-rpnu.onrender.com/api/v1';
let token = ''; // We will get a real token by logging in as Admin.

async function testAssign() {
    try {
        // 1. Log in as admin
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            username: 'admin',
            password: 'admin123'
        });
        token = loginRes.data.token;
        console.log('Logged in as Admin');

        // 2. Fetch pending orders
        const getRes = await axios.get(`${BASE_URL}/orders/pending`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        const orders = getRes.data.data;
        console.log(`Found ${orders.length} pending orders`);

        // 3. Fetch staff
        const staffRes = await axios.get(`${BASE_URL}/auth/users/by-role?role=staff`, {
            headers: { Authorization: `Bearer ${token}` }
        });
        const staffMembers = staffRes.data.data;
        console.log(`Found ${staffMembers.length} staff members`);

        if (orders.length === 0 || staffMembers.length === 0) {
            console.log('Nothing to test assign with.');
            return;
        }

        const targetOrder = orders[0]._id;
        const targetStaff = staffMembers[0];

        // 4. Test Assignment
        console.log(`Assigning Order ${targetOrder} to ${targetStaff.name} (${targetStaff._id})`);
        const assignRes = await axios.patch(`${BASE_URL}/orders/${targetOrder}/assign`, {
            staffId: targetStaff._id,
            staffName: targetStaff.name
        }, {
            headers: { Authorization: `Bearer ${token}` }
        });
        console.log('Assign Result:', assignRes.data);

    } catch (err) {
        if (err.response) {
            console.error('API Error:', err.response.status, err.response.data);
        } else {
            console.error('Network/Script Error:', err.message);
        }
    }
}

testAssign();
