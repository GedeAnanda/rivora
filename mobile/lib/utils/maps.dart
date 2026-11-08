import 'package:url_launcher/url_launcher.dart';

/// Buka lokasi di Google Maps (aplikasi kalau ada, kalau tidak di browser).
/// `arah: true` langsung membuka petunjuk jalan untuk petugas.
Future<bool> bukaPeta(double lat, double lng, {bool arah = false}) {
  final uri = arah
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1'
          '&destination=$lat,$lng&travelmode=walking',
        )
      : Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
