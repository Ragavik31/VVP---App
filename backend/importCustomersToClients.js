const XLSX = require("xlsx");
const { MongoClient } = require("mongodb");

async function importCustomers() {

    const workbook = XLSX.readFile("customers.xlsx");
    const sheet = workbook.Sheets[workbook.SheetNames[0]];

    // Read as ARRAY instead of JSON
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 });

    // Remove first row (headers)
    rows.shift();

    // Map columns manually
    const customers = rows.map(row => ({
        customerCode: row[0],
        customerName: row[1],
        customerAddress: row[2],
        dealerType: row[3],
        gstNumber: row[4]
    }));

    console.log("📄 Excel rows:", customers.length);

    const uri = "mongodb+srv://ragavikrish05_db_user:ragavikrish05_db_user@mobileapp.lbh5fen.mongodb.net/?appName=MobileApp";
    const client = new MongoClient(uri);

    try {
        await client.connect();
        const db = client.db("test");
        const collection = db.collection("clients");

        await collection.deleteMany({});
        console.log("🗑️ Old clients deleted");

        await collection.insertMany(customers);
        console.log("🎉 Clients imported correctly!");

    } catch (err) {
        console.error(err);
    } finally {
        await client.close();
    }
}

importCustomers();
