import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/foto_grup.dart';
import 'data/sholawat_repository.dart';
import 'models/sholawat.dart';
import 'screens/detail_screen.dart';
import 'screens/group_list_screen.dart';

/// Hijau tua islami (dipakai konsisten di Home, Daftar, Detail).
const _hijau = Color(0xFF1B5E20);
const _hijauMuda = Color(0xFFE8F5E9);
const _latar = Color(0xFFF6FAF6);

void main() {
  runApp(const SholawatApp());
}

class SholawatApp extends StatefulWidget {
  const SholawatApp({super.key});

  @override
  State<SholawatApp> createState() => _SholawatAppState();
}

class _SholawatAppState extends State<SholawatApp> {
  bool _modeGelap = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() => _modeGelap = p.getBool('modeGelap') ?? false);
    });
  }

  void _toggleTema() async {
    setState(() => _modeGelap = !_modeGelap);
    final p = await SharedPreferences.getInstance();
    await p.setBool('modeGelap', _modeGelap);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sholawat & Qasidah Muara Reborn',
      debugShowCheckedModeBanner: false,
      themeMode: _modeGelap ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: _latar,
        appBarTheme: const AppBarTheme(
          backgroundColor: _hijau,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        textTheme: Typography.whiteMountainView.apply(fontFamily: 'Inter'),
      ),
      home: HomeScreen(
        modeGelap: _modeGelap,
        onToggleTema: _toggleTema,
      ),
    );
  }
}

/// Menu utama: kartu per grup/majelis, dibuat OTOMATIS dari data.
/// Tambah grup baru = cukup tambah JSON dengan field "grup" baru.
/// Foto profil grup dibaca dari [fotoGrup]; grup tanpa foto (Umum/Semua)
/// otomatis tampil sebagai kartu ikon hijau.
class HomeScreen extends StatefulWidget {
  final bool modeGelap;
  final VoidCallback onToggleTema;

