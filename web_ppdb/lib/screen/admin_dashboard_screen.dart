import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminDashboardScreen extends StatefulWidget {
  final String nama;
  final String token;
  final VoidCallback onLogout;

  const AdminDashboardScreen({
    super.key,
    required this.nama,
    required this.token,
    required this.onLogout,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final String baseUrl = 'http://localhost:3000';

  int selectedMenu = 0;
  bool isLoading = true;
  bool isUpdating = false;

  String searchQuery = '';

  Map<String, dynamic> stats = {};
  Map<String, dynamic> funnel = {};

  List<Map<String, dynamic>> channels = [];
  List<Map<String, dynamic>> pendaftar = [];

  final List<String> menuItems = [
    'Overview',
    'Channel Analysis',
    'Funnel Depth',
    'Data Tables',
  ];

  final List<IconData> menuIcons = [
    Icons.dashboard_outlined,
    Icons.campaign_outlined,
    Icons.filter_alt_outlined,
    Icons.table_chart_outlined,
  ];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  int toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String formatNumber(dynamic value) {
    return toInt(value).toString();
  }

  Future<void> loadDashboard() async {
    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final responses = await Future.wait([
        http.get(
          Uri.parse('$baseUrl/api/admin/dashboard/stats'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/api/admin/dashboard/funnel'),
          headers: headers,
        ),
        http.get(
          Uri.parse('$baseUrl/api/admin/dashboard/channels'),
          headers: headers,
        ),
        http.get(Uri.parse('$baseUrl/api/admin/pendaftaran'), headers: headers),
      ]).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      // STATISTIK
      if (responses[0].statusCode == 200) {
        final result = jsonDecode(responses[0].body);

        stats =
            result is Map<String, dynamic>
                ? (result['data'] is Map
                    ? Map<String, dynamic>.from(result['data'])
                    : result)
                : {};
      }

      // FUNNEL
      if (responses[1].statusCode == 200) {
        final result = jsonDecode(responses[1].body);

        funnel =
            result is Map<String, dynamic>
                ? (result['data'] is Map
                    ? Map<String, dynamic>.from(result['data'])
                    : result)
                : {};
      }

      // CHANNEL
      if (responses[2].statusCode == 200) {
        final result = jsonDecode(responses[2].body);

        final List<dynamic> data =
            result is List
                ? result
                : (result['data'] is List ? result['data'] : []);

        channels = data.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // DATA PENDAFTAR
      if (responses[3].statusCode == 200) {
        final result = jsonDecode(responses[3].body);

        final List<dynamic> data =
            result is List
                ? result
                : (result['data'] is List ? result['data'] : []);

        pendaftar =
            data.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      final failedResponses =
          responses
              .where(
                (response) =>
                    response.statusCode == 401 || response.statusCode == 403,
              )
              .toList();

      if (failedResponses.isNotEmpty) {
        throw Exception(
          'Token tidak valid atau akun tidak memiliki akses admin.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil data dashboard: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateStatus(int id, String status) async {
    if (isUpdating) return;

    setState(() => isUpdating = true);

    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/pendaftaran/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah menjadi $status'),
            backgroundColor: Colors.green,
          ),
        );

        await loadDashboard();
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  int get totalPendaftar {
    return toInt(
      stats['total_pendaftar'] ?? stats['total'] ?? stats['pendaftaran'],
    );
  }

  int get totalMenunggu {
    return toInt(stats['menunggu']);
  }

  int get totalDiterima {
    return toInt(stats['diterima']);
  }

  int get totalDitolak {
    return toInt(stats['ditolak']);
  }

  int get totalPengunjung {
    return toInt(funnel['pengunjung']);
  }

  Widget buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Icon(icon, color: color, size: 25),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172B4D),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview Dashboard',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ringkasan informasi penerimaan peserta didik baru.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),

        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 850 ? 4 : 2;

            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.65,
              children: [
                buildStatCard(
                  'Total Pendaftar',
                  formatNumber(totalPendaftar),
                  Icons.people_alt_outlined,
                  Colors.blue,
                ),
                buildStatCard(
                  'Menunggu',
                  formatNumber(totalMenunggu),
                  Icons.pending_actions,
                  Colors.orange,
                ),
                buildStatCard(
                  'Diterima',
                  formatNumber(totalDiterima),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                buildStatCard(
                  'Ditolak',
                  formatNumber(totalDitolak),
                  Icons.cancel_outlined,
                  Colors.red,
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 30),

        const Text(
          'Pendaftaran Terbaru',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        buildRecentTable(),
      ],
    );
  }

  Widget buildRecentTable() {
    if (pendaftar.isEmpty) {
      return emptyData('Belum ada data pendaftaran.');
    }

    final recent = pendaftar.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children:
            recent.map((item) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F1FC),
                  child: Text(
                    (item['nama'] ?? 'P').toString().isNotEmpty
                        ? (item['nama'] ?? 'P').toString()[0].toUpperCase()
                        : 'P',
                    style: const TextStyle(
                      color: Color(0xFF2463A6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  item['nama']?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(item['email']?.toString() ?? '-'),
                trailing: buildStatusBadge(
                  item['status']?.toString() ?? 'Menunggu',
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget buildChannelAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Channel Analysis',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Analisis sumber informasi calon peserta didik.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),

        if (channels.isEmpty)
          emptyData(
            'Belum ada data sumber informasi.\n'
            'Pastikan formulir pendaftaran menyimpan sumber_informasi.',
          )
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children:
                  channels.map((item) {
                    final namaChannel =
                        item['sumber_informasi']?.toString() ??
                        item['channel']?.toString() ??
                        'Tidak diketahui';

                    final jumlah = toInt(
                      item['total'] ??
                          item['jumlah'] ??
                          item['jumlah_pendaftar'],
                    );

                    final total = channels.fold<int>(
                      0,
                      (sum, channel) =>
                          sum +
                          toInt(
                            channel['total'] ??
                                channel['jumlah'] ??
                                channel['jumlah_pendaftar'],
                          ),
                    );

                    final persentase = total == 0 ? 0.0 : jumlah / total;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  namaChannel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                '$jumlah pendaftar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: persentase,
                              minHeight: 12,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF2463A6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${(persentase * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
      ],
    );
  }

  Widget buildFunnelDepth() {
    final stages = [
      {
        'title': 'Pengunjung',
        'value': totalPengunjung,
        'color': Colors.blue,
        'icon': Icons.visibility_outlined,
      },
      {
        'title': 'Pendaftaran',
        'value': totalPendaftar,
        'color': Colors.orange,
        'icon': Icons.app_registration,
      },
      {
        'title': 'Menunggu',
        'value': totalMenunggu,
        'color': Colors.amber,
        'icon': Icons.pending_actions,
      },
      {
        'title': 'Diterima',
        'value': totalDiterima,
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      },
      {
        'title': 'Ditolak',
        'value': totalDitolak,
        'color': Colors.red,
        'icon': Icons.cancel_outlined,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funnel Depth',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tahapan perjalanan calon peserta didik.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),

        ...stages.map((stage) {
          final color = stage['color'] as Color;
          final value = stage['value'] as int;

          final denominator = totalPendaftar > 0 ? totalPendaftar : 1;

          final progress =
              stage['title'] == 'Pengunjung'
                  ? 0.0
                  : (value / denominator).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(stage['icon'] as IconData, color: color, size: 27),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        stage['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      stage['title'] == 'Pengunjung' && totalPengunjung == 0
                          ? 'Belum tersedia'
                          : value.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: 10),
        const Text(
          '* Jumlah pengunjung belum tersedia jika website belum '
          'menggunakan sistem pencatatan kunjungan.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get filteredPendaftar {
    if (searchQuery.isEmpty) return pendaftar;

    return pendaftar.where((item) {
      final nama = item['nama']?.toString().toLowerCase() ?? '';
      final email = item['email']?.toString().toLowerCase() ?? '';
      final nisn = item['nisn']?.toString().toLowerCase() ?? '';

      final query = searchQuery.toLowerCase();

      return nama.contains(query) ||
          email.contains(query) ||
          nisn.contains(query);
    }).toList();
  }

  Widget buildDataTables() {
    final data = filteredPendaftar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Tables',
          style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Kelola data pendaftaran peserta didik.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        TextField(
          onChanged: (value) {
            setState(() => searchQuery = value);
          },
          decoration: InputDecoration(
            hintText: 'Cari nama, email, atau NISN...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (data.isEmpty)
          emptyData('Data pendaftar tidak ditemukan.')
        else
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFEAF1F8),
                ),
                columns: const [
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('NISN')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows:
                    data.map((item) {
                      final status = item['status']?.toString() ?? 'Menunggu';

                      return DataRow(
                        cells: [
                          DataCell(Text(item['nama']?.toString() ?? '-')),
                          DataCell(Text(item['email']?.toString() ?? '-')),
                          DataCell(Text(item['nisn']?.toString() ?? '-')),
                          DataCell(buildStatusBadge(status)),
                          DataCell(
                            DropdownButton<String>(
                              value:
                                  [
                                        'Menunggu',
                                        'Diterima',
                                        'Ditolak',
                                      ].contains(status)
                                      ? status
                                      : 'Menunggu',
                              items: const [
                                DropdownMenuItem(
                                  value: 'Menunggu',
                                  child: Text('Menunggu'),
                                ),
                                DropdownMenuItem(
                                  value: 'Diterima',
                                  child: Text('Diterima'),
                                ),
                                DropdownMenuItem(
                                  value: 'Ditolak',
                                  child: Text('Ditolak'),
                                ),
                              ],
                              onChanged:
                                  isUpdating
                                      ? null
                                      : (value) {
                                        if (value == null) return;

                                        final id = toInt(item['id']);

                                        if (id > 0) {
                                          updateStatus(id, value);
                                        }
                                      },
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),

        const SizedBox(height: 15),
        Text(
          'Total data: ${data.length} pendaftar',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget buildStatusBadge(String status) {
    Color color;

    switch (status.toLowerCase()) {
      case 'diterima':
        color = Colors.green;
        break;
      case 'ditolak':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget emptyData(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 45, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildContent() {
    switch (selectedMenu) {
      case 1:
        return buildChannelAnalysis();
      case 2:
        return buildFunnelDepth();
      case 3:
        return buildDataTables();
      default:
        return buildOverview();
    }
  }

  Widget buildSidebar() {
    return Container(
      width: 245,
      color: const Color(0xFF123B70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: Colors.white, size: 40),
                SizedBox(height: 12),
                Text(
                  'PPDB DASHBOARD',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'SMPIT Nururrahman',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24),

          ...List.generate(menuItems.length, (index) {
            final selected = selectedMenu == index;

            return InkWell(
              onTap: () {
                setState(() => selectedMenu = index);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      selected
                          ? Colors.white.withValues(alpha: 0.17)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(menuIcons[index], color: Colors.white, size: 21),
                    const SizedBox(width: 13),
                    Text(
                      menuItems[index],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const Spacer(),

          InkWell(
            onTap: widget.onLogout,
            child: const Padding(
              padding: EdgeInsets.all(22),
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMobileDrawer() {
    return Drawer(child: buildSidebar());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      drawer:
          MediaQuery.of(context).size.width < 800 ? buildMobileDrawer() : null,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          menuItems[selectedMenu],
          style: const TextStyle(
            color: Color(0xFF172B4D),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: isLoading ? null : loadDashboard,
            icon: const Icon(Icons.refresh, color: Color(0xFF2463A6)),
            tooltip: 'Refresh data',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              child: Text(
                widget.nama,
                style: const TextStyle(
                  color: Color(0xFF172B4D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 800) buildSidebar(),

          Expanded(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                      onRefresh: loadDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(25),
                        child: buildContent(),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
