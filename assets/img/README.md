# Folder gambar (mode screenshot)

Taruh 1 screenshot per sholawat di sini, contoh:
`assets/img/ya-imamarusli.jpg`

Cara tambah konten gambar:
```powershell
dart run tool/add_sholawat.dart baru "Ya Imamarusli" --grup "Nurul Musthofa" --gambar ya-imamarusli.jpg
```

- 1 sholawat = 1 gambar (offline).
- Format: JPG lebih kecil dari PNG untuk foto/screenshot. Max lebar 1600px, kualitas 70-80%.
- Field `gambar` di JSON: `assets/img/nama-file.jpg`. Field `bait` dikosongkan `[]`.
- Grup otomatis muncul di home dari field `grup`, mis. `Nurul Musthofa`.
