const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

// ==========================================
// REGISTRASI USER
// ==========================================
router.post('/register', async (req, res) => {
    try {
        const { nama, email, password } = req.body;

        // Validasi input
        if (!nama || !email || !password) {
            return res.status(400).json({
                message: 'Semua data harus diisi'
            });
        }

        if (password.length < 6) {
            return res.status(400).json({
                message: 'Password minimal 6 karakter'
            });
        }

        const emailBersih = email.trim().toLowerCase();
        const namaBersih = nama.trim();

        // Cek email
        db.query(
            'SELECT id FROM users WHERE email = ?',
            [emailBersih],
            async (err, results) => {

                if (err) {
                    console.error('ERROR CEK EMAIL:', err);

                    return res.status(500).json({
                        message: 'Gagal memeriksa email',
                        error: err.message
                    });
                }

                // Cek apakah email sudah terdaftar
                if (results.length > 0) {
                    return res.status(409).json({
                        message: 'Email sudah terdaftar'
                    });
                }

                try {
                    // Hash password
                    const hashedPassword = await bcrypt.hash(password, 10);

                    // Simpan user
                    db.query(
                        `INSERT INTO users (nama, email, password, role)
                         VALUES (?, ?, ?, 'user')`,
                        [namaBersih, emailBersih, hashedPassword],
                        (err, result) => {

                            if (err) {
                                console.error('ERROR INSERT REGISTRASI:', err);

                                return res.status(500).json({
                                    message: 'Registrasi gagal',
                                    error: err.message
                                });
                            }

                            console.log('REGISTRASI BERHASIL:', emailBersih);

                            return res.status(201).json({
                                message: 'Registrasi berhasil',
                                user: {
                                    id: result.insertId,
                                    nama: namaBersih,
                                    email: emailBersih,
                                    role: 'user'
                                }
                            });
                        }
                    );

                } catch (error) {
                    console.error('ERROR HASH PASSWORD:', error);

                    return res.status(500).json({
                        message: 'Gagal memproses password',
                        error: error.message
                    });
                }
            }
        );

    } catch (error) {
        console.error('ERROR REGISTRASI:', error);

        return res.status(500).json({
            message: 'Terjadi kesalahan server',
            error: error.message
        });
    }
});

// ==========================================
// LOGIN ADMIN DAN USER
// ==========================================
router.post('/login', (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                message: 'Email dan password harus diisi'
            });
        }

        const emailBersih = email.trim().toLowerCase();

        db.query(
            'SELECT * FROM users WHERE email = ?',
            [emailBersih],
            async (err, results) => {

                if (err) {
                    console.error('ERROR LOGIN DATABASE:', err);

                    return res.status(500).json({
                        message: 'Gagal melakukan login',
                        error: err.message
                    });
                }

                if (results.length === 0) {
                    return res.status(401).json({
                        message: 'Email atau password salah'
                    });
                }

                try {
                    const user = results[0];

                    // Cek password
                    const passwordCocok = await bcrypt.compare(
                        password,
                        user.password
                    );

                    if (!passwordCocok) {
                        return res.status(401).json({
                            message: 'Email atau password salah'
                        });
                    }

                    // Pastikan JWT_SECRET tersedia
                    if (!process.env.JWT_SECRET) {
                        console.error('JWT_SECRET belum dikonfigurasi');

                        return res.status(500).json({
                            message: 'Konfigurasi server belum lengkap'
                        });
                    }

                    // Buat token
                    const token = jwt.sign(
                        {
                            id: user.id,
                            role: user.role
                        },
                        process.env.JWT_SECRET,
                        { expiresIn: '1d' }
                    );

                    return res.json({
                        message: 'Login berhasil',
                        token: token,
                        user: {
                            id: user.id,
                            nama: user.nama,
                            email: user.email,
                            role: user.role
                        }
                    });

                } catch (error) {
                    console.error('ERROR PROSES LOGIN:', error);

                    return res.status(500).json({
                        message: 'Terjadi kesalahan saat login',
                        error: error.message
                    });
                }
            }
        );

    } catch (error) {
        console.error('ERROR LOGIN:', error);

        return res.status(500).json({
            message: 'Terjadi kesalahan server',
            error: error.message
        });
    }
});

module.exports = router;
