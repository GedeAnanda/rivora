import 'package:flutter_test/flutter_test.dart';
import 'package:rivora/services/weather_service.dart';

Map<String, dynamic> _openMeteo(List<num> mm, {List<num>? peluang}) => {
  'hourly': {
    'time': [
      for (var i = 0; i < mm.length; i++)
        '2026-11-08T${(11 + i) % 24 < 10 ? '0' : ''}${(11 + i) % 24}:00',
    ],
    'precipitation': mm,
    'precipitation_probability': ?peluang,
  },
};

void main() {
  group('KategoriHujan (BMKG, mm/24 jam)', () {
    test('batas kategori', () {
      expect(KategoriHujan.dariTotal(0.4), KategoriHujan.tidak);
      expect(KategoriHujan.dariTotal(0.5), KategoriHujan.ringan);
      expect(KategoriHujan.dariTotal(19.9), KategoriHujan.ringan);
      expect(KategoriHujan.dariTotal(20), KategoriHujan.sedang);
      expect(KategoriHujan.dariTotal(50), KategoriHujan.lebat);
      expect(KategoriHujan.dariTotal(100), KategoriHujan.sangatLebat);
      expect(KategoriHujan.dariTotal(150), KategoriHujan.ekstrem);
    });

    test('perlu bertindak mulai hujan lebat (RENCANA_FINAL bagian 4)', () {
      expect(KategoriHujan.sedang.perluBertindak, isFalse);
      expect(KategoriHujan.lebat.perluBertindak, isTrue);
    });
  });

  group('PrakiraanHujan.dariOpenMeteo', () {
    test('total, puncak, mulai hujan, komponen hujan', () {
      final p = PrakiraanHujan.dariOpenMeteo(
        _openMeteo([0, 0, 0.2, 1.5, 12, 20, 9, 0]),
        lokasiPerkiraan: false,
      );
      expect(p.jam, hasLength(8));
      expect(p.total, closeTo(42.7, 0.001));
      expect(p.kategori, KategoriHujan.sedang);
      expect(p.puncak!.mm, 20);
      expect(p.puncak!.waktu.hour, 16);
      expect(p.mulaiHujan!.waktu.hour, 14);
      expect(p.komponenHujan, closeTo(0.427, 0.001));
    });

    test('komponen hujan maksimal 1 (total ÷ 100 mm)', () {
      final p = PrakiraanHujan.dariOpenMeteo(
        _openMeteo([60, 60]),
        lokasiPerkiraan: true,
      );
      expect(p.komponenHujan, 1);
      expect(p.lokasiPerkiraan, isTrue);
    });

    test('tanpa hujan: tidak ada puncak dan tidak ada jam mulai', () {
      final p = PrakiraanHujan.dariOpenMeteo(
        _openMeteo([0, 0, 0], peluang: [10, 35, 20]),
        lokasiPerkiraan: false,
      );
      expect(p.kategori, KategoriHujan.tidak);
      expect(p.puncak, isNull);
      expect(p.mulaiHujan, isNull);
      expect(p.peluangTertinggi!.peluang, 35);
    });

    test('nilai null dari API dianggap 0 mm', () {
      final p = PrakiraanHujan.dariOpenMeteo({
        'hourly': {
          'time': ['2026-11-08T11:00', '2026-11-08T12:00'],
          'precipitation': [1, null],
        },
      }, lokasiPerkiraan: false);
      expect(p.total, 1);
      expect(p.peluangTertinggi, isNull);
    });
  });
}
