// Model satu bait lirik: Arab + Latin + Arti.
class Bait {
  final String arab;
  final String latin;
  final String arti;

  const Bait({required this.arab, required this.latin, required this.arti});

  factory Bait.fromJson(Map<String, dynamic> json) {
    return Bait(
      arab: (json['arab'] ?? '').toString(),
      latin: (json['latin'] ?? '').toString(),
      arti: (json['arti'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {'arab': arab, 'latin': latin, 'arti': arti};
}

/// Model satu sholawat/qosidah.
/// `grup` = sumber/majelis, contoh: "Muhibbus Sholawat".
/// `gambar` = path asset lokal (assets/img/xxx.jpg) untuk konten berbasis
/// gambar/screenshot. Kosongkan ("") kalau konten berbasis teks.
/// Kalau `gambar` diisi, `bait` boleh kosong.
/// `audio` sudah tidak dipakai (fitur audio dihapus), tapi tetap dibaca dari
/// JSON supaya file konten yang ada tidak perlu diubah sama sekali.
class Sholawat {
  final String id;
  final String judul;
  final String grup;
  final String kategori;
  final String audio;
  final String gambar;
  final List<Bait> bait;

  const Sholawat({
    required this.id,
    required this.judul,
    required this.grup,
    required this.kategori,
    required this.audio,
    this.gambar = '',
    this.bait = const [],
  });

  bool get isGambar => gambar.trim().isNotEmpty;

  bool get gambarRemote =>
      gambar.startsWith('http://') || gambar.startsWith('https://');

  factory Sholawat.fromJson(Map<String, dynamic> json) {
    final baitJson = (json['bait'] as List?) ?? [];
    return Sholawat(
      id: (json['id'] ?? '').toString(),
      judul: (json['judul'] ?? '').toString(),
      grup: (json['grup'] ?? 'Umum').toString(),
      kategori: (json['kategori'] ?? 'Lainnya').toString(),
      audio: (json['audio'] ?? '').toString(),
      gambar: (json['gambar'] ?? '').toString(),
      bait: baitJson
          .whereType<Map<String, dynamic>>()
          .map(Bait.fromJson)
          .toList(),
    );
  }
}