  const HomeScreen({
    super.key,
    required this.modeGelap,
    required this.onToggleTema,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _repo = SholawatRepository();
  final _cari = TextEditingController();
  List<Sholawat> _semua = [];
  Set<String> _favorit = {};
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _cari.dispose();
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      final data = await _repo.loadSemua();
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _semua = data;
        _favorit = (p.getStringList('favorit') ?? []).toSet();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleFavorit(String id) async {
    setState(() {
      if (_favorit.contains(id)) {
        _favorit.remove(id);
      } else {
        _favorit.add(id);
      }
    });
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorit', _favorit.toList());
  }

  /// Hasil cari lintas grup: cocok judul/grup/kategori atau potongan lirik/arti.
  /// Konten mode gambar (bait kosong) tetap ketemu via judul/grup/kategori.
  List<Sholawat> get _hasilCari {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return _semua.where((s) {
      final isi = s.bait.map((b) => '${b.arab} ${b.latin} ${b.arti}').join(' ');
      return ('${s.judul} ${s.grup} ${s.kategori} $isi')
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final grups = <String>{..._semua.map((s) => s.grup)}.toList()..sort();
    final mencari = _query.trim().isNotEmpty;
    final hasil = _hasilCari;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sholawat & Qasidah Muara Reborn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Mode malam',
            icon: Icon(
              widget.modeGelap ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTema,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _hijau))
          : _semua.isEmpty
              ? const Center(
                  child: Text('Belum ada konten. Tambah via tool/content.'),
                )
              : Column(
                  children: [
                    _bannerPembuka(_semua.length),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _cari,
                          textInputAction: TextInputAction.search,
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          decoration: InputDecoration(
                            hintText: 'Cari judul, grup, atau potongan lirik...',
                            prefixIcon:
                                const Icon(Icons.search, color: _hijau),
                            suffixIcon: mencari
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _cari.clear();
                                      setState(() => _query = '');
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor:
                                Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            isDense: true,
                          ),
                          onChanged: (v) => setState(() => _query = v),
                          onSubmitted: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: mencari ? _hasilCariView(hasil) : _gridGrup(grups),
                    ),
                    const SafeArea(
                      top: false,
                      minimum: EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text(
                          'Created by Thoriq',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Banner salam di atas menu — gradient hijau + sapaan waktu + tanggal.
  Widget _bannerPembuka(int total) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _hijau.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_hijau, Color(0xFF2E7D32)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tanggalHariIni(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Assalamu\u2019alaikum',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${_salamWaktu()}, mau baca apa hari ini?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.library_music_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$total sholawat & qosidah offline',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Aksen lingkaran dekoratif.
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -60,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _salamWaktu() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _tanggalHariIni() {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final now = DateTime.now();
    return '${hari[now.weekday - 1]}, ${now.day} '
        '${bulan[now.month - 1]} ${now.year}';
  }

  /// Daftar hasil cari lintas grup, tiap baris ada badge grupnya.
  Widget _hasilCariView(List<Sholawat> hasil) {
    if (hasil.isEmpty) {
      return const Center(
        child: Text('Tidak ketemu. Coba kata kunci lain.'),
      );
    }
    return ListView.builder(
      itemCount: hasil.length,
      itemBuilder: (context, i) {
        final s = hasil[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shadowColor: _hijau.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.green.shade100),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _hijauMuda,
              child: Text(
                s.judul.isEmpty ? '?' : s.judul[0].toUpperCase(),
                style: const TextStyle(
                  color: _hijau,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              s.judul,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${s.grup} \u2022 ${s.kategori}'),
            trailing: const Icon(Icons.chevron_right, color: _hijau),
            onTap: () => _bukaDetail(s),
          ),
        );
      },
    );
  }

  Future<void> _bukaDetail(Sholawat s) async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          sholawat: s,
          isFavorit: _favorit.contains(s.id),
          onToggleFavorit: () => _toggleFavorit(s.id),
        ),
      ),
    );
    // Segarkan status favorit sepulang dari detail.
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _favorit = (p.getStringList('favorit') ?? []).toSet());
  }

  /// Grid kartu menu grup + kartu "Semua".
  /// Grup berfoto (lihat [fotoGrup]) tampil foto; "Semua"/"Umum" tampil ikon.
  Widget _gridGrup(List<String> grups) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: grups.length + 1, // +1 kartu "Semua"
      itemBuilder: (context, i) {
        final semua = i == grups.length;
        final nama = semua ? 'Semua' : grups[i];
        final jumlah =
            semua ? _semua.length : _semua.where((s) => s.grup == nama).length;
        final foto = semua ? null : fotoGrup(nama);
        return Card(
          elevation: 4,
          shadowColor: _hijau.withValues(alpha: 0.25),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupListScreen(
                    grup: semua ? null : nama,
                  ),
                ),
              ).then((_) async {
                // Favorit bisa diubah di GroupListScreen, muat ulang agar
                // status favorit di Home (mis. hasil cari) tidak basi.
                final p = await SharedPreferences.getInstance();
                if (!mounted) return;
                setState(
                  () => _favorit = (p.getStringList('favorit') ?? []).toSet(),
                );
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                _latarKartu(foto, semua),
                // Gradasi bawah agar teks terbaca di atas foto.
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                // Badge jumlah melayang kanan atas.
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$jumlah',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Nama grup di bawah.
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$jumlah sholawat',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Latar kartu: foto grup full; grup tanpa foto tampil gradient hijau
  /// dengan ikon besar transparan.
  Widget _latarKartu(String? foto, bool semua) {
    if (foto != null) {
      return Image.asset(
        foto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _latarGradient(semua),
      );
    }
    return _latarGradient(semua);
  }

  Widget _latarGradient(bool semua) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hijau, Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Icon(
              semua ? Icons.library_music_outlined : Icons.groups_outlined,
              size: 56,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
