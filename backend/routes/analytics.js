const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { verifyToken } = require('../middleware/authmiddleware');

// ========================================
// MIDDLEWARE
// Semua endpoint wajib login.
// User dan admin boleh membaca statistik.
// ========================================

router.use(verifyToken);

// ========================================
// 1. OVERVIEW STATISTICS
// ========================================

router.get('/stats', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                COUNT(*) AS total_pendaftar,
                SUM(status = 'Menunggu') AS menunggu,
                SUM(status = 'Diterima') AS diterima,
                SUM(status = 'Ditolak') AS ditolak
            FROM pendaftaran
        `);

        const data = results[0];

        res.json({
            total_pendaftar: Number(data.total_pendaftar || 0),
            menunggu: Number(data.menunggu || 0),
            diterima: Number(data.diterima || 0),
            ditolak: Number(data.ditolak || 0)
        });

    } catch (error) {
        console.error('Error Stats:', error.message);

        res.status(500).json({
            message: 'Gagal mengambil statistik.'
        });
    }
});

// ========================================
// 2. CHANNEL ANALYSIS
// ========================================

router.get('/channels', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                COALESCE(
                    NULLIF(sumber_informasi, ''),
                    'Lainnya'
                ) AS channel,
                COUNT(*) AS total
            FROM pendaftaran
            GROUP BY channel
            ORDER BY total DESC
        `);

        res.json({
            data: results.map(item => ({
                channel: item.channel,
                total: Number(item.total)
            }))
        });

    } catch (error) {
        console.error('Error Channels:', error.message);

        res.status(500).json({
            message: 'Gagal mengambil data channel.'
        });
    }
});

// ========================================
// 3. FUNNEL DEPTH
// ========================================

router.get('/funnel', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                COUNT(*) AS pendaftaran,
                SUM(status = 'Menunggu') AS menunggu,
                SUM(status = 'Diterima') AS diterima,
                SUM(status = 'Ditolak') AS ditolak
            FROM pendaftaran
        `);

        const data = results[0];

        res.json({
            pendaftaran: Number(data.pendaftaran || 0),
            menunggu: Number(data.menunggu || 0),
            diterima: Number(data.diterima || 0),
            ditolak: Number(data.ditolak || 0)
        });

    } catch (error) {
        console.error('Error Funnel:', error.message);

        res.status(500).json({
            message: 'Gagal mengambil data funnel.'
        });
    }
});

// ========================================
// EXPORT ROUTER
// ========================================

module.exports = router;