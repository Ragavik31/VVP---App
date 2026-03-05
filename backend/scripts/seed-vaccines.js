const mongoose = require('mongoose');
require('dotenv').config(); // Adjust path if running from scripts dir
const Vaccine = require('../src/models/vaccine.model');

const vaccines = [
  {
    vaccineName: 'ChildVax Polio',
    manufacturer: 'HealthGen Labs',
    vaccineType: 'Live',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'CVP101',
    expiryDate: '2026-12-10',
    quantity: 150,
    purchasePrice: 450,
    sellingPrice: 463.5
  },
  {
    vaccineName: 'BabyShield HepB',
    manufacturer: 'BioCare Pharma',
    vaccineType: 'Subunit',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'BSH202',
    expiryDate: '2027-01-15',
    quantity: 200,
    purchasePrice: 680,
    sellingPrice: 700.4
  },
  {
    vaccineName: 'LittleGuard DPT',
    manufacturer: 'MedLife Corp',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'LGD303',
    expiryDate: '2026-11-05',
    quantity: 180,
    purchasePrice: 520,
    sellingPrice: 535.6
  },
  {
    vaccineName: 'TinySafe MMR',
    manufacturer: 'Nova Health',
    vaccineType: 'Live',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'TSM404',
    expiryDate: '2027-03-18',
    quantity: 90,
    purchasePrice: 850,
    sellingPrice: 875.5
  },
  {
    vaccineName: 'InfantProtect Hib',
    manufacturer: 'LifeCore Labs',
    vaccineType: 'Subunit',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'IPH505',
    expiryDate: '2026-10-20',
    quantity: 140,
    purchasePrice: 720,
    sellingPrice: 741.6
  },
  {
    vaccineName: 'BabyCare IPV',
    manufacturer: 'CareWell Pharma',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'BCI606',
    expiryDate: '2027-05-10',
    quantity: 160,
    purchasePrice: 580,
    sellingPrice: 597.4
  },
  {
    vaccineName: 'KidDefense Rotavirus',
    manufacturer: 'GenX Bio',
    vaccineType: 'Live',
    doseVolumeMl: 1.0,
    boosterRequired: false,
    batchNumber: 'KDR707',
    expiryDate: '2026-09-25',
    quantity: 110,
    purchasePrice: 920,
    sellingPrice: 947.6
  },
  {
    vaccineName: 'ChildGuard Varicella',
    manufacturer: 'PureMed Labs',
    vaccineType: 'Live',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'CGV808',
    expiryDate: '2027-02-28',
    quantity: 70,
    purchasePrice: 1100,
    sellingPrice: 1133
  },
  {
    vaccineName: 'JuniorShield PCV',
    manufacturer: 'Global BioTech',
    vaccineType: 'Subunit',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'JSP909',
    expiryDate: '2026-08-12',
    quantity: 130,
    purchasePrice: 1250,
    sellingPrice: 1287.5
  },
  {
    vaccineName: 'BabyVax Influenza',
    manufacturer: 'SecureLife Pharma',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.25,
    boosterRequired: true,
    batchNumber: 'BVI010',
    expiryDate: '2027-06-05',
    quantity: 220,
    purchasePrice: 380,
    sellingPrice: 391.4
  },
  {
    vaccineName: 'TotCare Typhoid',
    manufacturer: 'MedPrime Corp',
    vaccineType: 'Subunit',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'TCT111',
    expiryDate: '2026-12-22',
    quantity: 85,
    purchasePrice: 420,
    sellingPrice: 432.6
  },
  {
    vaccineName: 'ChildProtect HepA',
    manufacturer: 'VitalCare Labs',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'CPH212',
    expiryDate: '2027-04-10',
    quantity: 170,
    purchasePrice: 550,
    sellingPrice: 566.5
  },
  {
    vaccineName: 'LittleSafe BCG',
    manufacturer: 'NextGen Health',
    vaccineType: 'Live',
    doseVolumeMl: 0.1,
    boosterRequired: false,
    batchNumber: 'LSB313',
    expiryDate: '2026-07-19',
    quantity: 60,
    purchasePrice: 280,
    sellingPrice: 288.4
  },
  {
    vaccineName: 'MiniGuard JE',
    manufacturer: 'FutureBio',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'MGJ414',
    expiryDate: '2027-08-11',
    quantity: 95,
    purchasePrice: 650,
    sellingPrice: 669.5
  },
  {
    vaccineName: 'BabyShield Meningo',
    manufacturer: 'HealthCore Pharma',
    vaccineType: 'Subunit',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'BSM515',
    expiryDate: '2026-10-02',
    quantity: 105,
    purchasePrice: 980,
    sellingPrice: 1009.4
  },
  {
    vaccineName: 'KidVax Measles',
    manufacturer: 'MedSure Labs',
    vaccineType: 'Live',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'KVM616',
    expiryDate: '2027-01-27',
    quantity: 140,
    purchasePrice: 480,
    sellingPrice: 494.4
  },
  {
    vaccineName: 'ChildCare Rabies',
    manufacturer: 'RapidBio Corp',
    vaccineType: 'Inactivated',
    doseVolumeMl: 1.0,
    boosterRequired: true,
    batchNumber: 'CCR717',
    expiryDate: '2026-11-30',
    quantity: 50,
    purchasePrice: 1350,
    sellingPrice: 1390.5
  },
  {
    vaccineName: 'TinyGuard Tetanus',
    manufacturer: 'BioNext',
    vaccineType: 'Inactivated',
    doseVolumeMl: 0.5,
    boosterRequired: true,
    batchNumber: 'TGT818',
    expiryDate: '2027-03-05',
    quantity: 190,
    purchasePrice: 350,
    sellingPrice: 360.5
  },
  {
    vaccineName: 'JuniorProtect Cholera',
    manufacturer: 'SafeHealth Labs',
    vaccineType: 'Inactivated',
    doseVolumeMl: 1.5,
    boosterRequired: false,
    batchNumber: 'JPC919',
    expiryDate: '2026-09-09',
    quantity: 40,
    purchasePrice: 750,
    sellingPrice: 772.5
  },
  {
    vaccineName: 'BabySafe COVID',
    manufacturer: 'PrimeMed Pharma',
    vaccineType: 'mRNA',
    doseVolumeMl: 0.25,
    boosterRequired: true,
    batchNumber: 'BSC020',
    expiryDate: '2027-07-18',
    quantity: 300,
    purchasePrice: 2200,
    sellingPrice: 2266
  }
];

async function seed() {
  try {
    const mongoUri = process.env.MONGODB_URI;
    if (!mongoUri) {
      throw new Error('MONGODB_URI not found in environment');
    }

    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB');

    // Optional: Clear existing vaccines if needed
    // await Vaccine.deleteMany({});
    // console.log('Cleared existing vaccines');

    for (const v of vaccines) {
      // Check if batch exists to avoid duplicates
      const exists = await Vaccine.findOne({ batchNumber: v.batchNumber });
      if (exists) {
        console.log(`Skipping existing batch: ${v.batchNumber}`);
        continue;
      }

      await Vaccine.create(v);
      console.log(`Created: ${v.vaccineName} (${v.batchNumber})`);
    }

    console.log('\nSeeding complete!');
  } catch (error) {
    console.error('Seeding error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

seed();
