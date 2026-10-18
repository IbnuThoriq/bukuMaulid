// Tool manual: tambah & validasi konten sholawat tanpa menyentuh kode Dart.
// Cara pakai (lihat juga .vscode/tasks.json):
//   dart run tool/add_sholawat.dart baru "Judul Sholawat" --kategori Sholawat --grup "Muhibbus Sholawat"
//   dart run tool/add_sholawat.dart validasi
//   dart run tool/add_sholawat.dart list
import 'dart:convert';
import 'dart:io';

const indexPath = 'assets/sholawat/index.json';
const baseDir = 'assets/sholawat';

void main(List<String> args) async {
  if (args.isEmpty) {
    _bantuan();
    exit(2);
  }
  switch (args.first) {
    case 'baru':
      await _baru(args.sublist(1));
    case 'validasi':
      await _validasi();
    case 'list':
      await _list();
    default:
      _bantuan();
      exit(2);
  }
}

void _bantuan() {
  print('''
Perintah konten sholawat:
  dart run tool/add_sholawat.dart baru "Judul" [--kategori X] [--grup "Nama Grup"] [--gambar file.jpg|URL]
  dart run tool/add_sholawat.dart validasi
  dart run tool/add_sholawat.dart list

Contoh teks (Muhibbus Sholawat):
  dart run tool/add_sholawat.dart baru "Ya Imamarusli" --kategori Qosidah
  dart run tool/add_sholawat.dart baru "Addinu Lana" --grup "Muhibbus Sholawat"

Contoh gambar 1 file offline (Nurul Musthofa):
  dart run tool/add_sholawat.dart baru "Ya Imamarusli" --grup "Nurul Musthofa" --gambar ya-imamarusli.jpg
  -> taruh screenshot di assets/img/ya-imamarusli.jpg, JSON otomatis pakai "gambar" + "bait": []
''');
}

String _slug(String judul) {
  var s = judul.toLowerCase().replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  s = s.trim().replaceAll(RegExp(r'\s+'), '-');
  return s.isEmpty ? 'tanpa-judul' : s;
}

Future<void> _baru(List<String> args) async {
  if (args.isEmpty) {
    print('Judul wajib diisi. Contoh: baru "Ya Imamarusli"');
    exit(2);
  }
  final judul = args.first;
  String kategori = 'Sholawat';
  String grup = 'Umum';
  String gambar = '';
  for (var i = 1; i < args.length; i++) {
    if (args[i] == '--kategori' && i + 1 < args.length) kategori = args[++i];
    if (args[i] == '--grup' && i + 1 < args.length) grup = args[++i];
    if (args[i] == '--gambar' && i + 1 < args.length) gambar = args[++i];
  }
  if (grup.trim().isEmpty) grup = 'Umum';

  final slug = _slug(judul);
  final file = File('$baseDir/$slug.json');
  if (file.existsSync()) {
    print('File ${file.path} sudah ada. Edit manual saja.');
    exit(1);
  }

  if (gambar.isNotEmpty && !gambar.startsWith('http')) {
    // Boleh "nama.jpg" atau "assets/img/nama.jpg" — normalkan ke assets/img/.
    if (!gambar.startsWith('assets/img/')) {
      gambar = 'assets/img/$gambar';
    }
  }

  final isGambar = gambar.trim().isNotEmpty;
  final Map<String, dynamic> template = {
    'id': slug,
    'judul': judul,
    'grup': grup,
    'kategori': kategori,
    'gambar': gambar,
    'bait': isGambar
        ? []
        : [
            {
              'arab': 'TULIS ARAB DI SINI',
              'latin': 'tulis latin di sini',
              'arti': 'tulis arti di sini',
            },
            {
              'arab': 'BAIT KEDUA',
              'latin': '',
              'arti': '',
            },
          ],
  };
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(template),
  );

  await _updateIndex(slug);
  if (isGambar) {
    print('''
OK: ${file.path} dibuat (mode gambar).
Taruh screenshot di $gambar, lalu jalankan validasi:
  dart run tool/add_sholawat.dart validasi
''');
    return;
  }
  print('''
OK: ${file.path} dibuat.
Isi bait-nya manual, lalu jalankan validasi:
  dart run tool/add_sholawat.dart validasi
''');
}

Future<List<String>> _bacaIndex() async {
  final f = File(indexPath);
  if (!f.existsSync()) return [];
  final data = json.decode(f.readAsStringSync()) as List;
  return data.map((e) => e.toString()).toList();
}

Future<void> _updateIndex(String slug) async {
  final files = await _bacaIndex();
  final nama = '$slug.json';
  if (!files.contains(nama)) {
    files.add(nama);
    files.sort();
    File(indexPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(files),
    );
  }
}

Future<void> _list() async {
  final files = await _bacaIndex();
  if (files.isEmpty) {
    print('Belum ada konten.');
    return;
  }
  for (final f in files) {
    print('- $f');
  }
}

/// Validasi: JSON valid, field wajib ada, file gambar lokal benar-benar ada.
Future<void> _validasi() async {
  final files = await _bacaIndex();
  var error = 0;
  var warning = 0;

  if (files.isEmpty) {
    print('index.json kosong. Tambah dulu via perintah "baru".');
    exit(1);
  }

  for (final nama in files) {
    final errorSebelum = error;
    final path = '$baseDir/$nama';
    final f = File(path);
    if (!f.existsSync()) {
      print('ERROR $nama: file tidak ditemukan (terdaftar di index).');
      error++;
      continue;
    }
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      print('ERROR $nama: JSON rusak: $e');
      error++;
      continue;
    }

    for (final field in ['id', 'judul', 'grup']) {
      if (jsonMap[field] == null ||
          jsonMap[field].toString().trim().isEmpty) {
        print('ERROR $nama: field "$field" wajib diisi.');
        error++;
      }
    }
    final gambar = (jsonMap['gambar'] ?? '').toString().trim();
    final isGambar = gambar.isNotEmpty;
    final bait = jsonMap['bait'];
    if (isGambar) {
      // Mode gambar: bait boleh kosong, tapi harus tetap list.
      if (bait is! List) {
        print('ERROR $nama: "bait" harus list (boleh kosong untuk mode gambar).');
        error++;
      }
      if (!gambar.startsWith('http') && !File(gambar).existsSync()) {
        print('WARN  $nama: file gambar "$gambar" belum ada di folder.');
        warning++;
      }
    } else {
      if (bait is! List || bait.isEmpty) {
        print('ERROR $nama: "bait" harus list dan tidak kosong.');
        error++;
        continue;
      }
      for (var i = 0; i < bait.length; i++) {
        final b = bait[i];
        if (b is! Map || (b['arab'] ?? '').toString().trim().isEmpty) {
          print('ERROR $nama bait ke-${i + 1}: teks arab kosong.');
          error++;
        }
      }
    }

    if (error == errorSebelum) {
      final info = isGambar ? 'gambar' : '${(bait as List).length} bait';
      print('OK    $nama ($info)');
    }
  }

  print('\nSelesai: $error error, $warning warning.');
  if (error > 0) exit(1);
}