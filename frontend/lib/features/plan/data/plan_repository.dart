import '../../../core/networking/api_client.dart';
import 'plan_models.dart';
import '../../../core/constants/api_config.dart';


class PlanRepository {
  const PlanRepository(this._api);

  final ApiClient _api;

  /// Today's plan, or null if none has been generated.
  Future<DietPlan?> today() async {
    final body = await _api.get('/diet-plans/today');
    // The endpoint returns null for no plan, which arrives as an empty map.
    if (body.isEmpty || body['id'] == null) return null;
    return DietPlan.fromJson(body);
  }

  /// Generates a plan for today, replacing any existing one.
  Future<DietPlan> generate({String? note}) async {
    final body = await _api.post('/diet-plans', body: {
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return DietPlan.fromJson(body);
  }

  Future<DietPlan> read(int id) async {
    final body = await _api.get('/diet-plans/$id');
    return DietPlan.fromJson(body);
  }

  Future<void> delete(int id) => _api.delete('/diet-plans/$id');


  /// The download URL for a plan's PDF.
  ///
  /// The token goes in a query parameter because a browser download is a
  /// plain navigation and cannot carry an Authorization header. The endpoint
  /// still verifies it and still checks ownership.
  String pdfUrl(int planId) => ApiConfig.url('/diet-plans/$planId/pdf');

}