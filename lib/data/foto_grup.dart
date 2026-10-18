/// Foto profil per grup/majelis untuk menu utama.
///
/// File disediakan manual di `assets/img/grup/`.
/// Grup yang tidak ada di sini (mis. "Umum") otomatis pakai ikon.
String? fotoGrup(String? grup) {
  switch (grup) {
    case 'Muhibbus Sholawat':
      return 'assets/img/grup/muhibbus.jpg';
    case 'Annawawi':
      return 'assets/img/grup/annawawi.jpg';
    case 'Nurul Musthofa':
      return 'assets/img/grup/nurulmusthofa.jpg';
    case 'Majelis Azzahir':
      return 'assets/img/grup/azzahir.jpg';
    case 'Ahbaabul Musthofa':
      return 'assets/img/grup/ahbabulmusthofa.jpg';
    default:
      return null;
  }
}
