import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screen/dashboard_screen.dart';
import 'screen/register_screen.dart';

void main() {
  runApp(const PPDBApp());
}

class PPDBApp extends StatelessWidget {
  const PPDBApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PPDB SMPIT Nururrahman',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2463A6)),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool showPassword = false;
  bool isLoading = false;

  final String baseUrl = 'http://localhost:3000';

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': emailController.text.trim(),
              'password': passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final result = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final user = result['user'];
        final token = result['token']?.toString();

        if (user == null || token == null || token.isEmpty) {
          throw Exception('Data pengguna atau token tidak ditemukan.');
        }

        final nama = user['nama']?.toString() ?? 'Pengguna';
        final role = user['role']?.toString().toLowerCase().trim() ?? '';

        if (role != 'admin' && role != 'user') {
          throw Exception('Role pengguna tidak dikenali.');
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => DashboardScreen(
                  nama: nama,
                  role: role,
                  token: token,
                  onLogout: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']?.toString() ?? 'Login gagal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghubungi backend: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> openRegister() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );

    if (!mounted) return;

    if (berhasil == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akun berhasil dibuat. Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF2463A6)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget informationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informasi Login',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123B70),
            ),
          ),
          SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.person_outline, color: Color(0xFF2463A6), size: 23),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Login Siswa / User\n'
                  'Gunakan email dan password yang sudah didaftarkan '
                  'melalui menu Daftar Akun Baru.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.admin_panel_settings_outlined,
                color: Colors.orange,
                size: 23,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Login Admin\n'
                  'Gunakan akun administrator yang sudah disediakan. '
                  'Admin tidak perlu melakukan registrasi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Sistem akan mengarahkan pengguna secara otomatis '
            'ke dashboard sesuai hak akses akun.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.school_rounded,
                    size: 65,
                    color: Color(0xFF2463A6),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'PPDB ONLINE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123B70),
                    ),
                  ),
                  const Text(
                    'SMPIT Nururrahman',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 25),

                  // INFORMASI LOGIN USER DAN ADMIN
                  informationCard(),

                  const SizedBox(height: 25),

                  const Text('Alamat Email'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: inputDecoration(
                      'Masukkan email',
                      Icons.email_outlined,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    decoration: inputDecoration(
                      'Masukkan password',
                      Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(
                          showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2463A6),
                        foregroundColor: Colors.white,
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'LOGIN SEKARANG',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 10),

                  const Text(
                    'Belum memiliki akun?',
                    textAlign: TextAlign.center,
                  ),

                  TextButton(
                    onPressed: isLoading ? null : openRegister,
                    child: const Text(
                      'Daftar Akun Baru',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2463A6),
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
}
