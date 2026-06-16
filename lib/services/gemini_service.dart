import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = '';

  GeminiService();

  Future<GigiAnalysisResult> analyzeGigi(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    const prompt =
        'Kamu adalah dokter gigi AI untuk anak-anak. '
        'Analisis foto gigi ini dan berikan respons dalam format JSON '
        'persis seperti berikut (tanpa markdown, tanpa kode blok, hanya teks JSON murni):\n'
        '{"skor_kesehatan":75,"kondisi":"Cukup sehat",'
        '"masalah":["contoh masalah 1","contoh masalah 2"],'
        '"skor_detail":{"kebersihan":70,"warna":65,"karang_gigi":80,"kondisi_umum":85},'
        '"rekomendasi":["Sikat gigi 2x sehari","Kurangi makanan manis","Periksa ke dokter gigi"]}';

    final response = await http
        .post(
          Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=$_apiKey',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inline_data': {
                      'mime_type': 'image/jpeg',
                      'data': base64Image,
                    },
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = (err['error'] as Map?)?['message'] ?? 'HTTP ${response.statusCode}';
      throw Exception(msg);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text =
        (data['candidates'] as List)[0]['content']['parts'][0]['text'] as String;

    final cleaned = text.trim()
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final json = jsonDecode(cleaned) as Map<String, dynamic>;
    return GigiAnalysisResult.fromJson(json);
  }
}

class GigiAnalysisResult {
  final int skorKesehatan;
  final String kondisi;
  final List<String> masalah;
  final Map<String, int> skorDetail;
  final List<String> rekomendasi;

  GigiAnalysisResult({
    required this.skorKesehatan,
    required this.kondisi,
    required this.masalah,
    required this.skorDetail,
    required this.rekomendasi,
  });

  factory GigiAnalysisResult.fromJson(Map<String, dynamic> json) {
    final raw = json['skor_detail'] as Map<String, dynamic>;
    return GigiAnalysisResult(
      skorKesehatan: (json['skor_kesehatan'] as num).toInt(),
      kondisi: json['kondisi'] as String,
      masalah: List<String>.from(json['masalah'] as List),
      skorDetail: raw.map((k, v) => MapEntry(k, (v as num).toInt())),
      rekomendasi: List<String>.from(json['rekomendasi'] as List),
    );
  }
}
