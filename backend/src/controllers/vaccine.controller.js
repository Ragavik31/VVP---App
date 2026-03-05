const Vaccine = require('../models/vaccine.model');

const toStaffView = vaccine => ({
  vaccineName: vaccine.vaccineName,
  manufacturer: vaccine.manufacturer,
  vaccineType: vaccine.vaccineType,
  doseVolumeMl: vaccine.doseVolumeMl,
  boosterRequired: vaccine.boosterRequired,
  batchNumber: vaccine.batchNumber,
  expiryDate: vaccine.expiryDate,
  quantity: vaccine.quantity,
  purchasePrice: vaccine.purchasePrice,
  sellingPrice: vaccine.sellingPrice,
  createdAt: vaccine.createdAt,
  updatedAt: vaccine.updatedAt,
});

const createVaccine = async (req, res) => {
  try {
    const {
      vaccineName,
      manufacturer,
      vaccineType,
      doseVolumeMl,
      boosterRequired,
      batchNumber,
      expiryDate,
      quantity,
      purchasePrice,
      sellingPrice,
    } = req.body;

    if (
      !vaccineName ||
      !manufacturer ||
      !vaccineType ||
      doseVolumeMl == null ||
      boosterRequired == null ||
      !batchNumber ||
      !expiryDate ||
      quantity == null ||
      purchasePrice == null ||
      sellingPrice == null
    ) {
      return res
        .status(400)
        .json({ success: false, message: 'All fields are required' });
    }

    const vaccine = await Vaccine.create({
      vaccineName,
      manufacturer,
      vaccineType,
      doseVolumeMl,
      boosterRequired,
      batchNumber,
      expiryDate,
      quantity,
      purchasePrice,
      sellingPrice,
    });

    return res.status(201).json({ success: true, data: vaccine });
  } catch (error) {
    if (error.code === 11000 && error.keyPattern?.batchNumber) {
      return res
        .status(409)
        .json({ success: false, message: 'Batch number must be unique' });
    }

    return res
      .status(400)
      .json({ success: false, message: error.message || 'Failed to create vaccine' });
  }
};

const getVaccines = async (req, res) => {
  try {
    const vaccines = await Vaccine.find().sort({ createdAt: -1 });

    if (req.user.role === 'staff') {
      return res.json({
        success: true,
        data: vaccines.map(toStaffView),
      });
    }

    return res.json({ success: true, data: vaccines });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to fetch vaccines' });
  }
};

const getVaccineByBatchNumber = async (req, res) => {
  try {
    const { batchNumber } = req.params;
    const vaccine = await Vaccine.findOne({ batchNumber });

    if (!vaccine) {
      return res
        .status(404)
        .json({ success: false, message: 'Vaccine not found' });
    }

    if (req.user.role === 'staff') {
      return res.json({ success: true, data: toStaffView(vaccine) });
    }

    return res.json({ success: true, data: vaccine });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to fetch vaccine' });
  }
};

const updateVaccine = async (req, res) => {
  try {
    const vaccine = await Vaccine.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });

    if (!vaccine) {
      return res
        .status(404)
        .json({ success: false, message: 'Vaccine not found' });
    }

    return res.json({ success: true, data: vaccine });
  } catch (error) {
    if (error.code === 11000 && error.keyPattern?.batchNumber) {
      return res
        .status(409)
        .json({ success: false, message: 'Batch number must be unique' });
    }

    return res
      .status(400)
      .json({ success: false, message: error.message || 'Failed to update vaccine' });
  }
};

const deleteVaccine = async (req, res) => {
  try {
    const vaccine = await Vaccine.findByIdAndDelete(req.params.id);

    if (!vaccine) {
      return res
        .status(404)
        .json({ success: false, message: 'Vaccine not found' });
    }

    return res.json({ success: true, message: 'Vaccine deleted' });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: 'Failed to delete vaccine' });
  }
};

module.exports = {
  createVaccine,
  getVaccines,
  getVaccineByBatchNumber,
  updateVaccine,
  deleteVaccine,
};
