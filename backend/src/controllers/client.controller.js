const Client = require('../models/client.model');

const createClient = async (req, res) => {
  try {
    const { name, specialization, contact, address } = req.body;

    if (!name || !specialization || !address) {
      return res.status(400).json({
        success: false,
        message: 'Name, specialization and address are required',
      });
    }

    const client = await Client.create({
      name,
      specialization,
      contact: contact || '—',
      address,
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
