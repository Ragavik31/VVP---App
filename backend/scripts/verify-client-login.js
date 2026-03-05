const axios = require('axios');

async function verifyLogin() {
  try {
    const response = await axios.post('http://localhost:5000/api/v1/auth/login', {
      username: 'drbalaji',
      password: '123456'
    });

    if (response.data.success) {
      console.log('Login successful!');
      console.log('Token:', response.data.token ? 'Present' : 'Missing');
      console.log('User Role:', response.data.user.role);
      console.log('Username:', response.data.user.username);
    } else {
      console.log('Login failed:', response.data.message);
    }
  } catch (error) {
    console.error('Login error:', error.response ? error.response.data : error.message);
  }
}

verifyLogin();
