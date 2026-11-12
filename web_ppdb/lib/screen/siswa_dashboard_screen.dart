import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SiswaDashboardScreen extends StatefulWidget {
  final String nama;
  final String token;
  final VoidCallback onLogout;

  const SiswaDashboardScreen({
    super.key,
    required this.nama,
    required this.token,
    required this.onLogout,
  });

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  static const Color primary = Color(0xFF2463A6);

  final String baseUrl = 'http://localhost:3000';

  int selectedMenu = 0;
  bool loading = true;
  String? errorMessage;

  Map<String, dynamic> stats = {};
  Map<String, dynamic> funnel = {};
  List<dynamic> channels = [];

  Map<String, dynamic>? pendaftaranSaya;

  final formKey = GlobalKey<FormState>();

  final nisnController = TextEditingController();
  final tempatController = TextEditingController();
  final tanggalController = TextEditingController();
  final alamatController = TextEditingController();
  final sekolahController = TextEditingController();

  String jenisKelamin = 'Laki-laki';
  String sumberInformasi = 'Instagram';

  final List<String> sumberPilihan = [
    'Instagram',
    'WhatsApp',
    'Facebook',
    'Google',
    'Teman/Keluarga',
    'Brosur',
    'Website Sekolah',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  @override
  void dispose() {
    nisnController.dispose();
    tempatController.dispose();
    tanggalController.dispose();
    alamatController.dispose();
    sekolahController.dispose();
    super.dispose();
  }

  Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${widget.token}',
  };

  Future<void> loadAllData() async {
    if (mounted) {
      setState(() {
        loading = true;
        errorMessage = null;
      });
    }

    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/analytics/stats'), headers: headers),
        http.get(
          Uri.parse('$baseUrl/api/analytics/channels'),
          headers: headers,
        ),
        http.get(Uri.parse('$baseUrl/api/analytics/funnel'), headers: headers),
        http.get(
          Uri.parse('$baseUrl/api/pendaftaran/status'),
          headers: headers,
        ),
      ]);

      if (!mounted) return;

      for (int i = 0; i < 3; i++) {
        if (responses[i].statusCode != 200) {
          throw Exception('Gagal mengambil data analitik.');
        }
      }

      final statsData = jsonDecode(responses[0].body);
      final channelData = jsonDecode(responses[1].body);
      final funnelData = jsonDecode(responses[2].body);

      setState(() {
        stats = Map<String, dynamic>.from(statsData);

        channels = channelData['data'] ?? [];

        funnel = Map<String, dynamic>.from(funnelData);

        if (responses[3].statusCode == 200) {
          final result = jsonDecode(responses[3].body);
          pendaftaranSaya = result['data'];
        } else if (responses[3].statusCode == 404) {
          pendaftaranSaya = null;
        } else {
          throw Exception('Gagal mengambil status pendaftaran.');
        }

        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        errorMessage = e.toString();
      });
    }
  }

  int get total => number(stats['total_pendaftar']);

  int get menunggu => number(stats['menunggu']);

  int get diterima => number(stats['diterima']);

  int get ditolak => number(stats['ditolak']);

  int number(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void changeMenu(int index) {
    setState(() {
      selectedMenu = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFFF4F7FB),
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildPageContent()),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17365D),
        elevation: 0,
        title: Text(
          _pageTitles[selectedMenu],
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF17365D)),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadAllData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: Drawer(width: 280, child: _buildSidebar()),
      body: _buildPageContent(),
    );
  }

  List<String> get _pageTitles => [
    'Overview',
    'Channel Analysis',
    'Funnel Depth',
    'Pendaftaran Saya',
  ];

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF123B70),
        boxShadow: [
          BoxShadow(
            color: Color(0x180D2748),
            blurRadius: 18,
            offset: Offset(4, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 18, 28),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PPDB',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'SMPIT NURURRAHMAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 18, 12),
              child: Text(
                'MENU UTAMA',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            _sidebarItem(0, Icons.grid_view_rounded, 'Overview'),
            _sidebarItem(1, Icons.campaign_rounded, 'Channel Analysis'),
            _sidebarItem(2, Icons.filter_alt_rounded, 'Funnel Depth'),
            _sidebarItem(3, Icons.assignment_rounded, 'Pendaftaran Saya'),
            const Spacer(),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.09),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFB9DDF7),
                    child: Text(
                      widget.nama.isNotEmpty
                          ? widget.nama[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Color(0xFF123B70),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.nama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Siswa / Calon Siswa',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onLogout,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 13,
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFFFC7C7),
                        size: 20,
                      ),
                      SizedBox(width: 13),
                      Text(
                        'Keluar',
                        style: TextStyle(
                          color: Color(0xFFFFDADA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarItem(int index, IconData icon, String label) {
    final selected = selectedMenu == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: selected ? const Color(0xFF2D6EAD) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            changeMenu(index);
            if (MediaQuery.of(context).size.width < 900) {
              Navigator.pop(context);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EDF4))),
      ),
      child: Row(
        children: [
          Text(
            _pageTitles[selectedMenu],
            style: const TextStyle(
              color: Color(0xFF17365D),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh data',
            onPressed: loadAllData,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF54708F)),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 30, color: const Color(0xFFE5EAF1)),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE2EFFB),
            child: Text(
              widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'S',
              style: const TextStyle(
                color: Color(0xFF2463A6),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.nama,
                style: const TextStyle(
                  color: Color(0xFF203B5D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Akun Siswa',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(width: 20),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF7890A8)),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: primary));
    }

    if (errorMessage != null) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.orange,
                size: 46,
              ),
              const SizedBox(height: 12),
              const Text(
                'Data belum dapat dimuat',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D3557),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: loadAllData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return IndexedStack(
      index: selectedMenu,
      children: [
        buildOverview(),
        buildChannels(),
        buildFunnel(),
        buildPendaftaran(),
      ],
    );
  }

  Widget buildOverview() {
    return RefreshIndicator(
      onRefresh: loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123B70), Color(0xFF1687C9)],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF123B70).withOpacity(0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.school, color: Colors.white, size: 45),
                const SizedBox(height: 15),
                const Text(
                  'DASHBOARD PPDB SMPIT NURURRAHMAN',
                  style: TextStyle(color: Colors.white70, letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Text(
                  'Halo, ${widget.nama}!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pantau perkembangan penerimaan peserta didik baru.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Statistik Pendaftaran',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              statCard('Total Pendaftar', total, Icons.people, Colors.blue),
              statCard(
                'Menunggu',
                menunggu,
                Icons.pending_actions,
                Colors.orange,
              ),
              statCard(
                'Diterima',
                diterima,
                Icons.check_circle_outline,
                Colors.green,
              ),
              statCard('Ditolak', ditolak, Icons.cancel_outlined, Colors.red),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Ringkasan Funnel',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 15),
          funnelCard('Pendaftaran', total, Colors.blue),
          funnelCard('Menunggu', menunggu, Colors.orange),
          funnelCard('Diterima', diterima, Colors.green),
          funnelCard('Ditolak', ditolak, Colors.red),
        ],
      ),
    );
  }

  Widget statCard(String title, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF193B60).withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 27),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          Text(title, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget buildChannels() {
    final maxValue =
        channels.isEmpty
            ? 1
            : channels
                .map((e) => number(e['total']))
                .reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Channel Analysis',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D3557),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sumber informasi yang digunakan calon peserta didik.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        if (channels.isEmpty)
          const Text('Belum ada data channel.')
        else
          ...channels.map((item) {
            final channel = item['channel'].toString();
            final value = number(item['total']);

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          channel,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '$value Pendaftar',
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  LinearProgressIndicator(
                    value: value / maxValue,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE8EEF5),
                    color: primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget buildFunnel() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Funnel Depth',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D3557),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Visualisasi perkembangan proses PPDB.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 25),
        funnelCard(
          'Total Pendaftaran',
          number(funnel['pendaftaran']),
          Colors.blue,
        ),
        funnelCard(
          'Menunggu Verifikasi',
          number(funnel['menunggu']),
          Colors.orange,
        ),
        funnelCard('Diterima', number(funnel['diterima']), Colors.green),
        funnelCard('Ditolak', number(funnel['ditolak']), Colors.red),
      ],
    );
  }

  Widget funnelCard(String title, int value, Color color) {
    final percentage = total == 0 ? 0.0 : value / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF193B60).withOpacity(0.045),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            color: color,
            backgroundColor: const Color(0xFFE8EEF5),
            minHeight: 9,
          ),
        ],
      ),
    );
  }

  Widget buildPendaftaran() {
    if (pendaftaranSaya != null) {
      final data = pendaftaranSaya!;
      final status = data['status']?.toString() ?? 'Menunggu';

      Color statusColor = Colors.orange;

      if (status == 'Diterima') {
        statusColor = Colors.green;
      } else if (status == 'Ditolak') {
        statusColor = Colors.red;
      }

      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Pendaftaran Saya',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3557),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.assignment_turned_in,
                  color: primary,
                  size: 40,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Status Pendaftaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const Divider(height: 30),
                detailRow('NISN', data['nisn']),
                detailRow('Tempat Lahir', data['tempat_lahir']),
                detailRow('Tanggal Lahir', data['tanggal_lahir']),
                detailRow('Jenis Kelamin', data['jenis_kelamin']),
                detailRow('Alamat', data['alamat']),
                detailRow('Asal Sekolah', data['asal_sekolah']),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Text(
          'Formulir Pendaftaran PPDB',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1D3557),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Silakan lengkapi data calon peserta didik.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                formField(
                  nisnController,
                  'NISN',
                  'Masukkan NISN',
                  keyboard: TextInputType.number,
                ),
                formField(
                  tempatController,
                  'Tempat Lahir',
                  'Masukkan tempat lahir',
                ),
                TextFormField(
                  controller: tanggalController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Tanggal Lahir',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      initialDate: DateTime(2012),
                    );

                    if (date != null) {
                      tanggalController.text =
                          '${date.year.toString().padLeft(4, '0')}-'
                          '${date.month.toString().padLeft(2, '0')}-'
                          '${date.day.toString().padLeft(2, '0')}';
                    }
                  },
                  validator:
                      (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: jenisKelamin,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Laki-laki',
                      child: Text('Laki-laki'),
                    ),
                    DropdownMenuItem(
                      value: 'Perempuan',
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => jenisKelamin = value);
                    }
                  },
                ),
                const SizedBox(height: 15),
                formField(
                  alamatController,
                  'Alamat',
                  'Masukkan alamat lengkap',
                  maxLines: 3,
                ),
                formField(
                  sekolahController,
                  'Asal Sekolah',
                  'Masukkan asal sekolah',
                ),
                DropdownButtonFormField<String>(
                  value: sumberInformasi,
                  decoration: const InputDecoration(
                    labelText: 'Mengetahui PPDB dari',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      sumberPilihan.map((item) {
                        return DropdownMenuItem(value: item, child: Text(item));
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => sumberInformasi = value);
                    }
                  },
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: submitPendaftaran,
                    icon: const Icon(Icons.send),
                    label: const Text('KIRIM PENDAFTARAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget formField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator:
            (value) =>
                value == null || value.trim().isEmpty
                    ? '$label wajib diisi'
                    : null,
      ),
    );
  }

  Widget detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> submitPendaftaran() async {
    if (!formKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/pendaftaran'),
        headers: headers,
        body: jsonEncode({
          'nisn': nisnController.text.trim(),
          'tempat_lahir': tempatController.text.trim(),
          'tanggal_lahir': tanggalController.text,
          'jenis_kelamin': jenisKelamin,
          'alamat': alamatController.text.trim(),
          'asal_sekolah': sekolahController.text.trim(),
          'sumber_informasi': sumberInformasi,
        }),
      );

      final result = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pendaftaran berhasil.'),
            backgroundColor: Colors.green,
          ),
        );

        await loadAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Pendaftaran gagal.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    }
  }
}
