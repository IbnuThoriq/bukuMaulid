# Qosidah & Sholawat App (Android)

Aplikasi teks Qosidah/Sholawat yang **100% offline**. Tidak butuh internet,
tidak butuh izin jaringan, tidak ada audio.

## 1. Cara menambah konten MANUAL (tanpa ngoding)

Pilih salah satu:

**A. Via VS Code (paling gampang)**

1. Buka Command Palette: `Ctrl+Shift+P` → `Tasks: Run Task`
2. Pilih `Sholawat: Tambah Baru` → ketik judul (contoh `Addinu Lana`) → ketik grup (contoh `Muhibbus Sholawat`, kosongkan = `Umum`)
3. File `assets/sholawat/addinu-lana.json` otomatis dibuat + terdaftar di `index.json`
4. Buka file itu, ganti bait contoh dengan teks asli:
   ```json
   { "arab": "...", "latin": "...", "arti": "..." }
   ```
5. Validasi: `Ctrl+Shift+P` → `Tasks: Run Task` → `Sholawat: Validasi Konten`

Kartu menu di home TERBENTUK OTOMATIS dari field `grup`. Ingin menu
"Muhibbus Sholawat, Annawawi, Majelis Rasulullah, Nurul Musthofa"?
Tinggal tambah konten dengan `--grup` sesuai nama itu.

**B. Via terminal**

```powershell
dart run tool/add_sholawat.dart baru "Addinu Lana" --grup "Muhibbus Sholawat" --kategori Qosidah
dart run tool/add_sholawat.dart validasi
dart run tool/add_sholawat.dart list
```

## 2. Struktur konten

```
assets/sholawat/index.json      <- daftar file (OTOMATIS via tool, jangan edit manual)
assets/sholawat/tholaal-badru.json
assets/img/tholaal-badru.jpg    <- screenshot untuk konten mode gambar (opsional)
```

Contoh satu file JSON: lihat `assets/sholawat/tholaal-badru.json`.

Semua konten ikut terbundel di dalam APK, jadi aplikasi jalan penuh tanpa internet.

## 3. Cara jalanin

`flutter` sudah masuk PATH user + cache dipindah ke D: agar C tidak penuh
(`ANDROID_SDK_ROOT=D:\Android\Sdk`, `GRADLE_USER_HOME=D:\Android\.gradle`,
`PUB_CACHE=D:\.pub-cache`). Buka ulang terminal VS Code agar PATH baru kebaca.

```powershell
flutter pub get
flutter run          # ke HP Android / emulator
flutter run -d chrome # preview cepat di laptop
flutter build apk --release  # APK rilis
```

HP asli: aktifkan Developer Options → USB Debugging → colok USB → `flutter run`.

## 4. Fitur aplikasi

- List + cari judul/potongan lirik + filter kategori + favorit (bintang)
- Halaman baca: Arab RTL besar, toggle Latin/Arti, slider font, mode malam
- Konten gambar (screenshot) dengan pinch-zoom
- Semua teks & gambar offline, tanpa izin jaringan

## Run Fluter??

D:\flutter\bin\flutter.bat run