const axios = require('axios');
require('dotenv').config();

const base = process.env.API_BASE || 'http://localhost:5000/api/v1';

async function loginAdmin() {
  const res = await axios.post(`${base}/auth/login`, { role: 'admin', password: 'admin123' });
  return res.data.token;
}

async function loginClient() {
  const res = await axios.post(`${base}/auth/login`, { username: 'drbalaji', password: '123456' });
  return res.data.token;
}

async function loginStaffByRole() {
  const res = await axios.post(`${base}/auth/login`, { role: 'staff', password: 'staff123' });
  return res.data.token;
}

async function run() {
  try {
    console.log('Logging in admin...');
    const adminToken = await loginAdmin();
    console.log('Admin token:', !!adminToken);

    console.log('Fetching staff users...');
    const staffRes = await axios.get(`${base}/auth/users/by-role?role=staff`, { headers: { Authorization: `Bearer ${adminToken}` } });
    const staffList = staffRes.data.data;
    console.log('Staff count:', staffList.length);
    const staff = staffList[0];

    console.log('Logging in client...');
    const clientToken = await loginClient();

    console.log('Fetching vaccines...');
    const vaccinesRes = await axios.get(`${base}/vaccines`, { headers: { Authorization: `Bearer ${clientToken}` } });
    const vaccines = vaccinesRes.data.data || vaccinesRes.data;
    if (!vaccines || vaccines.length === 0) {
      console.log('No vaccines available to order');
      return;
    }
    const vaccine = vaccines[0];
    console.log('Selected vaccine:', vaccine.vaccineName || vaccine.vaccine_name || vaccine.name || vaccine._id);

    console.log('Placing order as client...');
    const orderRes = await axios.post(`${base}/orders`, {
      vaccineId: vaccine._id,
      vaccineName: vaccine.vaccineName || vaccine.vaccine_name || vaccine.name,
      batchNumber: vaccine.batchNumber || vaccine.batch_number || vaccine.batchNumber || 'BATCH1',
      quantity: 1,
      sellingPrice: vaccine.sellingPrice || vaccine.selling_price || 0,
      totalPrice: vaccine.sellingPrice || vaccine.selling_price || 0,
      notes: 'Smoke test order'
    }, { headers: { Authorization: `Bearer ${clientToken}` } });

    const order = orderRes.data.data;
    console.log('Order created id:', order._id, 'status:', order.status);

    console.log('Admin fetching pending orders...');
    const pending = await axios.get(`${base}/orders/pending`, { headers: { Authorization: `Bearer ${adminToken}` } });
    console.log('Pending count:', pending.data.total || pending.data.data.length);

    if (!staff) {
      console.log('No staff to assign to');
      return;
    }

    console.log('Assigning order to staff:', staff.name);
    await axios.patch(`${base}/orders/${order._id}/assign`, { staffId: staff.id || staff.id, staffName: staff.name }, { headers: { Authorization: `Bearer ${adminToken}` } });
    console.log('Order assigned');

    console.log('Logging in staff by role to accept (legacy login)');
    const staffToken = await loginStaffByRole();

    console.log('Staff accepting order...');
    try {
      await axios.patch(`${base}/orders/${order._id}/accept`, {}, { headers: { Authorization: `Bearer ${staffToken}` } });
      console.log('Order accepted by staff');
    } catch (err) {
      console.error('Staff accept failed:', err.response ? err.response.data : err.message);
    }

    console.log('Fetching vaccine after accept to check quantity...');
    const v2 = await axios.get(`${base}/vaccines/${vaccine._id}`, { headers: { Authorization: `Bearer ${adminToken}` } });
    console.log('Vaccine quantity now:', v2.data.data.quantity);

    console.log('Smoke test done');
  } catch (err) {
    console.error('Smoke test error:', err.response ? err.response.data : err.message);
  }
}

run();
