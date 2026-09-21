import '../../../core/networking/api_client.dart';

/// What came back from reading an image.
class OcrResult {
  const OcrResult({required this.text, required this.likelyPoor});

  /// Raw extracted text, unparsed. OCR misreads drug names and dosages,
  /// so this is shown for correction rather than used as data.
  final String text;

  /// True when the output looks fragmented enough that retaking the
  /// photograph would be quicker than correcting it.
  final bool likelyPoor;

  factory OcrResult.fromJson(Map<String, dynamic> json) => OcrResult(
        text: json['text'] as String? ?? '',
        likelyPoor: json['likely_poor'] as bool? ?? false,
      );
}

class OcrRepository {
  const OcrRepository(this._api);

  final ApiClient _api;

  /// Whether extraction is set up on the server.
  Future<bool> isAvailable() async {
    try {
      final body = await _api.get('/ocr/status');
      return body['available'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sends an image for extraction. The server processes it in memory and
  /// keeps nothing; only the text comes back.
  Future<OcrResult> extract({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) async {
    final body = await _api.upload(
      '/ocr/extract',
      bytes: bytes,
      filename: filename,
      contentType: contentType,
    );
    return OcrResult.fromJson(body);
  }

  Future<void> saveConditions(String conditions) =>
      _api.patch('/ocr/conditions', body: {'conditions': conditions});
}