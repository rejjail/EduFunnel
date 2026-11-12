require('dotenv').config();

const express = require('express');
const cors = require('cors');

const db = require('./config/database');

// Import Routes
const authRoutes = require('./routes/auth');
const adminRoutes = require('./routes/admin');
const pendaftaranRoutes = require('./routes/pendaftaran');
const analyticsRoutes = require('./routes/analytics');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Pengecekan Routes
const routes = {
    authRoutes,
    adminRoutes,
    pendaftaranRoutes,
    analyticsRoutes
};

for (const [name, route] of Object.entries(routes)) {
    if (typeof route !== 'function') {
        throw new Error(`ERROR: ${name} bukan router/function!`);
    }

    console.log(`${name}: berhasil dimuat`);
}

// Daftarkan Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/pendaftaran', pendaftaranRoutes);
app.use('/api/analytics', analyticsRoutes);

// Halaman utama
app.get('/', (req, res) => {
    res.json({
        message: 'Backend PPDB berhasil berjalan!'
    });
});

// Tes database
app.get('/test-db', (req, res) => {
    db.query('SELECT 1 AS hasil', (err, result) => {
        if (err) {
            console.error('Database error:', err.message);

            return res.status(500).json({
                message: 'Database gagal diakses',
                error: err.message
            });
        }

        res.json({
            message: 'Database berhasil terhubung!',
            data: result
        });
    });
});

// Route tidak ditemukan
app.use((req, res) => {
    res.status(404).json({
        message: 'Endpoint tidak ditemukan'
    });
});

// Export aplikasi untuk Vercel
module.exports = app;

// Jalankan server hanya ketika dijalankan secara lokal
if (require.main === module) {
    const PORT = process.env.PORT || 3000;

    app.listen(PORT, () => {
        console.log('================================');
        console.log('   BACKEND PPDB BERHASIL JALAN');
        console.log(`   http://localhost:${PORT}`);
        console.log('================================');
    });
}
