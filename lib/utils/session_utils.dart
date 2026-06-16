/// Returns 'pagi', 'malam', or '' (bukan waktu sikat)
String determineSesi(DateTime time) {
  final h = time.hour;
  if (h >= 0 && h <= 11) return 'pagi';
  if (h >= 12 && h <= 23) return 'malam';
  return '';
}

String formatTanggal(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String formatWaktu(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';

String formatDurasi(int detik) {
  final m = detik ~/ 60;
  final s = detik % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
