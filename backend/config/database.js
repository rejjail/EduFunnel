const mysql = require('mysql2');
const fs = require('fs');
const path = require('path');

const db = mysql.createPool({
    host: process.env.DB_HOST,
    port: process.env.DB_PORT || 4000,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,

    ssl: {
        ca: fs.readFileSync(
            path.join(__dirname, 'isrgrootx1.pem')
        )
    },

    waitForConnections: true,
    connectionLimit: 5,
    queueLimit: 0
});

db.getConnection((err, connection) => {
    if (err) {
        console.error('Koneksi TiDB gagal:', err.message);
        return;
    }

    console.log('TiDB Cloud berhasil terhubung!');
    connection.release();
});

module.exports = db;