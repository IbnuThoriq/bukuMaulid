import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sholawat.dart';

const _hijau = Color(0xFF1B5E20);

/// Halaman baca: Arab rata kanan ukuran besar, Latin + Arti collapsible,
/// dan slider ukuran font.
/// Kalau [Sholawat.gambar] diisi (mode gambar, mis. grup Nurul Musthofa),
/// tampilkan 1 gambar offline dengan pinch-zoom, bukan teks bait.
class DetailScreen extends StatefulWidget {
  final Sholawat sholawat;
  final bool isFavorit;
  final VoidCallback onToggleFavorit;

  const DetailScreen({
    super.key,
    required this.sholawat,
    required this.isFavorit,
    required this.onToggleFavorit,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  double _fontArab = 26;
  bool _tampilLatin = true;
  bool _tampilArti = true;

  /// Diturunkan dari [DetailScreen.isFavorit] lalu dikelola di sini.
  /// Wajib lokal: setelah route ter-push, parent tidak pernah me-rebuild
  /// widget ini, jadi `widget.isFavorit` nilainya membeku selamanya.
  late bool _favorit;

  @override
  void initState() {
    super.initState();
    _favorit = widget.isFavorit;
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() => _fontArab = p.getDouble('fontArab') ?? 26);
    });
  }

  Future<void> _simpanFont(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('fontArab', v);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.sholawat;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _hijau,
        foregroundColor: Colors.white,
        title: Text(
          s.judul,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              s.grup,
              style: const TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: _favorit ? 'Hapus dari favorit' : 'Tambah ke favorit',
            icon: Icon(_favorit ? Icons.star : Icons.star_border),
            onPressed: () {
              setState(() => _favorit = !_favorit);
              widget.onToggleFavorit();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel pengaturan baca — hanya untuk konten teks.
          if (!s.isGambar)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.text_format, size: 18, color: _hijau),
                  Expanded(
                    child: Slider(
                      min: 18,
                      max: 40,
                      divisions: 11,
                      value: _fontArab,
                      label: _fontArab.round().toString(),
                      activeColor: _hijau,
                      onChanged: (v) => setState(() => _fontArab = v),
                      onChangeEnd: _simpanFont,
                    ),
                  ),
                  _chipOpsi('Latin', _tampilLatin,
                      (v) => setState(() => _tampilLatin = v)),
                  const SizedBox(width: 6),
                  _chipOpsi('Arti', _tampilArti,
                      (v) => setState(() => _tampilArti = v)),
                ],
              ),
            ),
          Expanded(
            child: s.isGambar ? _gambarView(context, s) : _teksView(),
          ),
        ],
      ),
    );
  }

  /// Chip opsi baca: aktif hijau solid, mati outline.
  Widget _chipOpsi(String label, bool aktif, ValueChanged<bool> onPilih) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: aktif ? Colors.white : _hijau,
          fontSize: 12,
          fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: aktif,
      selectedColor: _hijau,
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: aktif ? _hijau : Colors.green.shade200,
      ),
      showCheckmark: false,
      padding: EdgeInsets.zero,
      onSelected: onPilih,
    );
  }

  /// Tampilan 1 gambar offline (screenshot) dengan pinch-zoom.
  Widget _gambarView(BuildContext context, Sholawat s) {
    final Widget gambar = s.gambarRemote
        ? Image.network(
            s.gambar,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _gambarError(s),
          )
        : Image.asset(
            s.gambar,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _gambarError(s),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.green.shade100),
        ),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Center(child: gambar),
        ),
      ),
    );
  }

  Widget _gambarError(Sholawat s) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 48, color: _hijau),
          const SizedBox(height: 8),
          Text(
            'Gambar tidak ditemukan.\nTaruh file di ${s.gambar}',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Tampilan teks bait Arab + Latin + Arti.
  Widget _teksView() {
    final s = widget.sholawat;
    if (s.bait.isEmpty) {
      return const Center(child: Text('Konten belum diisi.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: s.bait.length,
      itemBuilder: (context, i) {
        final b = s.bait[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          elevation: 2,
          shadowColor: _hijau.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.green.shade100),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'BAIT ${i + 1}',
                      style: const TextStyle(
                        color: _hijau,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Divider(
                        color: Colors.green.shade100,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 8),
                Text(
                  b.arab,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: _fontArab,
                    height: 2.0,
                  ),
                ),
                if (_tampilLatin && b.latin.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    b.latin,
                    style: TextStyle(
                      fontSize: _fontArab * 0.6,
                      fontStyle: FontStyle.italic,
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_tampilArti && b.arti.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.only(left: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: _hijau, width: 3),
                      ),
                    ),
                    child: Text(
                      b.arti,
                      style: TextStyle(
                        fontSize: _fontArab * 0.55,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
