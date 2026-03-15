const { MongoClient } = require("mongodb");

async function randomizePhones() {
  const uri =
    "mongodb+srv://ragavikrish05_db_user:ragavikrish05_db_user@mobileapp.lbh5fen.mongodb.net/?appName=MobileApp";
  const client = new MongoClient(uri);

  try {
    await client.connect();
    console.log("✅ Connected to MongoDB Atlas");

    const db = client.db("test");
    const collection = db.collection("clients");

    // Indian mobile prefixes (common ones)
    const prefixes = ["70", "72", "73", "74", "75", "76", "77", "78", "79",
                      "80", "81", "82", "83", "84", "85", "86", "87", "88", "89",
                      "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"];

    function randomIndianPhone() {
      const prefix = prefixes[Math.floor(Math.random() * prefixes.length)];
      const rest = String(Math.floor(Math.random() * 100000000)).padStart(8, "0");
      return prefix + rest;
    }

    // Find clients with no real phone (empty, dash, or missing)
    const clients = await collection.find({
      $or: [
        { contact: { $exists: false } },
        { contact: null },
        { contact: "" },
        { contact: "—" },
        { contact: "-" },
      ],
    }).toArray();

    console.log(`📱 Found ${clients.length} client(s) without phone numbers`);

    for (const c of clients) {
      const phone = randomIndianPhone();
      await collection.updateOne(
        { _id: c._id },
        { $set: { contact: phone } }
      );
      console.log(`  ${c.name}: ${phone}`);
    }

    console.log("\n🎉 Done! All clients now have phone numbers.");
  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await client.close();
  }
}

randomizePhones();
