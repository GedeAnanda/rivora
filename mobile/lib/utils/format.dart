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
