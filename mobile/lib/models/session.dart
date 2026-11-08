/// Petugas yang sedang masuk (respons `POST /auth/login`, backend SRS 7.1).
/// Warga tidak wajib login (mobile SRS bagian 2), jadi sesi hanya ada
/// untuk petugas.
class Session {
  const Session({
    required this.token,
    required this.role,
    required this.nama,
    this.penggunaId,
    this.kelurahanId,
  });

  /// `{ token, role, pengguna: { id, nama, kelurahan_id } }`.
  /// Juga menerima bentuk datar `{ token, role, nama }` (sesi lama di HP).
  factory Session.fromJson(Map<String, dynamic> json) {
    final p = json['pengguna'] as Map<String, dynamic>?;
    return Session(
      token: json['token'] as String,
      role: json['role'] as String? ?? 'petugas',
      nama: p?['nama'] as String? ?? json['nama'] as String? ?? '',
      penggunaId: (p?['id'] ?? json['pengguna_id']) as int?,
      kelurahanId: (p?['kelurahan_id'] ?? json['kelurahan_id']) as int?,
    );
  }

  final String token;

  /// `petugas` | `lurah` | `warga`. Aplikasi ini hanya menerima `petugas`.
  final String role;
  final String nama;
  final int? penggunaId;
  final int? kelurahanId;

  bool get isPetugas => role == 'petugas';

  Map<String, dynamic> toJson() => {
    'token': token,
    'role': role,
    'pengguna': {'id': penggunaId, 'nama': nama, 'kelurahan_id': kelurahanId},
  };
}

const Map<String, String> labelRole = {
  'warga': 'Warga',
  'petugas': 'Petugas kebersihan',
  'lurah': 'Kelurahan',
};
