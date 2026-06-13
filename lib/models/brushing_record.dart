class BrushingRecord {
  final int? id;
  final String tanggal;
  final String waktuMulai;
  final String waktuSelesai;
  final int durasiDetik;
  final int jumlahGerakan;
  final String sesi;
  final String createdAt;

  const BrushingRecord({
    this.id,
    required this.tanggal,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.durasiDetik,
    required this.jumlahGerakan,
    required this.sesi,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'tanggal': tanggal,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        'durasi_detik': durasiDetik,
        'jumlah_gerakan': jumlahGerakan,
        'sesi': sesi,
        'created_at': createdAt,
      };

  factory BrushingRecord.fromMap(Map<String, dynamic> map) => BrushingRecord(
        id: map['id'] as int?,
        tanggal: map['tanggal'] as String,
        waktuMulai: map['waktu_mulai'] as String,
        waktuSelesai: map['waktu_selesai'] as String,
        durasiDetik: map['durasi_detik'] as int,
        jumlahGerakan: map['jumlah_gerakan'] as int,
        sesi: map['sesi'] as String,
        createdAt: map['created_at'] as String,
      );
}
