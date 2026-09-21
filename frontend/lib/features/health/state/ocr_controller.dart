import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../../profile/state/profile_controller.dart';
import '../data/ocr_repository.dart';

final ocrRepositoryProvider = Provider<OcrRepository>(
  (ref) => OcrRepository(ref.watch(apiClientProvider)),
);

/// Whether the server can extract text at all.
///
/// Checked before offering the feature, so a machine without Tesseract
/// shows an explanation rather than a failed upload.
final ocrAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(ocrRepositoryProvider).isAvailable(),
);

class OcrController extends Notifier<void> {
  @override
  void build() {}

  OcrRepository get _repo => ref.read(ocrRepositoryProvider);

  Future<OcrResult> extract({
    required List<int> bytes,
    required String filename,
    required String contentType,
  }) =>
      _repo.extract(
        bytes: bytes,
        filename: filename,
        contentType: contentType,
      );

  /// Returns an error message on failure rather than throwing, so the
  /// sheet can show it inline.
  Future<String?> saveConditions(String conditions) async {
    try {
      await _repo.saveConditions(conditions);
      ref.invalidate(profileControllerProvider);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final ocrControllerProvider =
    NotifierProvider<OcrController, void>(OcrController.new);