const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const User = require('../models/user.model');
const Order = require('../models/order.model');

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
  phone: user.phone || null,
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
    const { username, password } = req.body;

    if (!username || !password) {
      return res
        .status(400)
        .json({ success: false, message: 'Username and password are required' });
    }

    const user = await User.findOne({ username });

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

    // For staff, calculate how many active orders each member has
    const enriched = await Promise.all(users.map(async (user) => {
      const base = sanitizeUser(user);
      if (role === 'staff') {
        const activeOrders = await Order.countDocuments({
          assignedTo: user._id,
          status: { $in: ['assigned', 'accepted'] },
        });
        return { ...base, activeOrders, isFree: activeOrders === 0 };
      }
      return base;
    }));

    res.json({
      success: true,
      data: enriched,
    });
  } catch (error) {
    console.error('Get users by role error', error);
    return res.status(500).json({ success: false, message: 'Failed to get users' });
  }
};

const changePassword = async (req, res) => {
  try {
    const { username, oldPassword, newPassword } = req.body;

    if (!username || !oldPassword || !newPassword) {
      return res.status(400).json({ success: false, message: 'Username, old password, and new password are required' });
    }

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const valid = await bcrypt.compare(oldPassword, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Incorrect old password' });
    }

    user.passwordHash = await bcrypt.hash(newPassword, 10);
    await user.save();

    return res.json({ success: true, message: 'Password changed successfully' });
  } catch (error) {
    console.error('Change password error', error);
    return res.status(500).json({ success: false, message: 'Failed to change password' });
  }
};

const changePhone = async (req, res) => {
  try {
    const { username, password, newPhone } = req.body;

    if (!username || !password || !newPhone) {
      return res.status(400).json({ success: false, message: 'Username, password, and newPhone are required' });
    }

    const user = await User.findOne({ username });
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      return res.status(401).json({ success: false, message: 'Incorrect password' });
    }

    user.phone = newPhone;
    await user.save();

    return res.json({ success: true, message: 'Phone number updated successfully' });
  } catch (error) {
    console.error('Change phone error', error);
    return res.status(500).json({ success: false, message: 'Failed to change phone number' });
  }
};

module.exports = {
  register,
  login,
  me,
  getAllUsers,
  getUsersByRole,
  changePassword,
  changePhone,
};
