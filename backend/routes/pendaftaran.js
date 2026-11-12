const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { verifyToken } = require('../middleware/authmiddleware');

// Semua fitur pendaftaran membutuhkan login
router.use(verifyToken);

// 1. Mengirim formulir pendaftaran
router.post('/', async (req, res) => {
    const {
        nisn,
        tempat_lahir,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        asal_sekolah,
        sumber_informasi,
    } = req.body;

    if (
        !nisn ||
        !tempat_lahir ||
        !tanggal_lahir ||
        !jenis_kelamin ||
        !alamat ||
        !asal_sekolah
    ) {
        return res.status(400).json({
            message: 'Semua data pendaftaran wajib diisi.'
        });
    }

    if (!['Laki-laki', 'Perempuan'].includes(jenis_kelamin)) {
        return res.status(400).json({
            message: 'Jenis kelamin tidak valid.'
        });
    }

    try {
        // Cek apakah user sudah pernah mendaftar
        const [existingUser] = await db.promise().query(
            'SELECT id FROM pendaftaran WHERE user_id = ?',
            [req.user.id]
        );

        if (existingUser.length > 0) {
            return res.status(409).json({
                message: 'Anda sudah pernah melakukan pendaftaran.'
            });
        }

        // Simpan data pendaftaran
        const [result] = await db.promise().query(
    `INSERT INTO pendaftaran
    (
        user_id,
        nisn,
        tempat_lahir,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        asal_sekolah,
        sumber_informasi
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [
        req.user.id,
        nisn,
        tempat_lahir,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        asal_sekolah,
        sumber_informasi || 'Lainnya'
    ]
);

        res.status(201).json({
            message: 'Pendaftaran berhasil dikirim.',
            id_pendaftaran: result.insertId
        });

    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'NISN sudah digunakan.'
            });
        }

        res.status(500).json({
            message: 'Gagal menyimpan pendaftaran.',
            error: error.message
        });
    }
});

// 2. Melihat status pendaftaran milik user yang login
router.get('/status', (req, res) => {
    const sql = `
        SELECT
            id,
            nisn,
            tempat_lahir,
            tanggal_lahir,
            jenis_kelamin,
            alamat,
            asal_sekolah,
            status,
            created_at
        FROM pendaftaran
        WHERE user_id = ?
    `;

    db.query(sql, [req.user.id], (err, results) => {
        if (err) {
            return res.status(500).json({
                message: 'Gagal mengambil status pendaftaran.'
            });
        }

        if (results.length === 0) {
            return res.status(404).json({
                message: 'Anda belum melakukan pendaftaran.'
            });
        }

        res.json({
            message: 'Status pendaftaran berhasil diambil.',
            data: results[0]
        });
    });
});

module.exports = router;