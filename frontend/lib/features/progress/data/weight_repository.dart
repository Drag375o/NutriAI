import '../../../core/networking/api_client.dart';
import 'weight_models.dart';

class WeightRepository {
  const WeightRepository(this._api);

  final ApiClient _api;

  Future<WeightHistory> history() async {
    final body = await _api.get('/weights');
    return WeightHistory.fromJson(body);
  }

  /// Records a weigh-in. Omitting [recordedOn] records today.
  Future<WeightEntry> log({
    required double weightKg,
    DateTime? recordedOn,
    String? note,
  }) async {
    final body = await _api.post('/weights', body: {
      'weight_kg': weightKg,
      if (recordedOn != null)
        'recorded_on': recordedOn.toIso8601String().split('T').first,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return WeightEntry.fromJson(body);
  }

  Future<void> delete(int entryId) => _api.delete('/weights/$entryId');
}