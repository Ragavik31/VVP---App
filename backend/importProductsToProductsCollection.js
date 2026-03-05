const XLSX = require("xlsx");
const { MongoClient } = require("mongodb");

async function importProducts() {

    // Read Excel file
    const workbook = XLSX.readFile("products.xlsx");
    const sheet = workbook.Sheets[workbook.SheetNames[0]];

    // Read as array
    const rows = XLSX.utils.sheet_to_json(sheet, { header: 1 });

    // Remove header row
    rows.shift();

    // Map columns manually
    const products = rows.map(row => ({
        divisionName: row[0],
        productName: row[1],
        salesPrice: Number(row[2]),
        mrp: Number(row[3])
    }));

    console.log("📄 Excel rows:", products.length);

    const uri = "mongodb+srv://ragavikrish05_db_user:ragavikrish05_db_user@mobileapp.lbh5fen.mongodb.net/?appName=MobileApp";
    const client = new MongoClient(uri);

    try {
        await client.connect();
        console.log("✅ Connected to MongoDB Atlas");

        const db = client.db("test");
        const collection = db.collection("products");

        // Delete old products
        await collection.deleteMany({});
        console.log("🗑️ Old products deleted");

        // Insert new products
        await collection.insertMany(products);
        console.log("🎉 Products imported correctly!");

    } catch (err) {
        console.error(err);
    } finally {
        await client.close();
    }
}

importProducts();
