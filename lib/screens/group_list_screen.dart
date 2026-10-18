import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/foto_grup.dart';
import '../data/sholawat_repository.dart';
import '../models/sholawat.dart';
import 'detail_screen.dart';

const _hijau = Color(0xFF1B5E20);
const _hijauMuda = Color(0xFFE8F5E9);

/// Daftar sholawat dalam satu grup (null = semua grup).
/// Isi: cari judul/potongan lirik + filter kategori + favorit.
class GroupListScreen extends StatefulWidget {
  final String? grup;

  const GroupListScreen({super.key, required this.grup});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final _repo = SholawatRepository();
  final _cari = TextEditingController();

  List<Sholawat> _semua = [];
  Set<String> _favorit = {};
  bool _loading = true;
  String _query = '';
  String _kategori = 'Semua';
  bool _hanyaFavorit = false;

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
        _semua = widget.grup == null
            ? data
            : data.where((s) => s.grup == widget.grup).toList();
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

  List<Sholawat> get _tampil {
    final q = _query.trim().toLowerCase();
    return _semua.where((s) {
      if (_hanyaFavorit && !_favorit.contains(s.id)) return false;
      if (_kategori != 'Semua' && s.kategori != _kategori) return false;
      if (q.isEmpty) return true;
      final isi = s.bait.map((b) => '${b.arab} ${b.latin} ${b.arti}').join(' ');
      // Sertakan grup/kategori agar konten mode gambar (bait kosong)
      // tetap bisa ditemukan via judul/grup/kategori.
      return ('${s.judul} ${s.grup} ${s.kategori} $isi')
          .toLowerCase()
          .contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final kategoris = <String>{
      'Semua',
      ..._semua.map((s) => s.kategori),
    }.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _hijau,
        foregroundColor: Colors.white,
        title: Text(
          widget.grup ?? 'Semua Sholawat',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Hanya favorit',
            icon: Icon(
              _hanyaFavorit ? Icons.star : Icons.star_border,
            ),
            onPressed: () =>
                setState(() => _hanyaFavorit = !_hanyaFavorit),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _hijau))
          : Column(
              children: [
                if (fotoGrup(widget.grup) != null)
                  _bannerGrup(fotoGrup(widget.grup)!, _semua.length),
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
                        hintText: 'Cari judul atau potongan lirik...',
                        prefixIcon: const Icon(Icons.search, color: _hijau),
                        suffixIcon: _query.trim().isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _cari.clear();
                                  setState(() => _query = '');
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
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
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: kategoris.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final k = kategoris[i];
                      final dipilih = _kategori == k;
                      return ChoiceChip(
                        label: Text(
                          k,
                          style: TextStyle(
                            color: dipilih ? Colors.white : _hijau,
                            fontWeight:
                                dipilih ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: dipilih,
                        selectedColor: _hijau,
                        backgroundColor:
                            Theme.of(context).colorScheme.surface,
                        side: BorderSide(
                          color: dipilih ? _hijau : Colors.green.shade200,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _kategori = k),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: _tampil.isEmpty
                      ? const Center(
                          child: Text('Tidak ada hasil. Coba kata kunci lain.'),
                        )
                      : ListView.builder(
                          itemCount: _tampil.length,
                          itemBuilder: (context, i) {
                            final s = _tampil[i];
                            final fav = _favorit.contains(s.id);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              elevation: 2,
                              shadowColor: _hijau.withValues(alpha: 0.15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: Colors.green.shade100,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                leading: _avatarSholawat(s),
                                title: Text(
                                  s.judul,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _hijauMuda,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          s.kategori,
                                          style: const TextStyle(
                                            color: _hijau,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        s.isGambar
                                            ? 'gambar'
                                            : '${s.bait.length} bait',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: fav
                                        ? _hijau
                                        : Colors.green.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      fav ? Icons.star : Icons.star_border,
                                      color: fav ? Colors.white : _hijau,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleFavorit(s.id),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetailScreen(
                                        sholawat: s,
                                        isFavorit: fav,
                                        onToggleFavorit: () =>
                                            _toggleFavorit(s.id),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  /// Banner foto grup di atas daftar (hanya grup berfoto).
  Widget _bannerGrup(String foto, int jumlah) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      height: 130,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              foto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _hijauMuda),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.65),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 12,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.grup ?? 'Semua Sholawat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
  }

  Widget _avatarSholawat(Sholawat s) {
    if (s.isGambar) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hijau.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            s.gambar,
            width: 52,
            height: 52,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const CircleAvatar(
              backgroundColor: _hijauMuda,
              child: Icon(Icons.image_outlined, size: 18, color: _hijau),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_hijau, Color(0xFF2E7D32)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '${s.bait.length}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
