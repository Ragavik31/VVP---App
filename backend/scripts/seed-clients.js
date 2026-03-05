const mongoose = require('mongoose');
require('dotenv').config();
const Client = require('../src/models/client.model');

const clients = [
  {
    name: 'Dr. J. Balaji MD',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'No.14-G, Anthony Colony, opp. Govt. Dharmapuri Medical College Hospital, Dharmapuri, TN 636701'
  },
  {
    name: "Dr.Deepak's Newborn & Child Care",
    specialization: 'Pediatrician',
    contact: '—',
    address: '3-A, Sengodipuram, opposite Hotel PKP Grand, near Om Shakthi Hospital, Dharmapuri, TN 636701'
  },
  {
    name: "Dr.BALAJI'S -TR Children and Dental Hospital",
    specialization: 'Children’s Hospital',
    contact: '+91 94426 64400',
    address: 'Opp. Govt. Dharmapuri Medical College Hospital, Indhira Nagar, Dharmapuri, TN 636701'
  },
  {
    name: 'T.R. Child and Newborn Health Care Clinic',
    specialization: 'Pediatrician',
    contact: '+91 94432 47441',
    address: 'Indhira Nagar, Dharmapuri, TN 636701'
  },
  {
    name: 'Sri Ganesh child care clinic..,Dr.M.Arulganesh ,MD',
    specialization: 'Pediatrician',
    contact: '+91 78068 45926',
    address: 'Apollo Medical Underground, Opp. Town Bus Stand, Muhammed Ali Club Road, Dharmapuri, TN 636701'
  },
  {
    name: 'PMK Child Care Centre',
    specialization: 'Child Care Centre',
    contact: '+91 4342 263360',
    address: '3, CK Srinivasa Rao St, Dharmapuri, TN 636701'
  },
  {
    name: 'Shri sakthi hospital',
    specialization: 'Pediatric / General Hospital',
    contact: '+91 97506 70000',
    address: 'Perumbakkan Street, Salem Main Rd, near Mani Ortho Hospital, Dharmapuri, TN 636701'
  },
  {
    name: 'Murali Child Care Clinic',
    specialization: 'Children’s Hospital',
    contact: '+91 74488 68874',
    address: 'Hotel Anand, Nethaji Bypass, near Kamalam Hospital, Dharmapuri, TN 636701'
  },
  {
    name: 'J K CHILD CARE CENTRE',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'Vatthalmalai Road, opp. EB Office, near Govt Arts College, Dharmapuri, TN 636705'
  },
  {
    name: 'Rainbow Children Clinic',
    specialization: 'Pediatrician',
    contact: '+91 90038 94156',
    address: 'Railway Station Rd, adjacent to GH, Dharmapuri, TN 636701'
  },
  {
    name: 'VISHNU CHILDRENS HOSPITAL',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'Indhira Nagar, Dharmapuri, TN 636701'
  },
  {
    name: 'Shree Nithiyaa Child Care Clinic',
    specialization: 'Children’s Hospital',
    contact: '+91 79047 20442',
    address: 'JASS Complex, Kandasamy Vathiyar St, Dharmapuri, TN 636701'
  },
  {
    name: 'Priya Multispeciality Hospital & Kani Maternity Centre',
    specialization: 'Maternity / Hospital',
    contact: '+91 80152 90019',
    address: 'No.3/573, Avvai Nagar, Salem Main Rd, Dharmapuri, TN 636705'
  },
  {
    name: 'Sri Annai Hospital',
    specialization: 'Hospital',
    contact: '+91 4342 262738',
    address: 'Narasimha, Arumuga Achari St, Dharmapuri, TN 636701'
  },
  {
    name: 'Rajarajan Hospital',
    specialization: 'Hospital',
    contact: '+91 94437 51500',
    address: 'BSNL office backside, Narasimmachari St, near Bus Stand, Dharmapuri, TN 636701'
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

    // Optional: Clear existing clients
    // await Client.deleteMany({});
    
    for (const client of clients) {
      // Check if client exists by name
      const exists = await Client.findOne({ name: client.name });
      if (exists) {
        console.log(`Skipping existing client: ${client.name}`);
        continue;
      }

      await Client.create(client);
      console.log(`Created: ${client.name}`);
    }

    console.log('\nClient seeding complete!');
  } catch (error) {
    console.error('Seeding error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

seed();
