const _bulan = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// `8 Nov 2026, 09:15`
String formatWaktu(DateTime t) {
  final local = t.toLocal();
  return '${local.day} ${_bulan[local.month - 1]} ${local.year}, '
      '${_dua(local.hour)}:${_dua(local.minute)}';
}

/// `-6.940123, 107.690456`
String formatKoordinat(double lat, double lng) =>
    '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';

/// Desimal gaya Indonesia: `0,85`
String formatDesimal(double value, {int digits = 2}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// `baru saja`, `12 menit lalu`, `3 jam lalu`, `kemarin`, lalu tanggal.
String formatRelatif(DateTime t, {DateTime? now}) {
  final sekarang = now ?? DateTime.now();
  final selisih = sekarang.difference(t);
  if (selisih.inMinutes < 1) return 'baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24 && sekarang.day == t.toLocal().day) {
    return '${selisih.inHours} jam lalu';
  }
  if (selisih.inHours < 48) {
    return 'kemarin, ${_dua(t.toLocal().hour)}:${_dua(t.toLocal().minute)}';
  }
  return formatWaktu(t);
}

/// `350 m`, `1,2 km`
String formatJarak(double meter) => meter < 1000
    ? '${meter.round()} m'
    : '${formatDesimal(meter / 1000, digits: 1)} km';
