const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/user.model');

const signToken = user => {
  const payload = {
    userId: user._id.toString(),
    role: user.role,
  };

  const options = {};
  if (process.env.JWT_EXPIRES_IN) {
    options.expiresIn = process.env.JWT_EXPIRES_IN;
  }

  return jwt.sign(payload, process.env.JWT_SECRET, options);
};

const sanitizeUser = user => ({
  id: user._id,
  name: user.name,
  email: user.email,
  username: user.username,
  role: user.role,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const register = async (req, res) => {
  try {
    const { name, email, password, role } = req.body;

    if (!name || !email || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'Name, email and password are required' });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res
        .status(409)
        .json({ success: false, message: 'Email is already registered' });
    }

    const passwordHash = await bcrypt.hash(password, 10);

    const user = await User.create({
      name,
      email: email.toLowerCase(),
      passwordHash,
      role: role === 'admin' ? 'admin' : 'staff',
    });

    const token = signToken(user);

    return res
      .status(201)
      .json({ success: true, token, user: sanitizeUser(user) });
  } catch (error) {
    console.error('Register error', error);
    return res.status(500).json({ success: false, message: 'Register failed' });
  }
};

const login = async (req, res) => {
  try {
    const { role, username, password } = req.body;

    if ((!role && !username) || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'Role/Username and password are required' });
    }

    let user;
    
    if (username) {
       // Login by username
       user = await User.findOne({ username });
    } else {
       // Legacy login by role
       const dbRole = role === 'admin' ? 'admin' : 'staff';
       user = await User.findOne({ role: dbRole });
    }

    if (!user) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res
        .status(401)
        .json({ success: false, message: 'Invalid credentials' });
    }

    const token = signToken(user);

    return res.json({ success: true, token, user: sanitizeUser(user) });
  } catch (error) {
    console.error('Login error', error);
    return res.status(500).json({ success: false, message: 'Login failed' });
  }
};

const me = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.json({ success: true, user: sanitizeUser(user) });
  } catch (error) {
    console.error('Me error', error);
    return res.status(500).json({ success: false, message: 'Failed to get user' });
  }
};

const getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}).select('-passwordHash');
    return res.json({
      success: true,
      data: users.map(user => sanitizeUser(user)),
    });
  } catch (error) {
    console.error('Get all users error', error);
    return res.status(500).json({ success: false, message: 'Failed to get users' });
  }
};

const getUsersByRole = async (req, res) => {
  try {
    const { role } = req.query;

    if (!role) {
      return res.status(400).json({ success: false, message: 'Role is required' });
    }

    const users = await User.find({ role }).select('-passwordHash');

    res.json({
      success: true,
      data: users.map(sanitizeUser),
    });
  } catch (error) {
    console.error('Get users by role error', error);
    return res.status(500).json({ success: false, message: 'Failed to get users' });
  }
};

module.exports = {
  register,
  login,
  me,
  getAllUsers,
  getUsersByRole,
};
