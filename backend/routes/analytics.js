
const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { verifyToken } = require('../middleware/authmiddleware');

// ========================================
// 1. TRACKING AKTIVITAS WEBSITE 2
// Endpoint publik, tidak membutuhkan login
// ========================================

router.post('/track', async (req, res) => {
    const {
        event_name,
        source,
        session_id,
        page_path,
        referrer
    } = req.body;

    const allowedEvents = [
        'page_view',
        'register',
        'login',
        'application_submit',
        're_registration'
    ];

    if (!allowedEvents.includes(event_name)) {
        return res.status(400).json({
            success: false,
            message: 'Jenis aktivitas tidak valid.'
        });
    }

    try {
        await db.promise().query(
            `INSERT INTO analytics_events (
                event_name,
                source,
                session_id,
                page_path,
                referrer
            ) VALUES (?, ?, ?, ?, ?)`,
            [
                event_name,
                String(source || 'Website PPDB SMPIT Nururrahman').slice(0, 100),
                session_id ? String(session_id).slice(0, 100) : null,
                page_path ? String(page_path).slice(0, 255) : null,
                referrer ? String(referrer).slice(0, 500) : null
            ]
        );

        return res.status(201).json({
            success: true,
            message: 'Aktivitas berhasil dicatat.'
        });

    } catch (error) {
        console.error('ERROR TRACKING:', error.message);

        return res.status(500).json({
            success: false,
            message: 'Gagal mencatat aktivitas.'
        });
    }
});

// ========================================
// 2. MIDDLEWARE STATISTIK
// Endpoint di bawah ini wajib login
// ========================================

router.use(verifyToken);

// ========================================
// 3. OVERVIEW STATISTICS
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
// 4. CHANNEL ANALYSIS
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
// 5. FUNNEL DEPTH
// ========================================

router.get('/funnel', async (req, res) => {
    try {
        // Mengambil jumlah aktivitas dari Website 2
        const [eventResults] = await db.promise().query(`
            SELECT
                COUNT(CASE
                    WHEN event_name = 'page_view' THEN 1
                END) AS pengunjung,

                COUNT(CASE
                    WHEN event_name = 'register' THEN 1
                END) AS registrasi_akun,

                COUNT(CASE
                    WHEN event_name = 'application_submit' THEN 1
                END) AS pengiriman_formulir

            FROM analytics_events
            WHERE source = 'Website PPDB SMPIT Nururrahman'
        `);

        // Mengambil statistik status pendaftaran
        const [registrationResults] = await db.promise().query(`
            SELECT
                COUNT(*) AS pendaftaran,
                SUM(status = 'Menunggu') AS menunggu,
                SUM(status = 'Diterima') AS diterima,
                SUM(status = 'Ditolak') AS ditolak
            FROM pendaftaran
        `);

        const events = eventResults[0];
        const data = registrationResults[0];

        res.json({
            pengunjung: Number(events.pengunjung || 0),
            registrasi_akun: Number(events.registrasi_akun || 0),
            pengiriman_formulir: Number(events.pengiriman_formulir || 0),

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
