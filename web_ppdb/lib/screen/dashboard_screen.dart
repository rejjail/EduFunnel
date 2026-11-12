import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'siswa_dashboard_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String nama;
  final String role;
  final String token;
  final VoidCallback onLogout;

  const DashboardScreen({
    super.key,
    required this.nama,
    required this.role,
    required this.token,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    if (role.toLowerCase() == 'admin') {
      return AdminDashboardScreen(nama: nama, token: token, onLogout: onLogout);
    }

    return SiswaDashboardScreen(nama: nama, token: token, onLogout: onLogout);
  }
}
