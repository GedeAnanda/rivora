/// Pengguna yang sedang masuk (respons `POST /auth/login`).
class Session {
  const Session({required this.token, required this.role, required this.nama});

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    token: json['token'] as String,
    role: json['role'] as String? ?? 'warga',
    nama: json['nama'] as String? ?? '',
  );

  final String token;

  /// `warga` | `petugas` | `lurah`. Tab Tugas hanya untuk petugas.
  final String role;
  final String nama;

  bool get isPetugas => role == 'petugas';

  Map<String, dynamic> toJson() => {'token': token, 'role': role, 'nama': nama};
}

const Map<String, String> labelRole = {
  'warga': 'Warga',
  'petugas': 'Petugas kebersihan',
  'lurah': 'Kelurahan',
};
