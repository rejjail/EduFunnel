const express = require('express');
const router = express.Router();

const db = require('../config/database');

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/authmiddleware');

// Semua endpoint admin wajib menggunakan token dan role admin
router.use(verifyToken, verifyAdmin);


// ========================================
// 1. DATA SELURUH PENDAFTAR
// ========================================

router.get('/pendaftaran', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                p.*,
                u.nama,
                u.email
            FROM pendaftaran p
            LEFT JOIN users u ON p.user_id = u.id
            ORDER BY p.created_at DESC
        `);

        res.json({
            message: 'Data pendaftar berhasil diambil.',
            data: results
        });

    } catch (error) {
        console.error('Error mengambil pendaftar:', error);

        res.status(500).json({
            message: 'Gagal mengambil data pendaftar.'
        });
    }
});


// ========================================
// 2. STATISTIK DASHBOARD
// ========================================

router.get('/dashboard/stats', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                COUNT(*) AS total_pendaftar,

                SUM(CASE
                    WHEN status = 'Menunggu' THEN 1
                    ELSE 0
                END) AS menunggu,

                SUM(CASE
                    WHEN status = 'Diterima' THEN 1
                    ELSE 0
                END) AS diterima,

                SUM(CASE
                    WHEN status = 'Ditolak' THEN 1
                    ELSE 0
                END) AS ditolak

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
        console.error('Error statistik:', error);

        res.status(500).json({
            message: 'Gagal mengambil statistik.'
        });
    }
});


// ========================================
// 3. DATA FUNNEL
// ========================================

router.get('/dashboard/funnel', async (req, res) => {
    try {
        const [results] = await db.promise().query(`
            SELECT
                COUNT(*) AS pendaftaran,

                SUM(CASE
                    WHEN status = 'Menunggu' THEN 1
                    ELSE 0
                END) AS menunggu,

                SUM(CASE
                    WHEN status = 'Diterima' THEN 1
                    ELSE 0
                END) AS diterima,

                SUM(CASE
                    WHEN status = 'Ditolak' THEN 1
                    ELSE 0
                END) AS ditolak

            FROM pendaftaran
        `);

        const data = results[0];

        res.json({
            pengunjung: 0,
            pendaftaran: Number(data.pendaftaran || 0),
            menunggu: Number(data.menunggu || 0),
            diterima: Number(data.diterima || 0),
            ditolak: Number(data.ditolak || 0)
        });

    } catch (error) {
        console.error('Error funnel:', error);

        res.status(500).json({
            message: 'Gagal mengambil data funnel.'
        });
    }
});


// ========================================
// 4. CHANNEL ANALYSIS
// ========================================

router.get('/dashboard/channels', async (req, res) => {
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
            configured: true,
            data: results.map(item => ({
                channel: item.channel,
                total: Number(item.total)
            }))
        });

    } catch (error) {
        console.error('Error channel:', error);

        res.status(500).json({
            message: 'Gagal mengambil data channel.'
        });
    }
});


// ========================================
// 5. UPDATE STATUS PENDAFTAR
// ========================================

router.patch('/pendaftaran/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const statusValid = [
            'Menunggu',
            'Diterima',
            'Ditolak'
        ];

        if (!statusValid.includes(status)) {
            return res.status(400).json({
                message: 'Status tidak valid.'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE pendaftaran
             SET status = ?
             WHERE id = ?`,
            [status, id]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                message: 'Data pendaftar tidak ditemukan.'
            });
        }

        res.json({
            message: 'Status pendaftaran berhasil diperbarui.'
        });

    } catch (error) {
        console.error('Error update status:', error);

        res.status(500).json({
            message: 'Gagal memperbarui status.'
        });
    }
});


module.exports = router;