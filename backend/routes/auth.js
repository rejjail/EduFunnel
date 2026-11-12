const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');

// REGISTRASI USER
router.post('/register', async (req, res) => {
    try {
        const { nama, email, password } = req.body;

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

        db.query(
            'SELECT id FROM users WHERE email = ?',
            [emailBersih],
            async (err, results) => {
                if (err) {
                    return res.status(500).json({
                        message: 'Gagal memeriksa email'
                    });
                }

                if (results.length > 0) {
                    return res.status(409).json({
                        message: 'Email sudah terdaftar'
                    });
                }

                const hashedPassword = await bcrypt.hash(password, 10);

                db.query(
                    `INSERT INTO users (nama, email, password, role)
                     VALUES (?, ?, ?, 'user')`,
                    [nama.trim(), emailBersih, hashedPassword],
                    (err, result) => {
                        if (err) {
                            return res.status(500).json({
                                message: 'Registrasi gagal'
                            });
                        }

                        res.status(201).json({
                            message: 'Registrasi berhasil',
                            user: {
                                id: result.insertId,
                                nama: nama.trim(),
                                email: emailBersih,
                                role: 'user'
                            }
                        });
                    }
                );
            }
        );
    } catch (error) {
        res.status(500).json({
            message: 'Terjadi kesalahan server'
        });
    }
});

// LOGIN ADMIN DAN USER
router.post('/login', (req, res) => {
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
                return res.status(500).json({
                    message: 'Gagal melakukan login'
                });
            }

            if (results.length === 0) {
                return res.status(401).json({
                    message: 'Email atau password salah'
                });
            }

            const user = results[0];

            const passwordCocok = await bcrypt.compare(
                password,
                user.password
            );

            if (!passwordCocok) {
                return res.status(401).json({
                    message: 'Email atau password salah'
                });
            }

            const token = jwt.sign(
                {
                    id: user.id,
                    role: user.role
                },
                process.env.JWT_SECRET,
                { expiresIn: '1d' }
            );

            res.json({
                message: 'Login berhasil',
                token: token,
                user: {
                    id: user.id,
                    nama: user.nama,
                    email: user.email,
                    role: user.role
                }
            });
        }
    );
});

module.exports = router;