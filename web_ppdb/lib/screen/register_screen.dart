import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  // Alamat backend Node.js
  final String baseUrl = 'https://edu-funnel-eight.vercel.app';

  // ==========================================
  // FUNGSI REGISTRASI
  // ==========================================

  Future<void> register() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nama': namaController.text.trim(),
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final dynamic result = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Registrasi gagal. Silakan coba lagi.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghubungi server: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // DISPOSE CONTROLLER
  // ==========================================

  @override
  void dispose() {
    namaController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ==========================================
  // TAMPILAN HALAMAN REGISTRASI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1D3557),
        title: const Text(
          'Registrasi Akun',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black..withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 65,
                    color: Color(0xFF2463A6),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Buat Akun Baru',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D3557),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Silakan lengkapi data berikut untuk membuat akun PPDB.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  _buildLabel('Nama Lengkap'),

                  TextFormField(
                    controller: namaController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      'Masukkan nama lengkap',
                      Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama lengkap wajib diisi.';
                      }

                      if (value.trim().length < 3) {
                        return 'Nama minimal 3 karakter.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel('Alamat Email'),

                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      'Masukkan alamat email',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi.';
                      }

                      if (!RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(value.trim())) {
                        return 'Format email tidak valid.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel('Password'),

                  TextFormField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: _inputDecoration(
                      'Minimal 6 karakter',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi.';
                      }

                      if (value.length < 6) {
                        return 'Password minimal 6 karakter.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel('Konfirmasi Password'),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: _inputDecoration(
                      'Ulangi password',
                      Icons.lock_reset_outlined,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          showConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi.';
                      }

                      if (value != passwordController.text) {
                        return 'Konfirmasi password tidak cocok.';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    height: 53,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2463A6),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.blueGrey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          isLoading
                              ? const SizedBox(
                                width: 23,
                                height: 23,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                'DAFTAR SEKARANG',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed:
                        isLoading
                            ? null
                            : () {
                              Navigator.pop(context);
                            },
                    child: const Text(
                      'Sudah punya akun? Kembali ke Login',
                      style: TextStyle(
                        color: Color(0xFF2463A6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // KOMPONEN LABEL
  // ==========================================

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  // ==========================================
  // DESAIN INPUT
  // ==========================================

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2463A6)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2463A6), width: 1.5),
      ),
    );
  }
}
