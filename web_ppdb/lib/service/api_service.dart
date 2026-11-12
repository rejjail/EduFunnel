import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://localhost:5678/webhook-test/ppdb/pendaftaran';

  static Future<Map<String, dynamic>> kirimPendaftaran({
    required String nisn,
    required String namaLengkap,
    required String tempatLahir,
    required String tanggalLahir,
    required String alamat,
    required String email,
    required String noHp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'nisn': nisn,
          'nama_lengkap': namaLengkap,
          'tempat_lahir': tempatLahir,
          'tanggal_lahir': tanggalLahir,
          'alamat': alamat,
          'email': email,
          'no_hp': noHp,
          'status': 'Menunggu',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.trim().isEmpty) {
          return {'success': true, 'message': 'Data berhasil dikirim.'};
        }

        try {
          final hasil = jsonDecode(response.body);

          if (hasil is Map<String, dynamic>) {
            return hasil;
          }

          return {'success': true, 'message': 'Data berhasil dikirim.'};
        } catch (_) {
          return {'success': true, 'message': 'Data berhasil dikirim.'};
        }
      }

      return {
        'success': false,
        'message': 'Gagal mengirim data. Kode: ${response.statusCode}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan koneksi: $e'};
    }
  }
}
