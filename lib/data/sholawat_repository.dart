import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sholawat.dart';

/// Membaca semua konten dari assets/sholawat/index.json.
/// index.json = daftar nama file, contoh: ["tholaal-badru.json"]
/// File index ini di-update OTOMATIS oleh tool/add_sholawat.dart,
/// jadi kamu tidak perlu edit manual.
class SholawatRepository {
  static const _indexPath = 'assets/sholawat/index.json';
  static const _basePath = 'assets/sholawat';

  Future<List<Sholawat>> loadSemua() async {
    final List<String> files;
    try {
      final indexRaw = await rootBundle.loadString(_indexPath);
      files = (json.decode(indexRaw) as List).map((e) => e.toString()).toList();
    } catch (e) {
      // Index hilang/rusak jangan crash: kembalikan list kosong.
      debugPrint('Gagal memuat index: $e');
      return [];
    }

    final hasil = <Sholawat>[];
    for (final file in files) {
      try {
        final raw = await rootBundle.loadString('$_basePath/$file');
        hasil.add(
          Sholawat.fromJson(json.decode(raw) as Map<String, dynamic>),
        );
      } catch (e) {
        // Satu file rusak jangan jatuhkan seluruh aplikasi.
        debugPrint('Gagal memuat $file: $e');
      }
    }
    hasil.sort((a, b) => a.judul.compareTo(b.judul));
    return hasil;
  }
}
