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
        sumber_informasi
    } = req.body;

    // Validasi data
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

        // Cek ID terakhir dan buat ID berikutnya
        const [lastId] = await db.promise().query(
            'SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM pendaftaran'
        );

        const newId = lastId[0].next_id;

        // Simpan pendaftaran
        const [result] = await db.promise().query(
            `INSERT INTO pendaftaran (
                id,
                user_id,
                nisn,
                tempat_lahir,
                tanggal_lahir,
                jenis_kelamin,
                alamat,
                asal_sekolah,
                sumber_informasi
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                newId,
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

        return res.status(201).json({
            message: 'Pendaftaran berhasil dikirim.',
            id_pendaftaran: result.insertId || newId
        });

    } catch (error) {
        console.error('ERROR PENDAFTARAN:', {
            message: error.message,
            code: error.code,
            user_id: req.user.id
        });

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'NISN atau data pendaftaran sudah digunakan.'
            });
        }

        return res.status(500).json({
            message: 'Gagal menyimpan pendaftaran.',
            error: error.message
        });
    }
});

// 2. Melihat status pendaftaran
router.get('/status', async (req, res) => {
    try {
        const [results] = await db.promise().query(
            `SELECT
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
            WHERE user_id = ?`,
            [req.user.id]
        );

        if (results.length === 0) {
            return res.status(404).json({
                message: 'Anda belum melakukan pendaftaran.'
            });
        }

        return res.json({
            message: 'Status pendaftaran berhasil diambil.',
            data: results[0]
        });

    } catch (error) {
        console.error('ERROR STATUS PENDAFTARAN:', error.message);

        return res.status(500).json({
            message: 'Gagal mengambil status pendaftaran.',
            error: error.message
        });
    }
});

module.exports = router;
