const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const Client = require('../src/models/client.model');
const User = require('../src/models/user.model');

const clientsData = [
  {
    name: 'Dr. J. Balaji MD',
    username: 'drbalaji',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'No.14-G, Anthony Colony, opp. Govt. Dharmapuri Medical College Hospital, Dharmapuri, TN 636701 (Nithya Hospital)',
  },
  {
    name: "Dr.Deepak's Newborn & Child Care",
    username: 'drdeepak',
    specialization: 'Pediatrician',
    contact: '—',
    address: '3-A, Sengodipuram, opposite Hotel PKP Grand, near Om Shakthi Hospital, Dharmapuri, TN 636701 (Justdial)',
  },
  {
    name: "Dr.BALAJI'S -TR Children and Dental Hospital",
    username: 'drbalaji_tr',
    specialization: 'Children’s Hospital',
    contact: '+91 94426 64400',
    address: 'Opp. Govt. Dharmapuri Medical College Hospital, Indhira Nagar, Dharmapuri, TN 636701',
  },
  {
    name: 'T.R. Child and Newborn Health Care Clinic',
    username: 'trchildcare',
    specialization: 'Pediatrician',
    contact: '+91 94432 47441',
    address: 'Indhira Nagar, Dharmapuri, TN 636701',
  },
  {
    name: 'Sri Ganesh child care clinic..,Dr.M.Arulganesh ,MD',
    username: 'drarulganesh',
    specialization: 'Pediatrician',
    contact: '+91 78068 45926',
    address: 'Apollo Medical Underground, Opp. Town Bus Stand, Muhammed Ali Club Road, Dharmapuri, TN 636701',
  },
  {
    name: 'PMK Child Care Centre',
    username: 'pmkchildcare',
    specialization: 'Child Care Centre',
    contact: '+91 4342 263360',
    address: '3, CK Srinivasa Rao St, Dharmapuri, TN 636701',
  },
  {
    name: 'Shri sakthi hospital',
    username: 'shrisakthi',
    specialization: 'Pediatric / General Hospital',
    contact: '+91 97506 70000',
    address: 'Perumbakkan Street, Salem Main Rd, near Mani Ortho Hospital, Dharmapuri, TN 636701',
  },
  {
    name: 'Murali Child Care Clinic',
    username: 'muralichildcare',
    specialization: 'Children’s Hospital',
    contact: '+91 74488 68874',
    address: 'Hotel Anand, Nethaji Bypass, near Kamalam Hospital, Dharmapuri, TN 636701',
  },
  {
    name: 'J K CHILD CARE CENTRE',
    username: 'jkchildcare',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'Vatthalmalai Road, opp. EB Office, near Govt Arts College, Dharmapuri, TN 636705',
  },
  {
    name: 'Rainbow Children Clinic',
    username: 'rainbowclinic',
    specialization: 'Pediatrician',
    contact: '+91 90038 94156',
    address: 'Railway Station Rd, adjacent to GH, Dharmapuri, TN 636701',
  },
  {
    name: 'VISHNU CHILDRENS HOSPITAL',
    username: 'vishnuhospital',
    specialization: 'Pediatrician',
    contact: '—',
    address: 'Indhira Nagar, Dharmapuri, TN 636701',
  },
  {
    name: 'Shree Nithiyaa Child Care Clinic',
    username: 'shreenithiyaa',
    specialization: 'Children’s Hospital',
    contact: '+91 79047 20442',
    address: 'JASS Complex, Kandasamy Vathiyar St, Dharmapuri, TN 636701',
  },
  {
    name: 'Priya Multispeciality Hospital & Kani Maternity Centre',
    username: 'priyahospital',
    specialization: 'Maternity / Hospital',
    contact: '+91 80152 90019',
    address: 'No.3/573, Avvai Nagar, Salem Main Rd, Dharmapuri, TN 636705',
  },
  {
    name: 'Sri Annai Hospital',
    username: 'sriannai',
    specialization: 'Hospital',
    contact: '+91 4342 262738',
    address: 'Narasimha, Arumuga Achari St, Dharmapuri, TN 636701',
  },
  {
    name: 'Rajarajan Hospital',
    username: 'rajarajan',
    specialization: 'Hospital',
    contact: '+91 94437 51500',
    address: 'BSNL office backside, Narasimmachari St, near Bus Stand, Dharmapuri, TN 636701',
  },
];

async function seedClientsAndUsers() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const passwordHash = await bcrypt.hash('123456', 10);

    for (const data of clientsData) {
      // 1. Upsert Client
      const client = await Client.findOneAndUpdate(
        { name: data.name },
        { 
          name: data.name,
          specialization: data.specialization,
          contact: data.contact,
          address: data.address
        },
        { upsert: true, new: true }
      );
      console.log(`Upserted Client: ${client.name}`);

      // 2. Upsert User (Client Login)
      // Generate a dummy email for uniqueness/schema requirement
      const email = `client_${client._id}@stocksync.com`;
      
      // We need to handle potential username changes. 
      // If we blindly upsert by username, we might create duplicates if the username changed but the entity is the same.
      // Ideally, we should find by a stable identifier (like email constructed from client ID), 
      // but here we are establishing the initial state.
      
      // For this specific task, we want to ensure the user with 'Dr. J. Balaji MD' (old username) is updated or replaced.
      // But since we don't have a stable ID linkage in the seed script easily without querying first...
      // We will try to update based on the *Client Name* linkage we just established via the email.
      
      const user = await User.findOneAndUpdate(
        { email: email }, // Match by the email we generated from Client ID (stable)
        {
          name: data.name,
          username: data.username, // Update to new username
          email: email,
          passwordHash: passwordHash,
          role: 'client'
        },
        { upsert: true, new: true }
      );
      
      // Cleanup old username if it exists as a separate document (unlikely with email match, but good to be safe)
      if (data.username !== data.name) {
         await User.deleteOne({ username: data.name }); 
      }
      
      console.log(`Upserted User: ${user.username} (Role: ${user.role})`);
    }

    console.log('\nClient and User seeding complete!');

  } catch (error) {
    console.error('Seeding error:', error);
  } finally {
    await mongoose.disconnect();
  }
}

seedClientsAndUsers();
