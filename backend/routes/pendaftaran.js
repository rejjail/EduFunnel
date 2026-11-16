
const express = require('express');
const router = express.Router();

const db = require('../config/database');
const { verifyToken } = require('../middleware/authmiddleware');

// Semua fitur pendaftaran membutuhkan login
router.use(verifyToken);

// ==========================================
// 1. MENGIRIM FORMULIR PENDAFTARAN
// ==========================================

router.post('/', async (req, res) => {
    const {
        nisn,
        nik,
        nama_lengkap,
        tempat_lahir,
        tanggal_lahir,
        jenis_kelamin,
        alamat,
        asal_sekolah,
        nama_orang_tua,
        whatsapp,
        sumber_informasi
    } = req.body;

    // Data wajib untuk website lama dan baru
    if (
        !nisn ||
        !tempat_lahir ||
        !tanggal_lahir ||
        !jenis_kelamin ||
        !alamat ||
        !asal_sekolah
    ) {
        return res.status(400).json({
            message: 'Data wajib pendaftaran belum lengkap.'
        });
    }

    // Validasi jenis kelamin
    if (!['Laki-laki', 'Perempuan'].includes(jenis_kelamin)) {
        return res.status(400).json({
            message: 'Jenis kelamin tidak valid.'
        });
    }

    // Validasi tanggal YYYY-MM-DD
    if (!/^\d{4}-\d{2}-\d{2}$/.test(tanggal_lahir)) {
        return res.status(400).json({
            message: 'Format tanggal lahir harus YYYY-MM-DD.'
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

        // Cek NISN
        const [existingNisn] = await db.promise().query(
            'SELECT id FROM pendaftaran WHERE nisn = ?',
            [nisn.trim()]
        );

        if (existingNisn.length > 0) {
            return res.status(409).json({
                message: 'NISN sudah digunakan.'
            });
        }

        // Cek NIK hanya jika dikirim
        if (nik && nik.trim() !== '') {
            const [existingNik] = await db.promise().query(
                'SELECT id FROM pendaftaran WHERE nik = ?',
                [nik.trim()]
            );

            if (existingNik.length > 0) {
                return res.status(409).json({
                    message: 'NIK sudah digunakan.'
                });
            }
        }

        // Generate ID karena belum AUTO_INCREMENT
        const [lastId] = await db.promise().query(
            'SELECT COALESCE(MAX(id), 0) + 1 AS next_id FROM pendaftaran'
        );

        const newId = lastId[0].next_id;

        // Simpan data pendaftaran
        const [result] = await db.promise().query(
            `INSERT INTO pendaftaran (
                id,
                user_id,
                nisn,
                nik,
                nama_lengkap,
                tempat_lahir,
                tanggal_lahir,
                jenis_kelamin,
                alamat,
                asal_sekolah,
                nama_orang_tua,
                whatsapp,
                sumber_informasi
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                newId,
                req.user.id,
                nisn.trim(),
                nik && nik.trim() !== '' ? nik.trim() : null,
                nama_lengkap && nama_lengkap.trim() !== '' ? nama_lengkap.trim() : null,
                tempat_lahir.trim(),
                tanggal_lahir,
                jenis_kelamin,
                alamat.trim(),
                asal_sekolah.trim(),
                nama_orang_tua && nama_orang_tua.trim() !== '' ? nama_orang_tua.trim() : null,
                whatsapp && whatsapp.trim() !== '' ? whatsapp.trim() : null,
                sumber_informasi || 'Direct'
            ]
        );

        return res.status(201).json({
            success: true,
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
                message: 'NISN, NIK, atau data pendaftaran sudah digunakan.'
            });
        }

        return res.status(500).json({
            message: 'Gagal menyimpan pendaftaran.'
        });
    }
});

// ==========================================
// 2. MELIHAT STATUS PENDAFTARAN
// ==========================================

router.get('/status', async (req, res) => {
    try {
        const [results] = await db.promise().query(
            `SELECT
                id,
                nisn,
                nik,
                nama_lengkap,
                tempat_lahir,
                tanggal_lahir,
                jenis_kelamin,
                alamat,
                asal_sekolah,
                nama_orang_tua,
                whatsapp,
                sumber_informasi,
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
            success: true,
            message: 'Status pendaftaran berhasil diambil.',
            data: results[0]
        });

    } catch (error) {
        console.error('ERROR STATUS PENDAFTARAN:', error.message);

        return res.status(500).json({
            message: 'Gagal mengambil status pendaftaran.'
        });
    }
});

module.exports = router;
