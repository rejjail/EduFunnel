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

    // Validasi data wajib
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

    // Validasi jenis kelamin
    if (!['Laki-laki', 'Perempuan'].includes(jenis_kelamin)) {
        return res.status(400).json({
            message: 'Jenis kelamin tidak valid.'
        });
    }

    try {
        // Pastikan user ID tersedia
        if (!req.user || !req.user.id) {
            return res.status(401).json({
                message: 'Identitas pengguna tidak ditemukan. Silakan login kembali.'
            });
        }

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
        const sql = `
            INSERT INTO pendaftaran (
                user_id,
                nisn,
                tempat_lahir,
                tanggal_lahir,
                jenis_kelamin,
                alamat,
                asal_sekolah,
                sumber_informasi
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        `;

        const values = [
            req.user.id,
            nisn,
            tempat_lahir,
            tanggal_lahir,
            jenis_kelamin,
            alamat,
            asal_sekolah,
            sumber_informasi || 'Lainnya'
        ];

        const [result] = await db.promise().query(sql, values);

        console.log('PENDAFTARAN BERHASIL:', {
            user_id: req.user.id,
            id_pendaftaran: result.insertId
        });

        return res.status(201).json({
            message: 'Pendaftaran berhasil dikirim.',
            id_pendaftaran: result.insertId
        });

    } catch (error) {
        // Catat error asli di Vercel Runtime Logs
        console.error('ERROR PENDAFTARAN:', {
            message: error.message,
            code: error.code,
            sqlMessage: error.sqlMessage,
            user_id: req.user?.id
        });

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'NISN atau data pendaftaran sudah digunakan.',
                error: error.message
            });
        }

        return res.status(500).json({
            message: 'Gagal menyimpan pendaftaran.',
            error: error.message,
            code: error.code || 'UNKNOWN_ERROR'
        });
    }
});

// 2. Melihat status pendaftaran milik user yang login
router.get('/status', async (req, res) => {
    try {
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

        const [results] = await db.promise().query(sql, [req.user.id]);

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
        console.error('ERROR STATUS PENDAFTARAN:', {
            message: error.message,
            code: error.code,
            sqlMessage: error.sqlMessage,
            user_id: req.user?.id
        });

        return res.status(500).json({
            message: 'Gagal mengambil status pendaftaran.',
            error: error.message
        });
    }
});

module.exports = router;
