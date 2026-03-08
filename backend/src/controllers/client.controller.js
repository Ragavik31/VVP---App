const Client = require('../models/client.model');
const User = require('../models/user.model');
const bcrypt = require('bcryptjs');

const createClient = async (req, res) => {
  try {
    const { code, name, specialization, contact, address, password } = req.body;

    if (!code || !name || !specialization || !address || !password) {
      return res.status(400).json({
        success: false,
        message: 'Code, name, specialization, address and password are required',
      });
    }

    // Check if code/username already exists
    const existingClient = await Client.findOne({ code });
    const existingUser = await User.findOne({ username: code });

    if (existingClient || existingUser) {
      return res.status(409).json({
        success: false,
        message: 'Client code already exists',
      });
    }

    // Hash password
    const passwordHash = await bcrypt.hash(password, 10);

    const client = await Client.create({
      code,
      name,
      specialization,
      contact: contact || '—',
      address,
    });

    // Create linked User for login
    await User.create({
      name,
      email: `${code.toLowerCase()}@example.com`, // Dummy email, required by legacy schema but sparse/unique
      username: code,
      passwordHash,
      role: 'client',
    });

    return res.status(201).json({ success: true, data: client });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to create client' });
  }
};

const getClients = async (req, res) => {
  try {
    const clients = await Client.find().sort({ createdAt: -1 });
    return res.json({ success: true, data: clients });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to fetch clients' });
  }
};

const getClient = async (req, res) => {
  try {
    const { id } = req.params;
    const client = await Client.findById(id);
    if (!client) {
      return res.status(404).json({ success: false, message: 'Client not found' });
    }
    return res.json({ success: true, data: client });
  } catch (error) {
    return res.status(500).json({ success: false, message: 'Failed to fetch client' });
  }
};

const updateClient = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, specialization, contact, address } = req.body;

    const client = await Client.findByIdAndUpdate(
      id,
      {
        name,
        specialization,
        contact,
        address,
      },
      { new: true, runValidators: true }
    );

    if (!client) {
      return res
        .status(404)
        .json({ success: false, message: 'Client not found' });
    }

    // Also update User record name to stay in sync
    if (name) {
      await User.findOneAndUpdate({ username: client.code }, { name });
    }

    return res.json({ success: true, data: client });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to update client' });
  }
};

const deleteClient = async (req, res) => {
  try {
    const { id } = req.params;
    const client = await Client.findByIdAndDelete(id);

    if (!client) {
      return res
        .status(404)
        .json({ success: false, message: 'Client not found' });
    }

    // Delete linked User
    await User.findOneAndDelete({ username: client.code });

    return res.json({ success: true, message: 'Client deleted successfully' });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to delete client' });
  }
};

module.exports = {
  createClient,
  getClients,
  getClient,
  updateClient,
  deleteClient,
};
